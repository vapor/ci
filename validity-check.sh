#!/usr/bin/env bash

set -e
set -x

function fail() {
    local fmt="$1"; shift
    printf "${fmt}\n" "$@"
    exit 1
}

PR_ENVS_FILE="./pr-environments.json"
[[ -r "${PR_ENVS_FILE}" ]] || fail "PR environments file missing (expected at '%s')!" "${PR_ENVS_FILE}"
jq '.' "${PR_ENVS_FILE}" >/dev/null || fail "PR environments file ('%s') is invalid JSON!" "${PR_ENVS_FILE}"
# TODO: Validate better

XCODE_ACT_FILE="./setup-xcode-action.txt"
[[ -r "${XCODE_ACT_FILE}" ]] || fail "setup-xcode action file missing (expected at '%s')!" "${XCODE_ACT_FILE}"
xcode_act="$(cat "${XCODE_ACT_FILE}")"
act_repo="${xcode_act%%@*}"
act_ver="${xcode_act##*@}"
[[ -n "${act_repo}" ]] || fail "setup-xcode action must specify a repo!"
[[ -n "${act_ver}" ]] || fail "setup-xcode action must specify a version!"
curl -fsSL -o /dev/null "https://github.com/${act_repo}/tree/${act_ver}" || fail "setup-xcode action '%s' can't be found!" "${xcode_act}"
