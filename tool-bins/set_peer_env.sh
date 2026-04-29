#!/bin/bash
################################################################################
# set_peer_env.sh
# Usage: source ./tool-bins/set_peer_env.sh <org> <peer_num>
################################################################################

ORG=$1
PEER_NUM=${2:-0}

WORKSPACE=/workspaces/CampusParkingPermitManagementSystem
CRYPTO=$WORKSPACE/crypto-config

export ORDERER_CA=$CRYPTO/ordererOrganizations/university.com/tlsca/tlsca.university.com-cert.pem
export ORDERER_ADDRESS=orderer0.university.com:7050
export CORE_PEER_TLS_ENABLED=true
export FABRIC_LOGGING_SPEC=INFO

case "$ORG" in
  admin)
    export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
    export FABRIC_CFG_PATH=$WORKSPACE/config/admin
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.admin.university.com:7051
    export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem
    ;;
  finance)
    export CORE_PEER_LOCALMSPID="FinanceMSP"
    export FABRIC_CFG_PATH=$WORKSPACE/config/finance
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.finance.university.com:8051
    export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/finance.university.com/users/Admin@finance.university.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/finance.university.com/tlsca/tlsca.finance.university.com-cert.pem
    ;;
  security)
    export CORE_PEER_LOCALMSPID="SecurityMSP"
    export FABRIC_CFG_PATH=$WORKSPACE/config/security
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.security.university.com:9051
    export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/security.university.com/users/Admin@security.university.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/security.university.com/tlsca/tlsca.security.university.com-cert.pem
    ;;
  studentaffairs)
    export CORE_PEER_LOCALMSPID="StudentAffairsMSP"
    export FABRIC_CFG_PATH=$WORKSPACE/config/studentaffairs
    export CORE_PEER_ADDRESS=peer${PEER_NUM}.studentaffairs.university.com:10051
    export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/studentaffairs.university.com/users/Admin@studentaffairs.university.com/msp
    export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/studentaffairs.university.com/tlsca/tlsca.studentaffairs.university.com-cert.pem
    ;;
  *)
    echo "Unknown org: $ORG. Valid: admin, finance, security, studentaffairs"
    return 1
    ;;
esac

echo "Environment set for peer${PEER_NUM}.${ORG}"
echo "  CORE_PEER_LOCALMSPID = $CORE_PEER_LOCALMSPID"
echo "  CORE_PEER_ADDRESS    = $CORE_PEER_ADDRESS"
echo "  ORDERER_ADDRESS      = $ORDERER_ADDRESS"
