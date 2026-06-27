#!/bin/bash

TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter project connection list to be deleted file name: " INPUT_FILE_NAME
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
while IFS=',' read -r PROJECT_CODE CONN_ID || [[ -n "$PROJECT_CODE" ]]
do
    PROJECT_CODE=$(echo "${PROJECT_CODE}" | tr -d '\r')
    CONN_ID=$(echo "${CONN_ID}" | tr -d '\r')

    [[ "$PROJECT_CODE" == "PROJECT_CODE" ]] && continue
    [[ -z "${PROJECT_CODE}" || -z "${CONN_ID}" ]] && continue

    echo "Processing: $PROJECT_CODE"
    
    echo "Getting project integration details..."
    echo "Connection to delete: ${CONN_ID}"
    
    echo "Getting project connection details..."


CONN_JSON=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/connections?integrationInstance=${INTEGRATION_INSTANCE}")
  
 # echo "$CONN_JSON" | jq .
 
 # Check if any integrations exist
ITEM_COUNT=$(echo "${CONN_JSON}" | jq '.items | length')

if [ "${ITEM_COUNT}" -eq 0 ]; then
    echo "No Connections to delete for project ${PROJECT_CODE}"
else
	echo "${CONN_JSON}" | jq -c '.items[]' | while read -r connection
	do
    	CURRENT_CONN_ID=$(echo "$connection" | jq -r '.id')
    	CURRENT_CONN_NAME=$(echo "$connection" | jq -r '.name')
    	STATUS=$(echo "$connection" | jq -r '.status')
    	CONN_ID_USAGE=$(echo "$connection" | jq -r '.usage')
    	CONN_ID_USAGE_ACTIVE=$(echo "$connection" | jq -r '.usageActive')

    	echo "Current connection : ${CURRENT_CONN_ID}"
    	echo "Usage: ${CONN_ID_USAGE}"
    	echo "Usage Active: ${CONN_ID_USAGE_ACTIVE}"
    	echo "Status: ${STATUS}" 
    	echo "Conn from File ${CONN_ID}"
    
	if [[ "${STATUS}" == "CONFIGURED" ]] && [[ "${CURRENT_CONN_ID}" == "${CONN_ID}" ]] && [[ "${CONN_ID_USAGE}" -eq 0 ]] \
   		&& [[ "${CONN_ID_USAGE_ACTIVE}" -eq 0 ]]; then

        echo "Proceed to Delete ${CONN_ID}"
        
        DELETION_RESPONSE=$(curl -X DELETE \
          -H "Authorization: Bearer ${ACCESS_TOKEN}" \
         "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/connections/${CONN_ID}?integrationInstance=${INTEGRATION_INSTANCE}")


		ERROR_CODE=$(echo "${DELETION_RESPONSE}" | jq -r '.errorCode // empty')
		
		echo
		echo "Deletion of Connections"
		echo "${DELETION_RESPONSE}"

		if [[ -n "${ERROR_CODE}" ]]; then
   			 ERROR_STATUS=$(echo "${DELETION_RESPONSE}" | jq -r '.status')
   			 ERROR_MESSAGE=$(echo "${DELETION_RESPONSE}" | jq -r '.title')

   			 echo "Activation Error for ${INTEGRATION_ID}"
   			 echo "Error Code : ${ERROR_CODE}"
  			 echo "Status     : ${ERROR_STATUS}"
   			 echo "Message    : ${ERROR_MESSAGE}"
		else
             echo "Proceeding to next Connection..."          
		fi         
 	else
		echo "Cannot delete ${CURRENT_CONN_ID}"               
	fi    
done
fi
    
done < "${INPUT_FILE}"

echo "Deletion script completed."