#!/bin/bash

__DIR__=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

IMAGE=action-notify
ENV_FILE="$__DIR__/../.env"

GIT_COMMITTER_USERNAME="user12345678901234567890"
GIT_COMMITTER_MESSAGE_ESCAPED="我們的人生道路中，有很多的得到與失去，我們要學會用淡然的心態去面對，心中要充滿愛和感恩，幸福就在我們的身邊，多少緣分人走茶涼，一些捨不得，只能放在心底，一些禁不住，只能假裝忘記，諸多的放下，到底是無所謂還是輸不起，諸多的隨緣，究竟是不值得還是在玩你，有些事自己知道就好，沒必要去追問，因為答案未必能接受，不值得去難過。"
LINE_CHANNEL_ACCESS_TOKEN=$(jq -r .LINE_CHANNEL_ACCESS_TOKEN ./.config/secret.json)
LINE_TO=$(jq -r .LINE_TO ./.config/secret.json)
TEMPLATE=default
# TEMPLATE=debug

docker build -t $IMAGE .

docker run --rm \
	--env-file "$ENV_FILE" \
	-e GIT_COMMITTER_USERNAME="${GIT_COMMITTER_USERNAME}" \
	-e GIT_COMMIT_MESSAGE_ESCAPED="${GIT_COMMITTER_MESSAGE_ESCAPED}" \
	-e LINE_CHANNEL_ACCESS_TOKEN="${LINE_CHANNEL_ACCESS_TOKEN}" \
	-e LINE_TO="${LINE_TO}" \
	-e TEMPLATE="${TEMPLATE}" \
	$IMAGE
