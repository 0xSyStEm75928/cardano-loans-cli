# Cardano Loans CLI - Standalone

A completely generic, standalone command-line application for Cardano loan requests. No proprietary architecture, no external runtime dependencies beyond standard Cardano tools.

## Requirements

### System Dependencies
- **Linux/Unix** (tested on Ubuntu 20.04+, 24.04)
- **GHC 9.6.5+** (Haskell compiler)
- **Cabal 3.12+** (Haskell package manager)
- **cardano-cli 8.0+** (Cardano command-line tool)
- **curl** (for HTTP requests)

### Cardano Network Requirements
- Access to a **Cardano node** (testnet or mainnet)
- or **Blockfrost API** endpoint (optional, for status queries)

### Build Dependencies
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  libgmp-dev \
  libffi-dev \
  zlib1g-dev \
  pkg-config \
  libblst-dev
```

## Installation

### 1. Clone Repository
```bash
git clone https://github.com/0xSyStEm75928/cardano-loans-cli.git
cd cardano-loans-cli
```

### 2. Build
```bash
cabal clean
cabal update
cabal build exe:cardano-loans
```

### 3. Install Binary
```bash
BIN="$(cabal list-bin exe:cardano-loans)"
sudo cp "$BIN" /usr/local/bin/cardano-loans
chmod +x /usr/local/bin/cardano-loans
```

## Usage

### Commands

#### 1. Show Status
```bash
cardano-loans status
```

Output:
```json
{
  "command": "status",
  "status": "ready",
  "version": "1.0.0"
}
```

#### 2. Build Loan Request
```bash
cardano-loans build \
  --principal 10000000 \
  --term 180 \
  --collateral "" \
  --config loan-config.json
```

Output:
```json
{
  "command": "build",
  "phase": "BUILD",
  "status": "success",
  "transaction": {
    "txBody": "...",
    "txHash": "...",
    "fee": "170141"
  }
}
```

#### 3. Sign Transaction
```bash
cardano-loans sign \
  --tx-file tx.signed \
  --skey-file payment.skey \
  --config loan-config.json
```

Output:
```json
{
  "command": "sign",
  "phase": "SIGN",
  "status": "success",
  "signed_tx": "..."
}
```

#### 4. Submit Transaction
```bash
cardano-loans submit \
  --tx-file tx.signed \
  --config loan-config.json
```

Output:
```json
{
  "command": "submit",
  "phase": "SUBMIT",
  "status": "success",
  "txid": "abcd1234...",
  "network": "testnet"
}
```

#### 5. Check Status
```bash
cardano-loans confirm \
  --txid abcd1234... \
  --config loan-config.json
```

Output:
```json
{
  "command": "confirm",
  "phase": "CONFIRMED",
  "status": "confirmed",
  "txid": "abcd1234...",
  "block": "12345",
  "timestamp": "2026-09-05T10:30:00Z"
}
```

## Configuration

### loan-config.json
```json
{
  "network": "testnet",
  "cardano_node_socket": "/tmp/node.socket",
  "cardano_network_id": 0,
  "blockfrost_api_key": "optional-api-key",
  "blockfrost_endpoint": "https://cardano-testnet.blockfrost.io/api/v0",
  "loan_asset": "lovelace",
  "protocol_params": {
    "utxo_cost_per_word": 4310,
    "min_fee_a": 44,
    "min_fee_b": 155381
  }
}
```

### Loan Request (loan-request.json)
```json
{
  "principal": 10000000,
  "term_days": 180,
  "collateral": [],
  "borrower_address": "addr_test1...",
  "lender_address": "addr_test1...",
  "interest_rate": 5.0
}
```

## Architecture

### Phases

```
BUILD
  ↓
SIGN
  ↓
SUBMIT
  ↓
