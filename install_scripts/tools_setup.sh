#!/bin/bash

# --- KHAI BÁO MÀU SẮC ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- CÁC HÀM XỬ LÝ OLLAMA (Tích hợp từ script của bạn) ---

check_dependencies() {
    echo -e "${YELLOW}[1/3] Checking prerequisites...${NC}"
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt-get update && sudo apt-get install -y curl
    fi

    if ! command -v ollama &> /dev/null; then
        echo "Ollama is not installed. Installing now..."
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo -e "${GREEN}- Ollama is already installed.${NC}"
    fi

    if ! pgrep -x "ollama" > /dev/null; then
        echo "Starting Ollama service..."
        ollama serve > /dev/null 2>&1 &
        sleep 5
    fi
}

scan_system() {
    echo -e "\n${YELLOW}[1.1] Your system specifications:${NC}"
    echo "------------------------------------------"
    OS=$(uname -s)
    RAM=$(free -g | awk '/^Mem:/{print $2}')
    CPU=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    GPU=$(lspci | grep -i 'vga\|3d\|display' | cut -d':' -f3 | xargs)
    
    echo -e "Operating System: $OS"
    echo -e "CPU: $CPU"
    echo -e "RAM: ${RAM}GB"
    echo -e "GPU: ${GPU:-'No dedicated GPU detected'}"
    echo "------------------------------------------"
}

manage_ollama_qwen() {
    show_header "OLLAMA & QWEN MODELS"
    check_dependencies
    scan_system
    
    echo -e "\n${YELLOW}[2] Available Qwen model versions:${NC}"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "STT" "Model Name" "Size" "Rec. RAM/VRAM" "Use Case"
    echo "--------------------------------------------------------------------------------------------"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "1" "Qwen2.5-0.5B" "~0.4GB" "4GB+" "Low-end devices/IoT"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "2" "Qwen2.5-1.5B" "~1.1GB" "8GB+" "Basic chat/Laptop"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "3" "Qwen2.5-7B" "~4.7GB" "16GB+" "Multitask/Code/Text"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "4" "Qwen2.5-14B" "~9GB" "24GB+" "Advanced analysis"
    printf "%-5s | %-15s | %-10s | %-20s | %-25s\n" "5" "Qwen2.5-32B" "~19GB" "32GB+" "Academic/Complex reasoning"

    echo -e "\n${BLUE}Enter the number of the model you want (or press 0 to go back):${NC}"
    read -p "Chọn (0-5): " MODEL_STT
    
    if [[ "$MODEL_STT" == "0" ]]; then return; fi

    case $MODEL_STT in
        1) BASE_NAME="qwen2.5:0.5b" ;;
        2) BASE_NAME="qwen2.5:1.5b" ;;
        3) BASE_NAME="qwen2.5:7b" ;;
        4) BASE_NAME="qwen2.5:14b" ;;
        5) BASE_NAME="qwen2.5:32b" ;;
        *) echo -e "${RED}Invalid selection.${NC}"; sleep 2; return ;;
    esac

    echo -e "\n${YELLOW}Choose optimization type:${NC}"
    echo "1. Full precision (Original)"
    echo "2. Speed optimized (Q2_K)"
    echo "3. Storage optimized (Q3_K_S)"
    echo "4. Balanced (Q4_K_M - Recommended)"
    read -p "Select (1-4): " OPTION_STT

    case $OPTION_STT in
        1) TAG=$BASE_NAME ;;
        2) TAG="${BASE_NAME}:q2_K" ;; 
        3) TAG="${BASE_NAME}:q3_K_S" ;;
        4) TAG="${BASE_NAME}:q4_K_M" ;;
        *) echo -e "${RED}Invalid option.${NC}"; return ;;
    esac

    echo -e "\n${GREEN}Pulling model: $TAG${NC}"
    ollama pull $TAG
    echo -e "\n${GREEN}Done! Run with: ollama run $TAG${NC}"
    read -p "Press Enter to continue..."
}


