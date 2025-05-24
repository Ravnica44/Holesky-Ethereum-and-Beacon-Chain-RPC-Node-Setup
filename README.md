## 🛠️ Systemd Setup (Binary Installation)

To run the Holesky node as systemd services using binary installations:

### 1. Install Binaries

#### Install Geth
```bash
# Add Ethereum repository
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install -y ethereum
# check geth installed
geth --version
```

#### Install lighthouse
```bash
cd $HOME
# install Rust
curl https://sh.rustup.rs -sSf | sh

# source:
source $HOME/.cargo/env

# install lighthouse from source:
git clone https://github.com/sigp/lighthouse.git
cd lighthouse
make

#check if successfully install:
ls -l /root/.cargo/bin/lighthouse

#output expected:
# -rwxr-xr-x 1 root root ... /root/.cargo/bin/lighthouse
```

### 2. Create Directory Structure
```bash
# Create node directories
mkdir -p /root/holesky-node/data
mkdir -p /root/holesky-node/data/geth
mkdir -p /root/holesky-node/data/lighthouse
```

### 3. Generate JWT Secret
```bash
# Generate JWT secret
openssl rand -hex 32 > /root/holesky-node/data/jwtsecret
chmod 600 /root/holesky-node/data/jwtsecret
```

### 4. Create Service Files

Create Geth service file:
```ini
sudo tee /etc/systemd/system/geth-holesky.service > /dev/null <<EOF
[Unit]
Description=Go Ethereum Client - Holesky Testnet
After=network.target
Wants=network.target

[Service]
User=root
Type=simple
EnvironmentFile=/root/holesky-node/.env

ExecStart=/usr/bin/geth \
  --holesky \
  --port ${P2P_GETH_PORT} \
  --authrpc.addr ${LISTEN_ADDRESS} \
  --authrpc.port ${AUTHRPC_PORT} \
  --authrpc.vhosts=* \
  --authrpc.jwtsecret ${JWT_SECRET} \
  --http \
  --http.addr ${LISTEN_ADDRESS} \
  --http.port ${HTTP_GETH_PORT} \
  --http.api eth,net,web3 \
  --http.corsdomain "*" \
  --syncmode "snap" \
  --gcmode=full \
  --datadir ${GETH_DATADIR} \
  --verbosity 3 \
  --cache=1024 \
  --maxpeers=25 \
  --txlookuplimit=0 \
  --ipcdisable

Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=default.target
EOF

# 🔄 Reload systemd
sudo systemctl daemon-reload

```

Create lighthouse service file:

```ini
sudo tee /etc/systemd/system/lighthouse-holesky.service > /dev/null <<EOF
[Unit]
Description=Lighthouse Ethereum Client - Holesky Testnet
After=network.target geth-holesky.service
Wants=network.target geth-holesky.service

[Service]
User=root
Type=simple
EnvironmentFile=/root/holesky-node/.env

ExecStart=/root/.cargo/bin/lighthouse bn \
  --network holesky \
  --datadir ${LIGHTHOUSE_DATADIR} \
  --execution-endpoint ${EXECUTION_ENDPOINT} \
  --execution-jwt ${JWT_SECRET} \
  --checkpoint-sync-url ${CHECKPOINT_SYNC_URL} \
  --http \
  --http-address ${LISTEN_ADDRESS} \
  --http-port ${HTTP_LIGHTHOUSE_PORT} \
  --port ${P2P_LIGHTHOUSE_PORT} \
  --target-peers 25 \
  --logfile ${LIGHTHOUSE_LOGFILE} \
  --logfile-compress

Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=default.target
EOF

# 🔄 Reload systemd
sudo systemctl daemon-reload

```

### 5. Create .env file
```bash
sudo tee /root/holesky-node/.env > /dev/null <<EOF
# Address settings
LISTEN_ADDRESS=0.0.0.0

# Geth ports
P2P_GETH_PORT=30303
AUTHRPC_PORT=8551
HTTP_GETH_PORT=8545

# Geth parameters
JWT_SECRET=/root/holesky-node/data/jwtsecret
GETH_DATADIR=/root/holesky-node/data/geth

# Lighthouse ports
HTTP_LIGHTHOUSE_PORT=5052
P2P_LIGHTHOUSE_PORT=9000

# Lighthouse parameters
LIGHTHOUSE_DATADIR=/root/holesky-node/data/lighthouse
EXECUTION_ENDPOINT=http://localhost:$HTTP_GETH_PORT

# https://github.com/eth-clients/checkpoint-sync-endpoints/tree/main/endpoints
CHECKPOINT_SYNC_URL=https://checkpoint-sync.holesky.ethpandaops.io
LIGHTHOUSE_LOGFILE=/root/holesky-node/data/lighthouse/beacon/logs/beacon.log

# check_sync.sh apy key from https://docs.etherscan.io/etherscan-v2/getting-started/getting-an-api-key
ETHERSCAN_API_KEY=
EOF
```

### 6. Enable and Start Services
```bash
# Reload systemd
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# Enable services
systemctl enable geth-holesky.service
systemctl enable lighthouse-holesky.service

# Start services
systemctl start geth-holesky.service
sleep 10  # Wait for Geth to initialize
systemctl start lighthouse-holesky.service
```

### 7. Monitor Services
```bash
# Check service status
systemctl status geth-holesky.service
systemctl status lighthouse-holesky.service

# View logs
journalctl -u geth-holesky.service -f
journalctl -u lighthouse-holesky.service -f

# Restart services
systemctl restart geth-holesky.service
systemctl restart lighthouse-holesky.service

# Stop services
systemctl stop geth-holesky.service
systemctl stop lighthouse-holesky.service

# Disable services
systemctl disable geth-holesky.service
systemctl disable lighthouse-holesky.service
```

## 🔐 (Optional) Open Firewall Ports

If you use `ufw` or another firewall, run:

```bash
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow $P2P_GETH_PORT/tcp
sudo ufw allow  $P2P_GETH_PORT/udp
sudo ufw allow $GETH_HTTP_PORT/tcp
sudo ufw allow $HTTP_LIGHTHOUSE_PORT/tcp

sudo ufw reload
```

Once opened, you can access RPC or Beacon API from other machines via:
- Geth RPC: `http://<your-ip>:$HTTP_GETH_PORT`
- Beacon API: `http://<your-ip>:$HTTP_LIGHTHOUSE_PORT`

### 8. Monitor Sync

```bash
curl -s http://localhost:${HTTP_LIGHTHOUSE_PORT}/eth/v1/node/syncing | jq

# Expected Output
{
  "data": {
    "is_syncing": false,
    "is_optimistic": false,
    "el_offline": false,
    "head_slot": "*******",
    "sync_distance": "0"
```

```bash
geth attach http://localhost:${HTTP_GETH_PORT}

# Expected Output
Welcome to the Geth JavaScript console!

instance: Geth/v1.15.11-stable-36b2371c/linux-amd64/go1.24.2
at block: ******** (*** *** ** **** **:**:** ***+**** (****))
 modules: eth:1.0 net:1.0 rpc:1.0 web3:1.0

To exit, press ctrl-d or type exit
> eth.syncing
false # Expected result
> exit
```









