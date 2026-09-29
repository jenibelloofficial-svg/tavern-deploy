#!/bin/sh
cat > /app/config.yaml <<EOF
dataRoot: ./data
listen: true
listenAddress:
  ipv4: 0.0.0.0
  ipv6: '[::]'
protocol:
  ipv4: true
  ipv6: false
port: ${PORT:-10000}
whitelistMode: false
basicAuthMode: true
basicAuthUser:
  username: "${ST_USER}"
  password: "${ST_PASS}"
EOF
exec node --max-old-space-size=384 server.js
