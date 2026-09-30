FROM ghcr.io/sillytavern/sillytavern:latest
RUN apk add --no-cache git || true
COPY start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["tini", "--", "/start.sh"]
