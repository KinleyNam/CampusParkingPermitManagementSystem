#!/bin/bash
################################################################################
# create-artifacts.sh
# Campus Parking Management System
# Generates crypto material and channel artifacts
# Run from inside the devcontainer at /workspaces/CPPMS
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"
ARTIFACTS_DIR="$PROJECT_DIR/channel-artifacts"

echo "============================================================"
echo " Campus Parking Management System - Artifact Generation"
echo "============================================================"

# Step 1: Generate crypto material
echo ""
echo "[Step 1] Generating crypto material with cryptogen..."
cd "$PROJECT_DIR"
cryptogen generate \
  --config="$CONFIG_DIR/crypto-config.yaml" \
  --output="$PROJECT_DIR/crypto-config"
echo "  Crypto material generated in ./crypto-config"

# Step 2: Set FABRIC_CFG_PATH so configtxgen finds configtx.yaml
export FABRIC_CFG_PATH="$CONFIG_DIR"

# Step 3: Generate genesis block for the orderer system channel
echo ""
echo "[Step 2] Generating genesis block..."
configtxgen \
  -outputBlock "$ARTIFACTS_DIR/orderer/genesis.block" \
  -channelID ordererchannel \
  -profile CPPMSOrdererGenesis
echo "  Genesis block: $ARTIFACTS_DIR/orderer/genesis.block"

# Step 4: Generate channel transaction for parking-main-channel
echo ""
echo "[Step 3] Generating parking-main-channel transaction..."
configtxgen \
  -outputCreateChannelTx "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel
echo "  Channel tx: $ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx"

# Step 5: Generate channel transaction for finance-channel
echo ""
echo "[Step 4] Generating finance-channel transaction..."
configtxgen \
  -outputCreateChannelTx "$ARTIFACTS_DIR/finance-channel/finance-channel.tx" \
  -channelID finance-channel \
  -profile FinanceChannel
echo "  Channel tx: $ARTIFACTS_DIR/finance-channel/finance-channel.tx"

# Step 6: Generate anchor peer update transactions for parking-main-channel
echo ""
echo "[Step 5] Generating anchor peer updates for parking-main-channel..."
configtxgen \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/UniversityAdminMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg UniversityAdminMSP

configtxgen \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/SecurityMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg SecurityMSP

configtxgen \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/StudentAffairsMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg StudentAffairsMSP

# Step 7: Generate anchor peer update transactions for finance-channel
echo ""
echo "[Step 6] Generating anchor peer updates for finance-channel..."
configtxgen \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/finance-channel/UniversityAdminMSP-anchors.tx" \
  -channelID finance-channel \
  -profile FinanceChannel \
  -asOrg UniversityAdminMSP

configtxgen \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/finance-channel/FinanceMSP-anchors.tx" \
  -channelID finance-channel \
  -profile FinanceChannel \
  -asOrg FinanceMSP

echo ""
echo "============================================================"
echo " All artifacts generated successfully!"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  1. Run: docker network create campus-nets"
echo "  2. Run: ./tool-bins/create-volumes.sh"
echo "  3. Run: docker-compose up -d"
echo "  4. Run: ./tool-bins/setup-channels.sh"
