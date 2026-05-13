#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="agile-autonomy:noetic-ubuntu20"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XSOCK="/tmp/.X11-unix"
XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: docker daemon is not reachable. Try: sudo systemctl start docker" >&2
  exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Building $IMAGE_NAME ..."
  docker build -t "$IMAGE_NAME" -f "$REPO_ROOT/docker/Dockerfile.noetic-ubuntu20" "$REPO_ROOT"
fi

GPU_ARGS=()
if docker run --help | grep -q -- '--gpus'; then
  GPU_ARGS=(--gpus all)
fi

X11_ARGS=()
if [[ -d "$XSOCK" ]]; then
  xhost +local:docker >/dev/null 2>&1 || true
  X11_ARGS=(-e DISPLAY="${DISPLAY:-:0}" -v "$XSOCK:$XSOCK:rw")
  if [[ -f "$XAUTH" ]]; then
    X11_ARGS+=(-e XAUTHORITY=/root/.Xauthority -v "$XAUTH:/root/.Xauthority:ro")
  fi
fi

docker run --rm -it \
  "${GPU_ARGS[@]}" \
  --net=host \
  --ipc=host \
  --privileged \
  "${X11_ARGS[@]}" \
  -v "$REPO_ROOT:/workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy:rw" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -w /workspace/agile_autonomy_ws \
  "$IMAGE_NAME" \
  bash
