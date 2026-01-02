#!/bin/bash
# Quick fix script to resolve git conflicts and run installation

cd /root/virtual-number

echo "Stashing local changes..."
git stash

echo "Pulling latest changes..."
git pull

echo "Running installation..."
chmod +x scripts/install-missed-call-system.sh
./scripts/install-missed-call-system.sh

