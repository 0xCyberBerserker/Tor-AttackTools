# AttackTools & Tor Proxy

## Overview
This project consists of two Docker containers:
1. **Tor Container**: Runs a Tor proxy to route traffic through the Tor network.
2. **AttackTools Container**: A Kali Linux environment with penetration testing tools configured to use the Tor network via ProxyChains.

## Features
- Tor proxy configured to allow SOCKS5 connections on port 9050.
- AttackTools container includes:
  - Nmap
  - ProxyChains4
  - Nikto
  - FFUF
  - Metasploit Framework
  - Ping utilities
  - Vim
- ProxyChains is configured to route traffic through the Tor container.
- Automated setup of Docker network and environment variables.

## Installation
### Prerequisites
Ensure you have **Docker** installed on your system.

### Build and Run Containers
1. Clone this repository:
   ```bash
   git clone https://github.com/0xCyberBerserker/Tor-AttackTools.git
   cd Tor-AttackTools
   ```

2. Build the Docker images:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   This script will:
   - Build the Tor and AttackTools images.
   - Create a Docker network.
   - Start the Tor container.
   - Retrieve the internal IP of the Tor container.
   - Start the AttackTools container with the correct Tor configuration.

## Usage
### Check if Tor is working
Run inside the AttackTools container:
```bash
checktor
```
If the output confirms that you are using Tor, everything is correctly set up.

### Running Nmap through Tor
Use `proxychains4` before Nmap commands:
```bash
proxychains4 nmap -sT -p- <target-ip>
```

### Retrieve Public IP (through Tor)
```bash
pubip
```

### Attach to the AttackTools Container
If you get disconnected, you can reattach using:
```bash
docker attach attacktools
```

## Stopping and Cleaning Up
To stop and remove the containers:
```bash
docker stop tor attacktools
```

To remove the network:
```bash
docker network rm tor_network
```

You can use my docker-armaggedon script too.


## Notes
- The `tor-attacktools.sh` script should be run every time you restart your system to ensure correct environment variables and configurations.
- Tor may take some time to start up; ensure it is running before using ProxyChains.

## Disclaimer
This project is for **educational and ethical hacking purposes only**. Unauthorized scanning or attacks on networks you do not own is illegal.

## License
MIT License. Feel free to use and modify but always follow ethical hacking guidelines.

