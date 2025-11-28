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
