#!/bin/bash -e

__err=0
function log() {
	if [ "$VERBOSE" == "true" ]; then
		printf '[action-notify] %s\n' "$@"
	fi
}
function err() {
	__err=$((__err + 1))
	printf '[action-notify] %s\n' "$@" 1>&2
}

function setup_keys() {
	local prefix="$1"
	K_CUSTOM_SCRIPT="${prefix}CUSTOM_SCRIPT"
	K_VERBOSE="${prefix}VERBOSE"
	K_TELEGRAM_TEMPLATE_PATH="${prefix}TELEGRAM_TEMPLATE_PATH"
	K_TELEGRAM_BOT_TOKEN="${prefix}TELEGRAM_BOT_TOKEN"
	K_TELEGRAM_CHAT_ID="${prefix}TELEGRAM_CHAT_ID"
	K_TELEGRAM_PARSE_MODE="${prefix}TELEGRAM_PARSE_MODE"
	K_SLACK_TEMPLATE_PATH="${prefix}SLACK_TEMPLATE_PATH"
	K_SLACK_WEBHOOK_URL="${prefix}SLACK_WEBHOOK_URL"
	K_SLACK_API_TOKEN="${prefix}SLACK_API_TOKEN"
	K_SLACK_CHANNEL="${prefix}SLACK_CHANNEL"
	K_DISCORD_TEMPLATE_PATH="${prefix}DISCORD_TEMPLATE_PATH"
	K_DISCORD_WEBHOOK_URL="${prefix}DISCORD_WEBHOOK_URL"
	K_DISCORD_BOT_TOKEN="${prefix}DISCORD_BOT_TOKEN"
	K_DISCORD_CHANNEL_ID="${prefix}DISCORD_CHANNEL_ID"
	K_LINE_TEMPLATE_PATH="${prefix}LINE_TEMPLATE_PATH"
	K_LINE_CHANNEL_ACCESS_TOKEN="${prefix}LINE_CHANNEL_ACCESS_TOKEN"
	K_LINE_TO="${prefix}LINE_TO"
	K_TEMPLATE="${prefix}TEMPLATE"
	K_STATUS_COLOR_SUCCESS="${prefix}STATUS_COLOR_SUCCESS"
	K_STATUS_COLOR_FAILURE="${prefix}STATUS_COLOR_FAILURE"
	K_STATUS_COLOR_CANCELLED="${prefix}STATUS_COLOR_CANCELLED"
	K_STATUS_EMOJI_SUCCESS="${prefix}STATUS_EMOJI_SUCCESS"
	K_STATUS_EMOJI_FAILURE="${prefix}STATUS_EMOJI_FAILURE"
	K_STATUS_EMOJI_CANCELLED="${prefix}STATUS_EMOJI_CANCELLED"
}

################
# Setup github #
################

# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
if [ "$GITHUB_ACTIONS" == "true" ]; then
	# https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads
	log "Github event (${GITHUB_EVENT_PATH}):"
	log "$(cat $GITHUB_EVENT_PATH)"
	if [ $(cat "$GITHUB_EVENT_PATH" | jq 'has("workflow_run")') == "true" ]; then
		export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .workflow_run.head_commit.message || printf '')
		export GIT_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .workflow_run.head_commit.committer.name || printf '')
	else
		export GIT_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[-1].message || printf '')
		export GIT_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .commits[-1].committer.username || printf '')

		# backward compatible
		export GIT_HEAD_COMMIT_MESSAGE=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.message || printf '')
		export GIT_HEAD_COMMITTER_USERNAME=$(cat "$GITHUB_EVENT_PATH" | jq -cr .head_commit.committer.username || printf '')
	fi
	export GIT_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_SHA_SHORT=$(echo "$GITHUB_SHA" | cut -c1-8)

	setup_keys

	# backward compatible
	export GIT_HEAD_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE"
	export GIT_HEAD_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_HEAD_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_HEAD_COMMITTER_USERNAME="$GIT_COMMITTER_USERNAME"
	export GITHUB_SHA_SHORT="$GIT_SHA_SHORT"
	if [ -n "$GITHUB_JOB_SUCCESS_COLOR" ]; then
		STATUS_COLOR_SUCCESS="$GITHUB_JOB_SUCCESS_COLOR"
	fi
	if [ -n "$GITHUB_JOB_FAILURE_COLOR" ]; then
		STATUS_COLOR_FAILURE="$GITHUB_JOB_FAILURE_COLOR"
	fi
	if [ -n "$GITHUB_JOB_CANCELLED_COLOR" ]; then
		STATUS_COLOR_CANCELLED="$GITHUB_JOB_CANCELLED_COLOR"
	fi
	if [ -n "$GITHUB_JOB_SUCCESS_EMOJI" ]; then
		STATUS_EMOJI_SUCCESS="$GITHUB_JOB_SUCCESS_EMOJI"
	fi
	if [ -n "$GITHUB_JOB_FAILURE_EMOJI" ]; then
		STATUS_EMOJI_FAILURE="$GITHUB_JOB_FAILURE_EMOJI"
	fi
	if [ -n "$GITHUB_JOB_CANCELLED_EMOJI" ]; then
		STATUS_EMOJI_CANCELLED="$GITHUB_JOB_CANCELLED_EMOJI"
	fi

############
# Drone ci #
############

# https://docs.drone.io/pipeline/environment/reference/
elif [ "$DRONE" == "true" ]; then
	export GIT_COMMIT_MESSAGE="$DRONE_COMMIT_MESSAGE"
	export GIT_COMMIT_MESSAGE_ESCAPED=$(printf "$GIT_COMMIT_MESSAGE" | jq -RsM | sed -e 's/^"//' -e 's/"$//')
	export GIT_COMMITTER_USERNAME="$DRONE_COMMIT_AUTHOR"
	export GIT_SHA_SHORT=$(echo "$DRONE_COMMIT_SHA" | cut -c1-8)

	setup_keys PLUGIN_
fi

################
# Setup status #
################

function set_status_color() {
	local status="$1"
	local color="#ffffff"
	case "$status" in
	success)
		if [ -n "${!K_STATUS_COLOR_SUCCESS}" ]; then
			color="${!K_STATUS_COLOR_SUCCESS}"
		else
			color="#22863a"
		fi
		;;
	failure)
		if [ -n "${!K_STATUS_COLOR_FAILURE}" ]; then
			color="${!K_STATUS_COLOR_FAILURE}"
		else
			color="#cb2431"
		fi
		;;
	cancelled)
		if [ -n "${!K_STATUS_COLOR_CANCELLED}" ]; then
			color="${!K_STATUS_COLOR_CANCELLED}"
		else
			color="#6a737d"
		fi
		;;
	esac
	export STATUS_COLOR="$color"
	export STATUS_COLOR_DECIMAL="$((16${STATUS_COLOR}))"

	# backward compatible
	export GITHUB_JOB_STATUS_COLOR="$STATUS_COLOR"
	export GITHUB_JOB_STATUS_COLOR_DECIMAL="$STATUS_COLOR_DECIMAL"
}
function set_status_emoji() {
	local status="$1"
	local emoji="🛎"
	case "$status" in
	success)
		if [ -n "${!K_STATUS_EMOJI_SUCCESS}" ]; then
			emoji="${!K_STATUS_EMOJI_SUCCESS}"
		else
			emoji="🟢"
		fi
		;;
	failure)
		if [ -n "${!K_STATUS_EMOJI_FAILURE}" ]; then
			emoji="${!K_STATUS_EMOJI_FAILURE}"
		else
			emoji="🔴"
		fi
		;;
	cancelled)
		if [ -n "${!K_STATUS_EMOJI_CANCELLED}" ]; then
			emoji="${!K_STATUS_EMOJI_CANCELLED}"
		else
			emoji="⚪️"
		fi
		;;
	esac
	export STATUS_EMOJI="$emoji"

	# backward compatible
	export GITHUB_JOB_STATUS_EMOJI="$STATUS_EMOJI"
}
if [ "$GITHUB_ACTIONS" == "true" ]; then
	set_status_color "$GITHUB_JOB_STATUS"
	set_status_emoji "$GITHUB_JOB_STATUS"
