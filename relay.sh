#!/bin/sh
set -eu

# Cardano Loans Relay - 最小版
# ZER → 中継 → GitHub Actions

show_usage() {
  cat << 'USAGE'
cardano-loans-relay - Cardano Loans CLI中継層

使用方法:
  ./relay.sh [コマンド] [オプション]

コマンド:
  status      現在の設定を表示
  dispatch    GitHub Actionsをトリガー
  help        このヘルプを表示

例:
  ./relay.sh status
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
  "STATUS": "ready"
}
JSON
}

dispatch_workflow() {
  echo "=== GitHub Actions Dispatch ===" >&2
  echo "中継が受け取ったリクエスト:" >&2
  show_status >&2
  echo "" >&2
  echo "✓ GitHub Actionsへの接続準備完了" >&2
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
