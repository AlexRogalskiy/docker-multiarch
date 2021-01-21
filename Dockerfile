FROM alpine:3.13

### Set defaults
ENV ZABBIX_VERSION=5.0.3 \
    S6_OVERLAY_VERSION=v2.1.0.0 \
    DEBUG_MODE=FALSE \
    TIMEZONE=Etc/GMT \
    ENABLE_CRON=TRUE \
    ENABLE_SMTP=TRUE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=alpine

### Zabbix pre installation steps
RUN set -ex && \
    apk update && \
    apk upgrade && \
    apk add \
        iputils \
        bash \
        pcre \
        libssl1.1 && \
    \
### Add core utils
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
   
### S6 installation
RUN    apkArch="$(apk --print-arch)"; \
    apk --print-arch && \
    echo "APK ARCH ${apkArch}" && \
    case "$apkArch" in \
		x86_64) s6Arch='amd64' ;; \
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
