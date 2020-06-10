.PHONY: build run clean

clean:
	rm utils

build:
	go build -o ../bin/getUserAccounts

getMaintainer:
	../bin/getUserAccounts \
		maintainer \
			--jiraUsername xxx --jiraPassword password \
			--password s3cr3t \
			--protocol ldap --port 9389 \
			--memberOfGroup all

getJira:
	../bin/getUserAccounts \
		jira \
			--jiraUsername xxx --jiraPassword password \
			--password s3cr3t \
			--protocol ldap --port 9389 \
			--backup-file backup.csv \
			--memberOfGroup all
