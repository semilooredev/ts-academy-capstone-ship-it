# syntax=docker/dockerfile:1
FROM node:20.18.0-bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY package*.json ./

RUN npm ci && \
    npm cache clean --force && \
    mv /usr/local/app/node_modules /node_modules && \
    chown -R node:node /usr/local/app

# The app never uses npm at runtime, and the npm bundled with the node base
# image ships language packages with known HIGH/CRITICAL vulnerabilities
# (tar, pacote, glob, minimatch, ...). Remove it from the production image
# so the image scan only sees the application's own dependencies.
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

COPY --chown=node:node . .

ENV PORT=8080
EXPOSE 8080

USER node
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