CONFIRMED
```

### Build (BUILD Phase)
- Constructs transaction from loan parameters
- Uses cardano-cli for UTXO queries
- Calculates fees
- Returns unsigned transaction body

### Sign (SIGN Phase)
- Takes unsigned transaction + signer's private key
- Uses cardano-cli to sign
- Returns signed transaction

### Submit (SUBMIT Phase)
- Submits signed transaction to Cardano network
- Returns **real transaction ID only after network acceptance**
- Requires live Cardano node or API access

### Confirm (CONFIRMED Phase)
- Queries transaction status
- Returns block height and timestamp when confirmed
- Only reports success after block confirmation

## Environment Variables

```bash
# Cardano Node Configuration
export CARDANO_NODE_SOCKET_PATH="/tmp/node.socket"
export CARDANO_NETWORK_ID=0  # 0=testnet, 1=mainnet

# Blockfrost (optional)
export BLOCKFROST_API_KEY="your-api-key"

# Signing
export SIGNER_SKEY_FILE="/path/to/payment.skey"
```

## Output Format

All commands return **machine-readable JSON** to stdout:

```json
{
  "command": "...",
  "phase": "...",
  "status": "success|error",
  "data": { ... },
  "error": "..." (if status=error)
}
```

Errors go to stderr. Exit codes:
- `0` = success
- `1` = error

## Transaction ID Policy

⚠️ **IMPORTANT**: A transaction ID is returned ONLY when:
1. Transaction is signed and valid
2. Transaction is submitted to the Cardano network
3. Network accepts the transaction

If any step fails, no transaction ID is returned.

## Example: Complete Loan Flow

```bash
#!/bin/bash
set -eu

# 1. Build
BUILD_OUT=$(cardano-loans build \
  --principal 10000000 \
  --term 180 \
  --config loan-config.json)
TX_BODY=$(echo "$BUILD_OUT" | jq -r '.transaction.txBody')

# 2. Sign
SIGN_OUT=$(cardano-loans sign \
  --tx-file "$TX_BODY" \
  --skey-file payment.skey \
  --config loan-config.json)
SIGNED_TX=$(echo "$SIGN_OUT" | jq -r '.signed_tx')

# 3. Submit
SUBMIT_OUT=$(cardano-loans submit \
  --tx-file "$SIGNED_TX" \
  --config loan-config.json)
TXID=$(echo "$SUBMIT_OUT" | jq -r '.txid')

echo "Loan request submitted: $TXID"

# 4. Confirm
sleep 30  # Wait for block confirmation
CONFIRM_OUT=$(cardano-loans confirm \
  --txid "$TXID" \
  --config loan-config.json)
STATUS=$(echo "$CONFIRM_OUT" | jq -r '.status')

echo "Status: $STATUS"
```

## Limitations & Notes

1. **No Proprietary Runtime**: Uses only standard Cardano ecosystem tools
2. **No Mock Transactions**: All transactions must be real Cardano transactions
3. **No Secret Embedding**: Private keys are never embedded or stored in the application
4. **Network Dependent**: Submit/Confirm phases require network access
5. **Cardano CLI Dependency**: Relies on `cardano-cli` for transaction construction
6. **Standalone**: Can be installed on any Linux system without external project knowledge

## Dependencies

Core Haskell libraries:
- `base` - Standard Haskell library
- `aeson` - JSON serialization
- `bytestring` - Efficient string handling
- `process` - Execute external commands (cardano-cli)
- `cryptonite` - Cryptographic primitives
- `text` - Unicode text handling
- `optparse-applicative` - CLI argument parsing

See `cardano-loans.cabal` for full dependency list.

## Development

### Run Tests
```bash
cabal test
```

### Build Documentation
```bash
cabal haddock
```

## Support & Issues

For issues:
1. Check this README
2. Verify cardano-cli is installed: `cardano-cli --version`
3. Verify network access: `curl -s https://cardano-testnet.blockfrost.io/ | head`
4. Report with full JSON output and error logs

## License

Apache License 2.0 - See LICENSE.md

## Disclaimer

This tool handles real Cardano transactions. Use on **testnet** first. The authors are not responsible for transaction loss or misconfiguration.
