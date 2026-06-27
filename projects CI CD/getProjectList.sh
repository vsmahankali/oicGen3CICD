#!/bin/bash
TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

#OUTPUT_FILE="projectsList.csv"
#OUTPUT_INTEGRATION_FILE="integrationsList.csv"

read -p "Enter output project list file name: " OUTPUT_FILE_NAME
OUTPUT_FILE="${OUTPUT_FILE_NAME}.csv"

read -p "Enter output project integration list file name: " OUTPUT_INTEGRATION_FILE_NAME
OUTPUT_INTEGRATION_FILE="${OUTPUT_INTEGRATION_FILE_NAME}.csv"

read -p "Enter output project connections list file name: " OUTPUT_CONN_FILE_NAME
OUTPUT_CONN_FILE="${OUTPUT_CONN_FILE_NAME}.csv"

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

RESPONSE=$(curl -s \
    -X GET \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${OIC_URL}/ic/api/integration/v1/projects?integrationInstance=${INTEGRATION_INSTANCE}")
    
	#echo "Project List"
	#echo "${RESPONSE}"

	# Create CSV header
	echo "PROJECT_CODE" > "${OUTPUT_FILE}"

	# Extract all code values from items array
	jq -r '.items[].code' <<< "${RESPONSE}" >> "${OUTPUT_FILE}"

	echo "CSV file created: ${OUTPUT_FILE}"	
	
	echo "PROJECT_CODE,INTEGRATION_CODE,VERSION,STATUS" > "${OUTPUT_INTEGRATION_FILE}"
	
	echo "PROJECT_CODE,ID,STATUS,USAGE,USAGE_ACTIVE" > "${OUTPUT_CONN_FILE}"
	
	echo "${RESPONSE}" | jq -r '.items[].code' | while read -r PROJECT_CODE
	do
    	INTEGRATIONS_JSON=$(curl -s \
        	-H "Authorization: Bearer ${ACCESS_TOKEN}" \
        	"${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations?integrationInstance=${INTEGRATION_INSTANCE}")
        	
	     # Check if any integrations exist
		ITEM_COUNT=$(echo "${INTEGRATIONS_JSON}" | jq '.items | length')
		
		echo "Writing integration list in progress"
		echo "Integration List of Project: ${PROJECT_CODE}"
		echo "Integrations count: ${ITEM_COUNT}"

		if [ "${ITEM_COUNT}" -eq 0 ]; then
    		echo "\"${PROJECT_CODE}\",\"NO_INTEGRATIONS\",\"\",\"\"" \
        		>> "${OUTPUT_INTEGRATION_FILE}"
		else
			
	    	echo "${INTEGRATIONS_JSON}" | jq -r --arg project "${PROJECT_CODE}" '
    	    	.items[]? |
        		[$project, .code, .version, .status] | @csv
    		' 	>> "${OUTPUT_INTEGRATION_FILE}"
    	fi
    	
			echo "Writing integration list done"
			
		CONNECTIONS_JSON=$(curl -s \
        	-H "Authorization: Bearer ${ACCESS_TOKEN}" \
        	"${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/connections?integrationInstance=${INTEGRATION_INSTANCE}")	

		#echo "Connections List"
		#echo "${CONNECTIONS_JSON}"
			
		# Check if any connections exist
		CONN_ITEM_COUNT=$(echo "${CONNECTIONS_JSON}" | jq '.items | length')
		
		echo "Writing connections list in progress"
		echo "Connections List of Project: ${PROJECT_CODE}"
		echo "Connection count: ${CONN_ITEM_COUNT}"
		

		if [ "${CONN_ITEM_COUNT}" -eq 0 ]; then
    		echo "\"${PROJECT_CODE}\",\"NO_CONNECTIONS\",\"\",\"\"" \
        		>> "${OUTPUT_CONN_FILE}"
		else
			echo "${CONNECTIONS_JSON}" | jq -r --arg project "${PROJECT_CODE}" '
    			.items[]? |
    			[
        		$project,
        		.id,
        		.status,
        		.usage,
        		.usageActive
    			] | @csv
			' >> "${OUTPUT_CONN_FILE}"
    	fi
    	
			echo "Writing connection list done"	
	done