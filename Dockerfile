FROM alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set defaults
ENV ZABBIX_VERSION=5.2.3 \
    S6_OVERLAY_VERSION=v2.2.0.0 \
    DEBUG_MODE=FALSE \
    TIMEZONE=Etc/GMT \
    ENABLE_CRON=TRUE \
    ENABLE_SMTP=TRUE \
    ENABLE_ZABBIX=TRUE \
    ZABBIX_HOSTNAME=alpine

### S6 installation
    
RUN set -x && \
    apkArch="$(apk --print-arch)"; \    
    echo "ARCH IS $apkArch" ; \
	case "$apkArch" in \
		x86_64) s6Arch='amd64' ;; \
		armhf) s6Arch='armhf' ;; \
		armv7) s6Arch='arm' ;; \
		aarch64) s6Arch='aarch64' ;; \
		*) echo >&2 "Error: unsupported architecture ($apkArch)"; exit 1 ;; \
	esac;

