#!/bin/bash

# Virtual Phone System - Whisper.cpp Installation Script
# Installs Whisper.cpp for speech-to-text transcription

set -e

echo "=========================================="
echo "Installing Whisper.cpp for STT"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y \
    build-essential \
    cmake \
    ffmpeg \
    sox \
    libsox-dev \
    python3 \
    python3-pip

# Install Python dependencies
pip3 install openai-whisper

# Alternative: Install whisper.cpp (C++ version - faster)
echo "Installing whisper.cpp..."
cd /usr/src

if [ ! -d "whisper.cpp" ]; then
    git clone https://github.com/ggerganov/whisper.cpp.git
fi

cd whisper.cpp
make

# Download model (base model - good balance of speed and accuracy)
MODEL_DIR="/usr/local/share/whisper/models"
mkdir -p "$MODEL_DIR"

if [ ! -f "$MODEL_DIR/ggml-base.bin" ]; then
    echo "Downloading Whisper base model..."
    wget -O "$MODEL_DIR/ggml-base.bin" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
fi

# Create symlink for easy access
ln -sf /usr/src/whisper.cpp/main /usr/local/bin/whisper
chmod +x /usr/local/bin/whisper

# Test installation
echo "Testing Whisper installation..."
if command -v whisper &> /dev/null; then
    echo "Whisper.cpp installed successfully!"
else
    echo "Warning: Whisper binary not found in PATH"
fi

echo "=========================================="
echo "Whisper.cpp installation completed!"
echo "=========================================="
echo "Model location: $MODEL_DIR"
echo "Usage: whisper -m $MODEL_DIR/ggml-base.bin -f audio.wav"
echo "=========================================="

