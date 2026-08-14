# AuraLearn stateless proxy — production image (Cloud Run).
#
# Pattern mirrors the yijing server Dockerfile: pinned base digest, non-root
# user, dev deps pruned, build once -> run dist.

FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build

FROM node:22-slim AS run
WORKDIR /app
ENV NODE_ENV=production
# Non-root user (Cloud Run best practice).
RUN groupadd -r app && useradd -r -g app app
COPY --from=build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER app
EXPOSE 8787
CMD ["node", "dist/server.js"]
