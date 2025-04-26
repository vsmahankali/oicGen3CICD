# import_integration.sh
#!/bin/bash
read -p "If Integrations are present for import then enter yes: " EXECUTED

if [[ "$EXECUTED" != "yes" ]]; then
    echo "Choose Source environment for Export"
    source ./export_integration.sh 
else
    echo "Choose Source environment"
    source ./environmentConfiguration.sh 
    #INPUT_FILE="../migration.csv" 
    read -p "Enter name of csv file containing Integrations for import: " INPUT_FILE

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "File '$INPUT_FILE' not found. Please check the filename and try again."
        exit 1
    fi
fi

DIR1="${OIC_INSTANCE}IntegrationsForMigration"
DIRSCH1="${OIC_INSTANCE}SchedulesOfIntegrationsForMigration"
OUTPUT_FILE1="oic_response_${OIC_INSTANCE}.json" 

if [ ! -d "$DIR1" ]; then
    echo "Directory $DIR1 does not exist. exiting..."
    exit 1
else
    echo "Directory $DIR1 exists."
fi

ARRAY_ATTRIBUTE="items" 

echo "Choose Target environment for Import"
source ./deactivate_integration.sh 

echo "Please rechoose the same Target environment for Import"
source ./get_integration_list.sh

OUTPUT_FILE2="oic_response_${OIC_INSTANCE}.json" 
IMPORT_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations/archive?integrationInstance={instance}"

#For Import Env
BASIC_AUTH=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

echo "curl -s -X POST \"${AUTH_TOKEN_URL}\" -H \"Authorization: Basic ${BASIC_AUTH}\" -H \"Content-Type: application/x-www-form-urlencoded\" -d \"grant_type=client_credentials\" -d \"scope=${SCOPE_INSTANCE}\""

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

echo "Access token : $ACCESS_TOKEN"

tail -n +2 "$INPUT_FILE" | while IFS=',' read -r field1 field2 field3 || [ -n "$field1" ]; do
  match_code=$(echo "$field2" | tr -d '\r' | xargs)
  echo "🔍 Processing for code: '$match_code'"

    # Get integration ID by code
    id=$(jq -r --arg code "$match_code" '.items[] | select((.id | split("|")[0]) == $code) | .id' "$OUTPUT_FILE1")

    if [[ -z "$id" ]]; then
        echo "❌ No match found for: '$match_code'"
        continue
    fi

    # Get integration ID by code
    id1=$(jq -r --arg code "$match_code" '.items[] | select((.id | split("|")[0]) == $code) | .id' "$OUTPUT_FILE2")

    # Prepare import name
    new_str="${id//|/_}"
    echo "$new_str"

    if [[ -z "$id1" ]]; then
        echo "❌ No match found for integration in import environment: '$match_code'"
    #IMPORT
        import_url="${IMPORT_URL//\{instance\}/$OIC_INSTANCE}"
        echo "Full Import URL: $import_url"
        echo "Executing: curl -X POST -H \"Authorization: Bearer ${ACCESS_TOKEN} -H "Accept:application/json" -F file=\"@${new_str}.iar\" -F type=application/octet-stream\"  \"$import_url\""
        OLD_DIR=$(pwd)
        cd "$DIR1" || exit
        curl -v -X POST -H "Authorization: Bearer ${ACCESS_TOKEN}" \
            -H "Accept:application/json" -F file=@${new_str}.iar \
            -F type=application/octet-stream "$import_url"
        cd "$OLD_DIR" || exit    
        else
        echo "✅ match found for integration in import environment: '$match_code'"
        status=$(jq -r --arg id "$id" ".${ARRAY_ATTRIBUTE}[] | select(.id == \$id) | .status" "$OUTPUT_FILE2")
        if [[ "$status" == "CONFIGURED" ]]; then
            #IMPORT
                OLD_DIR=$(pwd)
                cd "$DIR1" || exit
                import_url="${IMPORT_URL//\{instance\}/$OIC_INSTANCE}"
                echo "Full Import URL: $import_url"
                echo "Executing: curl -X PUT -H \"Authorization: Bearer ${ACCESS_TOKEN} -H "Accept:application/json" -F file="@${new_str}.iar" -F type=application/octet-stream\"  \"$import_url\""
                curl -X PUT -H "Authorization: Bearer ${ACCESS_TOKEN} -H "Accept:application/json" -F file=@${new_str}.iar -F type=application/octet-stream"  "$import_url"
                cd "$OLD_DIR" || exit
        else
                echo "❌ integration '$status' in target environment: '$match_code'"
        fi
    fi
 
done  
