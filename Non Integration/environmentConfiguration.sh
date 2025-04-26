#!/bin/bash

read -p "Enter environment name (wduat1/wduat2/wduat3/wduat3/wdprd1/wdprd2/wdprd3/wdprd4/sandiskdev/sandisksit1/sandisksit2/sandiskqa1/sandiskqa2/sandiskprd1/sandiskprd2): " ENV

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
    echo "Invalid environment name. Please enter wduat1/wduat2/wduat3/wduat3/wdprd1/wdprd2/wdprd3/wdprd4/sandiskdev/sandisksit1/sandisksit2/sandiskqa1/sandiskqa2/sandiskprd1/sandiskprd2."
    exit 1
    ;;
esac

