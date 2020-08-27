FROM oraclelinux:7-slim
ARG HTTP_PROXY
ARG http_proxy
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
RUN yum install -q -y oracle-gluster-release-el7 && \
    yum install -q -y git glusterfs glusterfs-fuse attr && \
    curl --silent -L https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz | tar -C /usr/local -zxf -
ENV GOPATH=/root/go
COPY .git $GOPATH/src/github.com/BlueArchive/docker-volume-plugins/.git
COPY glusterfs-volume-plugin/ $GOPATH/src/github.com/BlueArchive/docker-volume-plugins/glusterfs-volume-plugin
COPY mounted-volume/ $GOPATH/src/github.com/BlueArchive/docker-volume-plugins/mounted-volume
RUN /usr/local/go/bin/go get -u -v -f github.com/BlueArchive/docker-volume-plugins/...
# get the wasabi version of docker's plugin helpers - to fix GEN2-843
RUN	set -eo pipefail; cd $GOPATH/src/github.com/docker/go-plugins-helpers; \
   	git remote | grep wasabi || git remote add wasabi https://github.com/bluearchive/go-plugins-helpers; \
   	git rev-parse --abbrev-ref HEAD | grep "wasabi/master" || git checkout -b wasabi/master; \
   	git pull wasabi master
RUN /usr/local/go/bin/go build -o /glusterfs-volume-plugin $GOPATH/src/github.com/BlueArchive/docker-volume-plugins/glusterfs-volume-plugin/main.go
RUN rm -rf $GOPATH /usr/local/go && \
    yum remove -q -y git && \
    yum autoremove -q -y && \
    yum clean all && \
    rm -rf /var/cache/yum /var/log/anaconda /var/cache/yum /etc/mtab && \
    rm /var/log/lastlog /var/log/tallylog
