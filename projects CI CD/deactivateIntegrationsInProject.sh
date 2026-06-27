#!/bin/bash
#############################################
# Function: Wait for Integration Activation
#############################################
wait_for_deactivation() {

    local PROJECT_CODE="$1"
    local INTEGRATION_ID="$2"
    local ACCESS_TOKEN="$3"
    local ENCODED_ID
    local STATUS
    local RESPONSE
    local WAIT_TIME=10
    local MAX_WAIT=100
    local ELAPSED=0

    ENCODED_ID=$(echo "${INTEGRATION_ID}" | sed 's/|/%7C/g')

	echo
    echo "Waiting for deactivation of ${INTEGRATION_ID}..."

    while [ ${ELAPSED} -lt ${MAX_WAIT} ]
    do
       RESPONSE=$(curl -s \
    -X GET \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations/${ENCODED_ID}/activationStatus?integrationInstance=${INTEGRATION_INSTANCE}")
      
         STATUS=$(echo "${RESPONSE}" | jq -r '.activationStatus')

        echo "$(date '+%Y-%m-%d %H:%M:%S') : ${INTEGRATION_ID} -> ${STATUS}"

        case "${STATUS}" in

          CONFIGURED)
                echo "✓ Deactivation completed for ${INTEGRATION_ID}"
                return 0
                ;;

            ACTIVATED|DEACTIVATION_INPROGRESS|FAILEDDEACTIVATION)
                sleep ${WAIT_TIME}
                ELAPSED=$((ELAPSED + WAIT_TIME))
                ;;

            *)
                echo "Unknown status: ${STATUS}"
                sleep ${WAIT_TIME}
                ELAPSED=$((ELAPSED + WAIT_TIME))
                ;;
        esac
    done

}

TOKEN_URL="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"

# Example scope format for OIC3
SCOPE="$4"

OIC_URL="$5"
INTEGRATION_INSTANCE="$6"

# Input CSV
read -p "Enter project integration list to be deactivated file name: " INPUT_FILE_NAME
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
    echo "Integration to deactivate: ${INTEGRATION_CODE}"
    
    echo "Getting project integration details..."


INTEGRATIONS_JSON=$(curl -s \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations?integrationInstance=${INTEGRATION_INSTANCE}")
  
 # echo "$INTEGRATIONS_JSON" | jq .
 
 # Check if any integrations exist
ITEM_COUNT=$(echo "${INTEGRATIONS_JSON}" | jq '.items | length')

if [ "${ITEM_COUNT}" -eq 0 ]; then
    echo "No Integrations to activate for project ${PROJECT_CODE}"
else
echo "${INTEGRATIONS_JSON}" | jq -c '.items[]' | while read -r integration
do
    INTEGRATION_ID=$(echo "$integration" | jq -r '.id')
    CURRENT_INTEGRATION_CODE=$(echo "$integration" | jq -r '.code')
    STATUS=$(echo "$integration" | jq -r '.status')

    echo "Current Integration : ${CURRENT_INTEGRATION_CODE}"
    echo "Status: ${STATUS}"

    if [[ "${STATUS}" == "ACTIVATED" ]] && [[ "${CURRENT_INTEGRATION_CODE}" == "${INTEGRATION_CODE}" ]]; then

        REQUEST_BODY='{"status":"CONFIGURED"}'

        echo "Deactivating ${INTEGRATION_ID}"
        
        #echo "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations/${INTEGRATION_ID}?integrationInstance=${INTEGRATION_INSTANCE}"

        DEACTIVATION_RESPONSE=$(curl -X POST \
          -H "Authorization: Bearer ${ACCESS_TOKEN}" \
          -H "Content-Type: application/json" \
          -H "X-HTTP-Method-Override: PATCH" \
          -d "${REQUEST_BODY}" \
         "${OIC_URL}/ic/api/integration/v1/projects/${PROJECT_CODE}/integrations/${INTEGRATION_ID}?integrationInstance=${INTEGRATION_INSTANCE}")


		ERROR_CODE=$(echo "${DEACTIVATION_RESPONSE}" | jq -r '.errorCode // empty')
		
		echo
		echo "DEACTIVATE Integration"
		echo "${DEACTIVATION_RESPONSE}"

		if [[ -n "${ERROR_CODE}" ]]; then
   			 ERROR_STATUS=$(echo "${DEACTIVATION_RESPONSE}" | jq -r '.status')
   			 ERROR_MESSAGE=$(echo "${DEACTIVATION_RESPONSE}" | jq -r '.title')

   			 echo "Activation Error for ${INTEGRATION_ID}"
   			 echo "Error Code : ${ERROR_CODE}"
  			 echo "Status     : ${ERROR_STATUS}"
   			 echo "Message    : ${ERROR_MESSAGE}"
		else
		 # Wait until activation completes
           wait_for_deactivation "${PROJECT_CODE}" "${INTEGRATION_ID}" "${ACCESS_TOKEN}"

          if [ $? -eq 0 ]; then
             echo "Proceeding to next integration..."
          else
             echo "Deactivation timeout/failure for ${INTEGRATION_ID}"
          fi
		fi          
    fi
done
fi
    
done < "${INPUT_FILE}"

echo "Deactivation script completed."