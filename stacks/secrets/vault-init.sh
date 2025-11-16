#!/bin/bash
# AIOS Supercell - Vault Initialization and Unsealing Script

set -e

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
INIT_FILE="/vault/file/.vault-init.json"
UNSEAL_KEYS_FILE="/mnt/c/aios-supercell/config/vault-unseal-keys.json"
ROOT_TOKEN_FILE="/mnt/c/aios-supercell/config/vault-root-token.txt"

echo "=== AIOS Vault Initialization ==="
echo "Vault Address: $VAULT_ADDR"

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until curl -s $VAULT_ADDR/v1/sys/health > /dev/null 2>&1; do
    echo "  Waiting..."
    sleep 2
done
echo "✓ Vault is ready"

# Check if Vault is already initialized
INIT_STATUS=$(curl -s $VAULT_ADDR/v1/sys/init | jq -r '.initialized')

if [ "$INIT_STATUS" = "false" ]; then
    echo "Initializing Vault..."
    
    # Initialize Vault with 5 key shares, 3 required to unseal
    INIT_RESPONSE=$(curl -s -X PUT -d '{"secret_shares": 5, "secret_threshold": 3}' $VAULT_ADDR/v1/sys/init)
    
    # Save initialization response
    echo "$INIT_RESPONSE" > "$INIT_FILE"
    echo "$INIT_RESPONSE" | jq '.' > "$UNSEAL_KEYS_FILE"
    
    # Extract root token
    ROOT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r '.root_token')
    echo "$ROOT_TOKEN" > "$ROOT_TOKEN_FILE"
    
    echo "✓ Vault initialized"
    echo "⚠️  IMPORTANT: Unseal keys saved to: $UNSEAL_KEYS_FILE"
    echo "⚠️  IMPORTANT: Root token saved to: $ROOT_TOKEN_FILE"
    echo "⚠️  SECURE THESE FILES IMMEDIATELY!"
    
    # Extract unseal keys
    UNSEAL_KEY_1=$(echo "$INIT_RESPONSE" | jq -r '.keys[0]')
    UNSEAL_KEY_2=$(echo "$INIT_RESPONSE" | jq -r '.keys[1]')
    UNSEAL_KEY_3=$(echo "$INIT_RESPONSE" | jq -r '.keys[2]')
    
else
    echo "✓ Vault already initialized"
    
    # Load unseal keys from file
    if [ -f "$UNSEAL_KEYS_FILE" ]; then
        UNSEAL_KEY_1=$(jq -r '.keys[0]' "$UNSEAL_KEYS_FILE")
        UNSEAL_KEY_2=$(jq -r '.keys[1]' "$UNSEAL_KEYS_FILE")
        UNSEAL_KEY_3=$(jq -r '.keys[2]' "$UNSEAL_KEYS_FILE")
        ROOT_TOKEN=$(cat "$ROOT_TOKEN_FILE" 2>/dev/null || echo "")
    else
        echo "✗ Unseal keys file not found: $UNSEAL_KEYS_FILE"
        exit 1
    fi
fi

# Check seal status
SEALED=$(curl -s $VAULT_ADDR/v1/sys/seal-status | jq -r '.sealed')

if [ "$SEALED" = "true" ]; then
    echo "Unsealing Vault..."
    
    # Unseal with 3 keys
    curl -s -X PUT -d "{\"key\": \"$UNSEAL_KEY_1\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
    echo "  Key 1/3 applied"
    
    curl -s -X PUT -d "{\"key\": \"$UNSEAL_KEY_2\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
    echo "  Key 2/3 applied"
    
    curl -s -X PUT -d "{\"key\": \"$UNSEAL_KEY_3\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
    echo "  Key 3/3 applied"
    
    echo "✓ Vault unsealed"
else
    echo "✓ Vault already unsealed"
fi

# Configure Vault if root token available
if [ -n "$ROOT_TOKEN" ]; then
    export VAULT_TOKEN="$ROOT_TOKEN"
    
    echo "Configuring Vault..."
    
    # Enable AppRole auth method
    echo "Enabling AppRole authentication..."
    curl -s -X POST -H "X-Vault-Token: $ROOT_TOKEN" \
        -d '{"type": "approle"}' \
        $VAULT_ADDR/v1/sys/auth/approle > /dev/null || true
    
    # Enable KV v2 secrets engine
    echo "Enabling KV v2 secrets engine..."
    curl -s -X POST -H "X-Vault-Token: $ROOT_TOKEN" \
        -d '{"type": "kv-v2"}' \
        $VAULT_ADDR/v1/sys/mounts/secret > /dev/null || true
    
    # Create AIOS policy
    echo "Creating AIOS policy..."
    POLICY_JSON='{
      "policy": "path \"secret/data/aios/*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"] } path \"secret/metadata/aios/*\" { capabilities = [\"list\", \"read\", \"delete\"] }"
    }'
    curl -s -X PUT -H "X-Vault-Token: $ROOT_TOKEN" \
        -d "$POLICY_JSON" \
        $VAULT_ADDR/v1/sys/policies/acl/aios-policy > /dev/null
    
    echo "✓ Vault configured"
fi

echo ""
echo "=== Vault Status ==="
curl -s $VAULT_ADDR/v1/sys/health | jq '.'

echo ""
echo "Access Vault UI at: https://vault.lan or http://localhost:8200"
echo "Root token: $(cat $ROOT_TOKEN_FILE 2>/dev/null || echo 'See $ROOT_TOKEN_FILE')"
