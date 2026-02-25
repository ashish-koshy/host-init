FROM alpine:latest
RUN apk add --no-cache wireguard-tools iptables

WORKDIR /app

COPY claw/gateway/setup-wg.sh /app/setup-wg.sh
COPY common/wg_utils.sh /app/common/wg_utils.sh

RUN chmod +x /app/setup-wg.sh
ENTRYPOINT ["/app/setup-wg.sh"]
