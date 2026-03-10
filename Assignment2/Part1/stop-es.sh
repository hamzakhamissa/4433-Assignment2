#!/usr/bin/env bash
set -euo pipefail

docker rm -f es01 >/dev/null 2>&1 || true
echo "Elasticsearch container 'es01' stopped and removed."

