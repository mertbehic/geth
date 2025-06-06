#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}✗ Root yetkisi gerekiyor. 'sudo su' ile root olun!${NC}" >&2
  exit 1
fi

# Banner
clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════╗"
echo "║   GETH NODE KURULUM SCRIPTI        ║"
echo "║   GitHub.com/mertbehic/geth        ║"
echo "╚════════════════════════════════════╝"
echo -e "${NC}"
sleep 2

# Main Function
install_geth() {
  echo -e "${GREEN}[1/4] Sistem güncellemeleri yapılıyor...${NC}"
  apt-get update && apt-get upgrade -y
  apt-get install -y curl git jq

  echo -e "${GREEN}[2/4] Docker kuruluyor...${NC}"
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker

  echo -e "${GREEN}[3/4] Geth için dizinler hazırlanıyor...${NC}"
  mkdir -p /ethereum/{execution,jwt}
  openssl rand -hex 32 > /ethereum/jwt/jwt.hex

  echo -e "${GREEN}[4/4] Docker-compose dosyası oluşturuluyor...${NC}"
  cat <<EOF > /ethereum/docker-compose.yml
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
      - "/ethereum/execution:/data"
      - "/ethereum/jwt:/jwt"
    command:
      - "--sepolia"
      - "--http"
      - "--http.api=eth,net,web3"
      - "--http.addr=0.0.0.0"
      - "--authrpc.jwtsecret=/jwt/jwt.hex"
      - "--syncmode=snap"
EOF

  # Start container
  echo -e "${GREEN}Container başlatılıyor...${NC}"
  cd /ethereum && docker compose up -d

  # Check status
  if docker ps | grep -q geth; then
    echo -e "\n${CYAN}✔ Kurulum tamamlandı!${NC}"
    echo -e "${GREEN}🔍 Loglar: ${NC}docker logs -f geth"
    echo -e "${GREEN}🛑 Durdur: ${NC}cd /ethereum && docker compose down"
  else
    echo -e "${RED}✗ Container başlatılamadı! Logları kontrol edin:${NC}"
    docker logs geth
  fi
}

# Run
install_geth
