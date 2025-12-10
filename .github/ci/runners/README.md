````markdown
# Self-Hosted GitHub Actions Runners

This directory contains Docker Compose configurations for deploying GitHub Actions self-hosted runners across multiple servers.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions - 6 Parallel Self-Hosted Runners                          │
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

- ✅ **6x Parallel Execution**: Run 6 jobs simultaneously
- ✅ **High Availability**: 2 servers, if one fails 3 runners remain
- ✅ **Isolated Services**: No port conflicts between runners
- ✅ **Auto-Restart**: Survives server reboots
- ✅ **Cost Savings**: Unlimited GitHub Actions minutes
- ✅ **Fast CI**: No queue time, local caching

## Related Documentation

- [Setup Guide](../../../docs/SELF_HOSTED_RUNNER.md)
- [GitHub Actions Runner](https://github.com/myoung34/docker-github-actions-runner)
- Issue #169: Self-hosted runner implementation

```

<!-- CI-TRIGGER: docs change (no-op) -->
# Self-Hosted GitHub Actions Runners

This directory contains Docker Compose configurations for deploying GitHub Actions self-hosted runners across multiple servers.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions - 6 Parallel Self-Hosted Runners                          │
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

- ✅ **6x Parallel Execution**: Run 6 jobs simultaneously
- ✅ **High Availability**: 2 servers, if one fails 3 runners remain
- ✅ **Isolated Services**: No port conflicts between runners
- ✅ **Auto-Restart**: Survives server reboots
- ✅ **Cost Savings**: Unlimited GitHub Actions minutes
- ✅ **Fast CI**: No queue time, local caching

## Related Documentation

- [Setup Guide](../../../docs/SELF_HOSTED_RUNNER.md)
- [GitHub Actions Runner](https://github.com/myoung34/docker-github-actions-runner)
- Issue #169: Self-hosted runner implementation
