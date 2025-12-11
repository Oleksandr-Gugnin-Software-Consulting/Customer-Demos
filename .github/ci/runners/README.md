````markdown
# Self-Hosted GitHub Actions Runners

This directory contains Docker Compose configurations for deploying GitHub Actions self-hosted runners across multiple servers.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions - Multiple Parallel Self-Hosted Runners                          │
└───────────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────┴──────────────────┐
        │                                     │
        ▼                                     ▼
┌─────────────────────────────────┐  ┌─────────────────────────────────┐
│  ci1 Server (Ubuntu)            │  │  ci0 Server (CentOS)            │
│                                 │  │                                 │
│  ┌──────────┐ ┌──────────┐     │  │  ┌──────────┐ ┌──────────┐     │
│  │Runner-1  │ │Runner-2  │     │  │  │Runner-4  │ │Runner-5  │     │
│  │PG: 5432  │ │PG: 5433  │ ... │  │  │PG: 5432  │ │PG: 5433  │ ... │
│  │Redis:6379│ │Redis:6380│     │  │  │Redis:6379│ │Redis:6380│     │
│  └──────────┘ └──────────┘     │  │  └──────────┘ └──────────┘     │
│                                 │  │                                 │
│  + Runner-3 (PG:5434, R:6381)  │  │  + Runner-6 (PG:5434, R:6381)  │
└─────────────────────────────────┘  └─────────────────────────────────┘
```

## Files

- `docker-compose.ci1.yml` - Configuration for runners 1-3 on ci1 server
- `docker-compose.ci0.yml` - Configuration for runners 4-6 on ci0 server
- `.env.example` - Example environment variables template

## Quick Start

### 1. Generate Registration Tokens

```bash
# Generate 3 tokens for each server
for i in {1..3}; do
  gh api -X POST repos/Oleksandr-Gugnin-Software-Consulting/Customer-Demos/actions/runners/registration-token --jq '.token'
done
```

### 2. Create .env File

```bash
# On each server (ci1, ci0)
cd ~/github-runner
cp .env.example .env
# Edit .env and paste the tokens
```

### 3. Deploy on ci1

# Self-Hosted GitHub Actions Runners

This directory contains Docker Compose configurations and helper files for
deploying GitHub Actions self-hosted runners across multiple servers. The
document below describes the current, supported deployment layout and
the commands used for registration and basic maintenance.

## Architecture (high level)

Two physical servers (referred to as `ci1` and `ci0`) host three runners
each, giving six parallel self-hosted runners:

- `ci1` — runners 1..3 (Ubuntu)
- `ci0` — runners 4..6 (CentOS)

Each runner is accompanied by isolated PostgreSQL and Redis containers to
support integration tests without port conflicts between runners.

## Files in this directory

- `docker-compose.ci1.yml` — Compose file for runners 1–3 (server `ci1`)
- `docker-compose.ci0.yml` — Compose file for runners 4–6 (server `ci0`)
- `.env.example` — Environment template for runner registration tokens and
  other runtime variables

## Quick Start

A small helper script is provided to automate deployment of self-hosted
runners from this repository. The script copies the selected compose file,
creates a `.env` (optionally populated with tokens) and starts the services
either locally or on a remote host via SSH.


Usage examples:

```bash
# Deploy remotely to `ci1` (replace user@ci1 with your SSH target), let the
# script generate tokens via the authenticated `gh` CLI:
.github/ci/runners/deploy_runner.sh --target user@ci1 --server ci1

# Deploy locally on the server and have the script generate tokens:
.github/ci/runners/deploy_runner.sh --server ci0 --local

# If you prefer to provide tokens yourself, use --tokens:
.github/ci/runners/deploy_runner.sh --target user@ci1 --server ci1 --tokens T1,T2,T3

