#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'USAGE'
Usage: deploy_runner.sh [--target user@host] [--server ci1|ci0] [--tokens t1,t2,t3] [--local]

Options:
  --target user@host   : deploy to a remote host (uses SSH + SCP). If omitted and
                         --local is not provided, script will operate locally.
  --server ci1|ci0     : which compose file to use (default: ci1)
  --tokens t1,t2,t3    : comma-separated runner registration tokens to populate .env
  --local              : perform deployment on the local machine (don't use SSH)
  -h, --help           : show this help

Examples:
  # Deploy remotely to ci1 using three tokens
  .github/ci/runners/deploy_runner.sh --target deploy@ci1.example.com --server ci1 --tokens T1,T2,T3

  # Deploy locally (run on the target server)
  .github/ci/runners/deploy_runner.sh --server ci0 --local --tokens T4,T5,T6
USAGE
}

err() { echo "ERROR: $*" >&2; exit 1; }

if [[ ${#@} -eq 0 ]]; then usage; exit 0; fi

target=""
server="ci1"
tokens=""
local_mode=0

repo=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="$2"; shift 2 ;;
    --repo) repo="$2"; shift 2 ;;
    --server) server="$2"; shift 2 ;;
    --tokens) tokens="$2"; shift 2 ;;
    --local) local_mode=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1" ;;
  esac
done

case "$server" in
  ci1) compose_file="$DIR/docker-compose.ci1.yml" ;;
  ci0) compose_file="$DIR/docker-compose.ci0.yml" ;;
  *) err "Unknown server: $server" ;;
esac

if [[ ! -f "$compose_file" ]]; then
  err "Compose file not found: $compose_file"
fi

REMOTE_DIR="~/github-runner"

build_env_file() {
  # $1: output path
  local out="$1"
  if [[ -f "$DIR/.env.example" ]]; then
    cat "$DIR/.env.example" > "$out"
  else
    cat > "$out" <<EOF
# Generated .env file for runners
EOF
  fi

  if [[ -n "$tokens" ]]; then
    IFS=',' read -r t1 t2 t3 <<< "$tokens"
    [[ -n "$t1" ]] && echo "RUNNER_TOKEN_1=$t1" >> "$out"
    [[ -n "$t2" ]] && echo "RUNNER_TOKEN_2=$t2" >> "$out"
    [[ -n "$t3" ]] && echo "RUNNER_TOKEN_3=$t3" >> "$out"
  else
    echo "# Place RUNNER_TOKEN_1, RUNNER_TOKEN_2, RUNNER_TOKEN_3 in this file before starting the runners" >> "$out"
  fi
}

generate_tokens_via_gh() {
  # Populate global 'tokens' variable with comma-separated tokens
  # Determine repo to use
  if [[ -n "$repo" ]]; then
    use_repo="$repo"
  else
    # Try gh to detect repo, fallback to default
    if command -v gh >/dev/null 2>&1; then
      use_repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)
    fi
    if [[ -z "$use_repo" ]]; then
      use_repo="Oleksandr-Gugnin-Software-Consulting/Customer-Demos"
    fi
  fi

  echo "Generating 3 registration tokens for repository $use_repo (via gh)..."
  tlist=()
  for i in 1 2 3; do
    # Use gh api to create a registration token
    token=$(gh api -X POST repos/$use_repo/actions/runners/registration-token --jq '.token' 2>/dev/null || true)
    if [[ -z "$token" ]]; then
      echo "Failed to generate token #$i via gh for repo $use_repo" >&2
      return 1
    fi
    tlist+=("$token")
    # small sleep to avoid hitting rate limits
    sleep 0.2
  done
  tokens=$(IFS=,; echo "${tlist[*]}")
}

run_compose_cmd() {
  local cmd="$1"; shift
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose -f "$@" $cmd
  else
    docker-compose -f "$@" $cmd
  fi
}

if [[ $local_mode -eq 1 && -n "$target" ]]; then
  echo "Both --local and --target provided; please choose one."; exit 1
fi

if [[ -n "$target" ]]; then
  echo "Deploying to remote host: $target"
  tmp_compose=$(mktemp)
  tmp_env=$(mktemp)
  cp "$compose_file" "$tmp_compose"
  build_env_file "$tmp_env"

  echo "Creating remote directory $REMOTE_DIR"
  ssh "$target" "mkdir -p $REMOTE_DIR"

  echo "Copying compose and .env to remote host"
  scp "$tmp_compose" "$target":"$REMOTE_DIR/docker-compose.yml"
  scp "$tmp_env" "$target":"$REMOTE_DIR/.env"

  echo "Starting services on remote host"
  ssh "$target" "cd $REMOTE_DIR && (docker compose pull || true) && (docker compose up -d)"

  echo "Remote deployment finished. You can run: ssh $target 'cd $REMOTE_DIR && docker compose ps' to inspect services."

  rm -f "$tmp_compose" "$tmp_env"
  exit 0
fi

echo "Performing local deployment using $compose_file"
workdir="./github-runner"
mkdir -p "$workdir"
cp "$compose_file" "$workdir/docker-compose.yml"
build_env_file "$workdir/.env"

pushd "$workdir" >/dev/null
echo "Starting services locally (in $workdir)"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose pull || true
  docker compose up -d
else
  docker-compose pull || true
  docker-compose up -d
fi
echo "Local deployment finished. Check 'docker compose ps' or 'docker ps' for status."
popd >/dev/null

exit 0
