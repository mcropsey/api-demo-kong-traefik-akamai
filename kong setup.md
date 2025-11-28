# BURP SUITE CORS DEMO – START TO FINISH

---

## **Part A – Kong Configuration (DB-less Mode)**

### 1. Create Kong configuration directory
```bash
sudo mkdir -p /etc/kong
```

### 2. Create `/etc/kong/kong.yaml`

_format_version: "3.0"
_transform: true

services:
  - name: juice-service
    url: http://192.168.1.98:3000
    routes:
      - name: juice-route
        hosts:
          - juicep.cropseyit.com
        paths:
          - /
        strip_path: false

plugins:
  - name: rate-limiting
    service: juice-service
    config:
      minute: 60

  - name: bot-detection
    service: juice-service

  - name: cors
    service: juice-service
    config:
      origins:
        - https://juicep.cropseyit.com

  - name: request-size-limiting
    service: juice-service
    config:
      allowed_payload_size: 2


### 3. Create `/etc/kong/kong.conf`
```conf
database = off
declarative_config = /etc/kong/kong.yaml
proxy_listen = 0.0.0.0:8000
admin_listen = off
log_level = notice
proxy_access_log = /dev/stdout
proxy_error_log = /dev/stderr
```

### 4. Restart Kong (using Podman)
```bash
sudo podman stop kong || true
sudo podman rm kong || true
sudo podman run -d \
  --name kong \
  --restart=always \
  -p 8000:8000 \
  -v /etc/kong:/etc/kong:Z \
  docker.io/kong/kong:3.7
```

### 5. Basic connectivity test
```bash
curl -H "Host: juicep.cropseyit.com" http://127.0.0.1:8000/rest/user/whoami
```

---

## **Part B – Burp Suite Demo Flow**

### **Goal:**
Demonstrate **OWASP API8:2023 – Security Misconfiguration**

| Endpoint | Protection |
|--------|------------|
| `https://juice.cropseyit.com` | **Unprotected** (Vulnerable CORS) |
| `https://juicep.cropseyit.com` | **Protected** (via Kong) |

---

## **Part C – Burp Suite Steps**

### 1. Open Burp → Repeater

---

### 2. **Test the Vulnerable API** *(Unprotected)*
```http
GET /rest/user/whoami HTTP/1.1
Host: juice.cropseyit.com
Origin: https://evil.com
User-Agent: Mozilla/5.0
Accept: */*
Connection: close
```