# To target a different GitHub repository when generating tokens, pass --repo:
.github/ci/runners/deploy_runner.sh --target user@ci1 --server ci1 --repo myorg/my-repo
```

If you prefer to manage files manually, the compose files for each server are
still present in this directory (`docker-compose.ci1.yml` and
`docker-compose.ci0.yml`).

## Generating registration tokens

Automatic generation (recommended)

The `deploy_runner.sh` script can automatically create registration tokens
using the `gh` CLI. If `--tokens` is not provided the script will attempt to
generate three tokens by calling the GitHub API through `gh`:

```text
gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token --jq '.token'
```

Requirements and notes:
- `gh` must be installed and authenticated on the machine where you run the
  deploy script (the script will call `gh api`).
- The authenticated account (or token used by `gh`) must have permissions to
  create registration tokens for the target repository.
- Generated tokens expire after one hour; the script writes them into the
  generated `.env` as `RUNNER_TOKEN_1/2/3` and then copies that `.env` to the
  target host.

Manual generation (optional)

If you prefer to create tokens manually, you can run the command above and
paste the resulting tokens into `.env` on the target host (or pass them via
`--tokens T1,T2,T3` to the script).

## Port allocation and isolation

Each runner runs its own PostgreSQL and Redis container. Host port mappings
are unique per runner to avoid host-port collisions (see the Port Allocation
table below). Inside each container PostgreSQL and Redis use their standard
internal ports (`5432` and `6379`).

The compose files publish these services on the host using distinct ports
(for example `5432`/`5433`/`5434` and `6379`/`6380`/`6381`) so services are
accessible from the host at those ports. Services are also reachable to other
containers on the same Docker network (`runner-network`) by service name.

Important implementation note: in the current compose files an alias named
`postgres` and `redis` is attached only to the *first* database/redis service
in each compose (for example `postgres-1` in `docker-compose.ci1.yml` or
`postgres-4` in `docker-compose.ci0.yml`). The runner containers' environment
variables (`DATABASE_URL`, `REDIS_URL`) currently use the hostnames
`postgres` and `redis`. That means, as implemented today, all runners in a
given compose file will resolve `postgres` / `redis` to the aliased instance
(the first one) unless you explicitly update a runner's environment to point
to `postgres-2`, `redis-2`, etc.

This README describes the repository's actual configuration (no code
changes). If you want per-runner DNS isolation instead of shared aliases,
adjust the runner `DATABASE_URL`/`REDIS_URL` to reference the explicit
service names (for example `postgres-2` / `redis-2`).

## Maintenance

- View logs: `docker-compose logs -f`
- Restart services: `docker-compose restart`
- Update images: `docker-compose pull && docker-compose up -d`
- Remove containers/networks (keeps volumes): `docker-compose down`
- Remove everything including volumes: `docker-compose down -v`

## Troubleshooting (common checks)

- Token not accepted: ensure token is fresh (tokens expire after 1 hour).
- Runner not appearing: check container logs (`docker logs <runner>`) and
  verify network connectivity to GitHub.
- Database connection failures: inspect the postgres container logs and
  ensure the compose file is not conflicting with other local services.

## Security notes

- The Docker socket is mounted inside the runner containers by design to
  support Docker-in-Docker scenarios; limit server access and use
  appropriate host security controls.
- Runner tokens rotate and must be kept secret.

## Benefits (current)

- 6x parallel execution (six self-hosted runners)
- High availability with runners across two servers
- Isolated test services per runner to avoid port conflicts

## Related documentation

- Setup Guide: `docs/SELF_HOSTED_RUNNER.md` (relative link)
- Runner image used: https://github.com/myoung34/docker-github-actions-runner


```bash
# Copy docker-compose to server
scp docker-compose.ci1.yml ci1:~/github-runner/docker-compose.yml

# SSH to server and start
ssh ci1
cd ~/github-runner
docker-compose up -d

# Verify
docker-compose ps
```

### 4. Deploy on ci0

```bash
# Copy docker-compose to server

scp docker-compose.ci0.yml ci0:~/github-runner/docker-compose.yml

# SSH to server and start
ssh ci0
cd ~/github-runner
docker-compose up -d

