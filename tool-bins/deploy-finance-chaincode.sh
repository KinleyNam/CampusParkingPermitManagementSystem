#!/bin/bash
################################################################################
# deploy-finance-chaincode.sh
# Packages, installs, approves, and commits the finance chaincode on
# finance-channel (UniversityAdmin + Finance peers).
#
# Usage: ./tool-bins/deploy-finance-chaincode.sh
# Run from the workspace root inside the dev container.
################################################################################

set -e

WORKSPACE=/workspaces/CampusParkingPermitManagementSystem
CRYPTO=$WORKSPACE/crypto-config
ORDERER_CA=$CRYPTO/ordererOrganizations/university.com/orderers/orderer0.university.com/tls/ca.crt
ORDERER_ADDRESS=orderer0.university.com:7050

CC_NAME="financemgt"
CC_PATH="./chaincodes/finance/"
CC_CHANNEL="finance-channel"
CC_LANGUAGE="golang"
CC_VERSION="1.0"
CC_SEQUENCE=1
PACKAGE_DIR="./chaincodes/packages"
CC_PACKAGE="$PACKAGE_DIR/$CC_NAME.$CC_VERSION.tar.gz"
CC_LABEL="$CC_NAME.$CC_VERSION"

echo "============================================================"
echo " CPPMS - Finance Chaincode Deployment"
echo "============================================================"

mkdir -p "$PACKAGE_DIR"

# ─── Step 1: Package ─────────────────────────────────────────────────────────
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

# ─── Step 2: Install on all finance-channel peers ────────────────────────────
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

# finance peers
install_on_peer finance 0 FinanceMSP 8051 finance.university.com
install_on_peer finance 1 FinanceMSP 8055 finance.university.com

# ─── Step 3: Get Package ID ──────────────────────────────────────────────────
echo ""
echo "[Step 3] Querying installed chaincode to get Package ID..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode queryinstalled

CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled 2>/dev/null \
  | grep "$CC_LABEL" | sed 's/.*Package ID: //' | sed 's/, Label:.*//')

echo "  Package ID: $CC_PACKAGE_ID"

# ─── Step 4: Approve for UniversityAdmin ─────────────────────────────────────
echo ""
echo "[Step 4] Approving chaincode for UniversityAdmin..."
peer lifecycle chaincode approveformyorg \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --package-id "$CC_PACKAGE_ID" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 5: Approve for Finance ─────────────────────────────────────────────
echo ""
echo "[Step 5] Approving chaincode for Finance..."
export CORE_PEER_LOCALMSPID="FinanceMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/finance
export CORE_PEER_ADDRESS=peer0.finance.university.com:8051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/finance.university.com/users/Admin@finance.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/finance.university.com/tlsca/tlsca.finance.university.com-cert.pem

peer lifecycle chaincode approveformyorg \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --package-id "$CC_PACKAGE_ID" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 6: Check commit readiness ──────────────────────────────────────────
echo ""
echo "[Step 6] Checking commit readiness..."
export CORE_PEER_LOCALMSPID="UniversityAdminMSP"
export FABRIC_CFG_PATH=$WORKSPACE/config/admin
export CORE_PEER_ADDRESS=peer0.admin.university.com:7051
export CORE_PEER_MSPCONFIGPATH=$CRYPTO/peerOrganizations/admin.university.com/users/Admin@admin.university.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=$CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem

peer lifecycle chaincode checkcommitreadiness \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --tls --cafile "$ORDERER_CA"

# ─── Step 7: Commit ──────────────────────────────────────────────────────────
echo ""
echo "[Step 7] Committing chaincode to $CC_CHANNEL..."
peer lifecycle chaincode commit \
  -n "$CC_NAME" -v "$CC_VERSION" \
  -C "$CC_CHANNEL" --sequence "$CC_SEQUENCE" \
  --orderer "$ORDERER_ADDRESS" \
  --tls --cafile "$ORDERER_CA" \
  --peerAddresses peer0.admin.university.com:7051 \
  --tlsRootCertFiles $CRYPTO/peerOrganizations/admin.university.com/tlsca/tlsca.admin.university.com-cert.pem \
  --peerAddresses peer0.finance.university.com:8051 \
  --tlsRootCertFiles $CRYPTO/peerOrganizations/finance.university.com/tlsca/tlsca.finance.university.com-cert.pem

# ─── Step 8: Verify ──────────────────────────────────────────────────────────
echo ""
echo "[Step 8] Verifying committed chaincode..."
peer lifecycle chaincode querycommitted \
  -n "$CC_NAME" -C "$CC_CHANNEL" \
  --tls --cafile "$ORDERER_CA"

echo ""
echo "============================================================"
echo " Finance chaincode deployed successfully on $CC_CHANNEL"
echo "============================================================"
