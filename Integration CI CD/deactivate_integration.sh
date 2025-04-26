# deactivate_integration.sh
#!/bin/bash
echo "Choose Target environment to deactivate"
source ./environmentConfiguration.sh 
source ./get_integration_list.sh

#For Import Env
BASIC_AUTH=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

echo "curl -s -X POST \"${AUTH_TOKEN_URL}\" -H \"Authorization: Basic ${BASIC_AUTH}\" -H \"Content-Type: application/x-www-form-urlencoded\" -d \"grant_type=client_credentials\" -d \"scope=${SCOPE_INSTANCE}\""

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

echo "Access token : $ACCESS_TOKEN"

ARRAY_ATTRIBUTE="items" 
OUTPUT_FILE="oic_response_${OIC_INSTANCE}.json" 

#INPUT_FILE="../migration.csv" 
    read -p "Enter name of csv file containing Integrations for import as to deactivate: " INPUT_FILE

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "File '$INPUT_FILE' not found. Please check the filename and try again."
        exit 1
    fi

ACT_DEC_INT_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}?integrationInstance={instance}"
INTG_STATUS_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}?integrationInstance={instance}"
STOP_SCHEDULE_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}/schedule/stop?integrationInstance={instance}"

tail -n +2 "$INPUT_FILE" | while IFS=',' read -r field1 field2 field3 || [ -n "$field1" ]; do
  match_code=$(echo "$field2" | tr -d '\r' | xargs)

  echo "🔍 Processing for code: '$match_code'"

  # Get integration ID by code
  id=$(jq -r --arg code "$match_code" '.items[] | select((.id | split("|")[0]) == $code) | .id' "$OUTPUT_FILE")

  if [[ -z "$id" ]]; then
    echo "❌ No match found for: '$match_code'"
    continue
  fi

  # Extract flags and status
  status=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .status" "$OUTPUT_FILE")
  locked_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .lockedFlag" "$OUTPUT_FILE")
  schedule_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleApplicableFlag" "$OUTPUT_FILE")
  schedule_defined_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleDefinedFlag" "$OUTPUT_FILE")

  if [[ "$status" == "CONFIGURED" ]]; then
    echo "⚠️ Skipping $id: already CONFIGURED"
    continue
  fi

  if [[ "$locked_flag" == "true" ]]; then
    echo "🔒 Skipping $id: locked_flag is true"
    continue
  fi

  # Stop Schedule if needed
  if [[ "$schedule_flag" == "true" && "$schedule_defined_flag" == "true" ]]; then
    stop_url="${STOP_SCHEDULE_URL//\{instance\}/$OIC_INSTANCE}"
    stop_url="${stop_url//\{id\}/$id}"
    echo "🛑 Stopping schedule for $id"
    echo curl -X POST -H \"Content-Type: application/json\" -H \"Authorization: Bearer $ACCESS_TOKEN\" -H \"Accept:application/json\" \"$stop_url\"
    curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept:application/json" -H "Content-Type: application/json" "$stop_url"
  fi

  # Deactivate integration
  dec_url="${ACT_DEC_INT_URL//\{instance\}/$OIC_INSTANCE}"
  dec_url="${dec_url//\{id\}/$id}"
  echo "📤 Sending deactivate request for $id"

  curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
       -H "Content-Type: application/json" \
       -H "X-HTTP-Method-Override: PATCH" \
       -d @deactivate.json "$dec_url"

  # Poll until integration is CONFIGURED
  status_url="${INTG_STATUS_URL//\{instance\}/$OIC_INSTANCE}"
  status_url="${status_url//\{id\}/$id}"

  echo "⏳ Waiting for $id to become CONFIGURED..."
  while true; do
    current_status=$(curl -s -X GET -H "Authorization: Bearer $ACCESS_TOKEN" "$status_url" | jq -r '.status')
    echo "  ➤ Current status: $current_status"
    [[ "$current_status" == "CONFIGURED" ]] && break
    sleep 3
  done

  echo "✅ Deactivated: $id"
done  
