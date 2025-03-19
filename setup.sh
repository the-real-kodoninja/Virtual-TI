#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install Python and pip if not already installed
if ! command -v python3 &> /dev/null; then
    echo "Installing Python and pip..."
    sudo apt-get install -y python3 python3-venv python3-pip
else
    echo "Python is already installed."
fi

# Install Node.js and npm if not already installed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js and npm..."
    sudo apt-get install -y nodejs npm
else
    echo "Node.js is already installed."
fi

# Install SASS globally if not already installed
if ! command -v sass &> /dev/null; then
    echo "Installing SASS..."
    sudo npm install -g sass
else
    echo "SASS is already installed."
fi

# Install Dart SDK if not already installed
if ! command -v dart &> /dev/null; then
    echo "Installing Dart SDK..."
    sudo apt-get install -y apt-transport-https
    sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
    sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
    sudo apt-get update
    sudo apt-get install -y dart
else
    echo "Dart SDK is already installed."
fi

# Check if the virtual environment exists, if not create it
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate the virtual environment
source venv/bin/activate

# Install required Python libraries
echo "Installing required Python libraries..."
pip install -r server/requirements.txt

# Install Dart dependencies
echo "Installing Dart dependencies..."
cd client
dart pub get

# Compile Dart to JavaScript
echo "Compiling Dart to JavaScript..."
dart run build_runner build --output web:client/js

# Print completion message
echo "Setup complete! You can now run the Flask app."
echo "To activate the virtual environment, use: source venv/bin/activate"
echo "To run the app, use: python server/app.py"