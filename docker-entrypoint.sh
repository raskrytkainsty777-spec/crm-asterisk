#!/bin/sh
set -eu

# Конфиги из шаблонов: ${ENV} подставляется, \${…} остаётся переменной Asterisk
mkdir -p /etc/asterisk
for template in /opt/asterisk/templates/*.conf.template; do
  target="/etc/asterisk/$(basename "$template" .template)"
  : > "$target"
  while IFS= read -r line || [ -n "$line" ]; do
    eval "printf '%s\n' \"$line\"" >> "$target"
  done < "$template"
done

# SIP-линии CRM заводятся в админке walead (CRM → Телефония). Бэкенд отдаёт готовый кусок
# pjsip.conf (регистрация у оператора + вход браузера сотрудника), он подключается #include.
# Раз в LINES_SYNC_INTERVAL секунд забираем его снова и перечитываем pjsip, если поменялся;
# заодно отдаём бэкенду статусы регистраций (видно в админке)
LINES_FILE=/etc/asterisk/pjsip_lines.conf
LINES_MARKER="; lk.walead crm sip lines"
LINES_URL="${BACKEND}/internal/crm-asterisk/pjsip?token=${TOKEN}"
INTERVAL="${LINES_SYNC_INTERVAL:-30}"

fetch_lines() {
  target="$1"
  tmp="${target}.tmp"
  if curl -fsS --max-time 10 "$LINES_URL" -o "$tmp" 2>/dev/null && head -n 1 "$tmp" | grep -qF "$LINES_MARKER"; then
    # строка «; generated …» меняется каждый раз — сравниваем без неё
    grep -v '^; generated' "$tmp" > "$target"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

if fetch_lines "$LINES_FILE"; then
  echo "[lines] loaded from backend"
else
  echo "[lines] backend unavailable, starting without lines"
  echo "$LINES_MARKER" > "$LINES_FILE"
fi

sync_loop() {
  while true; do
    sleep "$INTERVAL"
    if fetch_lines "${LINES_FILE}.new"; then
      if cmp -s "${LINES_FILE}.new" "$LINES_FILE"; then
        rm -f "${LINES_FILE}.new"
      else
        mv "${LINES_FILE}.new" "$LINES_FILE"
        echo "[lines] changed, reloading pjsip"
        /usr/sbin/asterisk -rx "module reload res_pjsip.so" || true
        /usr/sbin/asterisk -rx "module reload res_pjsip_outbound_registration.so" || true
      fi
    fi
    /usr/sbin/asterisk -rx "pjsip show registrations" 2>/dev/null \
      | curl -fsS --max-time 10 -H "X-Asterisk-Token: ${TOKEN}" -H "Content-Type: text/plain" --data-binary @- \
        "${BACKEND}/internal/crm-asterisk/registrations" >/dev/null 2>&1 || true
  done
}

if [ "${1:-}" = "/usr/sbin/asterisk" ] || [ "${1:-}" = "asterisk" ]; then
  "$@" &
  pid=$!
  sleep 3
  sync_loop &
  wait "$pid"
  exit $?
fi

exec "$@"
