# Logstash Forwarder Container

This project puts [Logstash Forwarder](https://github.com/elastic/logstash-forwarder) in scratch docker container. It is available on [Docker Hub](https://registry.hub.docker.com/u/alectolytic/logstash-forwarder/) and can be pulled using the following command.

```sh
docker pull alectolytic/logstash-forwarder
```

You will note that this is a tiny image.
```
$ docker images | grep docker.io/alectolytic/logstash-forwarder
docker.io/alectolytic/logstash-forwarder    latest    7170f359d1f7    2 hours ago    4.205 MB
```

## Quickstart Example

In this example we will capture the logs from an httpd container and forward it to a local running logstash container.

#### Generate OpenSSL keys for logstash lumberjack plugin

```sh
openssl req -x509  -batch -nodes -newkey rsa:2048 -keyout lumberjack.key -out lumberjack.crt -subj /CN=logstash
```

**NOTE:**
- The `CN` value is the server name of the logstash server. Here, we make use of docker links to name the server as `logstash`.
- If running on an SELinux enabled system, run `chcon -Rt svirt_sandbox_file_t /path/to/lumberjack.*` before using these files.

#### Start logstash

```sh
docker run -d --name logstash \
  logstash \
  -v `pwd`/lumberjack.key:/lumberjack.key \
  -v `pwd`/lumberjack.crt:/lumberjack.crt \
  logstash \
  logstash -e 'input { lumberjack { port => 12345 ssl_certificate => "/lumberjack.crt" ssl_key => "/lumberjack.key" } } output { stdout { } }'
```

#### Start logstash-forwarder

The following configuration file was used in this example.

```json
{
  "network": {
    "servers": [ "logstash:12345" ],
    "ssl ca": "/lumberjack.crt",
    "timeout": 15
  },
  "files": [
    {
      "paths": [
        "/var/log/httpd/*_log"
      ],
      "fields": { "type": "apache" }
    }
  ]
}
```

Once the created, fix SELinux lables by running:

```sh
chcon -Rt svirt_sandbox_file_t /path/to/logstash-forwarder.conf
```

The container can be started as follows. In this scenario, we use the above configuration file, configure the use of the generated crt file as the `ssl ca`, linked the running logstash instance to be availabled with the hostname `logstash` and mount volumes from the running httpd container. Note that TLS authentication is not used but can be enabled.

```sh
docker run --rm -it \
  -v `pwd`/logstash-forwarder.conf:/logstash-forwarder.conf \
  -v `pwd`/lumberjack.crt:/lumberjack.crt \
  --volumes-from httpd \
  --link logstash:logstash \
  alectolytic/logstash-forwarder
```

#### Start httpd container

Note the `local/httpd` is a Fedora 22 container running httpd.

```sh
docker run -d --name httpd local/httpd
```
