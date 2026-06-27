#!/bin/bash

TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter project integration list to be deleted file name: " INPUT_FILE_NAME
INPUT_FILE="${INPUT_FILE_NAME}.csv"

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
# "$ACCESS_TOKEN"

# Read project codes from CSV (skip header)
while IFS=',' read -r PROJECT_CODE INTEGRATION_CODE || [[ -n "$PROJECT_CODE" ]]
do
    PROJECT_CODE=$(echo "${PROJECT_CODE}" | tr -d '\r')
    INTEGRATION_CODE=$(echo "${INTEGRATION_CODE}" | tr -d '\r')

    [[ "$PROJECT_CODE" == "PROJECT_CODE" ]] && continue
    [[ -z "${PROJECT_CODE}" || -z "${INTEGRATION_CODE}" ]] && continue

    echo "Processing: $PROJECT_CODE"
    
    echo "Getting project integration details..."
    echo "Integration to delete: ${INTEGRATION_CODE}"
    
    echo "Getting project integration details..."


INTEGRATIONS_JSON=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations?integrationInstance=${INTEGRATION_INSTANCE}")
  
 # echo "$INTEGRATIONS_JSON" | jq .
 
 # Check if any integrations exist
ITEM_COUNT=$(echo "${INTEGRATIONS_JSON}" | jq '.items | length')

if [ "${ITEM_COUNT}" -eq 0 ]; then
    echo "No Integrations to delete for project ${PROJECT_CODE}"
else
echo "${INTEGRATIONS_JSON}" | jq -c '.items[]' | while read -r integration
do
    INTEGRATION_ID=$(echo "$integration" | jq -r '.id')
    CURRENT_INTEGRATION_CODE=$(echo "$integration" | jq -r '.code')
    STATUS=$(echo "$integration" | jq -r '.status')

    echo "Current Integration : ${CURRENT_INTEGRATION_CODE}"
    echo "Status: ${STATUS}"

    if [[ "${STATUS}" == "CONFIGURED"  ]] && [[ "${CURRENT_INTEGRATION_CODE}" == "${INTEGRATION_CODE}" ]]; then

        echo "Deleting ${INTEGRATION_ID}"
        
        #echo "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations/${INTEGRATION_ID}?integrationInstance=${INTEGRATION_INSTANCE}"

        DELETION_RESPONSE=$(curl -X DELETE \
          -H "Authorization: Bearer ${ACCESS_TOKEN}" \
         "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations/${INTEGRATION_ID}?integrationInstance=${INTEGRATION_INSTANCE}")


		ERROR_CODE=$(echo "${DELETION_RESPONSE}" | jq -r '.errorCode // empty')
		
		echo
		echo "Deletion of Integration"
		echo "${DELETION_RESPONSE}"

		if [[ -n "${ERROR_CODE}" ]]; then
   			 ERROR_STATUS=$(echo "${DELETION_RESPONSE}" | jq -r '.status')
   			 ERROR_MESSAGE=$(echo "${DELETION_RESPONSE}" | jq -r '.title')

   			 echo "Activation Error for ${INTEGRATION_ID}"
   			 echo "Error Code : ${ERROR_CODE}"
  			 echo "Status     : ${ERROR_STATUS}"
   			 echo "Message    : ${ERROR_MESSAGE}"
		else
             echo "Proceeding to next integration..."
          
		fi 
	else 
		echo "Skipping ${CURRENT_INTEGRATION_CODE} it..."         
    fi
done
fi
    
done < "${INPUT_FILE}"

echo "Deletion script completed."