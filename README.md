# Customer-Demos — Demo GitHub Actions Workflow

Этот репозиторий содержит пример (demo) конфигурации CI для проекта на Python и демонстрирует несколько возможностей GitHub Actions и сопутствующих инструментов.

**Цель этого README** — быстро объяснить, что демонстрирует workflow, какие элементы в нём присутствуют и где смотреть ключевые файлы.

**Что демонстрируется**

- **Детектирование изменений:** отдельный шаг/джоб, определяющий какие части репозитория изменились и какие джобы нужно запускать.
- **Reusable workflows:** разбивка CI на переиспользуемые workflow-файлы (`.github/workflows/reusable-*.yml`) и вызов их из основного workflow (`.github/workflows/ci.yml`).
- **Матрицы тестирования:** запуск unit/integration тестов на нескольких версиях Python и комбинациях окружений.
- **Линт, типизация и безопасность:** linting (black/isort/flake8), static type checking (mypy) и security scanning (bandit).
- **Integration tests:** отдельные интеграционные сценарии (database, messaging, plugins, api) с запуском вспомогательных сервисов через Docker Compose.
- **Performance:** замеры производительности / benchmark job.
- **Docker image build:** сборка тестового образа и проверка размера/артефактов.

**Ключевые элементы workflow и где их смотреть**

- ` .github/workflows/ci.yml` : основной orchestrator pipeline (вызовы reusable workflows, управление условиями запуска).
- ` .github/workflows/reusable-*.yml` : набор переиспользуемых workflow-файлов (unit tests, integration, lint, typecheck, security, performance).
- ` .github/ci/runners/` : compose-файлы и скрипты для локального/удалённого развёртывания self-hosted раннеров.
- ` .github/ci/runners/deploy_runner.sh` : утилита для автоматического деплоя раннера и генерации регистрационных токенов через GitHub CLI.
- ` pytest.ini`, `pyproject.toml`, `setup.py` : вспомогательные файлы для тестов и установки в CI (`pip install -e .`).

**Что включено в демонстрацию (коротко)**

- Pipeline показывает, как организовать CI через переиспользуемые блоки и как ограничивать запуск джобов в зависимости от изменённых файлов.
- Показаны best-practices для Python-проектов: изоляция зависимостей, тесты, lint, typecheck, security scan.
- Показан пример взаимодействия с Docker Compose для интеграционных проверок и развёртывания self-hosted раннеров.

**Как использовать / запустить локально**

- Локально можно прогнать тесты стандартными командами:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

- Чтобы протестировать workflow-демо на GitHub — внесите изменения в ветку и создайте PR или пуш в `main` — GitHub Actions автоматически запустит `ci.yml`.

**Замечания и ограничения**

- В репозитории есть несколько pragmatic-воркараундов (к примеру, временный `psycopg2`-stub и прочие вспомогательные правки), выполненных для того, чтобы демонстрационные прогоны CI были надёжными. Их можно заменить на более строгие проверки готовности сервисов.
- Некоторые куски конфигурации (например, детекция изменений) оставлены inline в основном workflow из-за совместимости локальных линтеров и схемы reusable workflows.

Если хотите, могу дополнить README диаграммой, примером запуска конкретного job-а локально (act/runner) или перевести его на английский.
