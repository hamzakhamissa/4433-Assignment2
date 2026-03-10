#!/usr/bin/env bash
set -euo pipefail

IMAGE="docker.elastic.co/elasticsearch/elasticsearch:8.6.0"
CONTAINER="es01"
NETWORK="elastic"

docker network create "${NETWORK}" >/dev/null 2>&1 || true
docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true

docker run -d \
  --name "${CONTAINER}" \
  --net "${NETWORK}" \
  -p 9200:9200 \
  -m 1GB \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  "${IMAGE}" >/dev/null

echo "Elasticsearch is starting in container '${CONTAINER}'."
echo "Watch logs with: docker logs -f ${CONTAINER}"
echo "Health check: curl http://localhost:9200"

