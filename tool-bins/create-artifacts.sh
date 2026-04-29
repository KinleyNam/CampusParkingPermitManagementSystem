#!/bin/bash
################################################################################
# create-artifacts.sh
# Campus Parking Management System
# Generates crypto material and channel artifacts
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"
ARTIFACTS_DIR="$PROJECT_DIR/channel-artifacts"

export FABRIC_CFG_PATH="$CONFIG_DIR"

echo "============================================================"
echo " Campus Parking Management System - Artifact Generation"
echo "============================================================"
echo " CONFIG_DIR   = $CONFIG_DIR"
echo " ARTIFACTS_DIR = $ARTIFACTS_DIR"

# Step 1: Generate crypto material
echo ""
echo "[Step 1] Generating crypto material with cryptogen..."
cd "$PROJECT_DIR"
rm -rf "$PROJECT_DIR/crypto-config"
cryptogen generate \
  --config="$CONFIG_DIR/crypto-config.yaml" \
  --output="$PROJECT_DIR/crypto-config"
echo "  Crypto material generated in ./crypto-config"

# Step 2: Generate genesis block
echo ""
echo "[Step 2] Generating genesis block..."
configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputBlock "$ARTIFACTS_DIR/orderer/genesis.block" \
  -channelID ordererchannel \
  -profile CPPMSOrdererGenesis
echo "  Genesis block: $ARTIFACTS_DIR/orderer/genesis.block"

# Step 3: Generate parking-main-channel transaction
echo ""
echo "[Step 3] Generating parking-main-channel transaction..."
configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputCreateChannelTx "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel
echo "  Channel tx: $ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx"

# Step 4: Generate finance-channel transaction
echo ""
echo "[Step 4] Generating finance-channel transaction..."
configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputCreateChannelTx "$ARTIFACTS_DIR/finance-channel/finance-channel.tx" \
  -channelID finance-channel \
  -profile FinanceChannel
echo "  Channel tx: $ARTIFACTS_DIR/finance-channel/finance-channel.tx"

# Step 5: Anchor peer updates for parking-main-channel
echo ""
echo "[Step 5] Generating anchor peer updates for parking-main-channel..."
configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/UniversityAdminMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg UniversityAdminMSP

configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/SecurityMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg SecurityMSP

configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/parking-main-channel/StudentAffairsMSP-anchors.tx" \
  -channelID parking-main-channel \
  -profile ParkingMainChannel \
  -asOrg StudentAffairsMSP

# Step 6: Anchor peer updates for finance-channel
echo ""
echo "[Step 6] Generating anchor peer updates for finance-channel..."
configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/finance-channel/UniversityAdminMSP-anchors.tx" \
  -channelID finance-channel \
  -profile FinanceChannel \
  -asOrg UniversityAdminMSP

configtxgen \
  -configPath "$CONFIG_DIR" \
  -outputAnchorPeersUpdate "$ARTIFACTS_DIR/finance-channel/FinanceMSP-anchors.tx" \
  -channelID finance-channel \
  -profile FinanceChannel \
  -asOrg FinanceMSP

echo ""
echo "============================================================"
echo " All artifacts generated successfully!"
echo "============================================================"
