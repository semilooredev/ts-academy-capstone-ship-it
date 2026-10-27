# syntax=docker/dockerfile:1
FROM node:20.18.0-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY package*.json ./

RUN npm ci && \
    npm cache clean --force && \
    mv /usr/local/app/node_modules /node_modules && \
    chown -R node:node /usr/local/app

COPY --chown=node:node . .

ENV PORT=8080
EXPOSE 8080

USER node
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
