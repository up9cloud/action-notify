#!/bin/bash -e

function log() {
	if [ "$VERBOSE" == "true" ]; then
		printf '[action-notify] %s\n' "$@"
	fi
}
function die() {
	printf '[action-notify] %s\n' "$@" 1>&2
	exit 1
}

################
# Setup github #
################
if [ -f "$GITHUB_EVENT_PATH" ]; then
	export GIT_HEAD_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.message || printf '')
	export GIT_HEAD_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_HEAD_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_HEAD_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.committer.username || printf '')
	export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[-1].message || printf '')
	export GIT_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[-1].committer.username || printf '')
fi
if [ -n "$GITHUB_SHA" ]; then
	export GITHUB_SHA_SHORT=$(echo "$GITHUB_SHA" | cut -c1-8)
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
function set_job_status_emoji() {
	local emoji="🛎"
	case "$GITHUB_JOB_STATUS" in
	success)
		if [ -n "$GITHUB_JOB_SUCCESS_EMOJI" ]; then
			emoji="$GITHUB_JOB_SUCCESS_EMOJI"
		else
			emoji="🟢"
		fi
		;;
	failure)
		if [ -n "$GITHUB_JOB_FAILURE_EMOJI" ]; then
			emoji="$GITHUB_JOB_FAILURE_EMOJI"
		else
			emoji="🔴"
		fi
		;;
	cancelled)
		if [ -n "$GITHUB_JOB_CANCELLED_EMOJI" ]; then
			emoji="$GITHUB_JOB_CANCELLED_EMOJI"
		else
			emoji="⚪️"
		fi
		;;
	esac
	export GITHUB_JOB_STATUS_EMOJI="$emoji"
}
if [ -n "$GITHUB_JOB_STATUS" ]; then
	set_job_status_color
	set_job_status_emoji
fi

##################
# Setup template #
##################
if [ -z "$TEMPLATE" ]; then
	TEMPLATE=default
fi
function set_default_telegram_template_path() {
	local ext=txt
	case "$TELEGRAM_PARSE_MODE" in
	html | md)
		ext=$TELEGRAM_PARSE_MODE
		;;
	HTML)
		ext=html
		;;
	markdown | Markdown | MarkdownV2)
		ext=md
		;;
	esac
	TELEGRAM_TEMPLATE_PATH="/template/telegram/${TEMPLATE}.${ext}"
}
if [ -z "$TELEGRAM_TEMPLATE_PATH" ]; then
	set_default_telegram_template_path
fi
if [ -z "$SLACK_TEMPLATE_PATH" ]; then
	SLACK_TEMPLATE_PATH="/template/slack/${TEMPLATE}.json"
fi
if [ -z "$DISCORD_TEMPLATE_PATH" ]; then
	DISCORD_TEMPLATE_PATH="/template/discord/${TEMPLATE}.json"
fi
if [ -z "$LINE_TEMPLATE_PATH" ]; then
	LINE_TEMPLATE_PATH="/template/line.me/${TEMPLATE}.json"
fi

##########
# Custom #
##########
if [ -n "$CUSTOM_SCRIPT" ]; then
	log "\$CUSTOM_SCRIPT detected, skip default notifying."
	eval "$CUSTOM_SCRIPT"
	exit 0
fi

#####################
# Default notifying #
#####################
__count=0

function default_notify_telegram() {
	local arg_p=""
	if [ -n "$TELEGRAM_PARSE_MODE" ]; then
		arg_p=" -p ${TELEGRAM_PARSE_MODE}"
	fi
	local cmd=$(printf 'cat %s | envsubst | tg -q%s' "$TELEGRAM_TEMPLATE_PATH" "$arg_p")
	eval "$cmd"
	__count=$((__count + 1))
}
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
	log "\$TELEGRAM_BOT_TOKEN \$TELEGRAM_CHAT_ID detected, run default telegram notifying."
	default_notify_telegram
fi

function default_notify_slack_via_webhook() {
	local parsed_file=$(mktemp)
	cat "$SLACK_TEMPLATE_PATH" | envsubst | jq --arg channel "${SLACK_CHANNEL}" '. + {channel: $channel}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" --data @"%s" "%s"' "$parsed_file" "$SLACK_WEBHOOK_URL")
	eval "$cmd"
	__count=$((__count + 1))
}
function default_notify_slack_via_api() {
	local parsed_file=$(mktemp)
	local url=https://slack.com/api/chat.postMessage
	cat "$SLACK_TEMPLATE_PATH" | envsubst | jq --arg channel "${SLACK_CHANNEL}" '. + {channel: $channel}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "authorization: Bearer %s" -H "content-type: application/json; charset=UTF-8" --data @"%s" "%s"' "$SLACK_API_TOKEN" "$parsed_file" "$url")
	eval "$cmd"
	__count=$((__count + 1))
}
if [ -n "$SLACK_WEBHOOK_URL" ]; then
	log "\$SLACK_WEBHOOK_URL detected, run default slack (webhook) notifying."
	default_notify_slack_via_webhook
elif [ -n "$SLACK_API_TOKEN" ] && [ -n "$SLACK_CHANNEL" ]; then
	log "\$SLACK_API_TOKEN \$SLACK_CHANNEL detected, run default slack (api) notifying."
	default_notify_slack_via_api
fi

function default_notify_discord_via_webhook() {
	local parsed_file=$(mktemp)
	cat "$DISCORD_TEMPLATE_PATH" | GITHUB_JOB_STATUS_COLOR="$((16${GITHUB_JOB_STATUS_COLOR}))" envsubst >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" --data @"%s" "%s"' "$parsed_file" "$DISCORD_WEBHOOK_URL")
	eval "$cmd"
	__count=$((__count + 1))
}
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
	log "\$DISCORD_WEBHOOK_URL detected, run default discord (webhook) notifying."
	default_notify_discord_via_webhook
fi

function default_notify_line() {
	local parsed_file=$(mktemp)
	local mode=push
	local LINE_TO_JSON="\"$LINE_TO\""
	if [[ "$LINE_TO" == *","* ]]; then
		LINE_TO_JSON=$(echo -en "$LINE_TO" | jq --raw-input --slurp 'split(",")')
		mode=multicast
	fi
	cat "$LINE_TEMPLATE_PATH" | envsubst | jq --argjson to "${LINE_TO_JSON}" '. + {to: $to}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" -H "Authorization: Bearer %s" --data @"%s" "https://api.line.me/v2/bot/message/%s"' "$LINE_CHANNEL_ACCESS_TOKEN" "$parsed_file" "$mode")
	eval "$cmd"
	__count=$((__count + 1))
}
if [ -n "$LINE_CHANNEL_ACCESS_TOKEN" ] && [ -n "$LINE_TO" ]; then
	log "\$LINE_CHANNEL_ACCESS_TOKEN \$LINE_TO detected, run default line notifying."
	default_notify_line
fi

# final handler
if [[ "$__count" -eq 0 ]]; then
	die "No any ENV Specified, nothing send."
fi
