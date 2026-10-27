FROM python:3.11.10-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /seed

COPY . .

RUN python make-data.py && chown -R nobody:nogroup /seed

USER nobody
CMD ["/seed/generate-votes.sh"]
