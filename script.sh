#!/bin/bash

# Colors
ORANGE='\033[0;33m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Banner
clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════╗"
echo "║   GETH NODE KURULUM SCRIPTI        ║"
echo "║   GitHub.com/UfukNode              ║"
echo "╚════════════════════════════════════╝"
echo -e "${RESET}"
sleep 2

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${ORANGE}⚠️ Root yetkisi gerekiyor. 'sudo' ile çalıştırın!${RESET}"
  exit 1
fi

# Main function
install_geth() {
  echo -e "${GREEN}[1/5] Sistem güncellemeleri yapılıyor...${RESET}"
  apt-get update && apt-get upgrade -y
  apt-get install -y curl git wget jq

  echo -e "${GREEN}[2/5] Docker kuruluyor...${RESET}"
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker

  echo -e "${GREEN}[3/5] Geth için dizinler hazırlanıyor...${RESET}"
  mkdir -p /root/ethereum/{execution,jwt}
  openssl rand -hex 32 > /root/ethereum/jwt/jwt.hex

  echo -e "${GREEN}[4/5] Docker-compose dosyası oluşturuluyor...${RESET}"
  cat <<EOF > /root/ethereum/docker-compose.yml
version: "3.9"
services:
  geth:
    image: ethereum/client-go:stable
    container_name: geth
    restart: unless-stopped
    ports:
      - "30303:30303/tcp"
      - "30303:30303/udp"
      - "8545:8545"
      - "8546:8546"
    volumes:
      - "/root/ethereum/execution:/data"
      - "/root/ethereum/jwt:/jwt"
    command:
      - "--sepolia"
      - "--http"
      - "--http.api=eth,net,web3"
      - "--http.addr=0.0.0.0"
      - "--authrpc.jwtsecret=/jwt/jwt.hex"
      - "--syncmode=snap"
EOF

  echo -e "${GREEN}[5/5] Geth container başlatılıyor...${RESET}"
  cd /root/ethereum && docker compose up -d

  # Show help
  echo -e "\n${CYAN}✔ Kurulum tamamlandı!${RESET}"
  echo -e "${ORANGE}🔍 Logları görüntüle: docker logs -f geth"
  echo -e "🛑 Durdurmak için: cd /root/ethereum && docker compose down${RESET}"
}

# Run
install_geth
