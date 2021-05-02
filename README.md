# github.com/tiredofit/docker-nginx-php-fpm


[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/nginx-php-fpm.svg)](https://hub.docker.com/r/tiredofit/nginx-php-fpm)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/nginx-php-fpm.svg)](https://hub.docker.com/r/tiredofit/nginx-php-fpm)
[![Docker Layers](https://images.microbadger.com/badges/image/tiredofit/nginx-php-fpm.svg)](https://microbadger.com/images/tiredofit/nginx-php-fpm)
* * *


## About

This repository will build a [Nginx](https://www.nginx.org) w/[PHP-FPM](https://php.net) docker image, suitable for serving PHP scripts, or utilizing as a base image for installing additional software.
`nano` `vim`
* Tracking PHP 5.3-8.0
* Easily enable / disable extensions based on your use case
* Automatic Log rotation
* Composer Included
* XDebug capability
* Caching via APC, opcache
* Includes client libraries for [MariaDB](https://www.mariadb.org) and [Postgresql](https://www.postgresql.org)


[Changelog](CHANGELOG.md)

## Maintainer

- [Dave Conroy](http://github/tiredofit/)

## Table of Contents

- [Multi Arch](#multi-arch)
  - [Data-Volumes](#data-volumes)
  - [Database](#database)
  - [Environment Variables](#environment-variables)
  - [Networking](#networking)
    - [Shell Access](#shell-access)
    - [PHP Extensions](#php-extensions)
    - [Maintenance Mode](#maintenance-mode)


## Prerequisites and Assumptions
*  Assumes you are using some sort of SSL terminating reverse proxy such as:
   *  [Traefik](https://github.com/tiredofit/docker-traefik)
   *  [Nginx](https://github.com/jc21/nginx-proxy-manager)
   *  [Caddy](https://github.com/caddyserver/caddy)

## Installation

Builds of the image are available on [Docker Huby](https://hub.docker.com/r/tiredofit/nginx-php-fpm) and is the recommended method of installation.

```bash
docker pull tiredofit/nginx-php-fpm:(imagetag)
```

The following image tags are available along with their taged release based on what's written in the [Changelog](CHANGELOG.md):

| PHP version | Alpine Base | Tag            | Debian Base | Tag           |
| ----------- | ----------- | -------------- | ----------- | ------------- |
| latest      | edge        | `:alpine-edge` |             |               |
| 8.0.x       | 3.13        | `:alpine-8.0`  | Buster      | `:debian-8.0` |
| 7.4.x       | 3.13        | `:alpine-7.4`  | Buster      | `:debian-7.3` |
| 7.3.x       | 3.12        | `:alpine-7.3`  | Buster      | `:debian-7.3` |
| 7.2.x       | 3.9         | `:alpine-8.0`  |             |               |
| 7.1.x       | 3.7         | `:alpine-7.4`  |             |               |
| 7.0.x       | 3.5         | `:alpine-7.3`  |             |               |
| 5.6.x       | 3.8         | `:alpine-5.6`  |             |               |
| 5.5.x       | 3.4         | `:5.5-latest`  |             |               |
| 5.3.x       | 3.4         | `:5.3-latest`  |             |               |

### Multi Arch
Images are built primarily for `amd64` architecture, and may also include builds for `arm/v6`, `arm/v7`, `arm64` and others. These variants are all unsupported. Consider [sponsoring](https://github.com/sponsors/tiredofit) my work so that I can work with various hardware. To see if this image supports multiple architecures, type `docker manifest (image):(tag)`

### Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [docker-compose.yml](examples/docker-compose.yml) that can be modified for development or production use.

* Set various [environment variables](#environment-variables) to understand the capabilities of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

## Configuration


### Data-Volumes

The container starts up and reads from `/etc/nginx/nginx.conf` for some basic configuration and to listen on port 73 internally for Nginx Status responses. `/etc/nginx/conf.d` contains a sample configuration file that can be used to customize a nginx server block.

The following directories are used for configuration and can be mapped for persistent storage.

| Directory   | Description                |
| ----------- | -------------------------- |
| `/www/html` | Root Directory             |
| `/www/logs` | Nginx and php-fpm logfiles |

* * *
### Environment Variables

#### Base Images used

This image relies on an [Alpine Linux](https://hub.docker.com/r/tiredofit/alpine) or [Debian Linux](https://hub.docker.com/r/tiredofit/debian) base image that relies on an [init system](https://github.com/just-containers/s6-overlay) for added capabilities. Outgoing SMTP capabilities are handlded via `msmtp`. Individual container performance monitoring is performed by [zabbix-agent](https://zabbix.org). Additional tools include: `bash` `curl` `less` `logrotate`.  
Be sure to view the following repositories to understand all the customizable options:

| Image                                                  | Description                            |
| ------------------------------------------------------ | -------------------------------------- |
| [OS Base](https://github.com/tiredofit/docker-alpine/) | Customized Image based on Alpine Linux |
| [Nginx](https://github.com/tiredofit/docker-nginx/)    | Nginx webserver                        |


#### Container Options

The container has an ability to work in 3 modes, `nginx-php-fpm` (default) is an All in One image with nginx and php-fpm working together, `nginx` will only utilize nginx however not the included php-fpm instance, allowing for connecting to multiple remote php-fpm backends, and finally `php-fpm` to operate PHP-FPM in standalone mode.


| Parameter        | Description                                                   | Default         |
| ---------------- | ------------------------------------------------------------- | --------------- |
| `CONTAINER_MODE` | Mode of running container `nginx-php-fpm`, `nginx`, `php-fpm` | `nginx-php-fpm` |

When `CONTAINER_MODE` set to `nginx` the `PHP_FPM_LISTEN_PORT` environment variable is ignored and the `PHP_FPM_HOST` variable defined below changes. You can add multiple PHP-FPM hosts to the backend in this syntax
<host>:<port> seperated by commas e.g `php-fpm-container1:9000,php-fpm-container2:9000`

*You can also pass arguments to each server as defined in the [Nginx Upstream Documentation](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)*

| Parameter                   | Description                                                    | Default                                   |
| --------------------------- | -------------------------------------------------------------- | ----------------------------------------- |
| `PHP_APC_SHM_SIZE`          | APC Cache Memory size - `0` to disable                         | `128M`                                    |
| `PHP_FPM_HOST`              | Default PHP-FPM Host                                           | `127.0.0.1` - See above Container options |
| `PHP_FPM_LISTEN_PORT`       | PHP-FPM Listening Port - Ignored with above container options  | `9000`                                    |
| `PHP_FPM_MAX_CHILDREN`      | Maximum Children                                               | `75`                                      |
| `PHP_FPM_MAX_REQUESTS`      | How many requests before spawning new server                   | `500`                                     |
| `PHP_FPM_MAX_SPARE_SERVERS` | Maximum Spare Servers available                                | `3`                                       |
| `PHP_FPM_MIN_SPARE_SERVERS` | Minium Spare Servers avaialble                                 | `1`                                       |
| `PHP_FPM_PROCESS_MANAGER`   | How to handle processes `static`, `ondemand`, `dynamic`        | `dynamic`                                 |
| `PHP_FPM_START_SERVERS`     | How many FPM servers to start initially                        | `2`                                       |
| `PHP_LOG_FILE`              | Logfile name                                                   | `php-fpm.log`                             |
| `PHP_LOG_LEVEL`             | PHP Log Level                                                  | `notice`                                  |
| `PHP_LOG_LOCATION`          | Log Location for PHP Logs                                      | `/www/logs/php-fpm`                       |
| `PHP_MEMORY_LIMIT`          | How much memory should PHP use                                 | `128M`                                    |
| `PHP_OPCACHE_MEM_SIZE`      | OPCache Memory Size - Set `0` to disable or via other env vars | `128`                                     |
| `PHP_POST_MAX_SIZE`         | Maximum Input Size for POST                                    | `2G`                                      |
| `PHP_TIMEOUT`               | Maximum Script execution Time                                  | `180`                                     |
| `PHP_UPLOAD_MAX_SIZE`       | Maximum Input Size for Uploads                                 | `2G`                                      |
| `PHP_WEBROOT`               | Used with `CONTAINER_MODE=php-fpm`                             | `/www/html`                               |

#### Enabling / Disabling Specific Extensions

Enable extensions by using the PHP extension name ie redis as `PHP_ENABLE_REDIS=TRUE`. Core extensions are enabled by default are:

| Parameter              | Default     |
| ---------------------- | --------- |
| `PHP_ENABLE_APCU`      | `TRUE` |
| `PHP_ENABLE_BCMATH`    | `TRUE` |
| `PHP_ENABLE_BZ2`       | `TRUE` |
| `PHP_ENABLE_CTYPE`     | `TRUE` |
| `PHP_ENABLE_CURL`      | `TRUE` |
| `PHP_ENABLE_DOM`       | `TRUE` |
| `PHP_ENABLE_EXIF`      | `TRUE` |
| `PHP_ENABLE_FILEINFO`  | `TRUE` |
| `PHP_ENABLE_GD`        | `TRUE` |
| `PHP_ENABLE_ICONV`     | `TRUE` |
| `PHP_ENABLE_IMAP`      | `TRUE` |
| `PHP_ENABLE_INTL`      | `TRUE` |
| `PHP_ENABLE_JSON`      | `TRUE` |
| `PHP_ENABLE_MBSTRING`  | `TRUE` |
| `PHP_ENABLE_MYSQLI`    | `TRUE` |
| `PHP_ENABLE_MYSQLND`   | `TRUE` |
| `PHP_ENABLE_OPCACHE`   | `TRUE` |
| `PHP_ENABLE_PDO`       | `TRUE` |
| `PHP_ENABLE_PDO_MYSQL` | `TRUE` |
| `PHP_ENABLE_PGSQL`     | `TRUE` |
| `PHP_ENABLE_PHAR`      | `TRUE` |
| `PHP_ENABLE_SIMPLEXML` | `TRUE` |
| `PHP_ENABLE_TOKENIZER` | `TRUE` |
| `PHP_ENABLE_XML`       | `TRUE` |
| `PHP_ENABLE_XMLREADER` | `TRUE` |
| `PHP_ENABLE_XMLWRITER` | `TRUE` |

To enable all extensions in image use `PHP_KITCHENSINK=TRUE`. Head inside the image and see what extensions are available by typing `php-ext list all`

#### Debug Options
To enable XDebug set `PHP_ENABLE_XDEBUG=TRUE`. Visit the [PHP XDebug Documentation](https://xdebug.org/docs/all_settings#remote_connect_back) to understand what these options mean.

| Parameter                            | Description                                |
| ------------------------------------ | ------------------------------------------ |
| `PHP_XDEBUG_PROFILER_DIR`            | Where to store Profiler Logs               | `/www/logs/xdebug/` |
| `PHP_XDEBUG_PROFILER_ENABLE`         | Enable Profiler                            | `0`                 |
| `PHP_XDEBUG_PROFILER_ENABLE_TRIGGER` | Enable Profiler Trigger                    | `0`                 |
| `PHP_XDEBUG_REMOTE_AUTOSTART`        | Enable Autostarting as opposed to GET/POST | `1`                 |
| `PHP_XDEBUG_REMOTE_CONNECT_BACK`     | Enbable Connection Back                    | `0`                 |
| `PHP_XDEBUG_REMOTE_ENABLE`           | Enable Remote Debugging                    | `1`                 |
| `PHP_XDEBUG_REMOTE_HANDLER`          | XDebug Remote Handler                      | `dbgp`              |
| `PHP_XDEBUG_REMOTE_HOST`             | Set this to your IP Address                | `127.0.0.1`         |
| `PHP_XDEBUG_REMOTE_PORT`             | XDebug Remote Port                         | `9090`              |

* * *

### Networking

The following ports are exposed.

| Port   | Description |
| ------ | ----------- |
| `9000` | PHP-FPM     |


## Maintenance
Inside the image are tools to perform modification on how the image runs.

### Shell Access
For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g. nginx-php-fpm) bash
```
### PHP Extensions
If you want to enable or disable or list what PHP extensions are available, type `php-ext help`

### Maintenance Mode
If you wish to turn the web server into maintenance mode showing a single page screen outlining that the service is being worked on, you can also enter into the container and type `maintenance ARG`, where ARG is either `ON`,`OFF`, or `SLEEP (seconds)` which will temporarily place the site in maintenance mode and then restore it back to normal after time has passed.

## License
MIT. See [LICENSE](LICENSE)LICENSE for more details.
## References

* http://www.php.org
* https://xdebug.org
