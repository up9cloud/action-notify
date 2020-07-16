#!/bin/sh
set -e

function log() {
	if [ "$VERBOSE" == "true" ]; then
		echo [action-notify] "$@"
	fi
}
function die() {
	echo [action-notify] "$@" 1>&2
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
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
	cmd=$(printf '%s | tg -v -p md' "$base_cmd")
	eval "$cmd"
fi
