#!/bin/bash
################################################################################
# teardown.sh
# Campus Parking Management System
# Stops and removes all containers, volumes, and generated artifacts
################################################################################

echo "Tearing down CPPMS network..."

cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker-compose down --volumes --remove-orphans 2>/dev/null || true

# Remove named volumes
docker volume rm -f \
  orderer0-data orderer1-data orderer2-data \
  peer0-admin-data peer1-admin-data \
  peer0-finance-data peer1-finance-data \
  peer0-security-data peer1-security-data \
  peer0-studentaffairs-data peer1-studentaffairs-data 2>/dev/null || true

# Remove generated chaincode containers
docker rm -f $(docker ps -aq --filter "name=dev-peer") 2>/dev/null || true
docker rmi -f $(docker images -q "dev-peer*") 2>/dev/null || true

# Remove generated crypto material and artifacts
rm -rf ./crypto-config
rm -f ./channel-artifacts/orderer/genesis.block
rm -f ./channel-artifacts/parking-main-channel/*.tx
rm -f ./channel-artifacts/parking-main-channel/*.block
rm -f ./channel-artifacts/finance-channel/*.tx
rm -f ./channel-artifacts/finance-channel/*.block

echo "Teardown complete."
