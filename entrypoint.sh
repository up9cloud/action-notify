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
	export GIT_HEAD_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_HEAD_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_HEAD_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.committer.username || printf '')
	export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].message || printf '')
	export GIT_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[0].committer.username || printf '')
fi
if [ -n "$GITHUB_SHA" ]; then
	export GITHUB_SHA_SHORT=$(echo "$GITHUB_SHA" | cut -c1-8)
fi
if [ -z "$TEMPLATE" ]; then
	TEMPLATE=default
fi
function set_job_status_color() {
	local color="#ffffff"
	case "$GITHUB_JOB_STATUS" in
	success)
		if [ -n "$GITHUB_JOB_SUCCESS_COLOR" ]; then
			color="$GITHUB_JOB_SUCCESS_COLOR"
		else
			color="#22863a"
		fi
		;;
	failure)
		if [ -n "$GITHUB_JOB_FAILURE_COLOR" ]; then
			color="$GITHUB_JOB_FAILURE_COLOR"
		else
			color="#cb2431"
		fi
		;;
	cancelled)
		if [ -n "$GITHUB_JOB_CANCELLED_COLOR" ]; then
			color="$GITHUB_JOB_CANCELLED_COLOR"
		else
			color="#6a737d"
		fi
		;;
	esac
	export GITHUB_JOB_STATUS_COLOR="$color"
}
if [ -n "$GITHUB_JOB_STATUS" ]; then
	set_job_status_color
fi

function set_default_telegram_template_path() {
	local ext=txt
	case "$TELEGRAM_PARSE_MODE" in
	html | md)
		ext=$TELEGRAM_PARSE_MODE
		;;
	esac
	TELEGRAM_TEMPLATE_PATH="/template/telegram/${TEMPLATE}.${ext}"
}
if [ -z "$TELEGRAM_TEMPLATE_PATH" ]; then
	set_default_telegram_template_path
fi
function set_default_slack_template_path() {
	SLACK_TEMPLATE_PATH="/template/slack/${TEMPLATE}.json"
}
if [ -z "$SLACK_TEMPLATE_PATH" ]; then
	set_default_slack_template_path
fi

if [ -n "$CUSTOM_SCRIPT" ]; then
	eval "$CUSTOM_SCRIPT"
	exit 0
fi

function default_notify_telegram() {
	local arg_p=""
	if [ -n "$TELEGRAM_PARSE_MODE" ]; then
		arg_p=" -p ${TELEGRAM_PARSE_MODE}"
	fi
	local cmd=$(printf 'cat %s | envsubst | tg -q%s' "$TELEGRAM_TEMPLATE_PATH" "$arg_p")
	eval "$cmd"
}
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
	default_notify_telegram
fi

function default_notify_slack() {
	local parsed_file=$(mktemp)
	cat "$SLACK_TEMPLATE_PATH" | envsubst >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" --data @"%s" "%s"' "$parsed_file" "$SLACK_WEBHOOK_URL")
	eval "$cmd"
}
if [ -n "$SLACK_WEBHOOK_URL" ]; then
	default_notify_slack
fi
