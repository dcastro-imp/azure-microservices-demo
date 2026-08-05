# --- Build stage: Node compiles the React app into static files ---
FROM node:22-alpine AS build
WORKDIR /src

COPY package*.json .
RUN npm install

COPY . .
# Baked in at build time — Vite env vars are resolved during "npm run build",
# not at container runtime, so this must be a build ARG, not an ENV var.
ARG VITE_API_URL
RUN npm run build

# --- Runtime stage: Nginx just serves the pre-built static files ---
FROM nginx:1.27-alpine AS runtime
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 80
