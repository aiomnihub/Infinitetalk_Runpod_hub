#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Start ComfyUI in the background
echo "Starting ComfyUI in the background..."
# The image's fast attention kernels exist for Blackwell (compute capability 12) only; any other GPU (an H100 is 9.0)
# uses PyTorch's own attention (2026-10-26: an H100 failed with "SM90 kernel is not available"). The handler reads
# AIO_ATTENTION and sets the video model's attention mode to match.
CAP_MAJOR=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -n 1 | cut -d. -f1)
if [ "${CAP_MAJOR:-0}" -ge 10 ] 2>/dev/null; then
    export AIO_ATTENTION=sageattn
    SAGE_FLAG="--use-sage-attention"
else
    export AIO_ATTENTION=sdpa
    SAGE_FLAG=""
fi
echo "GPU compute capability ${CAP_MAJOR:-unknown}: attention ${AIO_ATTENTION}"
python /ComfyUI/main.py --listen $SAGE_FLAG &

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
max_wait=120  # 최대 2분 대기
wait_count=0
while [ $wait_count -lt $max_wait ]; do
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    echo "Waiting for ComfyUI... ($wait_count/$max_wait)"
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "Error: ComfyUI failed to start within $max_wait seconds"
    exit 1
fi

# Start the handler in the foreground
# 이 스크립트가 컨테이너의 메인 프로세스가 됩니다.
echo "Starting the handler..."
exec python handler.py