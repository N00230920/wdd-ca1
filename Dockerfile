# Shared backend base for development and production
FROM node:22-slim AS base
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
ENV PORT=8000
EXPOSE 8000

# Build the frontend into backend/dist
FROM node:22-slim AS frontend
WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Development target: watched backend plus the built frontend
FROM base AS dev
RUN npm ci
COPY backend/ ./
COPY --from=frontend /backend/dist ./dist
CMD ["npm", "run", "dev"]

# Production target: runtime dependencies and static frontend
FROM base AS production
ENV NODE_ENV=production
ENV API_URL=http://localhost:8000
RUN npm ci --omit=dev
COPY backend/ ./
COPY --from=frontend /backend/dist ./dist
RUN mkdir -p uploads && chown node:node uploads
USER node
CMD ["node", "src/server.js"]
