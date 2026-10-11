# ---- Stage 1: build ----
FROM node:20-alpine AS builder
WORKDIR /app

# Dependencies first (layer cache): only reinstalls when package files change.
COPY package*.json ./
RUN npm ci

# Prisma client must be generated before the TS build references it.
COPY prisma ./prisma
RUN npx prisma generate

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ---- Stage 2: runtime ----
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
# wget is used by the container HEALTHCHECK; pm2 runs the API in cluster mode.
RUN apk add --no-cache wget && npm i -g pm2

COPY package*.json ./
RUN npm ci --omit=dev
# Generated Prisma client + engines from the builder (avoids re-generating).
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

USER node
EXPOSE 3000
# Default command is the API; worker/scheduler override `command` in compose.
CMD ["pm2-runtime", "start", "dist/main.js", "-i", "max", "--name", "pigeon-api"]
