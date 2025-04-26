#!/bin/bash

read -p "Enter environment name (env1/env2): " ENV

case "$ENV" in
  env1)
    INSTANCE_DESIGN_TIME_URL=""
    CLIENT_ID=""  # Replace with your actual client ID
    CLIENT_SECRET=""  # Replace with your actual client secret
    OIC_INSTANCE=""  # Replace with enviroment name parameter
    AUTH_TOKEN_URL=""
    SCOPE_INSTANCE=""     
    ;;
  env2)
    INSTANCE_DESIGN_TIME_URL=""
    CLIENT_ID=""  # Replace with your actual client ID
    CLIENT_SECRET=""  # Replace with your actual client secret
    OIC_INSTANCE=""  # Replace with enviroment name parameter
    AUTH_TOKEN_URL=""
    SCOPE_INSTANCE=""     
    ;;      
    *)
    echo "Invalid environment name. Please enter env1/env2."
    exit 1
    ;;
esac

