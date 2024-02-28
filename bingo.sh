#!/bin/bash

# Function to check if a port is valid
is_valid_port() {
  local port="$1"
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: Port must be a number." >&2
    return 1
  fi
  if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Error: Port must be between 1 and 65535." >&2
    return 1
  fi
  return 0
}
ssh_port() {
  # Check if SSH is installed
  if ! [ -x "$(command -v ssh)" ]; then
    echo 'Error: SSH is not installed.' >&2
    exit 1
  fi
  # Check if SSH configuration file exists
  if [ ! -f "$ssh_config_file" ]; then
    echo "Error: SSH configuration file not found at $ssh_config_file"
    exit 1
  fi
  # Extract SSH ports from the configuration file
  ssh_ports=$(awk '/^Port/{print $2}' "$ssh_config_file")
  # Check if any ports are configured
  if [ -z "$ssh_ports" ]; then
    # If no ports found, check if default port 22 is active
    if netstat -tuln | grep ':22 ' > /dev/null; then
      echo "Default SSH port 22 is active."
    else
      echo "No SSH ports configured."
    fi
  else
    echo "Current SSH port(s): $ssh_ports"
  fi
  # Get the new SSH port from user input
  read -p "Enter the new SSH port: " new_port
  # Validate the new port
  if ! is_valid_port "$new_port"; then
    return
  fi
  # Check if the new port is already configured
  if grep -q "^Port $new_port" "$ssh_config_file"; then
    echo "Error: Port $new_port is already configured in $ssh_config_file"
    return
  fi
  # Append the new port to the SSH configuration file
  echo "Port $new_port" | sudo tee -a "$ssh_config_file" > /dev/null
  # Restart SSH service
  systemctl restart sshd
  echo "New SSH port $new_port added successfully."
}
# Get SSH configuration file
ssh_config_file="/etc/ssh/sshd_config"

# Main menu
while true; do
clear
  echo "Menu:"
  echo "1 - SSH Port Manager"
  echo "2 - IP & Port Management"
  echo "0 - Exit"
  read -p "Enter your choice: " choice
  case $choice in
    1) ssh_port;;
    0) echo "Exiting..."; exit;;
  esac
done
