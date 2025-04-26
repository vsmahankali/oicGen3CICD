#!/bin/bash
echo "Choose Target environment to Activate Integration"
source ./environmentConfiguration.sh
source ./get_integration_list.sh

#INPUT_FILE="../migration.csv" 
read -p "Enter name of csv file containing Integrations for to activate: " INPUT_FILE

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "File '$INPUT_FILE' not found. Please check the filename and try again."
    exit 1
fi

OUTPUT_FILE="oic_response_${OIC_INSTANCE}.json"

read -p "Enter yes if the is to be scheduled, if applicable: " SCHEDULE

ACT_DEC_INT_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}?integrationInstance={instance}"
START_SCHEDULE_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}/schedule/start?integrationInstance={instance}"

tail -n +2 "$INPUT_FILE" | while IFS=',' read -r field1 field2 field3 || [ -n "$field1" ]; do
  match_code=$(echo "$field2" | tr -d '\r' | xargs)

  echo "🔍 Processing for code: '$match_code'"

  # Get integration ID by code
  id=$(jq -r --arg code "$match_code" '.items[] | select((.id | split("|")[0]) == $code) | .id' "$OUTPUT_FILE")
  schedule_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleApplicableFlag" "$OUTPUT_FILE")
  schedule_defined_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleDefinedFlag" "$OUTPUT_FILE")

  if [[ -z "$id" ]]; then
    echo "❌ No match found for: '$match_code'"
    continue
  fi

  act_url="${ACT_DEC_INT_URL//\{instance\}/$OIC_INSTANCE}"
  act_url="${act_url//\{id\}/$id}"
  curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
       -H "Content-Type:application/json" \
       -H "X-HTTP-Method-Override:PATCH" \
       -d @activate.json "$act_url"


        if [[ "$schedule_flag" == "true" ]]; then
            if [[ "$SCHEDULE" == "yes" ]]; then
                if [[ "$schedule_defined_flag" == "true" ]]; then   
                    start_url="${START_SCHEDULE_URL//\{instance\}/$OIC_INSTANCE}"
                    start_url="${start_url//\{id\}/$id}"
                    echo " Starting schedule for $id"
                    curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" \
                        -H "Accept: application/json" \
                        -H "Content-Type: application/json" \
                        -d @startScheduleIntegration.json "$start_url"
                else
                    echo "❌ Schedule is not to be activated for '$id'"
                fi       
            else
                echo "❌ Schedule not applicable for '$id'"
            fi
        else
            echo "❌ Schedule is not applicable '$id'"
        fi    

  echo "✅ Activated: $id"
      
done