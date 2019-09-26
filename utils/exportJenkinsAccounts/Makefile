.PHONY: build run clean

clean:
	rm utils

build:
	go build -o ../bin/exportJenkinsAccounts

run:
	../bin/exportJenkinsAccounts --password s3cr3t --protocol ldap --memberOfGroup admins
	../bin/exportJenkinsAccounts --password s3cr3t --protocol ldap --memberOfGroup all
