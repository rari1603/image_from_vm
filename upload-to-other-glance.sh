#!/bin/bash
set -e

VENV_PATH="/var/lib/jenkins/openstack-venv/bin/activate"

# Check if virtual environment exists
if [[ ! -f "$VENV_PATH" ]]; then
  echo "Error: Virtual environment not found at $VENV_PATH"
  exit 1
fi

source "$VENV_PATH"

# Ensure a valid working directory
cd /tmp || {
  echo "Failed to change to /tmp. Exiting."
  exit 1
}

# Set environment for target OpenStack (destination)
export OS_AUTH_URL="https://100.65.247.153:13000"
export OS_USERNAME="admin"
export OS_PASSWORD="eoZ37jP3T9DP4lePjUgZ0CwNQ"
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_COMPUTE_API_VERSION=2.88
export OS_IMAGE_API_VERSION=2
export OS_INSECURE=true

# Input arguments
IMAGE_FILE=$1
IMAGE_NAME=$2

# Validate arguments
if [[ -z "$IMAGE_FILE" || -z "$IMAGE_NAME" ]]; then
  echo "Usage: $0 <image_file> <image_name>"
  exit 1
fi

if [[ ! -f "$IMAGE_FILE" ]]; then
  echo "Error: File '$IMAGE_FILE' does not exist."
  exit 1
fi

echo "Uploading $IMAGE_FILE to target OpenStack as $IMAGE_NAME..."
openstack image create "$IMAGE_NAME" \
  --disk-format qcow2 \
  --container-format bare \
  --file "$IMAGE_FILE" \
  --public
