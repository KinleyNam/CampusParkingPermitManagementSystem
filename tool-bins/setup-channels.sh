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

# Refresh /etc/hosts: remove stale entries and add current container IPs
grep -v 'university\.com' /etc/hosts | sudo tee /tmp/hosts.clean > /dev/null && sudo cp /tmp/hosts.clean /etc/hosts
docker network inspect campus-nets \
  --format '{{range .Containers}}{{.IPv4Address}} {{.Name}}{{"\n"}}{{end}}' \
  | sed 's|/[0-9]*||g' | sudo tee -a /etc/hosts > /dev/null
echo "  /etc/hosts updated with current container IPs"

# Wait for orderer Raft leader to be elected before proceeding
echo "  Waiting for orderer Raft leader election..."
until docker logs orderer0.university.com 2>&1 | grep -q "elected leader"; do
  sleep 2
done
echo "  Orderer ready."

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
