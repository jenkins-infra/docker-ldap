.PHONY: build run shell mock

COMMIT         := $(shell git rev-parse HEAD | cut -c1-6)
GIT_TREE_STATE := $(shell test -z "`git status --porcelain`" && echo "clean" || echo "dirty")
GIT_SCM_URL    := $(shell git config --get remote.origin.url)
SCM_URI        := $(subst git@github.com:,https://github.com/,$(GIT_SCM_URL))
BUILD_DATE     := $(shell date --utc '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || gdate --utc '+%Y-%m-%dT%H:%M:%S')

IMAGE = jenkinsciinfra/ldap
TAG = $(COMMIT)

build:
	docker build \
		--no-cache \
		--label "org.opencontainers.image.source=$(GIT_SCM_URL)" \
		--label "org.label-schema.vcs-url=$(GIT_SCM_URL)" \
		--label "org.opencontainers.image.url=$(SCM_URI)" \
		--label "org.label-schema.url=$(SCM_URI)" \
		--label "org.opencontainers.image.revision=$(GIT_COMMIT_REV)" \
		--label "org.label-schema.vcs-ref=$(GIT_COMMIT_REV)" \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.label-schema.build-date=$(BUILD_DATE)" \
		--label "io.jenkins-tools.tree.state=$(GIT_TREE_STATE)" \
		-t $(IMAGE):$(TAG) \
		-t $(IMAGE):latest \
		.
	docker build \
		--build-arg \
			BASE_IMAGE=$(IMAGE):$(TAG) \
		--label "org.opencontainers.image.source=$(GIT_SCM_URL)" \
		--label "org.label-schema.vcs-url=$(GIT_SCM_URL)" \
		--label "org.opencontainers.image.url=$(SCM_URI)" \
		--label "org.label-schema.url=$(SCM_URI)" \
		--label "org.opencontainers.image.revision=$(GIT_COMMIT_REV)" \
		--label "org.label-schema.vcs-ref=$(GIT_COMMIT_REV)" \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.label-schema.build-date=$(BUILD_DATE)" \
		--label "io.jenkins-tools.tree.state=$(GIT_TREE_STATE)" \
		-t $(IMAGE):cron-$(TAG) \
		-t $(IMAGE):cron-latest \
		-f Dockerfile.cron \
		.

echo:
	echo $(IMAGE):$(TAG) $(IMAGE):$(BRANCH)

publish:
	docker push $(IMAGE):$(TAG)
	docker push $(IMAGE):latest
	docker push $(IMAGE):cron-$(TAG)
	docker push $(IMAGE):cron-latest

cron-shell:
	@docker run -i -t --rm \
		-p 389:389 \
		-p 636:636 \
		-v `pwd`/ssl/ca.pem:/etc/ldap/ssl-ca/cacert.pem:ro \
		-v `pwd`/ssl/ldap.pem:/etc/ldap/ssl/cert.pem:ro \
		-v `pwd`/ssl/ldap.key:/etc/ldap/ssl/privkey.key:ro \
		-v `pwd`/mock.ldif:/var/backups/backup.latest.ldif \
		--entrypoint /bin/bash \
		--name shell-cron $(IMAGE):cron-$(TAG)

shell:
	@docker run -i -t --rm \
		-p 389:389 \
		-p 636:636 \
		-v `pwd`/ssl/ca.pem:/etc/ldap/ssl/cacert.pem:ro \
		-v `pwd`/ssl/ldap.pem:/etc/ldap/ssl/cert.pem:ro \
		-v `pwd`/ssl/ldap.key:/etc/ldap/ssl/privkey.key:ro \
		-v `pwd`/mock.ldif:/var/backups/backup.latest.ldif \
		--entrypoint /bin/bash \
		--name ldap $(IMAGE):$(TAG)
cron-mock:
	@docker run -i -t --rm \
		-p 389:389 \
		-p 636:636 \
		-v `pwd`/ssl/ca.pem:/etc/ldap/ssl-ca/cacert.pem:ro \
		-v `pwd`/ssl/ldap.pem:/etc/ldap/ssl/cert.pem:ro \
		-v `pwd`/ssl/ldap.key:/etc/ldap/ssl/privkey.key:ro \
		-v `pwd`/mock.ldif:/var/backups/backup.latest.ldif \
		--name cron-ldap $(IMAGE):cron-$(TAG)

mock:
	@docker run -i -t --rm \
		-p 389:389 \
		-p 636:636 \
		-v `pwd`/ssl/ca.pem:/etc/ldap/ssl-ca/cacert.pem:ro \
		-v `pwd`/ssl/ldap.pem:/etc/ldap/ssl/cert.pem:ro \
		-v `pwd`/ssl/ldap.key:/etc/ldap/ssl/privkey.key:ro \
		-v `pwd`/mock.ldif:/var/backups/backup.latest.ldif \
		--name ldap $(IMAGE):$(TAG)

		#-e OPENLDAP_DEBUG_LEVEL='3'\

gen_cert:
	mkdir ssl || true
	openssl req \
       -newkey rsa:2048 \
	   -nodes \
	   -keyout ssl/ldap.key \
       -out ssl/ldap.csr\
	   -subj "/C=BE/O=JENKINSPROJECT/CN=sandbox.ldap.jenkins.io"
	openssl req \
       -newkey rsa:2048 \
	   -nodes \
	   -keyout ssl/ca.key \
       -x509 \
	   -days 365 \
	   -out ssl/ca.pem\
	   -subj "/C=BE/O=JENKINSPROJECT/CN=sandbox.jenkins.io"
	openssl x509 -req \
		-in ssl/ldap.csr \
		-CA ssl/ca.pem \
		-CAkey ssl/ca.key \
		-CAcreateserial \
		-out ssl/ldap.pem\
