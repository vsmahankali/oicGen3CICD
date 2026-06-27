#!/bin/bash
TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter project list to be imported file name: " INPUT_FILE_NAME
INPUT_FILE="${INPUT_FILE_NAME}.csv"

# Export Directory
read -p "Enter projects to be imported folder name: " EXPORT_DIR_NAME
EXPORT_DIR="./${EXPORT_DIR_NAME}"

echo "Generating OAuth token..."

ACCESS_TOKEN=$(curl -s -X POST "$TOKEN_URL" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  -d "grant_type=client_credentials&scope=${SCOPE}" \
  | jq -r '.access_token')


if [ -z "${ACCESS_TOKEN}" ] || [ "${ACCESS_TOKEN}" = "null" ]; then
    echo "Failed to generate access token"
    exit 1
fi

echo "Token generated successfully"
#echo "$ACCESS_TOKEN"


# Read project codes from CSV (skip header)
while IFS=',' read -r PROJECT_CODE || [[ -n "$PROJECT_CODE" ]]
do
    PROJECT_CODE=$(echo "${PROJECT_CODE}" | tr -d '\r')

    [[ "$PROJECT_CODE" == "PROJECT_CODE" ]] && continue
    [[ -z "$PROJECT_CODE" ]] && continue

    echo "Processing: $PROJECT_CODE"
    
#echo "${OIC_URL}/ic/api/integration/v1/projects/archive?integrationInstance=${INTEGRATION_INSTANCE}"    
    
echo "Starting import of: ${PROJECT_CODE}.car"    
    
curl -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -F "file=@${EXPORT_DIR}/${PROJECT_CODE}.car;type=application/octet-stream" \
  "${OIC_URL}/ic/api/integration/v1/projects/archive?integrationInstance=${INTEGRATION_INSTANCE}"
    
echo "Import completed: ${PROJECT_CODE}.car"
    
done < "${INPUT_FILE}"

echo "Project import completed."
