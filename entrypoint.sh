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

if [ -f "$GITHUB_EVENT_PATH" ]; then
	export GIT_HEAD_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.message || printf '')
	export GIT_HEAD_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.committer.username || printf '')
	export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].message || printf '')
	export GIT_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].committer.username || printf '')
fi
if [ -z "$TEMPLATE" ]; then
	TEMPLATE=default
fi
if [ -z "$TELEGRAM_PARSE_MODE" ]; then
	TELEGRAM_PARSE_MODE=
fi

function set_default_telegram_template_path() {
	local ext=txt
	case "$TELEGRAM_PARSE_MODE" in
	html)
		ext=$TELEGRAM_PARSE_MODE
		;;
	md)
		ext=$TELEGRAM_PARSE_MODE
		;;
	esac
	TELEGRAM_TEMPLATE_PATH="/template/telegram/${TEMPLATE}.${ext}"
}
if [ -z "$TELEGRAM_TEMPLATE_PATH" ]; then
	set_default_telegram_template_path
fi

if [ -n "$CUSTOM_SCRIPT" ]; then
	eval "$CUSTOM_SCRIPT"
	exit 0
fi

function default_notify_telegram() {
	local arg_p=""
	if [ -n "$TELEGRAM_PARSE_MODE"]; then
		arg_p=" -p ${TELEGRAM_PARSE_MODE}"
	fi
	local cmd=$(printf 'cat %s | envsubst | tg -q%s' "$TELEGRAM_TEMPLATE_PATH" "$base_cmd" "$arg_p")
	eval "$cmd"
}
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
	default_notify_telegram
fi
