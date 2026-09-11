# ZER EVM CLI

Ethereum Loan Protocol Interface - EVM版Cardano Loans

## 概要

ZER EVM CLIは、Cardano LoansプロトコルをEthereum/EVM互換チェーンに移植したCLIツールです。

### 対応チェーン

- **Ethereum Mainnet** (Chain ID: 1)
- **Ethereum Sepolia** (Chain ID: 11155111)
- **Ethereum Holesky** (Chain ID: 17000)
- **Arbitrum One** (Chain ID: 42161)
- **Optimism** (Chain ID: 10)
- **Polygon** (Chain ID: 137)

## インストール

```bash
cd evm-cli
npm install
npm run compile
npm run build
```

## 使い方

### ローン操作

```bash
# Ask作成（借り手リクエスト）
npx tsx src/cli.ts loan create-ask \
  --asset 0x... \
  --principal 1000000000000000000 \
  --term 2592000 \
  --collateral 0x...

# Offer作成（貸手提案）
npx tsx src/cli.ts loan create-offer \
  --borrower 0x... \
  --asset 0x... \
  --principal 1000000000000000000 \
  --epoch 604800 \
  --term 2592000 \
  --interest-num 5 \
  --interest-den 100 \
  --min-payment 100000000000000000 \
  --penalty-type 1 \
  --penalty-value 50000000000000000 \
  --max-misses 3 \
  --claim-period 604800

# Offer承認
npx tsx src/cli.ts loan accept-offer <offerId>

# 支払い
npx tsx src/cli.ts loan make-payment <loanId> <amount>

# デフォルト時の担保取得
npx tsx src/cli.ts loan claim-collateral <loanId>

# 失われた担保の解除
npx tsx src/cli.ts loan unlock-collateral <loanId>

# 貸手アドレス更新
npx tsx src/cli.ts loan update-lender <loanId> <newAddress>
```

### クエリ操作

```bash
# ローン詳細取得
npx tsx src/cli.ts query loan <loanId>

# Ask詳細取得
npx tsx src/cli.ts query ask <askId>

# Offer詳細取得
npx tsx src/cli.ts query offer <offerId>

# ローン残高計算
npx tsx src/cli.ts query balance <loanId>
```

### ビーコン操作

```bash
# オーナーのトークン取得
npx tsx src/cli.ts beacon tokens <ownerAddress>
```

### 設定

```bash
# 設定表示
npx tsx src/cli.ts config show

# 設定変更
npx tsx src/cli.ts config set network sepolia
npx tsx src/cli.ts config set rpcUrl https://...
```

## 環境変数

`.env` ファイルに以下を設定:

```env
# ネットワーク
ZER_NETWORK=sepolia

# RPC
INFURA_API_KEY=your_infura_key
ALCHEMY_API_KEY=your_alchemy_key
MAINNET_RPC_URL=https://mainnet.infura.io/v3/...
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/...

# ウォレット
PRIVATE_KEY=your_private_key

# コントラクトアドレス
MAINNET_LOAN_ADDRESS=0x...
MAINNET_BEACON_ADDRESS=0x...
SEPOLIA_LOAN_ADDRESS=0x...
SEPOLIA_BEACON_ADDRESS=0x...

# Etherscan
ETHERSCAN_API_KEY=your_etherscan_key
```

## デプロイ

```bash
# ローカルホスト
npx hardhat run scripts/deploy.ts --network localhost

# Sepolia
npx hardhat run scripts/deploy.ts --network sepolia

# メインネット
npx hardhat run scripts/deploy.ts --network mainnet
```

## Cardano → EVM対応表

| Cardano | EVM |
|---------|-----|
| AskDatum | struct Ask |
| OfferDatum | struct Offer |
| ActiveDatum | struct ActiveLoan |
| PaymentDatum | struct Payment |
| LoanRedeemer | enum LoanAction |
| Beacon NFTs | ERC-721 (BeaconNFT) |
| Plutus Scripts | Solidity Contracts |
| UTxO model | Account model |

## ライセンス

JSSH-2026-0001
