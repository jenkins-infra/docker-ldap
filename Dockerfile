FROM ubuntu:trusty
RUN apt-get install -y slapd ldap-utils

# ADD ./etc /etc/ldap
ADD ./run.sh /usr/local/bin/run.sh

# LDAP and LDAPS service
# TODO: remove LDAP endpoint once we figure out how to feed in self-signed cert for testing
EXPOSE 389 636

# BDB directory that stores the database
VOLUME ["/var/lib/ldap","/etc/ssl"]


#  -d will make it run in the foreground
CMD /usr/local/bin/run.sh

