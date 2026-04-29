#!/bin/bash
################################################################################
# set_peer_env.sh
# Campus Parking Management System
# Usage: source ./tool-bins/set_peer_env.sh <org> <peer_num>
# Example: source ./tool-bins/set_peer_env.sh admin 0
#          source ./tool-bins/set_peer_env.sh finance 0
#          source ./tool-bins/set_peer_env.sh security 0
#          source ./tool-bins/set_peer_env.sh studentaffairs 0
################################################################################

ORG=$1
PEER_NUM=${2:-0}

case "$ORG" in
  admin)
    export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
    export FABRIC_CFG_PATH=/workspaces/CPPMS/config/admin
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.admin.university.com:7051
    export CORE_PEER_MSPCONFIGPATH=/workspaces/CPPMS/crypto-config/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
    ;;
  finance)
    export CORE_PEER_LOCALMSPID="FinanceMSP"
    export FABRIC_CFG_PATH=/workspaces/CPPMS/config/finance
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.finance.university.com:8051
    export CORE_PEER_MSPCONFIGPATH=/workspaces/CPPMS/crypto-config/peerOrganizations/finance.university.com/users/Admin@finance.university.com/msp
    ;;
  security)
    export CORE_PEER_LOCALMSPID="SecurityMSP"
    export FABRIC_CFG_PATH=/workspaces/CPPMS/config/security
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.security.university.com:9051
    export CORE_PEER_MSPCONFIGPATH=/workspaces/CPPMS/crypto-config/peerOrganizations/security.university.com/users/Admin@security.university.com/msp
    ;;
  studentaffairs)
    export CORE_PEER_LOCALMSPID="StudentAffairsMSP"
    export FABRIC_CFG_PATH=/workspaces/CPPMS/config/studentaffairs
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.studentaffairs.university.com:10051
    export CORE_PEER_MSPCONFIGPATH=/workspaces/CPPMS/crypto-config/peerOrganizations/studentaffairs.university.com/users/Admin@studentaffairs.university.com/msp
    ;;
  *)
    echo "Unknown org: $ORG"
    echo "Valid orgs: admin, finance, security, studentaffairs"
    return 1
    ;;
esac

export FABRIC_LOGGING_SPEC=INFO
export CORE_PEER_TLS_ENABLED=false
export ORDERER_ADDRESS=orderer0.university.com:7050

echo "Environment set for peer${PEER_NUM}.${ORG}"
echo "  CORE_PEER_LOCALMSPID = $CORE_PEER_LOCALMSPID"
echo "  CORE_PEER_ADDRESS    = $CORE_PEER_ADDRESS"
echo "  ORDERER_ADDRESS      = $ORDERER_ADDRESS"
