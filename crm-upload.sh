#!/bin/sh
# Запись разговора → бэкенд (S3, расшифровка). Зовёт диалплан из обработчика завершения звонка
ID="$1"
FILE="/var/spool/asterisk/monitor/${ID}.wav"
# MixMonitor дописывает файл после завершения звонка
sleep 3
[ -s "$FILE" ] || exit 0
if curl -fsS --max-time 180 -H "X-Asterisk-Token: ${TOKEN}" -F "id=${ID}" -F "file=@${FILE};type=audio/wav" \
  "${BACKEND}/crm-internal/asterisk/recording" >/dev/null; then
  rm -f "$FILE"
fi
