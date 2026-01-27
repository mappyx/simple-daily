#!/bin/bash

# Install dependencies for SimpleDaily on Linux

echo "Installing dependencies..."
# Core Flutter Linux deps + libnotify for local_notifier
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libnotify-dev libayatana-appindicator3-dev

echo "Dependencies installed."
