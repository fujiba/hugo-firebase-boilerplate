#!/bin/bash
set -eu

echo "🚀 Creating GCS bucket for Terraform remote backend..."

# --- Helper Functions ---
usage() {
  echo "Usage: $0 [-p <project_id>]"
  echo "  -p <project_id>: Specify the Google Cloud project ID where the bucket should be created."
  echo "                   Defaults to the project currently configured in gcloud."
  exit 1
}

# Check if gcloud command exists
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud command not found. Please install Google Cloud SDK."
    exit 1
fi

# Get current project ID from gcloud config
# --- Argument Parsing ---
TARGET_PROJECT_ID=""
while getopts "p:h" opt; do
  case $opt in
    p) TARGET_PROJECT_ID="$OPTARG" ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND-1))

# Determine the target project ID
if [ -z "$TARGET_PROJECT_ID" ]; then
  TARGET_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  if [ -z "$TARGET_PROJECT_ID" ]; then
    echo "⚠️ No active project configured in gcloud and no project specified with -p."
    read -p "Please enter the Google Cloud project ID to create the bucket in: " TARGET_PROJECT_ID
    if [ -z "$TARGET_PROJECT_ID" ]; then
        echo "Error: Project ID is required."
        exit 1
    fi
    echo "ℹ️ Using entered project ID: ${TARGET_PROJECT_ID}"
  else
      echo "ℹ️ Using active gcloud project: ${TARGET_PROJECT_ID}"
  fi
else
    echo "ℹ️ Using specified project ID: ${TARGET_PROJECT_ID}"
fi

# Generate a unique bucket name suggestion
RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 6)
BUCKET_NAME_SUGGESTION="tf-state-${TARGET_PROJECT_ID}-${RANDOM_SUFFIX}"

read -p "Enter a globally unique bucket name (suggestion: ${BUCKET_NAME_SUGGESTION}): " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-$BUCKET_NAME_SUGGESTION}

# Choose a location (e.g., ASIA-NORTHEAST1)
read -p "Enter bucket location (e.g., ASIA-NORTHEAST1): " BUCKET_LOCATION
BUCKET_LOCATION=${BUCKET_LOCATION:-ASIA-NORTHEAST1}

echo "Creating bucket ${BUCKET_NAME} in ${BUCKET_LOCATION}..."

# Create the bucket with recommended settings for Terraform state
gcloud storage buckets create "gs://${BUCKET_NAME}" \
    --project="${TARGET_PROJECT_ID}" \
    --location="${BUCKET_LOCATION}" \
    --uniform-bucket-level-access \
    --enable-object-versioning # Enable versioning for state file history/recovery

echo "✅ Bucket ${BUCKET_NAME} created successfully."

# Ask user if they want to update backend.tf
read -p "Do you want to automatically update terraform/backend.tf with this bucket name? (y/N): " UPDATE_BACKEND_TF

if [[ "$UPDATE_BACKEND_TF" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  BACKEND_TF_FILE="terraform/backend.tf"
  if [ -f "$BACKEND_TF_FILE" ]; then
    echo "Updating ${BACKEND_TF_FILE}..."
    # Use sed to uncomment the block and replace the bucket name
    # Note: Using '|' as delimiter for sed because bucket names can contain '-' but not '|'
    sed -i.bak \
        -e 's|^# \(terraform {\)|\1|' \
        -e 's|^#   \(backend "gcs" {\)|\1|' \
        -e "s|^#     bucket = \".*\"|    bucket = \"${BUCKET_NAME}\"|" \
        -e 's|^#     \(prefix = .*\)|\1|' \
        -e 's|^#   }\)|\1|' \
        -e 's|^# }\)|\1|' \
        "$BACKEND_TF_FILE"
    echo "✅ ${BACKEND_TF_FILE} updated. Original file saved as ${BACKEND_TF_FILE}.bak"
    echo "➡️ Please run 'terraform init -reconfigure' in the 'terraform' directory."
  else
    echo "⚠️ ${BACKEND_TF_FILE} not found. Please update it manually."
  fi
else
  echo "➡️ Please update terraform/backend.tf manually with bucket name '${BUCKET_NAME}' and run 'terraform init -reconfigure'."
fi
