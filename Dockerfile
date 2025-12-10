FROM python:3.13-slim

WORKDIR /app

# Install runtime requirements
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy package
COPY . /app

EXPOSE 8000

CMD ["uvicorn", "core.app:app", "--host", "0.0.0.0", "--port", "8000"]

# ci-trigger: no-op change to cause CI to run all jobs
