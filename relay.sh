#!/bin/sh
set -eu
REPO="0xSyStEm75928/cardano-loans-cli"
WORKFLOW="build-cli.yml"
REF="main"
case "${1:-status}" in
  status)
    printf '%s\n' '{"JSSH":"--ZER","RELAY":"cardano-loans","CHAIN":"CARDANO","STATUS":"READY"}'
    ;;
  dispatch)
    if [ -z "${GITHUB_TOKEN:-}" ]; then
      printf '%s\n' '{"JSSH":"--ZER","RELAY":"cardano-loans","ERROR":"GITHUB_TOKEN_NOT_SET"}'
      exit 1
    fi
    curl -fsS -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches" \
      -d '{"ref":"main"}'
    printf '%s\n' '{"JSSH":"--ZER","RELAY":"cardano-loans","CHAIN":"CARDANO","ACTION":"DISPATCH","STATUS":"SENT"}'
    ;;
  *)
    printf '%s\n' '{"JSSH":"--ZER","ERROR":"UNKNOWN_COMMAND"}'
    exit 1
    ;;
esac
