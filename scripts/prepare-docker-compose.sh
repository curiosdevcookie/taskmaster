#!/bin/sh
cat << EOF
networks:
  internal:
  traefik_default:
    external: true

services:

  backend:
    image: docker.io/postgres:13
    privileged: true
    env_file: .env
    environment:
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - db_data:/var/lib/postgresql/data
    expose:
      - 5432
    networks:
      - internal
    container_name: taskmaster-db
    restart: unless-stopped
    logging:
      driver: loki
      options:
        loki-external-labels: job=docker,container_name={{.Name}},owner=curiosdevcookie,environment=\${ENV},system=taskmaster-db
    hostname: backend

  frontend:
    image: $APP_DEPLOY_IMAGE
    privileged: true
    env_file: .env
    environment:
      PHX_CHECK_ORIGIN: https://\${PHX_HOST}
      POOL_SIZE: 10
      PORT: 8080
    networks:
      - traefik_default
      - internal
    container_name: taskmaster
    volumes:
      - app_data:/app/lib/task_master-0.1.0/priv/static
    restart: unless-stopped
    logging:
      driver: loki
      options:
        loki-external-labels: job=docker,container_name={{.Name}},owner=curiosdevcookie,environment=\${ENV},system=taskmaster-app
    depends_on:  
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik_default"
      - "traefik.http.routers.\${TRAEFIK_LABEL}-http.entrypoints=web"
      - "traefik.http.routers.\${TRAEFIK_LABEL}-http.rule=Host(\`\${DOMAIN}\`)"
      - "traefik.http.routers.\${TRAEFIK_LABEL}-http.middlewares=\${TRAEFIK_LABEL}-https"
      - "traefik.http.middlewares.\${TRAEFIK_LABEL}-https.redirectscheme.scheme=https"
      - "traefik.http.services.\${TRAEFIK_LABEL}.loadbalancer.server.port=8080"
      - "traefik.http.routers.\${TRAEFIK_LABEL}.rule=Host(\`\${DOMAIN}\`)"
      - "traefik.http.routers.\${TRAEFIK_LABEL}.entrypoints=websecure"
      - "traefik.http.routers.\${TRAEFIK_LABEL}.tls=true"
      - "traefik.http.routers.\${TRAEFIK_LABEL}.tls.certresolver=leresolver"
  migration:
    image: $APP_DEPLOY_IMAGE
    privileged: true
    env_file: .env
    depends_on:
      - backend
    command: ["/app/bin/migrate"]
    logging:
      driver: loki
      options:
        loki-external-labels: job=docker,container_name={{.Name}},owner=curiosdevcookie,environment=\${ENV},system=taskmaster-migration
    container_name: taskmaster-migration
    networks:
      - internal
volumes:
  db_data:
  app_data:
EOF
