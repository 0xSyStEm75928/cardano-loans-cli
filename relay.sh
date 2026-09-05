#!/bin/sh
set -eu

# Cardano Loans Relay - Phase 2
# ZER → 中継 → GitHub Actions (実装版)

# GitHub API 設定
GITHUB_OWNER="0xSyStEm75928"
GITHUB_REPO="cardano-loans-cli"
GITHUB_WORKFLOW="build-cardano-loans-cli"

# トークン（環境変数から取得）
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

show_usage() {
  cat << 'USAGE'
cardano-loans-relay - Cardano Loans CLI中継層

使用方法:
  ./relay.sh [コマンド] [オプション]

コマンド:
  status      現在の設定を表示
  dispatch    GitHub Actionsをトリガー
  help        このヘルプを表示

環境変数:
  GITHUB_TOKEN    GitHub Personal Access Token (必須)

例:
  export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
  ./relay.sh dispatch
USAGE
}

show_status() {
  cat << 'JSON'
{
  "JSSH": "--ZER",
  "CHAIN": "CARDANO",
  "RELAY": "cardano-loans",
  "LOAN_ASSET": "lovelace",
  "PRINCIPAL": 10000,
  "TERM": "180 days",
  "COLLATERAL": [],
  "TARGET": "linux-x86_64",
  "MODE": "RELAY",
  "STATUS": "ready",
  "GITHUB_OWNER": "0xSyStEm75928",
  "GITHUB_REPO": "cardano-loans-cli",
  "GITHUB_WORKFLOW": "build-cardano-loans-cli"
}
JSON
}

dispatch_workflow() {
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "エラー: GITHUB_TOKEN が設定されていません" >&2
    echo "実行方法:" >&2
    echo "  export GITHUB_TOKEN=\"ghp_xxxxxxxxxxxxxxxxxxxx\"" >&2
    echo "  ./relay.sh dispatch" >&2
    exit 1
  fi

  echo "=== GitHub Actions Dispatch ===" >&2
  echo "リポジトリ: $GITHUB_OWNER/$GITHUB_REPO" >&2
  echo "ワークフロー: $GITHUB_WORKFLOW" >&2
  echo "" >&2

  # GitHub API へリクエスト
  RESPONSE=$(curl -s -X POST \
    "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/workflows/$GITHUB_WORKFLOW/dispatches" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -d '{"ref":"main"}' \
    -w "\n%{http_code}")

  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
  BODY=$(echo "$RESPONSE" | head -n -1)

  if [ "$HTTP_CODE" = "204" ]; then
    echo "✓ GitHub Actions がトリガーされました" >&2
    echo "" >&2
    echo "現在の設定:" >&2
    show_status >&2
    echo "" >&2
    echo "ビルド状態確認: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions" >&2
    echo "✓ 成功"
  else
    echo "✗ エラー (HTTP $HTTP_CODE)" >&2
    echo "レスポンス: $BODY" >&2
    exit 1
  fi
}

case "${1:-help}" in
  status)
    show_status
    ;;
  dispatch)
    dispatch_workflow
    ;;
  help|*)
    show_usage
    ;;
esac
