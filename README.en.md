# 🧅 ft_onion - Tor HTTP Hidden Service

> Tor Hidden Service with HTTP web server and SSH access

**[🇫🇷 Version française](./README.md)**

## 📚 Table of Contents

- [Description](#-description)
- [Prerequisites](#-prerequisites)
- [Step-by-Step Installation](#-step-by-step-installation)
- [Usage](#-usage)
- [Advanced Configuration](#-advanced-configuration)
- [Service Access](#-service-access)
- [Available Commands](#-available-commands)
- [Troubleshooting](#-troubleshooting)
- [Security](#-security)

---

## 📖 Description

This project creates a complete **Tor Hidden Service** with:
- 🌐 **nginx** web server (HTTP port 80)
- 🔐 **SSH** server (port 4242)
- 🧅 Anonymization via **Tor**
- 🐳 Everything containerized with **Docker**

### Architecture

```
Internet (Tor) → Hidden Service .onion → Docker Container
                                         ├── nginx (web HTTP:80)
                                         ├── SSH (4242)
                                         └── Tor daemon
```

---

## ✅ Prerequisites

Before starting, make sure you have:

### Required Software

- **Docker** installed and running
  ```bash
  docker --version  # Should display a version
  ```

- **Make** installed
  ```bash
  make --version    # Should display a version
  ```

- **OpenSSH** (to generate keys)
  ```bash
  ssh-keygen --help # Should display help
  ```

### Tor Browser (for testing)

- Download [Tor Browser](https://www.torproject.org/download/)

---

## 🚀 Step-by-Step Installation

### Step 1: Navigate to the project

```bash
cd 42-cybersecurity-ft_onion
```

### Step 2: Generate SSH keys

**Important:** This step is **mandatory** before building!

```bash
make generate_key
```

**Expected output:**
```
✅ Key generated in ./ssh_key_folder/
⚠️  WARNING: Private key NOT protected by passphrase!
   Private key: ./ssh_key_folder/ft_onion_key
   Public key: ./ssh_key_folder/ft_onion_key.pub
```

**What does it do?**
- Creates an ED25519 SSH key pair
- Stores the public key in `./ssh_key_folder/ft_onion_key.pub`
- Stores the private key in `./ssh_key_folder/ft_onion_key`

### Step 3: 

#### Method 1: Simplest - installation, container launch, and automatic display of web and SSH addresses

```bash
make
```
You can directly proceed to [Usage](#usage)

#### Method 2: Build the Docker image

```bash
make build
```

**Duration:** ~2-5 minutes (depending on your connection)

**What does it do?**
- Downloads Ubuntu 22.04
- Installs nginx, tor, openssh-server, vim
- Configures all services
- Copies your SSH public key

**Expected output:**
```
Successfully tagged ft_onion:latest
```

### Step 4: Launch the container

```bash
make run
```

**Expected output:**
```
<container_id>
```

The container is now running in the background (detached mode `-d`).

### Step 5: Retrieve .onion addresses

#### For the website:

```bash
make addr
```

**Expected output:**
```
Address of website:
abc123def456ghi789jkl.onion
```

#### For SSH:

```bash
make addr_ssh
```

**Expected output:**
```
Address of ssh:
xyz789uvw456rst123def.onion
```

**💡 Note:** These addresses are **unique** and change with each new build.

---

## 🎯 Usage

### Access the website

1. **Open Tor Browser**
2. **Copy the .onion address** of the site (from `make addr`)
3. **Paste in Tor Browser:**
   ```
   http://your-address.onion
   ```

You should see a simple HTML page: "test"

### Connect via SSH

1. **Retrieve the SSH .onion address:**
   ```bash
   make addr_ssh
   ```

2. **Configure torify or ProxyCommand in ~/.ssh/config:**

   **Option A - With torify (simple):**
   ```bash
   torify ssh -i ./ssh_key_folder/ft_onion_key yourUsername@your-ssh-address.onion -p 4242
   ```

   **Option B - With ProxyCommand (recommended):**
   
   Add to `~/.ssh/config`:
   ```
   Host ft-onion
       HostName your-ssh-address.onion
       User yourUsername
       Port 4242
       IdentityFile /absolute/path/to/ssh_key_folder/ft_onion_key
       # port 9050 for tor without browser
       # ProxyCommand nc -X 5 -x 127.0.0.1:9050 %h %p
       # port 9150 for tor via tor browser
       ProxyCommand nc -xlocalhost:9150 %h %p
   ```

   Then connect:
   ```bash
   ssh ft-onion
   ```

3. **You're connected!**
   ```bash
   yourUsername@<container_id>:~$
   ```

### Explore the container

```bash
make bash
```

You get a root shell in the container:

```bash
root@<container_id>:/#
```

**Useful commands inside the container:**

```bash
# Check that nginx is running
curl http://localhost:80

# Check that Tor is running
pgrep tor

# View Tor logs
cat /var/log/tor/notices.log

# View nginx config
cat /etc/nginx/sites-available/default

# View SSH config
cat /etc/ssh/sshd_config
```

---

## ⚙️ Advanced Configuration

### Customize parameters

Create a `.env` file at the project root:

```bash
nano .env
```

**.env content:**
```env
SSH_USER=MyName
SSH_PORT=2222
WEB_PORT=8080
```

**Then rebuild:**
```bash
make re
```

### Available variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_USER` | Lachignol | SSH username |
| `SSH_PORT` | 4242 | Internal SSH port |
| `WEB_PORT` | 80 | Internal web port |

---

## 📋 Available Commands

### Main commands

```bash
# Build the Docker image
make build

# Launch the container
make run

# Build + Run + Display addresses
make all

# Display web .onion address
make addr

# Display SSH .onion address
make addr_ssh

# Shell access to container
make bash
```

### Cleanup commands

```bash
# Stop the container
make clean

# Remove container + image
make fclean

# Complete rebuild (fclean + build)
make re
```

### Generation commands

```bash
# Generate SSH keys (do this before build)
make generate_key
```

---

## 🔍 Troubleshooting

### Problem: "No such file or directory: ./public_key_folder/ft_onion_key.pub"

**Solution:**
```bash
make generate_key
```

You forgot to generate SSH keys before building.

---

### Problem: Container starts then immediately stops

**Diagnosis:**
```bash
docker logs ft_onion
```

**Possible solutions:**

1. **SSH didn't start:**
   ```
   ERROR: SSH didn't start
   ```
   → Check that the SSH key is valid

2. **Tor didn't start:**
   ```
   ERROR: Tor didn't start
   ```
   → Check permissions on `/var/lib/tor`

---

### Problem: "Connection refused" when connecting via SSH

**Checks:**

1. **Is the container running?**
   ```bash
   docker ps | grep ft_onion
   ```

2. **Is SSH listening on the right port?**
   ```bash
   make bash
   netstat -tlnp | grep sshd
   ```

3. **Are you using the correct .onion address?**
   ```bash
   make addr_ssh
   ```

4. **Is Tor Browser or Tor running locally?**
   ```bash
   # On macOS/Linux
   brew services list | grep tor
   # or
   systemctl status tor
   ```

---

### Problem: "Permission denied (publickey)"

**Solution:**

Check that you're using the correct private key:
```bash
ssh -i ./ssh_key_folder/ft_onion_key -v yourUsername@address.onion -p 4242
```

The `-v` option displays connection details.

---

### Problem: Website doesn't load in Tor Browser

**Checks:**

1. **Is the .onion address correct?**
   ```bash
   make addr
   ```

2. **Is nginx running in the container?**
   ```bash
   make bash
   curl http://localhost:80
   ```
   You should see the HTML.

3. **Is Tor Browser properly configured?**
   - Check that you're connected to the Tor network (green onion icon)

---

## 🔐 Security

### Implemented security features ✅

- ✅ **SSH authentication by key only** (no password)
- ✅ **SSH listens on 127.0.0.1** (no direct exposure)
- ✅ **Strict SSH file permissions** (700/600)
- ✅ **HTTP security headers** (X-Frame-Options, CSP, etc.)
- ✅ **SSH attempt limitation** (3 max)
- ✅ **SSH connection timeout** (30 seconds)
- ✅ **Disconnection after inactivity** (10 minutes)
- ✅ **Tor logs enabled** (debugging)
- ✅ **Tor bandwidth limitation** (anti-saturation)
- ✅ **Docker healthcheck** (monitoring)

### Recommendations

⚠️ **SSH key without passphrase**: The private key is not password-protected. Keep it secret!

⚠️ **Test environment**: This project is educational. For production, strengthen security.

---

## 📁 Project Structure

```
cybersecurity-ft_onion/
├── dockerfile                    # Docker configuration
├── entrypoint.sh                 # Service startup script
├── Makefile                      # Make commands
├── .gitignore                    # Files ignored by git
├── README.md                     # French version
├── README.en.md                  # This file
│
├── ssh_key_folder/            # SSH keys
│   ├── .gitkeep                  # (tracked)
│   ├── ft_onion_key              # Private key (generated, ignored)
│   └── ft_onion_key.pub          # Public key (generated, ignored)
│
├── html/                         # Static website
│   └── index.html
│
├── nginx.conf.template           # nginx template (dynamic port)
├── sshd_config.template          # SSH template (dynamic port)
├── torrc.template                # Tor template (dynamic ports)
│
└── ssh_config(...)               # Example SSH client config
```

---

## 🌐 How Tor Works

### How does it work?

1. **Tor generates a unique .onion address** during the first startup
2. **The Tor daemon** routes traffic through 3 random relays
3. **The .onion address** is stored in `/var/lib/tor/web/hostname`
4. **Visitors** connect via the Tor network
5. **Tor redirects** to nginx (port 80) or SSH (port 4242) locally

### Flow diagram

```
User
    ↓
Tor Browser
    ↓
Tor Network (3 relays)
    ↓
Your .onion address
    ↓
Docker Container
    ↓
nginx (HTTP:80) or SSH (4242)
```

---

## 🎓 Concepts Learned

By completing this project, you learn:

- 🐳 **Docker**: Application containerization
- 🧅 **Tor**: Hidden Services and anonymization
- 🌐 **nginx**: Web server configuration
- 🔐 **SSH**: Public key authentication
- 🛠️ **Make**: Task automation
- 📝 **Templates**: Dynamic substitution with sed
- 🔒 **Security**: SSH hardening, HTTP headers, permissions

---

## 📖 Resources

- [Tor Documentation](https://www.torproject.org/docs/)
- [nginx Documentation](https://nginx.org/en/docs/)
- [SSH Documentation](https://www.openssh.com/manual.html)
- [Docker Documentation](https://docs.docker.com/)

---

## ⚖️ License

Educational project - 42 School

---

**Author:** Lachignol
**Project:** ft_onion (HTTP version)  
**Date:** 2026