elif [ "$DRONE" == "true" ]; then
	set_status_color "$DRONE_BUILD_STATUS"
	set_status_emoji "$DRONE_BUILD_STATUS"
fi

##################
# Setup template #
##################

if [ -z "${!K_TEMPLATE}" ]; then
	if [ "$GITHUB_ACTIONS" == "true" ]; then
		TEMPLATE=default
	elif [ "$DRONE" == "true" ]; then
		TEMPLATE=default.drone
	fi
fi
function set_default_telegram_template_path() {
	local ext=txt
	case "${!K_TELEGRAM_PARSE_MODE}" in
	html | md)
		ext=${!K_TELEGRAM_PARSE_MODE}
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
if [ -z "${!K_TELEGRAM_TEMPLATE_PATH}" ]; then
	set_default_telegram_template_path
else
	TELEGRAM_TEMPLATE_PATH="${!K_TELEGRAM_TEMPLATE_PATH}"
fi
if [ -z "${!K_SLACK_TEMPLATE_PATH}" ]; then
	SLACK_TEMPLATE_PATH="/template/slack/${TEMPLATE}.json"
else
	SLACK_TEMPLATE_PATH="${!K_SLACK_TEMPLATE_PATH}"
fi
if [ -z "${!K_DISCORD_TEMPLATE_PATH}" ]; then
	DISCORD_TEMPLATE_PATH="/template/discord/${TEMPLATE}.json"
else
	DISCORD_TEMPLATE_PATH="${!K_DISCORD_TEMPLATE_PATH}"
fi
if [ -z "${!K_LINE_TEMPLATE_PATH}" ]; then
	LINE_TEMPLATE_PATH="/template/line.me/${TEMPLATE}.json"
else
	LINE_TEMPLATE_PATH="${!K_LINE_TEMPLATE_PATH}"
fi

##########
# Custom #
##########
if [ -n "${!K_CUSTOM_SCRIPT}" ]; then
	log "\$$K_CUSTOM_SCRIPT detected, skip default notifying."
	eval "${!K_CUSTOM_SCRIPT}"
	exit 0
fi

#####################
# Default notifying #
#####################
__count=0

function default_notify_telegram() {
	local arg_p=""
	if [ -n "${!K_TELEGRAM_PARSE_MODE}" ]; then
		arg_p=" -p ${!K_TELEGRAM_PARSE_MODE}"
	fi
	local cmd=$(printf 'cat %s | envsubst | tg -q%s' "${!K_TELEGRAM_TEMPLATE_PATH}" "$arg_p")
	eval "$cmd"
}
if [ -n "${!K_TELEGRAM_BOT_TOKEN}" ] && [ -n "${!K_TELEGRAM_CHAT_ID}" ]; then
	log "\$$K_TELEGRAM_BOT_TOKEN \$$K_TELEGRAM_CHAT_ID detected, run default telegram notifying."
	__count=$((__count + 1))
	default_notify_telegram
fi

function default_notify_slack_via_webhook() {
	local parsed_file=$(mktemp)
	cat "${!K_SLACK_TEMPLATE_PATH}" | envsubst | jq --arg channel "${!K_SLACK_CHANNEL}" '. + {channel: $channel}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" --data @"%s" "%s"' "$parsed_file" "${!K_SLACK_WEBHOOK_URL}")
	eval "$cmd"
}
function default_notify_slack_via_api() {
	local parsed_file=$(mktemp)
	local url=https://slack.com/api/chat.postMessage
	cat "${!K_SLACK_TEMPLATE_PATH}" | envsubst | jq --arg channel "${!K_SLACK_CHANNEL}" '. + {channel: $channel}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "authorization: Bearer %s" -H "content-type: application/json; charset=UTF-8" --data @"%s" "%s"' "${!K_SLACK_API_TOKEN}" "$parsed_file" "$url")
	eval "$cmd"
}
if [ -n "${!K_SLACK_WEBHOOK_URL}" ]; then
	log "\$$_K_SLACK_WEBHOOK_URL detected, run default slack (webhook) notifying."
	__count=$((__count + 1))
	default_notify_slack_via_webhook
