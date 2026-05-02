#!/bin/bash
echo "[RUNTIME] Deploiement des conteneurs..."

if [ -f "/opt/radm/runtime/docker-compose.yml" ]; then
    docker compose -f /opt/radm/runtime/docker-compose.yml up -d
    echo "Conteneurs demarres"
else
    echo "Aucun docker-compose.yml trouve"
fi

echo "[RUNTIME] Termine"