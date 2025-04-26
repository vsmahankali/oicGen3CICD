#!/bin/bash

read -p "Enter name of directory where the exported lookups are present: " DIR1

# Check if directory exists
if [ ! -d "$DIR1" ]; then
    echo "Directory $DIR1 does not exist. Creating..."
    exit 1
else
    echo "Directory $DIR1 exists."
fi

read -p "Enter name of directory where the modified looks must be placed: " DIR2
# 1. Create the new folder
mkdir -p "$DIR2"

# 2. Copy all CSV files from lookupsForModification to modifiedLookups
cp ./${DIR1}/*.csv ./${DIR2}/

# 3. e.g. Replace all emails in the copied files
for file in ./modifiedLookups/*.csv; do
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+/vsample@org.com/g' "$file"
    else
        sed -i -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+/vsample@org.com/g' "$file"
    fi
done

