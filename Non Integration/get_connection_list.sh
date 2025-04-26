#!/bin/bash

source ./environmentConfiguration.sh

# Set your Oracle IDCS or IAM details
LIMIT=100
OFFSET=0
URL="${INSTANCE_DESIGN_TIME_URL}/ic/api/integration/v1/connections?integrationInstance="

BASIC_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w 0)

ACCESS_TOKEN=$(curl -s -X POST "${AUTH_TOKEN_URL}" \
     -H "Authorization: Basic ${BASIC_AUTH}" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "scope=${SCOPE_INSTANCE}" | jq -r .access_token)

OUTPUT_FILE="../oic_response_${OIC_INSTANCE}.json"                   # Output file

# Clear file before writing new data
> "$OUTPUT_FILE"

while true; do
    # Make API request
    RESPONSE=$(curl -s -X GET "${URL}${OIC_INSTANCE}&offset=${OFFSET}&limit=${LIMIT}" -H "Authorization: Bearer ${ACCESS_TOKEN}")

    ITEMS=$(echo "$RESPONSE" | jq -r '.items')

     if [[ -s "$OUTPUT_FILE" && $(jq 'has("items")' "$OUTPUT_FILE") == "true" ]]; then
          echo "Appending to existing file..."
     
          # Merge new items into existing file
          jq --argjson newItems "$(echo "$RESPONSE" | jq '.items')" '.items += $newItems' "$OUTPUT_FILE" > temp.json && mv temp.json "$OUTPUT_FILE"
     else
          echo "Initializing file with response..."
     
          # Write the full response to the file
          echo "$RESPONSE" > "$OUTPUT_FILE"
     fi

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
