#!/bin/bash
TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter export project list file name: " INPUT_FILE_NAME
INPUT_FILE="${INPUT_FILE_NAME}.csv"

# Export Directory
read -p "Enter export project folder name: " EXPORT_DIR_NAME
EXPORT_DIR="./${EXPORT_DIR_NAME}"
mkdir -p "${EXPORT_DIR}"

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
    
    echo "Getting project details..."

PROJECT_JSON=$(curl -s \
  -X GET \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}?integrationInstance=${INTEGRATION_INSTANCE}")

#echo "$PROJECT_JSON" | jq .

# Extract required fields
NAME=$(echo "$PROJECT_JSON" | jq -r '.name')
CODE=$(echo "$PROJECT_JSON" | jq -r '.code')
TYPE=$(echo "$PROJECT_JSON" | jq -r '.type')
BUILT_BY=$(echo "$PROJECT_JSON" | jq -r '.state.created.by')

# Build request body
REQUEST_BODY=$(jq -n \
  --arg name "$NAME" \
  --arg code "$CODE" \
  --arg type "$TYPE" \
  --arg builtBy "$BUILT_BY" \
  '{
      name: $name,
      code: $code,
      type: $type,
      builtBy: $builtBy
   }')

  #echo "Request body:"
  #echo "$REQUEST_BODY"

   echo "Exporting project..."

curl -v \
  -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  -o "${EXPORT_DIR}/${PROJECT_CODE}.car" \
  "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/archive?integrationInstance=${INTEGRATION_INSTANCE}"

echo "Export completed: ${PROJECT_CODE}.car"

    if [ $? -eq 0 ]; then
        echo "✓ Exported ${PROJECT_CODE}.car"
    else
        echo "✗ Failed to export ${PROJECT_CODE}"
    fi
    
done < "${INPUT_FILE}"

echo "Project export completed."
