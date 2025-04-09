#!/bin/bash
#
# Author  : Steve Michael
# Date    : 09 April 2025
# Purpose : Install all dependecies and programs

DEPEND=dependecies.conf
PROGRAMS=application.conf

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check if the script is run on a system with at least 20GB of disk space
if [ "$(df -h / | awk '/\//{print $4}' | sed 's/G//')" -lt 20 ]; then
  echo "This script is only for systems with at least 20GB of disk space"
  exit 1
fi

# Update & Upgrade
sudo apt update && sudo apt upgrade
if [ $? -ne 0 ]; then
  echo "Error: Failed to update and upgrade!"
  exit 1
fi

# Source the dependecy list
if [ ! -f "dependencies.conf"]; then
  echo "Error: dependencies.conf not found!"
  exit 1
fi

source dependencies.conf
# Source the program list
if [ ! -f "application.conf"]; then
  echo "Error: application.conf not found!"
  exit 1
fi
source application.conf
# Check if the dependencies.conf file exists
if [ ! -f "$DEPEND" ]; then
  echo "Error: $DEPEND not found!"
  exit 1
fi
# Check if the application.conf file exists
if [ ! -f "$PROGRAMS" ]; then
  echo "Error: $PROGRAMS not found!"
  exit 1
fi
# Read the dependencies and programs from the configuration files
DEPEND=$(cat $DEPEND)
programs=()
while IFS= read -r line; do
  # Skip empty lines and comments
  if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
    programs+=("$line")
  fi
done < $PROGRAMS
# Check if the dependencies are installed
for dep in $DEPEND; do
  if ! dpkg -l | grep -q "$dep"; then
    echo "Error: $dep is not installed!"
    exit 1
  fi
done
# Check if the programs are installed
for program in "${programs[@]}"; do
  if ! dpkg -l | grep -q "$program"; then
    echo "Error: $program is not installed!"
    exit 1
  fi
done

echo "Starting dependencies setup..."

# Install dependencies
sudo apt install $DEPEND
if [ $? -ne 0 ]; then
  echo "Error: Failed to install dependencies!"
  exit 1
fi
echo "Dependencies installed successfully!"
echo "Starting program setup..."

# Install programs
for program in "${programs[@]}"; do
  if ! command -v $program &> /dev/null; then
    echo "Installing $program..."
    sudo apt install $program
    if [ $? -ne 0 ]; then
      echo "Error: Failed to install $program!"
      exit 1
    fi
    echo "$program installed successfully!"
  else
    echo "$program is already installed."
  fi
done
echo "All programs installed successfully!"
echo "Starting configuration setup..."

# Configure programs
for program in "${programs[@]}"; do
  if command -v $program &> /dev/null; then
    echo "Configuring $program..."
    # Add your configuration commands here
    # Example: sudo $program --configure
    if [ $? -ne 0 ]; then
      echo "Error: Failed to configure $program!"
      exit 1
    fi
    echo "$program configured successfully!"
  else
    echo "$program is not installed, skipping configuration."
  fi
done
echo "All configurations completed successfully!"
echo "Starting cleanup..."

# Cleanup
sudo apt autoremove
if [ $? -ne 0 ]; then
  echo "Error: Failed to cleanup!"
  exit 1
fi