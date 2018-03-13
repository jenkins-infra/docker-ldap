FROM alpine:3.7

ENV OPENLDAP_ADMIN_DN 'cn=admin,dc=jenkins-ci,dc=org'
ENV OPENLDAP_ADMIN_PASSWORD 's3cr3t'
ENV OPENLDAP_BACKUP_PATH /var/lib/openldap/openldap-data
ENV OPENLDAP_BACKUP_FILE 'backup.latest.ldif'
ENV OPENLDAP_DATABASE 'dc=jenkins-ci,dc=org'
ENV OPENLDAP_DEBUG_LEVEL 256
ENV OPENLDAP_SSL_KEY 'privkey.key'
ENV OPENLDAP_SSL_CRT 'cert.pem'
ENV OPENLDAP_SSL_CA 'cacert.pem'

EXPOSE 389 636

VOLUME /var/lib/openldap/openldap-data

RUN \
  addgroup -g 101 ldap && \
  adduser -H -D -u 100 -h /var/lib/openldap/ -G ldap ldap

RUN mkdir /entrypoint

COPY entrypoint/start.sh /entrypoint/start
COPY entrypoint/backup.sh /entrypoint/backup
COPY entrypoint/healthcheck.sh /entrypoint/healthcheck
COPY entrypoint/restore.sh /entrypoint/restore
COPY entrypoint/functions /entrypoint/functions

RUN \
  chmod 0755 /entrypoint/start && \
  chmod 0755 /entrypoint/backup && \
  chmod 0755 /entrypoint/healthcheck && \
  chmod 0755 /entrypoint/restore

RUN \
  apk add --no-cache \
  bash \
  lmdb-tools \
  openldap-back-mdb \
  openldap-clients \
  openldap \
  openssl

COPY config/slapd.conf /etc/openldap/slapd.conf

RUN \
  mkdir /etc/openldap/ssl && \
  mkdir /var/run/openldap/ && \
  chmod 700 /var/lib/openldap/openldap-data && \
  chown -R root:ldap /etc/openldap && \
  chown ldap:ldap /var/lib/openldap/openldap-data && \
  chown ldap:ldap /var/run/openldap

ENTRYPOINT /entrypoint/start
