#!/usr/bin/env bash
set -euo pipefail

echo "== Assignment 2 Environment Check =="
echo

echo "[1/5] Java runtime"
java -version
echo

echo "[2/5] Available JDK installs"
/usr/libexec/java_home -V || true
echo

echo "[3/5] curl"
curl --version | head -n 1
echo

echo "[4/5] Docker CLI"
docker --version
echo

echo "[5/5] Docker daemon status"
if docker info >/dev/null 2>&1; then
  echo "Docker daemon is running."
else
  echo "Docker daemon is NOT running. Start Docker Desktop, then re-run this script."
fi

