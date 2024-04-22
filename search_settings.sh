#!/bin/bash

# Initialize variables
search_type="value"  # Default search type
search_term=""

# Function to display usage
usage() {
    echo "Usage: $0 [-k|-v] <search_term>"
    echo "  -k    Search by key name"
    echo "  -v    Search by value"
    exit 1
}

# Parse command-line options
while getopts "kv" opt; do
    case $opt in
        k) search_type="key" ;;
        v) search_type="value" ;;
        *) usage ;;
    esac
done

# Remove the options from the positional parameters
shift $((OPTIND - 1))

# Check if a search term was provided
if [ -z "$1" ]; then
    usage
else
    search_term=$1
fi

# Loop through each schema
for schema in $(gsettings list-schemas); do
    # Loop through each key in the schema
    for key in $(gsettings list-keys $schema); do
        # Get the value of the key
        value=$(gsettings get $schema $key)

        # Determine the search type
        case $search_type in
            "key")
                echo "$key" | grep -qi "$search_term" && echo "Schema: $schema - Key: $key - Value: $value"
                ;;
            "value")
                echo "$value" | grep -qi "$search_term" && echo "Schema: $schema - Key: $key - Value: $value"
                ;;
        esac
    done
done