install_docker() {
    show_header "DOCKER ENGINE INSTALLATION (UBUNTU)"
    
    echo -e "${GREEN}1.${NC} Online Installation via fficial Apt Repository"
    echo -e "${GREEN}2.${NC} Offline Installation using .deb files in 'docker_offline' folder, which inside github folder 'install_offline'"
    echo -e "${RED}0.${NC} Back to Main Menu"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    read -p "Select method [0-2]: " docker_choice

    case $docker_choice in
        1)
            # --- ONLINE INSTALLATION ---
            echo -e "${YELLOW}[1/4] Removing conflicting packages...${NC}"
            for pkg in docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc; do
                sudo apt-get remove -y $pkg > /dev/null 2>&1
            done

            echo -e "${YELLOW}[2/4] Setting up Docker Apt Repository...${NC}"
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            echo -e "${BLUE}Adding Docker source list...${NC}"
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF
            sudo apt-get update

            echo -e "${YELLOW}[3/4] Installing Docker Engine & Plugins...${NC}"
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        2)
            # --- OFFLINE INSTALLATION ---
            OFFLINE_DIR="./docker_offline"
            show_header "OFFLINE INSTALLATION"
            
            if [ -d "$OFFLINE_DIR" ]; then
                echo -e "${YELLOW}Searching for .deb packages in: ${BLUE}$OFFLINE_DIR${NC}"
                # Kiểm tra xem có file deb nào không
                if ls "$OFFLINE_DIR"/*.deb >/dev/null 2>&1; then
                    echo -e "${YELLOW}[1/2] Installing packages using dpkg...${NC}"
                    sudo dpkg -i "$OFFLINE_DIR"/*.deb
                    
                    # Fix dependencies nếu thiếu (trong trường hợp offline một phần)
                    # sudo apt-get install -f -y
                else
                    echo -e "${RED}Error: No .deb files found in '$OFFLINE_DIR'.${NC}"
                    echo -e "Please ensure you have: containerd.io, docker-ce, docker-ce-cli, etc."
                    sleep 3; return
                fi
            else
                echo -e "${RED}Error: Directory '$OFFLINE_DIR' does not exist.${NC}"
                sleep 3; return
            fi
            ;;

        0) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; return ;;
    esac

    # --- COMMON POST-INSTALLATION ---
    echo -e "\n${YELLOW}[Checking] Starting and verifying Docker...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker

    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✔ Docker is successfully installed and running!${NC}"
        
        read -p "Do you want to run Docker without 'sudo'? (y/n): " add_user
        if [[ "$add_user" == "y" ]]; then
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}ℹ Please log out and log back in for changes to take effect.${NC}"
        fi
        
        echo -e "\n${BLUE}Version Info:${NC}"
        docker --version
    else
        echo -e "${RED}✘ Installation failed or service couldn't start.${NC}"
    fi

    read -p "Press Enter to return..."
}


install_airflow() {
    show_header "APACHE AIRFLOW INSTALLATION"
    
    echo -e "${GREEN}1.${NC} Install using Docker Compose (Recommended)"
    echo -e "${GREEN}2.${NC} Install Local using Python Pip (Standalone)"
    echo -e "${RED}0.${NC} Back to Main Menu"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    read -p "Select method [0-2]: " airflow_choice

    case $airflow_choice in
        1)
            # --- DOCKER COMPOSE METHOD ---
            if ! command -v docker &> /dev/null; then
                echo -e "${RED}Error: Docker is not installed. Please run Option 2 first.${NC}"
                sleep 3; return
            fi

            echo -e "${YELLOW}Setting up Airflow with Docker Compose...${NC}"
            mkdir -p ~/airflow-docker && cd ~/airflow-docker
            
            echo -e "${BLUE}Downloading official docker-compose.yaml...${NC}"
            curl -LfO 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'
            
            # Tạo các thư mục cần thiết
            mkdir -p ./dags ./logs ./plugins ./config
            echo -e "AIRFLOW_UID=$(id -u)" > .env
            
            echo -e "${YELLOW}Initializing Airflow database...${NC}"
            sudo docker compose up airflow-init
            
            echo -e "${GREEN}Starting Airflow containers...${NC}"
            sudo docker compose up -d
            
            echo -e "${GREEN}✔ Airflow is running at http://localhost:8080${NC}"
            echo -e "${YELLOW}Default Login: airflow / airflow${NC}"
            cd - > /dev/null
            ;;

        2)
            # --- LOCAL PIP METHOD ---
            echo -e "${YELLOW}Installing Airflow via Pip...${NC}"
            sudo apt-get update
            sudo apt-get install -y python3-pip python3-venv
            
            export AIRFLOW_HOME=~/airflow
            PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
            CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-main/constraints-${PYTHON_VERSION}.txt"
            
            pip install "apache-airflow==2.10.2" --constraint "${CONSTRAINT_URL}"
            
            echo -e "${YELLOW}Initializing Airflow Standalone...${NC}"
            airflow db init
            airflow users create \
                --username admin \
                --firstname Admin \
                --lastname User \
                --role Admin \
                --email admin@example.com \
                --password admin
            
            echo -e "${GREEN}✔ Airflow installed locally.${NC}"
            echo -e "Run 'airflow standalone' to start."
            ;;

        0) return ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1; return ;;
    esac

    read -p "Press Enter to return..."
}


# --- Main UI ---

show_header() {
    clear
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${YELLOW}          $1          ${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

main_menu() {
    while true; do
        show_header "AUTOMATED TOOL INSTALLATION SCRIPTS"
        echo -e " STATUS: $(whoami)@$(hostname)"
        echo -e "${BLUE}----------------------------------------------------${NC}"
        echo -e "${GREEN}1.${NC} Install Ollama & Qwen Models"
        echo -e "${GREEN}2.${NC} Install Docker Ubuntu"
        echo -e "${GREEN}3.${NC} Install Apache Airflow"
        echo -e "${RED}0.${NC} Thoát"
        echo -e "${BLUE}----------------------------------------------------${NC}"
        read -p "Choose [0-3]: " choice

        case $choice in
            1) manage_ollama_qwen ;;
            2) install_docker;;
            3) install_airflow;;
            0) echo -e "\n${GREEN}Tạm biệt!${NC}"; exit 0 ;;
            *) echo -e "\n${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

# Khởi chạy
main_menu
