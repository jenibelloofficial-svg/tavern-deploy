#!/bin/sh
APP=/home/node/app
DATA=$APP/data
cd $APP

cat > /tmp/st-config.yaml <<EOF
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
hostWhitelist:
  enabled: false
  scan: false
basicAuthMode: true
basicAuthUser:
  username: "${ST_USER}"
  password: "${ST_PASS}"
EOF
mkdir -p "$APP/config"
cp /tmp/st-config.yaml "$APP/config/config.yaml" 2>/dev/null
cp /tmp/st-config.yaml "$APP/config.yaml" 2>/dev/null

BACKUP_OK=0

backup_now() {
  [ "$BACKUP_OK" = "1" ] || return 0
  cd /tmp/backup || return 0
  rm -rf data
  mkdir -p data
  cp -a "$DATA"/. data/ 2>/dev/null
  rm -rf data/_cache data/default-user/thumbnails data/default-user/backups
  git add -A >/dev/null 2>&1
  if ! git diff --cached --quiet; then
    if git commit -q -m "backup $(date -u +%FT%TZ)" >/dev/null 2>&1 && git push -q origin HEAD:main >/dev/null 2>&1; then
      echo "[backup] pushed"
    else
      echo "[backup] push FAILED"
    fi
  fi
  cd $APP
}

if [ -n "$GH_TOKEN" ] && [ -n "$GH_REPO" ] && command -v git >/dev/null 2>&1; then
  rm -rf /tmp/backup
  if git clone -q --depth 1 "https://x-access-token:${GH_TOKEN}@github.com/${GH_REPO}.git" /tmp/backup >/dev/null 2>&1; then
    BACKUP_OK=1
    git -C /tmp/backup config user.email "backup@localhost"
    git -C /tmp/backup config user.name "st-backup"
    if [ -d /tmp/backup/data ]; then
      mkdir -p "$DATA"
      cp -a /tmp/backup/data/. "$DATA"/
      echo "[backup] restored data from GitHub"
    else
      echo "[backup] repo is empty, starting fresh"
    fi
  else
    echo "[backup] clone FAILED, backups disabled"
  fi
else
  echo "[backup] not configured, backups disabled"
fi

node --max-old-space-size=384 server.js --listen --port "${PORT:-10000}" &
NODE_PID=$!

if [ "$BACKUP_OK" = "1" ]; then
  ( while true; do sleep 300; backup_now; done ) &
fi

trap 'echo "[backup] shutting down"; backup_now; kill $NODE_PID 2>/dev/null; exit 0' TERM INT
wait $NODE_PID
backup_now
