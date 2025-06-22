#!/bin/sh
set -e

cmd="aria2c  --enable-rpc --dir=/aria2c/downloads"

# Booleans and flags, set if env variable exists and is non-empty
[ -n "${RPC_LISTEN_ALL:-}" ] && cmd="$cmd --rpc-listen-all=${RPC_LISTEN_ALL}"
[ -n "${RPC_ALLOW_ORIGIN_ALL:-}" ] && cmd="$cmd --rpc-allow-origin-all"
# [ -n "${DAEMON:-}" ] && cmd="$cmd --daemon=${DAEMON}"
[ -n "${DISABLE_IPV6:-}" ] && cmd="$cmd --disable-ipv6=${DISABLE_IPV6}"

# Options with values, set if env variable exists and is non-empty
[ -n "${RPC_USER:-}" ] && cmd="$cmd --rpc-user=${RPC_USER}"
[ -n "${RPC_SECRET:-}" ] && cmd="$cmd --rpc-secret=${RPC_SECRET}"
[ -n "${CONTINUE:-}" ] && cmd="$cmd --continue=${CONTINUE}"
[ -n "${RPC_MAX_REQUEST_SIZE:-}" ] && cmd="$cmd --rpc-max-request-size=${RPC_MAX_REQUEST_SIZE}"
[ -n "${MAX_CONCURRENT:-}" ] && cmd="$cmd --max-concurrent-downloads=${MAX_CONCURRENT}"
[ -n "${MAX_CONNECTION:-}" ] && cmd="$cmd --max-connection-per-server=${MAX_CONNECTION}"
[ -n "${RPC_SAVE_UPLOAD_METADATA:-}" ] && cmd="$cmd ----rpc-save-upload-metadata=${RPC_SAVE_UPLOAD_METADATA}"
[ -n "${SPLIT:-}" ] && cmd="$cmd --split=${SPLIT}"
[ -n "${MIN_SPLIT_SIZE:-}" ] && cmd="$cmd --min-split-size=${MIN_SPLIT_SIZE}"
[ -n "${SAVE_SESSION_INTERVAL:-}" ] && cmd="$cmd --save-session-interval=${SAVE_SESSION_INTERVAL}"
[ -n "${ALL_PROXY:-}" ] && cmd="$cmd --all-proxy=${ALL_PROXY}"

exec $cmd
