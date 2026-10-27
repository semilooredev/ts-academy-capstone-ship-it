# syntax=docker/dockerfile:1
# Upstream base stage, hardened for the capstone: the Python version is pinned
# and the production stage runs as an unprivileged user on port 8080.
FROM python:3.11.10-slim-bookworm AS base

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir --upgrade setuptools wheel

# Development stage retained from upstream for local debugging only. The
# Compose file and CI use the final stage below.
FROM base AS dev
RUN pip install --no-cache-dir watchdog==6.0.0
ENV FLASK_ENV=development
CMD ["python", "app.py"]

FROM base AS final

RUN groupadd --gid 10001 app && \
    useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

COPY --chown=app:app . .

USER app
EXPOSE 8080

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
