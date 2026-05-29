#!/bin/bash
################################################################################
# deploy-parking-chaincode.sh
# Packages, installs, approves, and commits the parking chaincode on
# parking-main-channel (UniversityAdmin + Security + StudentAffairs peers).
#
# Usage: ./tool-bins/deploy-parking-chaincode.sh
# Run from the workspace root inside the dev container.
################################################################################

set -e

WORKSPACE=/workspaces/CampusParkingPermitManagementSystem
CRYPTO=$WORKSPACE/crypto-config
ORDERER_CA=$CRYPTO/ordererOrganizations/university.com/orderers/orderer0.university.com/tls/ca.crt
ORDERER_ADDRESS=orderer0.university.com:7050

CC_NAME="parkingmgt"
CC_PATH="./chaincodes/parking/"
CC_CHANNEL="parking-main-channel"
CC_LANGUAGE="golang"
CC_VERSION="1.0"
CC_SEQUENCE=1
PACKAGE_DIR="./chaincodes/packages"
CC_PACKAGE="$PACKAGE_DIR/$CC_NAME.$CC_VERSION.tar.gz"
CC_LABEL="$CC_NAME.$CC_VERSION"

echo "============================================================"
echo " CPPMS - Parking Chaincode Deployment"
echo "============================================================"

mkdir -p "$PACKAGE_DIR"

# ─── Step 1: Set env for admin peer0 and package ─────────────────────────────
echo ""
echo "[Step 1] Packaging chaincode..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode package "$CC_PACKAGE" \
  --path "$CC_PATH" \
  --lang "$CC_LANGUAGE" \
  --label "$CC_LABEL"
echo "  Package created: $CC_PACKAGE"

# ─── Step 2: Install on all parking-main-channel peers ───────────────────────
echo ""
echo "[Step 2] Installing chaincode on all channel peers..."

install_on_peer() {
  local ORG=$1
  local PEER_NUM=$2
  local MSP_ID=$3
  local PEER_PORT=$4
  local ORG_DOMAIN=$5

  export CORE_PEER_LOCALMSPID="$MSP_ID"
  export FABRIC_CFG_PATH=$WORKSPACE/config/$ORG
  export CORE_PEER_ADDRESS=peer${PEER_NUM}.${ORG_DOMAIN}:${PEER_PORT}
  export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/${ORG_DOMAIN}/users/Admin@${ORG_DOMAIN}/msp
  export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/${ORG_DOMAIN}/tlsca/tlsca.${ORG_DOMAIN}-cert.pem

  echo "  Installing on peer${PEER_NUM}.${ORG_DOMAIN}..."
  peer lifecycle chaincode install "$CC_PACKAGE"
}

# admin peers
install_on_peer admin 0 UniversityAdminMSP 7051 admin.university.com
install_on_peer admin 1 UniversityAdminMSP 7055 admin.university.com

# security peers
install_on_peer security 0 SecurityMSP 9051 security.university.com
install_on_peer security 1 SecurityMSP 9055 security.university.com

# studentaffairs peers
install_on_peer studentaffairs 0 StudentAffairsMSP 10051 studentaffairs.university.com
install_on_peer studentaffairs 1 StudentAffairsMSP 10055 studentaffairs.university.com

# ─── Step 3: Query installed to get Package ID ───────────────────────────────
echo ""
echo "[Step 3] Querying installed chaincode to get Package ID..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode queryinstalled

# Extract package ID automatically
CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled 2>/dev/null \
  | grep "$CC_LABEL" | sed 's/.*Package ID: //' | sed 's/, Label:.*//')

echo "  Package ID: $CC_PACKAGE_ID"

# ─── Step 4: Approve for UniversityAdmin ─────────────────────────────────────
echo ""
echo "[Step 4] Approving chaincode for UniversityAdmin..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode approveformyorg \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --package-id "$CC_PACKAGE_ID" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 5: Approve for Security ────────────────────────────────────────────
echo ""
echo "[Step 5] Approving chaincode for Security..."
export CORE_PEER_LOCALMSPID="SecurityMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/security
export CORE_PEER_ADDRESS=peer0.security.university.com:9051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/security.university.com/users/Admin@security.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/security.university.com/tlsca/tlsca.security.university.com-cert.pem

peer lifecycle chaincode approveformyorg \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --package-id "$CC_PACKAGE_ID" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 6: Approve for StudentAffairs ──────────────────────────────────────
echo ""
echo "[Step 6] Approving chaincode for StudentAffairs..."
export CORE_PEER_LOCALMSPID="StudentAffairsMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/studentaffairs
export CORE_PEER_ADDRESS=peer0.studentaffairs.university.com:10051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/studentaffairs.university.com/users/Admin@studentaffairs.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/studentaffairs.university.com/tlsca/tlsca.studentaffairs.university.com-cert.pem

peer lifecycle chaincode approveformyorg \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --package-id "$CC_PACKAGE_ID" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 7: Check commit readiness ──────────────────────────────────────────
echo ""
echo "[Step 7] Checking commit readiness..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode checkcommitreadiness \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 8: Commit chaincode ────────────────────────────────────────────────
echo ""
echo "[Step 8] Committing chaincode to $CC_CHANNEL..."
peer lifecycle chaincode commit \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA" \
  --peerAddresses peer0.admin.university.com:7051 \
  --tlsRootCertFiles $CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem \
  --peerAddresses peer0.security.university.com:9051 \
  --tlsRootCertFiles $CRYPTO/peerOrganizations/security.university.com/tlsca/tlsca.security.university.com-cert.pem \
  --peerAddresses peer0.studentaffairs.university.com:10051 \
  --tlsRootCertFiles $CRYPTO/peerOrganizations/studentaffairs.university.com/tlsca/tlsca.studentaffairs.university.com-cert.pem

# ─── Step 9: Verify ──────────────────────────────────────────────────────────
echo ""
echo "[Step 9] Verifying committed chaincode..."
peer lifecycle chaincode querycommitted \
  -n "$CC_NAME" -C "$CC_CHANNEL" \
  --tls --cafile "$ORDERER_CA"

echo ""
echo "============================================================"
echo " Parking chaincode deployed successfully on $CC_CHANNEL"
echo "============================================================"