**Response Highlights:**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
```
→ **User data returned in body**

> **Talking Point:**  
> _“This API allows **any origin**, including `evil.com`. Classic OWASP API8 misconfiguration.”_

---

### 3. **Test the Protected API** *(Kong-Protected)*
Duplicate request → **Change only Host**:
```http
GET /rest/user/whoami HTTP/1.1
Host: juicep.cropseyit.com
Origin: https://evil.com
User-Agent: Mozilla/5.0
Accept: */*
Connection: close
```

**Response:**
- **No** `Access-Control-Allow-Origin: https://evil.com`  
- CORS request **blocked by Kong**

> **Talking Point:**  
> _“Kong enforces **strict CORS**, allowing only `juicep.cropseyit.com`. Malicious origins are blocked.”_

---

### 4. **Optional – Legitimate Origin Test**
Update `Origin`:
```http
Origin: https://juicep.cropseyit.com
```

**Response:**
- `Access-Control-Allow-Origin: https://juicep.cropseyit.com`  
- `Access-Control-Allow-Credentials: true`  
- Request **succeeds**

---
## TEST SCRIPT ##
mcropsey@hv-rocky-linux-1:~$ cat kong-compare.sh 
#!/bin/bash

VULN="https://juice.cropseyit.com"
PROT="https://juicep.cropseyit.com"

green() { echo -e "\e[32m$1\e[0m"; }
red()   { echo -e "\e[31m$1\e[0m"; }
blue()  { echo -e "\e[34m$1\e[0m"; }

line()  { echo "------------------------------------------------------------"; }

echo "============================================================"
echo "     KONG SIDE-BY-SIDE SECURITY COMPARISON"
echo "============================================================"
echo "Vulnerable: $VULN"
echo "Protected : $PROT"
echo "============================================================"
echo


#############################
# 1. CORS — Allowed Origin
#############################
blue "[1] CORS Allowed Origin Test"

V_CORS_ALLOW=$(curl -sI -H "Origin: $VULN" $VULN | grep -i "^access-control-allow-origin")
P_CORS_ALLOW=$(curl -sI -H "Origin: $PROT" $PROT | grep -i "^access-control-allow-origin")

echo "Vulnerable: $V_CORS_ALLOW"
echo "Protected : $P_CORS_ALLOW"

[[ "$V_CORS_ALLOW" == *"*"* ]] \
    && red   "Vulnerable site: WILDCARD (BAD)" \
    || green "Vulnerable site: Restricted (UNEXPECTED)"

[[ "$P_CORS_ALLOW" == *"$PROT"* ]] \
    && green "Protected site: Correct origin (GOOD)" \
    || red   "Protected site: CORS NOT configured (BAD)"

line
echo


#############################
# 2. CORS — Malicious Origin
#############################
blue "[2] CORS Malicious Origin Test"

V_CORS_EVIL=$(curl -sI -H "Origin: https://evil.com" $VULN | grep -i "^access-control-allow-origin")
P_CORS_EVIL=$(curl -sI -H "Origin: https://evil.com" $PROT | grep -i "^access-control-allow-origin")

echo "Vulnerable: $V_CORS_EVIL"
echo "Protected : $P_CORS_EVIL"

[[ "$V_CORS_EVIL" == *"*"* ]] \
    && red   "Vulnerable site ACCEPTS evil origin (VERY BAD)" \
    || green "Vulnerable site REJECTS evil origin (unexpected)"

[[ "$P_CORS_EVIL" == *"evil.com"* ]] \
    && red   "Protected site incorrectly allows evil.com (BAD)" \
    || green "Protected site rejects evil.com (GOOD)"

line
echo


#############################
# 3. Rate Limiting
#############################
blue "[3] Rate Limiting Test (60/min expected on protected site)"

V_RL=$(curl -sI $VULN | grep -i "^ratelimit-remaining")
P_RL1=$(curl -sI $PROT | grep -i "^ratelimit-remaining" | awk '{print $2}' | tr -d '\r')
P_RL2=$(curl -sI $PROT | grep -i "^ratelename=" | awk '{print $2}' | tr -d '\r')

echo "Vulnerable site headers:"
echo "$V_RL"
echo
echo "Protected remaining #1: $P_RL1"
echo "Protected remaining #2: $P_RL2"

if [[ -z "$V_RL" ]]; then
    red "Vulnerable: NO rate limiting"
else
    green "Vulnerable: Unexpected rate limit headers found"
fi

if [[ "$P_RL2" -lt "$P_RL1" ]]; then
    green "Protected: Rate limiting is working"
else
    red "Protected: Rate limiting NOT decreasing"
fi

line
echo


#############################
# 4. Bot Detection
#############################
blue "[4] Bot Detection Test"

V_BOT=$(curl -sI -A "BadScraperBot/1.0" $VULN | head -n 1)
P_BOT=$(curl -sI -A "BadScraperBot/1.0" $PROT | head -n 1)

echo "Vulnerable: $V_BOT"
echo "Protected : $P_BOT"

[[ "$V_BOT" == *"403"* ]] \
    && green "Vulnerable: Bot detection active (unexpected)" \
    || red   "Vulnerable: No bot detection (expected)"

[[ "$P_BOT" == *"403"* ]] \
    && green "Protected: Bot blocked (GOOD)" \
    || red   "Protected: Bot NOT blocked (BAD)"

line
echo

#######################################################################
# 5. Mass Assignment Test — Create Admin via Registration
#######################################################################
blue "[5] Mass Assignment Test — Attempt Admin Creation via Registration"

EMAIL="evil$(date +%s)@juice.sh"
PASSWORD="Test123!"

# ⭐ The ONLY addition — randomize 999
RANDOM_ID=$((RANDOM % 900 + 100))

PAYLOAD=$(cat <<EOF
{
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "role": "admin",
  "isAdmin": true,
  "id": $RANDOM_ID
}
EOF
)

############################################
# 1. Register user on vulnerable instance
############################################
V_REG=$(curl -sk -X POST "$VULN/api/Users/" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

############################################
# 2. Register user on protected instance
############################################
P_REG=$(curl -sk -X POST "$PROT/api/Users/" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "Using randomized ID: $RANDOM_ID"
echo
echo "Vulnerable registration response: $V_REG"
echo "Protected  registration response: $P_REG"
echo

############################################
# 3. Check if mass assignment succeeded
############################################
if echo "$V_REG" | grep -qi "admin"; then
    red "Vulnerable: MASS ASSIGNMENT SUCCESS — NEW ADMIN ACCOUNT CREATED!"
else
    green "Vulnerable: Mass assignment blocked (unexpected)"
fi

if echo "$P_REG" | grep -qi "admin"; then
    red "Protected: Mass assignment NOT blocked (BAD)"
else
    green "Protected: Mass assignment blocked (GOOD)"
fi

line
echo

## **Demo Summary**

| Scenario | Behavior |
|--------|----------|
| **Unprotected** (`juice.cropseyit.com`) | Allows **any origin** → Data leakage risk |
| **Kong-Protected** (`juicep.cropseyit.com`) | **Restricts origins** to official UI domain |

> **This fixes OWASP API8:2023 – Security Misconfiguration**  
> Proper CORS policy enforcement prevents unauthorized cross-origin access.