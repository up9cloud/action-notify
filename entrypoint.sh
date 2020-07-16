#!/bin/sh
set -e

function log() {
	if [ "$VERBOSE" == "true" ]; then
		printf '[action-notify] %s\n' "$@"
	fi
}
function die() {
	printf '[action-notify] %s\n' "$@" 1>&2
	exit 1
}

if [ -z "$TEMPLATE" ]; then
	TEMPLATE=default
fi
if [ -z "$TEMPLATE_PATH" ]; then
	TEMPLATE_PATH="/template/${TEMPLATE}.txt"
fi

if [ -n "$CUSTOM_SCRIPT" ]; then
	eval "$CUSTOM_SCRIPT"
	exit 0
fi

base_cmd=$(printf 'cat %s | envsubst' "$TEMPLATE_PATH")
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CAHT_ID" ]; then
	cmd=$(printf '%s | tg -q -p code' "$base_cmd")
	eval "$cmd"
fi
