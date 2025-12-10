# Server Runners Deployment Instructions

## Overview

This document describes deploying the repository's self-hosted GitHub Actions runners across two servers named `ci0` and `ci1`.
 
Each server hosts three runner groups (3 parallel runners each). The composition is:


 The runners include isolated PostgreSQL and Redis services and run in a dedicated Docker network named `runner-network`.
````markdown
# Server Runners Deployment Instructions

## Overview

This document describes deploying the repository's self-hosted GitHub Actions runners across two servers named `ci0` and `ci1`.

Each server hosts three runner groups (3 parallel runners each). The composition is:

- `ci1` — runners 1-3 (Ubuntu)
- `ci0` — runners 4-6 (CentOS)

The runners include isolated PostgreSQL and Redis services and run in a dedicated Docker network named `runner-network`.

## Docker Compose and Environment

- Compose files:
   - `.github/ci/runners/docker-compose.ci1.yml` — configuration for runners 1–3 on `ci1`
   - `.github/ci/runners/docker-compose.ci0.yml` — configuration for runners 4–6 on `ci0`
   - `.github/ci/runners/.env.example` — example tokens for runners

Each runner container sets `DATABASE_URL` and `REDIS_URL` to point to its local PostgreSQL and Redis instances by alias (`postgres`, `redis`) inside the `runner-network`.

## Deployment Steps

### Step 1: Stop Existing Runners (if any)

On `ci0` server:
```bash
cd /path/to/runners
docker-compose -f docker-compose.ci0.yml down
```

On `ci1` server:
```bash
cd /path/to/runners
docker-compose -f docker-compose.ci1.yml down
```

### Step 2: Pull Latest Changes

On both servers:
```bash
git pull origin main
```

### Step 3: Start Runners with New Configuration

On `ci0` server:
```bash
docker-compose -f .github/ci/runners/docker-compose.ci0.yml up -d
```

On `ci1` server:
```bash
docker-compose -f .github/ci/runners/docker-compose.ci1.yml up -d
```

### Step 4: Verify Services

Check that services are healthy:
````markdown
# Server Runners Deployment Instructions

## Overview

This document describes deploying the repository's self-hosted GitHub Actions runners across two servers named `ci0` and `ci1`.

Each server hosts three runner groups (3 parallel runners each). The composition is:

- `ci1` — runners 1-3 (Ubuntu)
- `ci0` — runners 4-6 (CentOS)

The runners include isolated PostgreSQL and Redis services and run in a dedicated Docker network named `runner-network`.

## Docker Compose and Environment

- Compose files:
   - `.github/ci/runners/docker-compose.ci1.yml` — configuration for runners 1–3 on `ci1`
   - `.github/ci/runners/docker-compose.ci0.yml` — configuration for runners 4–6 on `ci0`
   - `.github/ci/runners/.env.example` — example tokens for runners

Each runner container sets `DATABASE_URL` and `REDIS_URL` to point to its local PostgreSQL and Redis instances by alias (`postgres`, `redis`) inside the `runner-network`.

## Deployment Steps

### Step 1: Stop Existing Runners (if any)

On `ci0` server:
```bash
cd /path/to/runners
docker-compose -f docker-compose.ci0.yml down
```

On `ci1` server:
```bash
cd /path/to/runners
docker-compose -f docker-compose.ci1.yml down
```

### Step 2: Pull Latest Changes

On both servers:
```bash
git pull origin main
```

### Step 3: Start Runners with New Configuration

On `ci0` server:
```bash
docker-compose -f .github/ci/runners/docker-compose.ci0.yml up -d
```

On `ci1` server:
```bash
docker-compose -f .github/ci/runners/docker-compose.ci1.yml up -d
```

### Step 4: Verify Services

Check that services are healthy:

```bash
# On ci0
docker ps | grep runner
docker logs runner-postgres-4
docker logs runner-redis-4
docker logs github-runner-4

# On ci1
docker ps | grep runner
docker logs runner-postgres-1
docker logs runner-redis-1
docker logs github-runner-1
```

### Step 5: Test Connectivity

Test PostgreSQL connectivity from within a runner:

```bash
# On ci0
docker exec github-runner-4 python -c "import psycopg2; psycopg2.connect(host='postgres', port=5432, dbname='realestate_test', user='test_user', password='test_pass'); print('PostgreSQL OK')"

# Test Redis
docker exec github-runner-4 sh -c "apk add --no-cache redis && redis-cli -h redis ping"
```

### Step 6: Update CI Configuration (optional)

If you previously restricted workflows to macOS, update `.github/workflows/ci.yml` to allow self-hosted runners. Example:

```yaml
integration-test:
   runs-on: self-hosted

docker-build:
   runs-on: self-hosted
```

### Step 7: Verify CI Jobs

Create a test PR and verify that integration tests and docker builds run on the server runners.

## Rollback Procedure

If you need to roll back to previous compose files:

```bash
git checkout HEAD~1 .github/ci/runners/docker-compose.ci0.yml
git checkout HEAD~1 .github/ci/runners/docker-compose.ci1.yml
docker-compose -f .github/ci/runners/docker-compose.ci0.yml down
docker-compose -f .github/ci/runners/docker-compose.ci0.yml up -d
```

## Validation

After deployment:

```bash
# Check runner labels in GitHub UI (should include: self-hosted, Linux, X64)
# Trigger CI workflow and verify integration tests pass
```

## Troubleshooting

- Check container logs with `docker logs <container>`
- Inspect `runner-network` with `docker network inspect runner-network`
- Ensure runner tokens in `.env` are valid (tokens expire after 1 hour)

````
