#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}========================================================${NC}"
echo -e "${GREEN}      QWEN 2.5 LOCAL DEPLOYMENT HELPER (UBUNTU)${NC}"
echo -e "${BLUE}========================================================${NC}"

# 1. Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${YELLOW}[!] Ollama not found. Installing now...${NC}"
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}[V] Ollama is already installed.${NC}"
fi

show_hardware_info() {
    echo -e "\n${BLUE}--- Current Hardware Stats ---${NC}"
    # Get RAM
    ram=$(free -g | awk '/^Mem:/{print $2}')
    # Get GPU info
    if command -v nvidia-smi &> /dev/null; then
        gpu=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)
        echo -e "System RAM: ${ram}GB"
        echo -e "GPU Detected: ${gpu}"
    else
        echo -e "System RAM: ${ram}GB"
        echo -e "GPU: No NVIDIA GPU detected (Running on CPU)"
    fi
}

main_menu() {
    show_hardware_info
    echo -e "\n${YELLOW}STEP 1: Choose your device type:${NC}"
    echo "1) Laptop (Power-saving, thermally constrained)"
    echo "2) PC / Workstation (Performance oriented, better cooling)"
    echo "3) Laptop/PC (Non-GPU / CPU Only - Integrated Graphics)"
    echo "4) Exit"
    read -p "Select option [1-4]: " dev_choice

    case $dev_choice in
        1|2|3) sub_menu ;;
        4) exit 0 ;;
        *) echo "Invalid option"; main_menu ;;
    esac
}

sub_menu() {
    echo -e "\n${YELLOW}STEP 2: Choose Qwen 2.5 Download Strategy:${NC}"
    echo "1) Standard Versions (Official Ollama Library)"
    echo "2) Optimized Versions (Categorized by Hardware Specs)"
    echo "3) Back to Main Menu"
    read -p "Select option [1-3]: " strat_choice

    case $strat_choice in
        1) standard_qwen ;;
        2) optimized_qwen ;;
        3) main_menu ;;
        *) echo "Invalid option"; sub_menu ;;
    esac
}

standard_qwen() {
    echo -e "\n${BLUE}--- Standard Qwen 2.5 Versions ---${NC}"
    echo "1) Qwen 2.5 - 1.5B (Ultra light)"
    echo "2) Qwen 2.5 - 7B   (Standard balanced)"
    echo "3) Qwen 2.5 - 14B  (Smart, needs decent GPU)"
    echo "4) Qwen 2.5 - 32B  (High reasoning, heavy)"
    echo "5) Qwen 2.5 - 72B  (Expert level, needs 40GB+ VRAM)"
    read -p "Select model [1-5]: " m_choice

    case $m_choice in
        1) ollama run qwen2.5:1.5b ;;
        2) ollama run qwen2.5:7b ;;
        3) ollama run qwen2.5:14b ;;
        4) ollama run qwen2.5:32b ;;
        5) ollama run qwen2.5:72b ;;
    esac
}

optimized_qwen() {
    echo -e "\n${BLUE}--- Optimized Quantized Versions (Recommended) ---${NC}"
    echo -e "${YELLOW}Description & Suggestions (English):${NC}"
    
    echo -e "--------------------------------------------------------------------------------"
    echo -e "| OPTION | MODEL SIZE | RECOMMENDED SPECS             | USE CASE               |"
    echo -e "--------------------------------------------------------------------------------"
    echo -e "| [1]    | 1.5B-Q4_K_M| RAM: 4GB+ / CPU Only          | Fastest for Low-end PC |"
    echo -e "| [2]    | 7B-Q4_K_M  | RAM: 8GB+ / VRAM: 6GB+        | Daily tasks/Translation|"
    echo -e "| [3]    | 14B-Q4_K_M | RAM: 16GB+ / VRAM: 10GB+      | Technical reporting    |"
    echo -e "| [4]    | 32B-IQ3_M  | RAM: 32GB+ / VRAM: 12GB+      | High-quality logic     |"
    echo -e "| [5]    | 72B-IQ2_XS | RAM: 64GB+ / VRAM: 16GB+      | Expert research (Slow) |"
    echo -e "--------------------------------------------------------------------------------"
    
    read -p "Select optimized model [1-5]: " opt_choice

    case $opt_choice in
        1) echo "Pulling 1.5B Ultra Light..."; ollama run qwen2.5:1.5b ;;
        2) echo "Pulling 7B Balanced..."; ollama run qwen2.5:7b ;;
        3) echo "Pulling 14B High Fidelity..."; ollama run qwen2.5:14b ;;
        4) echo "Pulling 32B IQ3 (Compressed for Consumer GPUs)..."; ollama run mannix/qwen2.5:32b-iq3_m ;;
        5) echo "Pulling 72B IQ2 (Ultra Compressed)..."; ollama run mannix/qwen2.5:72b-iq2_xs ;;
    esac
}

# Start script
main_menu
