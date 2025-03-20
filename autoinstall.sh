#!/bin/bash

# Color variables
GREEN='\033[0;32m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/Layer-Edge/light-node.git"
GRPC_URL="34.31.74.109:9090"
CONTRACT_ADDR="cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709"
ZK_PROVER_URL="http://127.0.0.1:3001"
POINTS_API="https://light-node.layeredge.io"

function install_dependencies() {
    echo -e "${GREEN}Installing Go, Rust, and Risc0 Toolchain...${NC}"
    cp ~/.bashrc ~/.bashrc.bak
    sudo apt update && sudo apt install -y curl build-essential git pkg-config libssl-dev

    # Install Go
    if ! command -v go &> /dev/null; then
        wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        source ~/.bashrc
        rm go1.21.0.linux-amd64.tar.gz
    fi

    # Install Rust
    if ! command -v cargo &> /dev/null; then
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Install Risc0 Toolchain
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
    cd ~/light-node/risc0-merkle-service || exit
    cargo build && cargo run
}

function build_light_node() {
    echo -e "${GREEN}Building Light Node...${NC}"
    cd ~/light-node || exit
    go build
    echo -e "${GREEN}Build complete. Run './light-node' to start.${NC}"
}

function run_light_node() {
    echo -e "${GREEN}Running Light Node...${NC}"
    cd ~/light-node || exit
    ./light-node
}

function uninstall() {
    echo -e "${GREEN}Uninstalling Light Node and cleaning up...${NC}"
    rm -rf ~/light-node
    rm -rf ~/.risc0
    rm -rf ~/.cargo
    mv ~/.bashrc.bak ~/.bashrc
    source ~/.bashrc
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
        echo "5. Build Light Node"
        echo "6. Run Light Node"
        echo "7. Uninstall"
        echo "8. Exit"
        read -rp "Choose an option [1-8]: " choice

        case $choice in
            1) install_dependencies ;;
            2) clone_repo ;;
            3) setup_env ;;
            4) start_merkle_service ;;
            5) build_light_node ;;
            6) run_light_node ;;
            7) uninstall ;;
            8) echo "Exiting..."; break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

menu
