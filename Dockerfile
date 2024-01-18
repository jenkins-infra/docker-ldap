FROM debian:10

ENV OPENLDAP_CONFIG_ADMIN_DN 'cn=admin,cn=config'
ENV OPENLDAP_CONFIG_ADMIN_PASSWORD config
ENV OPENLDAP_ADMIN_DN 'cn=admin,dc=jenkins-ci,dc=org'
ENV OPENLDAP_ADMIN_PASSWORD 's3cr3t'
ENV OPENLDAP_BACKUP_PATH /var/backups
ENV OPENLDAP_BACKUP_FILE 'backup.latest.ldif'
ENV OPENLDAP_DATABASE 'dc=jenkins-ci,dc=org'
ENV OPENLDAP_DEBUG_LEVEL 256
ENV OPENLDAP_SSL_KEY 'privkey.key'
ENV OPENLDAP_SSL_CRT 'cert.pem'
ENV OPENLDAP_SSL_CA 'ca.crt'
ENV OPENLDAP_SSL_CA_ROOTDIR '/etc/ldap/ssl-ca'

EXPOSE 389 636


RUN \
  addgroup --gid 101 openldap && \
  useradd -d /var/lib/ldap/ -g openldap -m -u 101 openldap

VOLUME /var/lib/ldap

RUN mkdir /entrypoint

COPY entrypoint/start.sh /entrypoint/start
COPY entrypoint/backup.sh /entrypoint/backup
COPY entrypoint/healthcheck.sh /entrypoint/healthcheck
COPY entrypoint/restore.sh /entrypoint/restore
COPY entrypoint/functions /entrypoint/functions

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /sbin/tini

RUN \
  chmod 0755 /entrypoint/start && \
  chmod 0755 /entrypoint/backup && \
  chmod 0755 /entrypoint/healthcheck && \
  chmod 0755 /entrypoint/restore && \
  chmod 0755 /sbin/tini

# Alays install latest version of APT packages
#hadolint ignore=DL3008
RUN \
  apt-get -y update && \
  LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    procps \
    ca-certificates \
    gnutls-bin \
    slapd \
    ldap-utils \
    libsasl2-modules \
    libsasl2-modules-db \
    libsasl2-modules-gssapi-mit \
    libsasl2-modules-ldap \
    libsasl2-modules-otp \
    libsasl2-modules-sql \
    openssl && \
  apt-get clean &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY config/slapd.conf /etc/ldap/slapd.conf
COPY acme/ca.crt /etc/ldap/ssl-ca/ca.crt

RUN \
  mkdir /etc/ldap/ssl && \
  chmod 700 /var/lib/ldap && \
  chown openldap:openldap /var/lib/ldap && \
  chown openldap:openldap /var/run/slapd

ENTRYPOINT [ "/sbin/tini","--","/entrypoint/start" ]
