#!/bin/bash
# Function to check if a port is valid
is_valid_port() {
  clear
  local port="$1"
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: Port must be a number." >&2
    read -n 1 -s -r -p "Press any key to continue"
    echo
    return 1
  fi
  if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Error: Port must be between 1 and 65535." >&2
    read -n 1 -s -r -p "Press any key to continue"
    echo
    return 1
  fi
  return 0
}
is_ssh_check() {
  clear
  # Check if SSH is installed
  if ! [ -x "$(command -v ssh)" ]; then
    echo 'Error: SSH is not installed.' >&2
    read -n 1 -s -r -p "Press any key to continue"
    echo
    exit 1
  fi
  # Check if SSH configuration file exists
  if [ ! -f "$ssh_config_file" ]; then
    echo "Error: SSH configuration file not found at $ssh_config_file"
    read -n 1 -s -r -p "Press any key to continue"
    echo
    exit 1
  fi
}
add_port() {
	clear
	is_ssh_check
	# Count the number of existing SSH ports
	existing_ports=$(grep -c "^Port" "$ssh_config_file")

	# Check if the number of existing ports is already 8
	if [ "$existing_ports" -ge 8 ]; then
  		echo "Error: Maximum number of SSH ports (8) already configured."
  		return
	fi

	# Extract SSH ports from the configuration file
	ssh_ports=$(awk '/^Port/{printf "%s,", $2}' "$ssh_config_file")
	# Check if any ports are configured
	if [ -z "$ssh_ports" ]; then
  		# If no ports found, check if default port 22 is active
		if netstat -tuln | grep ':22 ' > /dev/null; then
			echo "Default SSH port 22 is active."
  		else
    			echo "No SSH ports configured."
  		fi
	else
ssh_ports=${ssh_ports%,}
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
		read -n 1 -s -r -p "Press any key to continue"
		echo
  		return
	fi
	# Append the new port to the SSH configuration file
	echo "Port $new_port" | sudo tee -a "$ssh_config_file" > /dev/null
	# Add the new port to ufw
	echo "Adding port $new_port to ufw..."
	sudo ufw allow "$new_port"
	sudo ufw reload
	# Restart SSH service
	systemctl restart sshd
	echo "New SSH port $new_port added successfully."
	read -n 1 -s -r -p "Press any key to continue"
	echo
}
delete_port() {
        clear
        is_ssh_check
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
	# Get the port to delete from user input
	read -p "Enter the SSH port to delete: " delete_port
	# Check if the port is configured
	if grep -q "^Port $delete_port" "$ssh_config_file"; then

		# Count the number of configured ports
  		num_ports=$(grep -c "^Port" "$ssh_config_file")

  		# Ensure that at least one port is always configured
  		if [ "$num_ports" -gt 1 ]; then
  			# Remove the port from the SSH configuration file
			echo "Deleting port $delete_port from SSH configuration..."
			sed -i "/^Port $delete_port/d" "$ssh_config_file"

			# Delete the SSH port from ufw
			echo "Deleting port $delete_port from ufw..."
			sudo ufw delete allow "$delete_port"
			sudo ufw reload
			# Restart SSH service
  			echo "Restarting SSH service..."
  			systemctl restart sshd

  			echo "SSH port $delete_port deleted successfully."
  		else
    			echo "Error: Cannot delete the last configured SSH port."
	    		return
  		fi
	else
  		echo "Error: Port $delete_port is not configured in $ssh_config_file"
  		return
	fi
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
        1) #SSH Port Manager
           while true; do
               clear
               echo "    SSH Port Manager Menu:"
               echo "    1 - ADD Port"
               echo "    2 - Delete Port"
               echo "    9 - Back to Main Menu"
               read -p "Enter your choice: " backup_choice
               case $backup_choice in
                   1) add_port;;
                   2) delete_port;;
                   9) break;;
                   *) echo "Invalid choice. Please enter a valid option.";;
               esac
           done;;

        0) echo "Exiting..."; exit;;
    esac
done
