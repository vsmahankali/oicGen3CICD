#!/bin/bash
#############################################
# Function: Wait for Integration Activation
#############################################
TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter project list to be copied file name: " INPUT_FILE_NAME
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

while IFS=',' read -r SOURCE_PROJECT_CODE SOURCE_INTEGRATION_CODE TARGET_PROJECT_CODE \
      || [[ -n "$SOURCE_PROJECT_CODE" ]]
do
    SOURCE_PROJECT_CODE=$(echo "${SOURCE_PROJECT_CODE}" | tr -d '\r')
    SOURCE_INTEGRATION_CODE=$(echo "${SOURCE_INTEGRATION_CODE}" | tr -d '\r')
    TARGET_PROJECT_CODE=$(echo "${TARGET_PROJECT_CODE}" | tr -d '\r')

    # Skip header
    [[ "$SOURCE_PROJECT_CODE" == "SOURCE_PROJECT_CODE" ]] && continue

    # Skip blank lines
    [[ -z "$SOURCE_PROJECT_CODE" ]] && continue
    [[ -z "$SOURCE_INTEGRATION_CODE" ]] && continue
    [[ -z "$TARGET_PROJECT_CODE" ]] && continue

    echo "Source Project      : ${SOURCE_PROJECT_CODE}"
    echo "Source Integration  : ${SOURCE_INTEGRATION_CODE}"
    echo "Target Project      : ${TARGET_PROJECT_CODE}"

    # Get integration details
    INTEGRATIONS_JSON=$(curl -s \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "${OIC_URL}/ic/api/integration/v1/projects/${SOURCE_PROJECT_CODE}/integrations?integrationInstance=${INTEGRATION_INSTANCE}")

	#echo "${INTEGRATIONS_JSON}"
    # Get version of the integration
    VERSION=$(echo "${INTEGRATIONS_JSON}" | \
        jq -r --arg code "${SOURCE_INTEGRATION_CODE}" \
        '.items[] | select(.code==$code) | .version')
        
    echo "Version: ${VERSION}"    

    if [[ -z "${VERSION}" || "${VERSION}" == "null" ]]; then
        echo "Integration ${SOURCE_INTEGRATION_CODE} not found in project ${PROJECT_CODE}"
        continue
    fi
    
    # Prepare JSON payload
	REQUEST_BODY=$(jq -n \
    	--arg projectCode "${SOURCE_PROJECT_CODE}" \
    	--arg integrationCode "${SOURCE_INTEGRATION_CODE}" \
    	--arg version "${VERSION}" \
    	'{
        	projectCode: $projectCode,
        	integrations: [
            	{
                	code: $integrationCode,
                	version: $version
            	}
        	]
    	}')

	#echo "Request Body:"
	#echo "${REQUEST_BODY}"
	   
    echo "Starting copy of ${SOURCE_INTEGRATION_CODE}..."

    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${REQUEST_BODY}" \
        "${OIC_URL}/ic/api/integration/v1/projects/${TARGET_PROJECT_CODE}/integrations/copy?integrationInstance=${INTEGRATION_INSTANCE}")

    #echo "Response:"
    #echo "${RESPONSE}" | jq .
    
    ERROR_CODE=$(echo "${RESPONSE}" | jq -r '.status // empty')
    
    if [[ -n "${ERROR_CODE}" ]]; then
   			 ERROR_STATUS=$(echo "${RESPONSE}" | jq -r '.title')
   			 ERROR_MESSAGE=$(echo "${RESPONSE}" | jq -r '.type')

   			 echo "Copy Error for ${INTEGRATION_ID}"
   			 echo "Error Code : ${ERROR_CODE}"
  			 echo "Status     : ${ERROR_STATUS}"
   			 echo "Message    : ${ERROR_MESSAGE}"
	else
    	echo "Copy completed: ${SOURCE_INTEGRATION_CODE}"
    	echo
    fi	
    
done < "${INPUT_FILE}"

echo "Copy script completed."