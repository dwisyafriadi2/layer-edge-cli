#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

REPO_URL="https://github.com/Layer-Edge/light-node.git"
GRPC_URL="rpc.testnet.layeredge.io:9090"
CONTRACT_ADDR="cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709"
ZK_PROVER_URL="https://layeredge.mintair.xyz/"
POINTS_API="https://light-node.layeredge.io"
SERVICE_NAME="layer-edge-light-node"
LOG_FILE="/var/log/layer-edge-light-node.log"

function install_dependencies() {
    echo -e "${GREEN}Installing Go, Rust, and Risc0 Toolchain...${NC}"
    cp ~/.bashrc ~/.bashrc.bak
    sudo apt update && sudo apt install -y curl build-essential git pkg-config libssl-dev

    if ! command -v go &> /dev/null; then
        wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        source ~/.bashrc
        rm go1.21.0.linux-amd64.tar.gz
    fi

    if ! command -v cargo &> /dev/null; then
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    curl -L https://risczero.com/install | bash
    export PATH="$HOME/.risc0/bin:$PATH"
    rzup install
}

function clone_repo() {
    echo -e "${GREEN}Cloning Light Node repository...${NC}"
    cd || exit
    rm -rf light-node
    git clone $REPO_URL
    cd light-node || exit
}

function setup_env() {
    echo -e "${GREEN}Setting up .env file...${NC}"
    read -rsp "Enter your PRIVATE_KEY: " PRIVATE_KEY_INPUT
    echo ""

    cat <<EOF > .env
GRPC_URL=$GRPC_URL
CONTRACT_ADDR=$CONTRACT_ADDR
ZK_PROVER_URL=$ZK_PROVER_URL
API_REQUEST_TIMEOUT=100
POINTS_API=$POINTS_API
PRIVATE_KEY='$PRIVATE_KEY_INPUT'
EOF

    echo -e "${GREEN}.env file created successfully.${NC}"
}

function start_merkle_service() {
    echo -e "${GREEN}Starting Merkle Service...${NC}"
    source ~/.bashrc
    cd ~/light-node/risc0-merkle-service || exit
    cargo build
}

function build_light_node() {
    echo -e "${GREEN}Building Light Node...${NC}"
    cd ~/light-node || exit
    go build
    echo -e "${GREEN}Build complete. Run './light-node' to start.${NC}"
}

function create_systemd_service() {
    echo -e "${GREEN}Creating systemd service...${NC}"
    sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=LayerEdge Light Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/light-node
ExecStart=$HOME/light-node/light-node
Restart=always
StandardOutput=append:${LOG_FILE}
StandardError=append:${LOG_FILE}

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME}
    sudo systemctl start ${SERVICE_NAME}
    echo -e "${GREEN}Systemd service created and started.${NC}"
}

function run_light_node() {
    build_light_node
    create_systemd_service
}

function view_logs() {
    echo -e "${GREEN}Showing logs (tail -f)...${NC}"
    sudo tail -f ${LOG_FILE}
}

function check_status() {
    echo -e "${GREEN}Checking Light Node status...${NC}"
    sudo systemctl status ${SERVICE_NAME}
}

function uninstall() {
    echo -e "${GREEN}Uninstalling Light Node and cleaning up...${NC}"
    sudo systemctl stop ${SERVICE_NAME}
    sudo systemctl disable ${SERVICE_NAME}
    sudo rm /etc/systemd/system/${SERVICE_NAME}.service
    sudo rm -rf ~/light-node
    sudo rm -rf ~/.risc0
    sudo rm -rf ~/.cargo
    sudo rm -f ${LOG_FILE}
    mv ~/.bashrc.bak ~/.bashrc
    source ~/.bashrc
    sudo systemctl daemon-reload
    echo -e "${GREEN}Uninstallation complete.${NC}"
}

function menu() {
    while true; do
        curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/main/logo.sh | bash
        echo -e "\n${GREEN}====== LayerEdge Light Node Installer ======${NC}"
        echo "1. Install Dependencies"
        echo "2. Clone Repository"
        echo "3. Setup .env File"
        echo "4. Start Merkle Service"
        echo "5. Build & Run Light Node (Systemd)"
        echo "6. View Logs"
        echo "7. Check Node Status"
        echo "8. Uninstall"
        echo "9. Exit"
        read -rp "Choose an option [1-9]: " choice

        case $choice in
            1) install_dependencies ;;
            2) clone_repo ;;
            3) setup_env ;;
            4) start_merkle_service ;;
            5) run_light_node ;;
            6) view_logs ;;
            7) check_status ;;
            8) uninstall ;;
            9) echo "Exiting..."; break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

menu
