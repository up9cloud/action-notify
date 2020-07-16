FROM sstc/telegram-bot-send.sh

RUN apk add --no-cache \
	gettext

COPY template /template
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
