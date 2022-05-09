# Raporty

Raporty do zajęć znajdują się w plikach:
 - [Raport_1.md](../Raport_1.md)
 - [Raport_2.md](../Raport_2.md)
 - [Raport_3.md](../Raport_3.md)

# Instrukcja uruchomienia środowiska

## Nginx

Zbudowanie z dockerfile:

```bash
docker build -f Dockerfile-nginx -t bawnginx .
```

Uruchomienie kontenera Nginx z konfiguracja z folderów:

```bash
docker run -it --rm --name nginx -p 80:80 -p 443:443 \
    -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf -v $(pwd)/certs:/etc/nginx/ bawnginx
```

## Apache

Zbudowanie z dockerfile:

```bash
docker build -f Dockerfile-apache -t bawhttpd .
```

Uruchomienie kontenera Apache z konfiguracja z folderów:

```bash
docker run -it --rm --name apache -p 80:80 -p 443:443 \
    -v $(pwd)/apache/httpd.conf:/usr/local/apache2/conf/httpd.conf \
    -v $(pwd)/apache/httpd-ssl.conf:/usr/local/apache2/conf/extra/httpd-ssl.conf \
    -v $(pwd)/certs/cbe.local.crt:/usr/local/apache2/conf/server.crt \
    -v $(pwd)/certs/cbe.local.key:/usr/local/apache2/conf/server.key bawhttpd
```