# Github Actins CI/CD Showcase for Python-based projects

[![CI Pipeline](https://github.com/Oleksandr-Gugnin-Software-Consulting/Customer-Demos/actions/workflows/ci.yml/badge.svg)](https://github.com/Oleksandr-Gugnin-Software-Consulting/Customer-Demos/actions/workflows/ci.yml)
[![Python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue.svg)](https://www.python.org/downloads/)
[![Code Style: Black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

> **Python application demonstrating production CI/CD pipelines, containerization, testing strategies, and infrastructure automation.**

This repository showcases professional software engineering practices for building, testing, and deploying modern Python applications. Perfect reference for teams seeking to implement robust DevOps workflows.

---

## Key Features

### **Production CI/CD Pipeline**
- **Modular GitHub Actions workflows** with reusable components
- **Multi-version testing** across Python 3.11, 3.12, and 3.13
- **Parallel execution** for unit and integration tests
- **Change detection** to optimize CI runs
- **Docker image building** with size optimization (target: < 200 MB)

### **Comprehensive Testing**
- **Unit tests** with pytest and parallel execution (pytest-xdist)
- **Integration tests** covering:
  - Database operations (PostgreSQL)
  - Message queue integration (Redis)
  - API endpoints (FastAPI)
  - Plugin architecture
- **Code coverage** reporting with pytest-cov
- **Performance benchmarks** with configurable thresholds

### **Code Quality & Security**
- **Automated linting** (Black, isort, Flake8)
- **Static type checking** (mypy)
- **Security scanning** (Bandit)
- **Pre-commit hooks** for local validation
- **Consistent formatting** across the codebase

### **Infrastructure as Code**
- **Self-hosted GitHub runners** with Docker Compose
- **Automated deployment script** with token management
- **Network isolation** via custom Docker networks
- **Service orchestration** (PostgreSQL, Redis per runner)

---

## 🏗️ Architecture

```
Customer-Demos/
├── core/                    # Application core
│   ├── app.py              # FastAPI application
│   └── utils.py            # Utility functions
├── tests/                   # Test suite
│   ├── unit/               # Unit tests
│   └── integration/        # Integration tests
├── .github/
│   ├── workflows/          # CI/CD pipelines
│   │   ├── ci.yml         # Main orchestration workflow
│   │   └── reusable-*.yml # Modular job definitions
│   └── ci/runners/         # Self-hosted runner infrastructure
│       ├── deploy_runner.sh        # Automated deployment
│       ├── docker-compose.ci0.yml  # Runner 0 setup
│       └── docker-compose.ci1.yml  # Runner 1 setup
├── Dockerfile              # Production container image
├── requirements.txt        # Runtime dependencies
├── requirements-dev.txt    # Development dependencies
└── pyproject.toml         # Project configuration
```

---

## 🚀 Quick Start

### **Prerequisites**
- Python 3.11 or higher
- Docker (for containerization)
- Git

### **Local Development**

1. **Clone the repository**
   ```bash
   git clone https://github.com/Oleksandr-Gugnin-Software-Consulting/Customer-Demos.git
   cd Customer-Demos
   ```

2. **Set up virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements-dev.txt
   pip install -e .
   ```

4. **Run tests**
   ```bash
   pytest                          # Run all tests
   pytest tests/unit              # Unit tests only
   pytest tests/integration       # Integration tests only
   pytest --cov=core --cov-report=html  # With coverage
   ```

5. **Run the application**
   ```bash
   uvicorn core.app:app --host 127.0.0.1 --port 8000 --reload
   ```

   Visit [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health) to verify.

### **Docker Deployment**

```bash
# Build the image
docker build -t customer-demos:latest .

# Run the container
docker run -p 8000:8000 customer-demos:latest
```

---

## 🔧 CI/CD Pipeline

### **Workflow Architecture**

The CI pipeline uses **reusable workflows** for modularity and maintainability:

| Workflow | Purpose | Triggers |
|----------|---------|----------|
| `ci.yml` | Main orchestrator | Push, PR to `main` |
| `reusable-test.yml` | Unit tests (matrix: 3.11, 3.12, 3.13) | Called by `ci.yml` |
| `reusable-integration.yml` | Integration tests (4 suites) | Called by `ci.yml` |
| `reusable-lint.yml` | Code formatting validation | Called by `ci.yml` |
| `reusable-typecheck.yml` | Static type checking | Called by `ci.yml` |
| `reusable-security.yml` | Security vulnerability scanning | Called by `ci.yml` |
| `reusable-performance.yml` | Benchmark tests | Called by `ci.yml` |

### **Change Detection**

The pipeline intelligently skips jobs when changes don't affect them:
- **Core changes** → Run all tests
- **Documentation only** → Skip tests, run lint
- **CI config changes** → Run all jobs

### **Performance Metrics**
- **Docker image size**: ~155 MB (target: < 200 MB)
- **Unit test duration**: ~30 seconds (3 Python versions in parallel)
- **Integration test duration**: ~2 minutes (4 suites in parallel)

---

## 🛠️ Self-Hosted Runners

Deploy GitHub Actions runners with automated token management:

```bash
# Deploy locally
.github/ci/runners/deploy_runner.sh \
  --target ci0 \
  --local

# Deploy to remote server
.github/ci/runners/deploy_runner.sh \
  --target ci0 \
  --server user@hostname \
  --repo Oleksandr-Gugnin-Software-Consulting/Customer-Demos
```

**Features:**
- Auto-generates runner registration tokens via GitHub CLI
- Supports local and remote deployment (SSH)
- Configures isolated Docker networks
- Sets up PostgreSQL and Redis per runner

📖 See [`.github/ci/runners/README.md`](.github/ci/runners/README.md) for details.

---

## 📊 Code Quality Standards

- **Test Coverage**: Minimum 80% (tracked via pytest-cov)
- **Type Coverage**: 100% with mypy strict mode
- **Security**: Zero high-severity Bandit findings
- **Formatting**: Black (line length: 88)
- **Import Sorting**: isort (compatible with Black)
- **Linting**: Flake8 (max complexity: 10)

---

## 🤝 Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test locally**
   ```bash
   pytest
   pre-commit run --all-files  # Run formatters and linters
   ```

3. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add new feature"
   git commit -m "fix: resolve bug in utils"
   git commit -m "docs: update README"
   ```

4. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

The CI pipeline will automatically:
- Run all tests across Python versions
- Check code formatting and types
- Scan for security issues
- Build and validate Docker image

---

## 📝 Technologies Used

| Category | Technologies |
|----------|-------------|
| **Language** | Python 3.11+ |
| **Web Framework** | FastAPI, Uvicorn |
| **Testing** | pytest, pytest-xdist, pytest-cov |
| **Code Quality** | Black, isort, Flake8, mypy, Bandit |
| **CI/CD** | GitHub Actions (reusable workflows) |
| **Containerization** | Docker, Docker Compose |
| **Databases** | PostgreSQL (integration tests) |
| **Caching** | Redis (integration tests) |
| **Automation** | Bash scripting, GitHub CLI |

---

## 📈 Project Highlights

✅ **Production-ready CI/CD** with optimized parallel execution  
✅ **Multi-environment testing** (Python 3.11, 3.12, 3.13)  
✅ **Infrastructure automation** for self-hosted runners  
✅ **Comprehensive test coverage** (unit + integration)  
✅ **Security-first approach** with automated scanning  
✅ **Docker best practices** (slim images, non-root user)  
✅ **Maintainable architecture** with reusable workflows  

---

## 📧 Contact

**Oleksandr Gugnin**

- GitHub: [@Oleksandr-Gugnin-Software-Consulting](https://github.com/Oleksandr-Gugnin-Software-Consulting)
- Repository: [Customer-Demos](https://github.com/Oleksandr-Gugnin-Software-Consulting/Customer-Demos)

---

## 📄 License

This project is a demonstration repository for showcasing professional software engineering practices.