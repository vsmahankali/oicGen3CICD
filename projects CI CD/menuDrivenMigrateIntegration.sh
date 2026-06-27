#!/bin/bash

# Read environment
read -p "Enter environment (env1/env2): " ENVIRONMENT

case "${ENVIRONMENT}" in
    env1)
        TOKEN_URL="env1_token_url"
        CLIENT_ID="env1_client_id"
        CLIENT_SECRET="env1_client_secret"
        SCOPE="env1_scope"
        OIC_URL="env1_oic_url"
        INTEGRATION_INSTANCE="env1_instance"
        ;;
        
    env2)
        TOKEN_URL="env2_token_url"
        CLIENT_ID="env2_client_id"
        CLIENT_SECRET="env2_client_secret"
        SCOPE="env2_scope"
        OIC_URL="env2_oic_url"
        INTEGRATION_INSTANCE="env2_instance"
        ;;
        
    *)
        echo "Invalid environment: ${ENVIRONMENT}"
        echo "Valid values: env1 | env2"
        exit 1
        ;;
esac

echo
echo "=========================================="
echo "        Oracle Integration Utility"
echo "=========================================="
echo "1. Get Project List"
echo "2. Import Integration Projects"
echo "3. Export Integration Projects"
echo "4. Activate Integrations in Project"
echo "5. Deactivate Integrations in Project"
echo "6. Delete Integrations in Project"
echo "7. Copy Integrations Between Projects"
echo "8. Delete Connections In Projects"
echo "0. Exit"
echo "=========================================="

read -p "Select an option: " OPTION

case "${OPTION}" in
    1)
        echo "Executing getProjectList.sh..."
        ./getProjectList.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    2)
        echo "Executing importIntegrationProject.sh..."
        ./importIntegrationProject.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    3)
        echo "Executing exportIntegrationProjects.sh..."
        ./exportIntegrationProjects.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    4)
        echo "Executing activateIntegrationsInProject.sh..."
        ./activateIntegrationsInProject.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    5)
        echo "Executing deactivateIntegrationsInProject.sh..."
        ./deactivateIntegrationsInProject.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    6)
        echo "Executing deleteIntegrationsInProject.sh..."
        ./deleteIntegrationsInProject.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    7)
        echo "Executing copyIntegrationBetweenProjects.sh..."
        ./copyIntegrationBetweenProjects.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    8)
        echo "Executing deleteConnectionsInProjects.sh..."
        ./deleteConnectionsInProjects.sh \
            "${TOKEN_URL}" \
            "${CLIENT_ID}" \
            "${CLIENT_SECRET}" \
            "${SCOPE}" \
            "${OIC_URL}" \
            "${INTEGRATION_INSTANCE}"
        ;;

    0)
        echo "Exiting..."
        exit 0
        ;;

    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac