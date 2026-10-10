FROM andrius/asterisk:latest

COPY templates /opt/asterisk/templates
COPY docker-entrypoint.sh /usr/local/bin/asterisk-entrypoint
COPY crm-upload.sh /usr/local/bin/crm-upload.sh

RUN chmod +x /usr/local/bin/asterisk-entrypoint /usr/local/bin/crm-upload.sh \
 && mkdir -p /var/spool/asterisk/monitor

ENTRYPOINT ["/bin/sh", "/usr/local/bin/asterisk-entrypoint"]
CMD ["/usr/sbin/asterisk", "-vvvf", "-T", "-W", "-U", "asterisk", "-p"]
