# Campus Parking Management System (CPPMS)
Hyperledger Fabric v2.x blockchain network for managing campus parking permits, gate access, violations, and fee payments.

---

## Prerequisites

- Docker Desktop (with WSL2 enabled on Windows)
- VSCode with the Dev Containers extension installed

---

## Setup

**Step 1 — Open in Dev Container**

Open this folder in VSCode. When prompted, click **"Reopen in Container"** and wait for it to build.

All remaining steps are run inside the Dev Container terminal.

**Step 2 — Create Docker network and volumes**

```bash
docker network create campus-nets
chmod +x ./tool-bins/*.sh
./tool-bins/create-volumes.sh
```

**Step 3 — Generate crypto material and channel artifacts**

```bash
./tool-bins/create-artifacts.sh
```

**Step 4 — Start the network**

```bash
docker-compose up -d
```

**Step 5 — Create channels and join peers**

```bash
./tool-bins/setup-channels.sh
```

**Step 6 — Verify the network is running**

```bash
source ./tool-bins/set_peer_env.sh admin 0
peer channel list
```

Expected output:
```
Channels peers has joined:
  parking-main-channel
  finance-channel
```

---

## Teardown

```bash
./tool-bins/teardown.sh
```
