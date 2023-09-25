#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [IP_OR_HOSTNAME]"
    exit 1
fi

# Use the provided hostname or IP as an argument
HOST=$1

# Define the filename based on the hostname or IP for uniqueness
filename="${HOST}.txt"

# Check if the file exists
if [ ! -f "$filename" ]; then
    # If not, run traceroute and save the output to the file
    traceroute -n $HOST > "$filename"
fi

# Parse the saved file to produce JSON output
cat "$filename" | awk -F " " 'NR>1 {printf (NR==2 ? "" : ",") "\n{ \"hop\": \"" $1 "\", \"ip\": \"" $3 "\", \"ms\": \"" $2 "\" }" }' | jq -s '{ traceroute: . }'

