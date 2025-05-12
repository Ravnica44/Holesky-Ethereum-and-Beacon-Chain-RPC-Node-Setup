#!/bin/bash

# Holesky Ethereum & Beacon Chain Private RPC Node Setup
# This script sets up both execution client (ETH) and consensus client (Beacon Chain) for Holesky testnet

set -e

# Create directories
mkdir -p ~/holesky-node/{geth,lighthouse,data,logs}
cd ~/holesky-node

echo "======================================================"
echo "Setting up Holesky Private RPC Node (ETH + Beacon Chain)"
echo "======================================================"

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential git wget software-properties-common cmake clang

# Install Go (required for Geth)
if ! command -v go &> /dev/null; then
    echo "Installing Go..."
    wget https://go.dev/dl/go1.21.3.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.21.3.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    source ~/.profile
    rm go1.21.3.linux-amd64.tar.gz
fi

# Install Rust (required for Lighthouse)
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Install and configure Geth (Execution Client)
if ! command -v geth &> /dev/null; then
    echo "Installing Geth execution client..."
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install -y ethereum
else
    echo "Geth already installed, skipping..."
fi

# Install Lighthouse (Consensus Client)
if ! command -v lighthouse &> /dev/null; then
    echo "Installing Lighthouse consensus client..."
    cd ~/holesky-node
    git clone https://github.com/sigp/lighthouse.git
    cd lighthouse
    git checkout stable
    make
    cd ..
else
    echo "Lighthouse already installed, skipping..."
fi

# Create Geth service file
cat > ~/holesky-node/geth-holesky.service << EOF
[Unit]
Description=Go Ethereum Client - Holesky Testnet
After=network.target
Wants=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/geth \
  --holesky \
  --authrpc.addr 0.0.0.0 \
  --authrpc.port 8553 \
  --authrpc.vhosts=* \
  --authrpc.jwtsecret /root/holesky-node/data/jwtsecret \
  --http \
  --http.addr 0.0.0.0 \
  --http.port 8550 \
  --http.api eth,net,engine,admin,web3 \
  --http.corsdomain "*" \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port 8554 \
  --ws.api eth,net,engine,admin,web3 \
  --syncmode "full" \
  --gcmode=full \
  --datadir /root/holesky-node/data/geth \
  --verbosity 3
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=default.target
EOF

# Create Lighthouse service file
cat > ~/holesky-node/lighthouse-holesky.service << EOF
[Unit]
Description=Lighthouse Ethereum Client - Holesky Testnet
After=network.target geth-holesky.service
Wants=network.target geth-holesky.service

[Service]
User=root
Type=simple
ExecStart=/root/.cargo/bin/lighthouse bn \
  --network holesky \
  --datadir /root/holesky-node/data/lighthouse \
  --execution-endpoint http://localhost:8551 \
  --execution-jwt /root/holesky-node/data/jwtsecret \
  --checkpoint-sync-url https://checkpoint-sync.holesky.ethpandaops.io \
  --http \
  --http-address 0.0.0.0 \
  --http-port 5055 \
  --metrics \
  --metrics-address 0.0.0.0 \
  --metrics-port 5056
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=default.target
EOF

# Generate JWT Secret
echo "Generating JWT secret for secure client communication..."
openssl rand -hex 32 > ~/holesky-node/data/jwtsecret

# Install services
echo "Installing services..."
sudo cp ~/holesky-node/geth-holesky.service /etc/systemd/system/
sudo cp ~/holesky-node/lighthouse-holesky.service /etc/systemd/system/
sudo systemctl daemon-reload

# Create start script
cat > ~/holesky-node/start-holesky-node.sh << EOF
#!/bin/bash
echo "Starting Holesky Ethereum Node (Execution + Consensus)"
sudo systemctl start geth-holesky
echo "Waiting for Geth to initialize (30 seconds)..."
sleep 30
sudo systemctl start lighthouse-holesky
echo "Holesky node services started!"
echo "RPC Endpoints:"
echo "- Execution (ETH) HTTP RPC: http://localhost:8546"
echo "- Execution (ETH) WebSocket: ws://localhost:8547"
echo "- Consensus (Beacon) HTTP: http://localhost:5052"
echo "Monitor logs:"
echo "- Execution: sudo journalctl -fu geth-holesky"
echo "- Consensus: sudo journalctl -fu lighthouse-holesky"
EOF

# Create stop script
cat > ~/holesky-node/stop-holesky-node.sh << EOF
#!/bin/bash
echo "Stopping Holesky Ethereum Node services..."
sudo systemctl stop lighthouse-holesky
sudo systemctl stop geth-holesky
echo "Services stopped!"
EOF

# Make scripts executable
chmod +x ~/holesky-node/start-holesky-node.sh
chmod +x ~/holesky-node/stop-holesky-node.sh

echo "======================================================"
echo "Setup completed successfully!"
echo "======================================================"
echo ""
echo "To start your Holesky node:"
echo "  ~/holesky-node/start-holesky-node.sh"
echo ""
echo "To stop your Holesky node:"
echo "  ~/holesky-node/stop-holesky-node.sh"
echo ""
echo "RPC Endpoints once started:"
echo "- Execution (ETH) HTTP RPC: http://localhost:8546"
echo "- Execution (ETH) WebSocket: ws://localhost:8547"
echo "- Consensus (Beacon) HTTP: http://localhost:5052"
echo ""
echo "Initial synchronization may take several hours to complete."
echo "You can monitor sync progress using the following commands:"
echo "- Execution client: sudo journalctl -fu geth-holesky"
echo "- Consensus client: sudo journalctl -fu lighthouse-holesky"
