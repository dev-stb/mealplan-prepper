# =============================
# Stage 1: Build (Install Poetry & dependencies)
# =============================
FROM python:3.11-slim as builder

# Set environment variables
# Prevents Python from writing pyc files to disk
ENV PYTHONDONTWRITEBYTECODE=1
# Ensures that Python output is logged directly to the terminal
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Install system dependencies for Poetry and build process
RUN apt-get update && apt-get install -y curl gcc libpq-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to the system PATH
ENV PATH="/root/.local/bin:$PATH"

# Copy only pyproject.toml and poetry.lock to leverage Docker cache for dependencies
COPY mealplan-prepper-backend/pyproject.toml mealplan-prepper-backend/poetry.lock /app/

# Install dependencies without installing project
RUN poetry install --no-dev --no-root

# =============================
# Stage 2: Final Stage (Production Image)
# =============================
FROM python:3.11-slim as development

# Set environment variables
# Prevents Python from writing pyc files to disk
ENV PYTHONDONTWRITEBYTECODE=1
# Ensures that Python output is logged directly to the terminal
ENV PYTHONUNBUFFERED=1  

# Set the working directory
WORKDIR /app

# Install system dependencies required for production
RUN apt-get update && apt-get install -y libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy application source code from the host
COPY mealplan-prepper-backend/ /app/

# Copy the installed dependencies from the build stage
COPY --from=builder /root/.cache/pypoetry/virtualenvs/**/ /opt/venv

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Expose Django's default port
EXPOSE 8000

# Run database migrations and start the Django development server
CMD ["sh", "-c", "python manage.py runserver 0.0.0.0:8000"]

FROM development as production

RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
RUN chown -R appuser:appuser /opt/venv
USER appuser

CMD ["sh", "-c", "uvicorn mealplan_prepper_backend.asgi:application --host 0.0.0.0 --port 8000"]