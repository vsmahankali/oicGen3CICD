source ./environmentConfiguration.sh

INSTANCE_URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/integrations?integrationInstance="

# For Instance 
LIMIT=100
OFFSET=0

BASIC_AUTH=$(printf "%s" "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d '\n')

echo "curl -s -X POST \"${AUTH_TOKEN_URL}\" -H \"Authorization: Basic ${BASIC_AUTH}\" -H \"Content-Type: application/x-www-form-urlencoded\" -d \"grant_type=client_credentials\" -d \"scope=${SCOPE_INSTANCE}\""

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

echo "Access token : $ACCESS_TOKEN"

OUTPUT_FILE="oic_response_${OIC_INSTANCE}.json" # Output file

# Clear file before writing new data
> "$OUTPUT_FILE"

while true; do
    # Make API request
    RESPONSE=$(curl -s -X GET "${INSTANCE_URL}${OIC_INSTANCE}&offset=${OFFSET}&limit=${LIMIT}" -H "Authorization: Bearer ${ACCESS_TOKEN}")

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