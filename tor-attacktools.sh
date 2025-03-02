#!/bin/bash

set -e  # Exit if an error occurs

###############################################################################
# 1. DOCKERFILE.TOR
###############################################################################
cat << 'EOF' > Dockerfile.tor
FROM debian:latest

RUN apt-get update && apt-get install -y tor curl netcat-traditional && rm -rf /var/lib/apt/lists/*
RUN echo "SocksPort 0.0.0.0:9050" >> /etc/tor/torrc

CMD ["tor"]
EOF

###############################################################################
# 2. DOCKERFILE.ATTACKTOOLS
###############################################################################
cat << 'EOF' > Dockerfile.attacktools
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# 1) Install necessary tools
RUN apt-get update && apt-get install -y \
    zsh \
    proxychains4 \
    curl \
    nmap \
    nikto \
    ffuf \
    metasploit-framework \
    iputils-ping \
    vim \
 && rm -rf /var/lib/apt/lists/*

# 2) Initial configuration of proxychains4 (strict_chain mode, proxy_dns)
RUN sed -i 's/^dynamic_chain/#dynamic_chain/' /etc/proxychains4.conf \
 && sed -i 's/^#strict_chain/strict_chain/' /etc/proxychains4.conf \
 && sed -i 's/^#proxy_dns/proxy_dns/' /etc/proxychains4.conf \
 && sed -i 's/^socks4.*/#placeholder_socks5 127.0.0.1 9050/' /etc/proxychains4.conf

# 3) Add aliases for proxychains4
RUN echo "\
alias curl='curl --socks5-hostname tor:9050'\n\
alias pubip='curl --socks5-hostname tor:9050 https://ifconfig.io/country_code'\n\
alias checktor='curl -s https://check.torproject.org | grep -q "Congratulations" && echo "Congrats! You are using TOR!" || echo "Cannot detect TOR. Check the configuration."'\n\
" >> /root/.zshrc

# 4) Copy entrypoint.sh to replace #placeholder_socks5 with the actual IP
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/zsh","-i"]
EOF

###############################################################################
# 3. ENTRYPOINT.SH (For AttackTools)
###############################################################################
cat << 'EOF' > entrypoint.sh
#!/bin/bash
# This script runs each time the AttackTools container starts.
# It takes the environment variable $TOR_IP and updates /etc/proxychains4.conf to use:
# socks5 $TOR_IP 9050

if [ -z "$TOR_IP" ]; then
  echo "[!] Variable TOR_IP is not defined; use -e TOR_IP=\$(docker inspect ...)"
else
  echo "[+] Configuring /etc/proxychains4.conf with socks5 $TOR_IP 9050 ..."
  sed -i "s|^#placeholder_socks5 127.0.0.1 9050|socks5 $TOR_IP 9050|" /etc/proxychains4.conf
fi

# Execute the original command (CMD)
exec "$@"
EOF

###############################################################################
# 4. BUILD IMAGES
###############################################################################
echo "[+] Building Tor image..."
docker build -f Dockerfile.tor -t mytor .

echo "[+] Building AttackTools image (Kali + ProxyChains)..."
docker build -f Dockerfile.attacktools -t attacktools .

###############################################################################
# 5. CREATE NETWORK
###############################################################################
NETWORK_NAME="tor_network"

if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "[+] Creating Docker network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME"
else
    echo "[+] Network $NETWORK_NAME already exists."
fi

###############################################################################
# 6. START TOR CONTAINER
###############################################################################
if ! docker ps --format '{{.Names}}' | grep -q '^tor$'; then
    echo "[+] Starting Tor container..."
    docker run -d --rm --name tor \
      --network "$NETWORK_NAME" \
      -p 9050:9050 \
      mytor
else
    echo "[+] Tor container is already running."
fi

echo "[+] Waiting 10s for Tor to start..."
sleep 10

###############################################################################
# 7. GET TOR CONTAINER IP
###############################################################################
TOR_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' tor)
echo "[+] Internal IP of the Tor container: $TOR_IP"

###############################################################################
# 8. START ATTACKTOOLS CONTAINER
###############################################################################
if ! docker ps --format '{{.Names}}' | grep -q '^attacktools$'; then
    echo "[+] Starting 'attacktools' container with -e TOR_IP=$TOR_IP ..."
    docker run -dit --rm --name attacktools \
      --network "$NETWORK_NAME" \
      --cap-add=NET_RAW \
      --cap-add=NET_ADMIN \
      -e TOR_IP=$TOR_IP \
      attacktools
else
    echo "[+] AttackTools container is already running."
fi

echo "[+] Connecting to the attacktools container..."
docker attach attacktools
