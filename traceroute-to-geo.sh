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
GEO_FILE="/tmp/${HOSTNAME}_geo.json"

# Check if MTR file already exists
if [[ -f $MTR_FILE ]]; then
    echo "MTR data already exists for $HOSTNAME. Using existing data."
else
    echo "Running mtr for $HOSTNAME..."
    sudo mtr "$HOSTNAME" -jn > "$MTR_FILE"
    echo "MTR data saved to $MTR_FILE"
fi

# Check if geo data file already exists
if [[ -f $GEO_FILE ]]; then
    echo "Geo data already exists for $HOSTNAME. Using existing data."
else
    # Initialize geoData as an empty array
    geoData=[]

    # Extracting IP addresses and Avg latency values from MTR report
    while IFS= read -r ip && IFS= read -r avg <&3; do
        if [[ $ip != "???" ]]; then
            echo "Fetching data for IP: $ip..."
            newData=$(curl -s "https://ipinfo.io/$ip/json" | jq --arg avg "$avg" '{ip, hostname, city, region, country, loc, org, Avg: $avg}')
            # Append the new data to the existing geoData
            geoData=$(echo "$geoData" | jq --argjson new "$newData" '. += [$new]')
        fi
    done < <(jq -r '.report.hubs[].host' "$MTR_FILE") 3< <(jq -r '.report.hubs[].Avg' "$MTR_FILE")


        # Save the geo data
        echo "$geoData" > "$GEO_FILE"
        echo "Geo data saved to $GEO_FILE"
    fi

# Convert the JSON file to a JSON string and then encode it in a URL-friendly way
encodedData=$(jq -sRr '@uri' "$GEO_FILE")
# encodedData=$(base64 < "$GEO_FILE" | tr -d '\n')

# Provide the user with the URL
echo "Open the following URL to view the map:"
echo "https://maxmind.pantheon.support/mtr.html?data=$encodedData&hostname=$HOSTNAME"
