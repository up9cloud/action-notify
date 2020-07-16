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
if [ -f "$GITHUB_EVENT_PATH" ]; then
	export GIT_HEAD_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.message || printf '')
	export GIT_HEAD_COMMITER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.commiter.username || printf '')
	export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].message || printf '')
	export GIT_COMMITER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].commiter.username || printf '')
fi

if [ -n "$CUSTOM_SCRIPT" ]; then
	eval "$CUSTOM_SCRIPT"
	exit 0
fi

base_cmd=$(printf 'cat %s | envsubst' "$TEMPLATE_PATH")
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
	cmd=$(printf '%s | tg -q' "$base_cmd")
	eval "$cmd"
fi
