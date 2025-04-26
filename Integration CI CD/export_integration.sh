# export_integration.sh
#!/bin/bash

read -p "If get_integration_list.sh has been executed then enter yes: " EXECUTED

if [[ "$EXECUTED" != "yes" ]]; then
    source ./get_integration_list.sh   
   else
    echo "Enter environment for wich getintegration list was executed..."
    source ./environmentConfiguration.sh 
fi

#INPUT_FILE="../migration.csv" 
read -p "Enter name of csv file containing Integrations for import: " INPUT_FILE

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "File '$INPUT_FILE' not found. Please check the filename and try again."
    exit 1
fi

# EXPORT INSTANCE
EXPORT_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}/archive?integrationInstance="
EXPORT_SCHEDULE_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/{id}/schedule?integrationInstance="

DIR="${OIC_INSTANCE}IntegrationsForMigration"
DIRSCH="${OIC_INSTANCE}SchedulesOfIntegrationsForMigration"

# Check if directory exists
for path in "$DIR" "$DIR/$DIRSCH"; do
    if [ ! -d "$path" ]; then
        echo "Directory $path does not exist. Creating..."
        mkdir -p "$path"
    else
        echo "Directory $path already exists."
    fi
done

OUTPUT_FILE="oic_response_${OIC_INSTANCE}.json" 

ARRAY_ATTRIBUTE="items" 

BASIC_AUTH=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

echo "curl -s -X POST \"${AUTH_TOKEN_URL}\" -H \"Authorization: Basic ${BASIC_AUTH}\" -H \"Content-Type: application/x-www-form-urlencoded\" -d \"grant_type=client_credentials\" -d \"scope=${SCOPE_INSTANCE}\""

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

echo "Access token : $ACCESS_TOKEN"

# Check if the file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

# Print the first few lines of the CSV to verify format
echo "Preview of the CSV file:"
head -n 5 "$INPUT_FILE"

# Skip the header and read data rows
tail -n +2 "$INPUT_FILE" | while IFS=',' read -r field1 field2 field3 || [ -n "$field1" ]; do
  match_code=$(echo "$field2" | tr -d '\r' | xargs)
  echo "🔍 Processing for code: '$match_code'"

  # Get integration ID by code
  id=$(jq -r --arg code "$match_code" '.items[] | select((.id | split("|")[0]) == $code) | .id' "$OUTPUT_FILE")

  if [[ -z "$id" ]]; then
    echo "❌ No match found for: '$match_code'"
    continue
  fi

  status=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .status" "$OUTPUT_FILE")
  locked_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .lockedFlag" "$OUTPUT_FILE")
  schedule_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleApplicableFlag" "$OUTPUT_FILE")
  schedule_defined_flag=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .scheduleDefinedFlag" "$OUTPUT_FILE")

  if [[ "$status" != "ACTIVATED" ]]; then
    echo "⚠️ Skipping $id: status is '$status' (not ACTIVATED)"
    continue
  fi

  if [[ "$locked_flag" == "true" ]]; then
    echo "🔒 Skipping $id: locked_flag is 'true'"
    continue
  fi

  # Prepare export name
  new_str="${id//|/_}"
  echo "$new_str"

  # --- EXPORT IAR ---
  echo "📦 Exporting IAR for $id"
  IAR_URL="${EXPORT_URL}${OIC_INSTANCE}"
  IAR_URL="${IAR_URL//\{id\}/$id}"
  curl -s -X GET -H "Authorization: Bearer ${ACCESS_TOKEN}" \
       -o "$DIR/${new_str}.iar" "$IAR_URL"

  # --- EXPORT SCHEDULE (if applicable) ---
  if [[ "$schedule_flag" == "true" ]]; then
    echo "📅 Schedule export applicable for $id"
    if [[ "$schedule_defined_flag" == "true" ]]; then
      FULL_EXPORT_SCH_URL="${EXPORT_SCHEDULE_URL}${OIC_INSTANCE}"
      FULL_EXPORT_SCH_URL="${FULL_EXPORT_SCH_URL//\{id\}/$id}"
      echo "  📤 Exporting Schedules: $FULL_EXPORT_SCH_URL"
      curl -s -X GET -H "Authorization: Bearer ${ACCESS_TOKEN}" \
           -H "Accept: application/json" \
           -o "$DIR/$DIRSCH/${new_str}_schedule.json" \
           "$FULL_EXPORT_SCH_URL"
    else
      echo "⚠️ Skipping Schedule export of $id: schedule not defined."
    fi
  else
    echo "ℹ️ Skipping Schedule export of $id: schedule not applicable."
  fi
done