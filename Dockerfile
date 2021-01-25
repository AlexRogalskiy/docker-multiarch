FROM alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set defaults
ENV ZABBIX_VERSION=5.2.3 \
    S6_OVERLAY_VERSION=v2.2.0.1 \
    DEBUG_MODE=FALSE \
    TIMEZONE=Etc/GMT \
    ENABLE_CRON=TRUE \
    ENABLE_SMTP=TRUE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=alpine

### Add core utils
RUN set -x && \
   apk add -t .base-rundeps \
            bash \
            busybox-extras \
            curl \
            grep \
            less \
            logrotate \
            msmtp \
            nano \
            sudo \
            tzdata \
            vim \
            && \
    rm -rf /var/cache/apk/* && \
    rm -rf /etc/logrotate.d/acpid && \
    rm -rf /root/.cache /root/.subversion && \
    cp -R /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    echo '%zabbix ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    \
    ## Quiet down sudo
    echo "Set disable_coredump false" > /etc/sudo.conf
    \
RUN set -x ; apkArch="$(apk --print-arch)";

RUN set -ex
RUN addgroup -g 10050 zabbix
RUN adduser -S -D -H -h /dev/null -s /sbin/nologin -G zabbix -u 10050 zabbix
RUN mkdir -p /etc/zabbix
RUN mkdir -p /etc/zabbix/zabbix_agentd.d
RUN mkdir -p /var/lib/zabbix
RUN mkdir -p /var/lib/zabbix/enc
RUN mkdir -p /var/lib/zabbix/modules
RUN chown --quiet -R zabbix:root /var/lib/zabbix
RUN apk update
RUN apk upgrade
RUN apk add iputils bash pcre libssl1.1
    
### Zabbix compilation
RUN apk add --no-cache -t .zabbix-build-deps  coreutils  alpine-sdk automake autoconf openssl-dev pcre-dev
RUN mkdir -p /usr/src/zabbix 
RUN curl -sSL https://github.com/zabbix/zabbix/archive/${ZABBIX_VERSION}.tar.gz | tar xfz - --strip 1 -C /usr/src/zabbix 
RUN cd /usr/src/zabbix 
RUN ./bootstrap.sh 1>/dev/null 
RUN export CFLAGS="-fPIC -pie -Wl,-z,relro -Wl,-z,now" 
RUN ./configure \
            --prefix=/usr \
            --silent \
            --sysconfdir=/etc/zabbix \
            --libdir=/usr/lib/zabbix \
            --datadir=/usr/lib \
            --enable-agent \
            --enable-ipv6 \
            --with-openssl && \
RUN make -j"$(nproc)" -s 1>/dev/null
RUN cp src/zabbix_agent/zabbix_agentd /usr/sbin/zabbix_agentd 
RUN cp src/zabbix_sender/zabbix_sender /usr/sbin/zabbix_sender 
RUN cp conf/zabbix_agentd.conf /etc/zabbix 
RUN mkdir -p /etc/zabbix/zabbix_agentd.conf.d 
RUN mkdir -p /var/log/zabbix 
RUN chown -R zabbix:root /var/log/zabbix
RUN chown --quiet -R zabbix:root /etc/zabbix
RUN rm -rf /usr/src/zabbix

### S6 installation
RUN set -x && \
    apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		x86_64) s6Arch='amd64' ;; \
		armv7) s6Arch='arm' ;; \
        armhf) s6Arch='armhf' ;; \
		aarch64) s6Arch='aarch64' ;; \
		ppc64le) s6Arch='ppc64le' ;; \
		*) echo >&2 "Error: unsupported architecture ($apkArch)"; exit 1 ;; \
	esac; \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${s6Arch}.tar.gz | tar xfz - -C / && \
    mkdir -p /assets/cron && \
### Clean up
    rm -rf /usr/src/*

### Networking configuration
EXPOSE 1025 8025 10050/TCP

### Add folders
ADD /install /

### Entrypoint configuration
ENTRYPOINT ["/init"]

