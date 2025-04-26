#!/bin/bash
source ./environmentConfiguration.sh
read -p "Enter name of directory where the lookups must be exported into: " DIR

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist. Creating..."
    mkdir -p "$DIR"
else
    echo "Directory $DIR already exists."
fi

# Change to the directory
cd "$DIR" || exit

# Execute the rest of your commands here
echo "Executing commands inside $DIR..."


LIMIT=100
OFFSET=0
URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/lookups?integrationInstance="
EXPORT_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/lookups/{name}/archive?integrationInstance="

BASIC_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w 0)

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

OUTPUT_FILE="../oic_lookup_response_${OIC_INSTANCE}.json"                   # Output file

# Clear file before writing new data
> "$OUTPUT_FILE"

while true; do
    # Make API request
    RESPONSE=$(curl -s -X GET "${URL}${OIC_INSTANCE}&offset=${OFFSET}&limit=${LIMIT}" -H "Authorization: Bearer ${ACCESS_TOKEN}")

    # Ensure output file is initialized
    if [[ ! -s "$OUTPUT_FILE" ]]; then
        echo '{"items":[]}' > "$OUTPUT_FILE"
    fi

    # Extract new items safely
    echo "$RESPONSE" | jq '.items' > new_items.json

    # Merge new items into existing file
    jq '.items += input' "$OUTPUT_FILE" new_items.json > temp.json && mv temp.json "$OUTPUT_FILE"
    rm -f new_items.json  # Cleanup

    # Check if the response contains "hasMore": true
    HAS_MORE=$(echo "$RESPONSE" | jq -r '.hasMore')

    if [[ "$HAS_MORE" != "true" ]]; then
        echo "No more data to fetch."
        break
    fi

    # Increase offset
    OFFSET=$((OFFSET + LIMIT))
    echo "Fetching next page with offset: $OFFSET"
done

echo "Data fetching complete. Saved in $OUTPUT_FILE."

ARRAY_ATTRIBUTE="items"  

# Count the number of elements in the array
ITEM_COUNT=$(jq "[.${ARRAY_ATTRIBUTE}[]] | length" "$OUTPUT_FILE")

echo "Total number of items in '${ARRAY_ATTRIBUTE}': $ITEM_COUNT"

# Loop over each item and extract the 'id'
for id in $(jq -r ".${ARRAY_ATTRIBUTE}[].id" "$OUTPUT_FILE"); do
    echo "Processing item ID: $id"
    # Extract lockedFlag for this id
    locked_flag=$(jq -r ".${ARRAY_ATTRIBUTE}[] | select(.id == \"$id\") | .lockedFlag" "$OUTPUT_FILE")
    # Extract status for this id 
    status=$(jq -r ".${ARRAY_ATTRIBUTE}[] | select(.id == \"$id\") | .status" "$OUTPUT_FILE")
    name=$(jq -r ".${ARRAY_ATTRIBUTE}[] | select(.id == \"$id\") | .name" "$OUTPUT_FILE")

     if [[ "$status" == "CONFIGURED" ]]; then
            if [[ "$locked_flag" == "false" ]]; then
 
                FULL_EXPORT_URL="${EXPORT_URL}${OIC_INSTANCE}"
                FULL_EXPORT_URL="${FULL_EXPORT_URL//\{name\}/$name}"

                echo "Full URL: $FULL_EXPORT_URL"
                echo "Executing: curl -X GET -H \"Authorization: Bearer ${ACCESS_TOKEN}\" -o \"${name}.csv\" \"$FULL_EXPORT_URL\""
                curl -X GET -H "Authorization: Bearer ${ACCESS_TOKEN}" -o "${name}.csv" "$FULL_EXPORT_URL"
       else
            echo "Skipping item ID: $id (lockedFlag is true)"
      fi
     else
       echo "Skipping item ID: $id (Status is $status)"
     fi  
done