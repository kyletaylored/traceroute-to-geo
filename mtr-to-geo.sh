#!/bin/bash

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "Error: jq could not be found. Please install jq first."
    exit 1
fi

# Check if mtr is installed
if ! command -v mtr &>/dev/null; then
    echo "Error: mtr could not be found. Please install mtr using 'brew install mtr' or via other methods."
    exit 1
fi

# Get the hostname as argument
HOSTNAME=$1
MTR_FILE="/tmp/${HOSTNAME}_mtr.json"

# Check if MTR file already exists
if [[ -f $MTR_FILE ]]; then
    echo "MTR data already exists for $HOSTNAME. Using existing data."
else
    echo "Running mtr for $HOSTNAME..."
    sudo mtr "$HOSTNAME" -jn > "$MTR_FILE"
    echo "MTR data saved to $MTR_FILE"
fi

# Convert the JSON file to a JSON string and then encode it in a URL-friendly way
# encodedData=$(jq -sRr '@uri' "$MTR_FILE")
encodedData=$(base64 < "$MTR_FILE" | tr -d '\n')

# Provide the user with the URL
echo "Open the following URL to view the map:"
# echo "https://maxmind.pantheon.support/mtr?data=$encodedData"
curl -X POST -H "Content-Type: application/json" -d @$MTR_FILE http://localhost:3031/mtr
