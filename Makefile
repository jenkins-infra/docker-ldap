IMAGENAME=jenkinsciinfra/ldap
TAG=$(shell date '+%Y%m%d_%H%M%S')
# directory to bind-mount BDB database in.
# should be outside $PWD, or else Docker will capture the whole thing as context during build
DATA=${PWD}/../ldap.data
CONFIG=${PWD}/config.ldif

image :
	docker build -t ${IMAGENAME} .

run :
	docker run -v ${DATA}:/var/lib/ldap -v ${CONFIG}:/etc/ldap/config.ldif -P --rm -i -t ${IMAGENAME}

tag :
	docker tag ${IMAGENAME} ${IMAGENAME}:${TAG}
