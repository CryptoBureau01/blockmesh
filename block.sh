#!/bin/bash

curl -s https://raw.githubusercontent.com/CryptoBureau01/logo/main/logo.sh | bash
sleep 5

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



install_dependency() {
    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing required tools..."

    # Update the system and install essential packages
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget tar jq git 

    # Call the uni_menu function to display the menu
    node_menu

}



setup_blockmesh_cli() {
    # Create the blockmesh directory if it doesn't exist
    mkdir -p ~/blockmesh

    # Navigate to the blockmesh directory
    cd ~/blockmesh || exit

    # URL and filename for the BlockMesh CLI
    URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.321/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
    FILENAME=$(basename "$URL")  # Extracts the filename from the URL

    # Step 1: Download the file
    echo "Downloading BlockMesh CLI..."
    wget "$URL" -O "$FILENAME"
    
    # Step 2: Extract the downloaded file
    if [ -f "$FILENAME" ]; then
        echo "Extracting BlockMesh CLI..."
        tar -xzf "$FILENAME" -C ~/blockmesh  # Extract in the blockmesh folder
        
        # Step 3: Remove the downloaded archive file
        echo "Cleaning up the downloaded archive..."
        rm "$FILENAME"
        
        echo "Setup completed successfully!"
    else
        echo "Error: Download failed."
        return 1
    fi

    # Call the node_menu function
    node_menu
}





setup_blockmesh_service() {
    # File path for credentials
    credentials_file="/root/blockmesh/data.txt"

    # Check if block-data.txt already exists
    if [[ -f "$credentials_file" ]]; then
        echo "An existing configuration already exists for BlockMesh."
        read -p "Do you want to overwrite it? (y/n): " choice

        if [[ "$choice" == "n" || "$choice" == "N" ]]; then
            echo "Exiting without making changes."
            return  # End the function if the user chooses not to overwrite
        elif [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Deleting existing configuration..."
            rm -f "$credentials_file"  # Delete the old file
        else
            echo "Invalid choice. Exiting."
            return  # End function on invalid choice
        fi
    fi

    # Prompt for email and password
    read -p "Enter your email: " email
    read -s -p "Enter your password: " password
    echo

    # Create the /root/blockmesh directory if it doesn't exist
    mkdir -p /root/blockmesh
    
    # Save email and password to block-data.txt
    echo -e "Email: $email\nPassword: $password" > "$credentials_file"
    echo "Credentials saved in $credentials_file."

    # Create the systemd service file with user-provided email and password
    sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh Node Service
After=network.target

[Service]
User=$USER
ExecStart=/root/blockmesh/target/release/blockmesh-cli --email '$email' --password '$password' login
WorkingDirectory=/root/blockmesh/target/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    # Reload the systemd daemon and enable the service
    sudo systemctl daemon-reload
    sudo systemctl enable blockmesh.service

    # Start the service
    sudo systemctl start blockmesh.service

    echo "BlockMesh service created and started successfully."

    # Call the node_menu function
    node_menu
}




logs_checker() {
    # Define the systemd service name
    local service_name="blockmesh.service"
    local line_count=100  # Set the number of lines to display to 100

    echo "Checking logs for $service_name..."

    # Check if the service is active
    service_status=$(systemctl is-active "$service_name")
    if [[ "$service_status" != "active" ]]; then
        echo "The service $service_name is not running. Please start it first."
        return  # Exit the function if the service is not active
    fi

    # Display the latest logs
    echo "Displaying the last $line_count lines of logs for $service_name:"
    sudo journalctl -u "$service_name" -n "$line_count" --no-pager

    # Call the node_menu function
    node_menu
}




restart_service() {
    # Define the systemd service name
    local service_name="blockmesh.service"

    echo "Attempting to restart $service_name..."

    # Restart the service
    sudo systemctl restart "$service_name"

    # Check the status of the service after attempting to restart
    service_status=$(systemctl is-active "$service_name")
    if [[ "$service_status" == "active" ]]; then
        echo "$service_name has been restarted successfully."
    else
        echo "Failed to restart $service_name. Please check the logs for more information."
    fi

    # Call the node_menu function
    node_menu
}



delete_node() {
    # Define the systemd service name
    local service_name="blockmesh.service"
    
    echo "Attempting to stop and delete $service_name..."

    # Stop the service
    sudo systemctl stop "$service_name"

    # Disable the service
    sudo systemctl disable "$service_name"

    # Remove the service file
    sudo rm /etc/systemd/system/"$service_name"

    # Reload the systemd manager configuration
    sudo systemctl daemon-reload

    # Remove the target directory
    rm -rf /root/blockmesh

    echo "$service_name has been stopped and deleted successfully."

    # Call the node_menu function
    node_menu
}





# Function to display menu and handle user input
node_menu() {
    print_info "====================================="
    print_info "  BlockMesh Node Tool Menu    "
    print_info "====================================="
    print_info "Sync-Status"
    print_info "1. Install-Dependencies"
    print_info "2. Setup-Node"
    print_info "3. Run-Node"
    print_info "4. Logs-Checker"
    print_info "5. ReStart-Node"
    print_info "6. Delete-Node"
    print_info "7. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CryptoBureauMaster "
    print_info "==============================="
    print_info ""  

    # Prompt the user for input
    read -p "Enter your choice (1 to 7): " user_choice
    
    # Handle user input
    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            setup_blockmesh_cli
            ;;
        3)  
            setup_blockmesh_service
            ;;
        4)  
            logs_checker
            ;;
        5)
            restart_service
            ;;
        6)  
            delete_node
            ;;
        7)
            print_info "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter 1-7"
            node_menu # Re-prompt if invalid input
            ;;
    esac
}

# Call the node_menu function
node_menu