elif [ -n "${!K_SLACK_API_TOKEN}" ] && [ -n "${!K_SLACK_CHANNEL}" ]; then
	log "\$$K_SLACK_API_TOKEN \$$K_SLACK_CHANNEL detected, run default slack (api) notifying."
	__count=$((__count + 1))
	default_notify_slack_via_api
fi

function default_notify_discord_via_webhook() {
	local parsed_file=$(mktemp)
	cat "${!K_DISCORD_TEMPLATE_PATH}" | envsubst >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" --data @"%s" "%s"' "$parsed_file" "${!K_DISCORD_WEBHOOK_URL}")
	eval "$cmd"
}
if [ -n "${!K_DISCORD_WEBHOOK_URL}" ]; then
	log "\$$K_DISCORD_WEBHOOK_URL detected, run default discord (webhook) notifying."
	__count=$((__count + 1))
	default_notify_discord_via_webhook
fi
function default_notify_discord_via_bot() {
	local parsed_file=$(mktemp)
	cat "${!K_DISCORD_TEMPLATE_PATH}" | envsubst >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" -H "authorization: Bot %s" --data @"%s" "https://discordapp.com/api/v7/channels/%s/messages"' "${!K_DISCORD_BOT_TOKEN}" "$parsed_file" "${!K_DISCORD_CHANNEL_ID}")
	eval "$cmd"
}
if [ -n "${!K_DISCORD_BOT_TOKEN}" ] && [ -n "${!K_DISCORD_CHANNEL_ID}" ]; then
	log "\$$K_DISCORD_BOT_TOKEN and \$$K_DISCORD_CHANNEL_ID detected, run default discord (bot) notifying."
	__count=$((__count + 1))
	default_notify_discord_via_bot
fi

function default_notify_line() {
	local parsed_file=$(mktemp)
	local mode=push
	local LINE_TO_JSON="\"${!K_LINE_TO}\""
	if [[ "${!K_LINE_TO}" == *","* ]]; then
		LINE_TO_JSON=$(echo -en "${!K_LINE_TO}" | jq --raw-input --slurp 'split(",")')
		mode=multicast
	fi
	cat "${!K_LINE_TEMPLATE_PATH}" | envsubst | jq --argjson to "${LINE_TO_JSON}" '. + {to: $to}' >$parsed_file
	local cmd=$(printf 'curl -sSL -X POST -H "content-type: application/json" -H "Authorization: Bearer %s" --data @"%s" "https://api.line.me/v2/bot/message/%s"' "${!K_LINE_CHANNEL_ACCESS_TOKEN}" "$parsed_file" "$mode")
	exec 3>&1
	local http_status=$(eval "$cmd" -w '%{http_code}' -o >(cat >&3))
	if ((http_status > 399)); then
		err "Line api returned http code: ${http_status}"
	fi
}
if [ -n "${!K_LINE_CHANNEL_ACCESS_TOKEN}" ] && [ -n "${!K_LINE_TO}" ]; then
	log "\$$K_LINE_CHANNEL_ACCESS_TOKEN \$$K_LINE_TO detected, run default line notifying."
	__count=$((__count + 1))
	default_notify_line
fi

# final handler
if [[ "$__count" -eq 0 ]]; then
	err "No any ENV Specified, nothing send."
fi
if [[ "$__err" -ne 0 ]]; then
	exit 1
fi
