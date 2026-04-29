#!/bin/bash
################################################################################
# setup-channels.sh
# Campus Parking Management System
# Creates channels and joins all relevant peers
# Run from inside the devcontainer at /workspaces/CPPMS
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARTIFACTS_DIR="$PROJECT_DIR/channel-artifacts"

echo "============================================================"
echo " Campus Parking Management System - Channel Setup"
echo "============================================================"

sleep 5  # Give orderers time to fully start

##############################################################################
# CHANNEL 1: parking-main-channel
# Members: UniversityAdmin + Security + StudentAffairs
##############################################################################

echo ""
echo "[parking-main-channel] Creating channel..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel create \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.tx" \
  --outputBlock "$ARTIFACTS_DIR/parking-main-channel/parking-main-channel.block"

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

# Update anchor peers for parking-main-channel
echo "[parking-main-channel] Updating anchor peers..."

source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/UniversityAdminMSP-anchors.tx"

source "$SCRIPT_DIR/set_peer_env.sh" security 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/SecurityMSP-anchors.tx"

source "$SCRIPT_DIR/set_peer_env.sh" studentaffairs 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c parking-main-channel \
  -f "$ARTIFACTS_DIR/parking-main-channel/StudentAffairsMSP-anchors.tx"

echo "[parking-main-channel] Setup complete."

##############################################################################
# CHANNEL 2: finance-channel
# Members: UniversityAdmin + Finance
##############################################################################

echo ""
echo "[finance-channel] Creating channel..."
source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel create \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/finance-channel.tx" \
  --outputBlock "$ARTIFACTS_DIR/finance-channel/finance-channel.block"

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

# Update anchor peers for finance-channel
echo "[finance-channel] Updating anchor peers..."

source "$SCRIPT_DIR/set_peer_env.sh" admin 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/UniversityAdminMSP-anchors.tx"

source "$SCRIPT_DIR/set_peer_env.sh" finance 0
peer channel update \
  -o "$ORDERER_ADDRESS" \
  -c finance-channel \
  -f "$ARTIFACTS_DIR/finance-channel/FinanceMSP-anchors.tx"

echo "[finance-channel] Setup complete."

echo ""
echo "============================================================"
echo " All channels created and peers joined successfully!"
echo "============================================================"
echo ""
echo "Verify channel membership with:"
echo "  source ./tool-bins/set_peer_env.sh admin 0"
echo "  peer channel list"
