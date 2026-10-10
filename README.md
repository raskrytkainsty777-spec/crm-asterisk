# crm-asterisk

Asterisk для CRM walead (crm.walead.ru): менеджеры звонят клиентам из браузера (WebRTC, JsSIP)
через SIP-линии оператора, входящие на номер линии звонят сотруднику в браузер. Разговоры
пишутся (MixMonitor), запись уходит в бэкенд — там расшифровка SpeechKit и пересказ ИИ.

- Линии заводятся в админке walead: CRM → Телефония. Бэкенд отдаёт кусок pjsip.conf
  (`/api/crm-internal/asterisk/pjsip`), контейнер забирает его раз в 30 с.
- События звонков — CURL из диалплана (`/crm-internal/asterisk/call`), запись — `crm-upload.sh`.
- Браузер: `wss://sip.walead.ru/ws` → Traefik Coolify → порт 8088 контейнера.
- Наружу: SIP к оператору TCP `SIP_PORT` (5070, 5060 занят Asterisk фермы), RTP UDP 12000–12200.

Переменные: `CRM_ASTERISK_TOKEN` (тот же у бэкенда), `BACKEND` (http://xleads-backend:3000/api),
`EXTERNAL_HOST` (публичный IP сервера), `SIP_PORT`.
