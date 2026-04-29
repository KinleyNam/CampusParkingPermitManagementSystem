#!/bin/bash
################################################################################
# setup-channels.sh
# Campus Parking Management System
# Creates channels and joins all relevant peers
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARTIFACTS_DIR="$PROJECT_DIR/channel-artifacts"

echo "============================================================"
echo " Campus Parking Management System - Channel Setup"
echo "============================================================"

sleep 5

##############################################################################
# CHANNEL 1: parking-main-channel
##############################################################################

echo ""
echo "[parking-main-channel] Creating channel..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel create \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx" \
  --outputBlock "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block" \
  --tls --cafile "$ORDERER_CA"

echo "[parking-main-channel] Joining peer0.admin..."
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Joining peer1.admin..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 1
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Joining peer0.security..."
source "$SCRIPT_DIR/set_peer_env.sh" security 0
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Joining peer1.security..."
source "$SCRIPT_DIR/set_peer_env.sh" security 1
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Joining peer0.studentaffairs..."
source "$SCRIPT_DIR/set_peer_env.sh" studentaffairs 0
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Joining peer1.studentaffairs..."
source "$SCRIPT_DIR/set_peer_env.sh" studentaffairs 1
peer channel join -b "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

echo "[parking-main-channel] Updating anchor peers..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/UniversityAdminMSP-anchors.tx" \
  --tls --cafile "$ORDERER_CA"

source "$SCRIPT_DIR/set_peer_env.sh" security 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/SecurityMSP-anchors.tx" \
  --tls --cafile "$ORDERER_CA"

source "$SCRIPT_DIR/set_peer_env.sh" studentaffairs 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/StudentAffairsMSP-anchors.tx" \
  --tls --cafile "$ORDERER_CA"

echo "[parking-main-channel] Done."

##############################################################################
# CHANNEL 2: finance-channel
##############################################################################

echo ""
echo "[finance-channel] Creating channel..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel create \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/finance-channel.tx" \
  --outputBlock "$ARTIFACTS_DIR/finance-channel/finance-channel.block" \
  --tls --cafile "$ORDERER_CA"

echo "[finance-channel] Joining peer0.admin..."
peer channel join -b "$ARTIFACTS_DIR/finance-channel/finance-channel.block"

echo "[finance-channel] Joining peer1.admin..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 1
peer channel join -b "$ARTIFACTS_DIR/finance-channel/finance-channel.block"

echo "[finance-channel] Joining peer0.finance..."
source "$SCRIPT_DIR/set_peer_env.sh" finance 0
peer channel join -b "$ARTIFACTS_DIR/finance-channel/finance-channel.block"

echo "[finance-channel] Joining peer1.finance..."
source "$SCRIPT_DIR/set_peer_env.sh" finance 1
peer channel join -b "$ARTIFACTS_DIR/finance-channel/finance-channel.block"

echo "[finance-channel] Updating anchor peers..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/UniversityAdminMSP-anchors.tx" \
  --tls --cafile "$ORDERER_CA"

source "$SCRIPT_DIR/set_peer_env.sh" finance 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/FinanceMSP-anchors.tx" \
  --tls --cafile "$ORDERER_CA"

echo "[finance-channel] Done."

echo ""
echo "============================================================"
echo " All channels created and peers joined successfully!"
echo "============================================================"
echo ""
echo "Verify with:"
echo "  source ./tool-bins/set_peer_env.sh admin 0"
echo "  peer channel list"