# Verify
docker-compose ps
```

## Configuration Details

### Each Runner Includes

- **GitHub Runner Container**: Executes CI/CD jobs
- **PostgreSQL 15**: Isolated test database (ports 5432, 5433, 5434)
- **Redis 7**: Isolated cache/session store (ports 6379, 6380, 6381)
- **Persistent Volumes**: Data survives container restarts
- **Health Checks**: Ensures services are ready before runner starts
- **Auto-Restart**: `restart: unless-stopped` policy on all containers

### Port Allocation

| Runner | Server | PostgreSQL | Redis |
|--------|--------|------------|-------|
| 1      | ci1    | 5432       | 6379  |
| 2      | ci1    | 5433       | 6380  |
| 3      | ci1    | 5434       | 6381  |
| 4      | ci0    | 5432       | 6379  |
| 5      | ci0    | 5433       | 6380  |
| 6      | ci0    | 5434       | 6381  |

## Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific runner
docker logs -f github-runner-1

# Specific service
docker logs -f runner-postgres-1
```

### Restart Runners

```bash
# All services
docker-compose restart

# Specific runner
docker-compose restart github-runner-1
```

### Update Images

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

### Renew Tokens

Runner tokens expire after 1 hour. To regenerate:

```bash
# Generate new token
gh api -X POST repos/Oleksandr-Gugnin-Software-Consulting/Customer-Demos/actions/runners/registration-token --jq '.token'

# Update .env
echo "RUNNER_TOKEN_1=NEW_TOKEN" >> .env

# Restart runner
docker-compose restart github-runner-1
```

### Stop Services

```bash
# Stop all
docker-compose stop

# Stop specific service
docker-compose stop github-runner-1
```

### Remove Everything

# Stop and remove containers, networks (keeps volumes)
docker-compose down

# Remove everything including volumes
docker-compose down -v
```

## Monitoring

### Check Runner Status

```bash
# Via GitHub API
gh api repos/Oleksandr-Gugnin-Software-Consulting/Customer-Demos/actions/runners --jq '.runners[] | {name, status, busy}'

# Container health
docker ps
docker stats
```

### Resource Usage

```bash
# CPU and memory
docker stats

# Disk usage
df -h
docker system df
```

## Troubleshooting

### Runner Not Appearing in GitHub

1. Check token is valid (expires in 1 hour)
2. Verify container logs: `docker logs github-runner-1`
3. Ensure network connectivity to GitHub
4. Check Docker socket is mounted

### Database Connection Failed

```bash
# Test PostgreSQL
docker exec runner-postgres-1 psql -U test_user -d realestate_test -c "SELECT 1;"

# Check health
docker inspect runner-postgres-1 | grep -A 10 Health

# Restart if needed
docker-compose restart postgres-1
```

### Redis Connection Failed

```bash
# Test Redis
docker exec runner-redis-1 redis-cli ping

# Check health
docker inspect runner-redis-1 | grep -A 10 Health

# Restart if needed
docker-compose restart redis-1
```

### Port Already in Use

If you see "port is already allocated":

1. Check what's using the port: `sudo lsof -i :5432`
2. Stop conflicting service
3. Or change port in docker-compose.yml

## Security

- PostgreSQL and Redis only exposed on localhost
- Runner tokens auto-rotate after registration
- Docker socket mounted (required for Docker-in-Docker)
- Network isolation via Docker bridge network
- Server access via SSH only

## Benefits

- **Nx Parallel Execution**: Run N jobs simultaneously
- **High Availability**: Several servers, if one fails other runners remain
- **Isolated Services**: No port conflicts between runners
- **Auto-Restart**: Survives server reboots
- **Cost Savings**: Unlimited GitHub Actions minutes
- **Fast CI**: No queue time, local caching

## Related Documentation

- [Setup Guide](../../../docs/SELF_HOSTED_RUNNER.md)
- [GitHub Actions Runner](https://github.com/myoung34/docker-github-actions-runner)
