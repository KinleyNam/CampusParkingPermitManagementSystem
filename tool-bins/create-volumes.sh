#!/bin/bash
################################################################################
# create-volumes.sh
# Campus Parking Management System
# Creates Docker named volumes for persistent ledger storage
################################################################################

set -e

echo "Creating Docker named volumes for CPPMS..."

docker volume create orderer0-data
docker volume create orderer1-data
docker volume create orderer2-data
docker volume create peer0-admin-data
docker volume create peer1-admin-data
docker volume create peer0-finance-data
docker volume create peer1-finance-data
docker volume create peer0-security-data
docker volume create peer1-security-data
docker volume create peer0-studentaffairs-data
docker volume create peer1-studentaffairs-data

echo "All volumes created successfully."
