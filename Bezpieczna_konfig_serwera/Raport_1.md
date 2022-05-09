<p align="center">
    <img width="20%" src="..\..\Logo\logo-pwr.png">
    <h1 align="center">Bezpieczna konfiguracja serwera webowego - zadanie 1</h1>
    <h3 align="center">Bezpieczeństwo aplikacji webowych (projekt)</h3>
    <h3 align="center">piątek 8:15</h3>
</p>

---

Wykonano raport bezpiecznej konfiguracji serwera webowego. Uwzględniono w nim konfigurację dla serwerów Nginx oraz Apache. Zadanie wykonano w oparciu o środowisko Docker. W [Readme](../Bezpieczna_konfig_serwera/infrastructure/Readme.md) opublikowano instrukcję uruchomienia serwerów Nginx i Apache z DockerFile.

## Generowanie certyfikatu self-signed oraz konfiguracja HTTPS

Przy pomocy narzędzia `openssl` jesteśmy w stanie wygenerować certyfikat self-signed do wykorzystania na naszym serwerze.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -sha256 -keyout certs/server.key -out certs/server.crt \
    -subj "/C=PL/ST=Dolnoslaskie/L=Wroclaw/O=PWR/OU=W4N/CN=ad.baw/emailAddress=admin@ad.baw"
```

Parametry:

- `req` - moduł do wygenerowania certyfikatów
- `-x509` - generowanie certyfikatu (bez certificate request)
- `-nodes` - zabronienie szyfrowania klucza prywatnego
- `-days 365` - konfiguracja daty ważności certyfikatu
- `-newkey rsa:2048` - generowanie klucza prywatnego RSA o długości 2048 bitów
- `-sha256` - zdefiniowanie algorytmu hashowania sha256
- `-keyout` - ścieżka do pliku z kluczem
- `-out` - ścieżka do pliku z certyfikatem
- `-subj` - określenie szczegółów podmiotu wystawiającego certyfikat

![cert](\infrastructure\Images\cert_generation.PNG)

### Podstawowa konfiguracja serwera HTTP - Nginx

Plik konfiguracyjny `nginx.conf` zawiera podstawowe informacje o serwerze oraz obsługiwanych protokołach:

```conf
worker_processes    auto;
error_log   /var/log/nginx/error.log;

events {
    worker_connections    1024;
}

http {
    access_log   /var/log/nginx/access.log;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;

        server_name     ad.baw localhost;

        include    /etc/nginx/ssl.conf;
        
        include    /etc/nginx/locations.conf;

    }
}
```

W porównaniu do domyślnej konfiguracji Nginx zmieniono nazwę domeny na `ad.baw` oraz zaimporotwano w osobnych plikach konfiguracje dla certyfikatu SSL `ssl.conf` oraz zasady dla ścieżek, wymaganych w zadaniu 1 - `locations.conf`. Domena `ad.baw` będzie dostępna na porcie `80` i `443`.

W pliku `ssl.conf` umieszczono informację o wygenerowanym wcześniej certyfikacie i kluczu prywatnym:

```conf
ssl_certificate     server.crt;
ssl_certificate_key     server.key;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
```

Określono wspierane protokoły TLS w wersji `1.0`, `1.1` i `1.2`.

### Apache

Apache posiada domyślny plik konfiguracyjny nazwany `httpd.conf`. Apache przechowuje domyślnie pliki konfiguracyjne w `/usr/local/apache2`. W ramach konfiguracji, uporządkowano plik, usuwając z niego komentarze oraz dodano odniesienie do dwóch osobnych plików konfiguracyjnych - `httpd-ssl.conf` dla konfiguracji protokołu HTTPS oraz `httpd-http` dla konfiguracji HTTP.

```conf
ServerRoot "/usr/local/apache2"

LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
LoadModule filter_module modules/mod_filter.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule env_module modules/mod_env.so
LoadModule headers_module modules/mod_headers.so
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
LoadModule dir_module modules/mod_dir.so
LoadModule alias_module modules/mod_alias.so
LoadModule rewrite_module modules/mod_rewrite.so

ServerAdmin you@example.com
ServerName ad.baw

<IfModule unixd_module>
    User www-data
    Group www-data
</IfModule>

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "/usr/local/apache2/htdocs"
<Directory "/usr/local/apache2/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

DirectoryIndex index.html

<Files ".ht*">
    Require all denied
</Files>

ErrorLog /proc/self/fd/2
LogLevel warn

LogFormat "%t %h \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common

CustomLog /proc/self/fd/1 combined

# HTTP
Include conf/extra/httpd-http.conf

# Secure (SSL/TLS) connections
Include conf/extra/httpd-ssl.conf
```

Plik `httpd-ssl.conf` wymaga do działania SSL poniższych modułów:

- mod_log_config
- mod_setenvif
- mod_ssl
- socache_shmcb_module

Zawartość pliku `httpd-ssl.conf`:

```
Listen 443

<VirtualHost *:443>
    DocumentRoot "/usr/local/apache2/htdocs"

    SSLEngine on
    SSLCertificateFile "/usr/local/apache2/conf/server.crt"
    SSLCertificateKeyFile "/usr/local/apache2/conf/server.key"
    SSLProtocol all -SSLv3

    LogFormat "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined-ssl
    CustomLog /proc/self/fd/1 \
            combined-ssl
</VirtualHost>                                  
```

W pliku zdefiniowano ścieżki certyfikatu oraz klucza, a także wsparcie TLS w wersjach 1.0, 1.1 oraz 1.2.

## Konfiguracja ścieżki /http-only i jej podścieżek do obsługiwania tylko HTTP

### Nginx

Do pliku `locations.conf` dodajemy wpis:

```conf
location /http-only {
    if ($scheme = https) {
        return 301 http://$server_name$request_uri;
    }
    alias    /usr/share/nginx/html/;
}
```

Przy pomocy warunku `if` zdefiniowano, czy klient łączy się z naszą stroną przy pomocy protokołu HTTP/HTTPS. W przypadku, gdy klient połączy się z HTTPS, zostanie on  przekierowany na HTTP. Ścieżka wykorzystuje domyślny plik `index.html`, znajdujący się w `/usr/share/nginx/html/`.

Poprawność konfiguracji widać po wykonaniu `curl`:

```bash
$ curl -k -I https://localhost/http-only
HTTP/2 301
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 16:42:38 GMT
Content-type: text/html
Content-length: 169
Location: http://ad.baw/http-only
```

### Apache

W konfiguracji `httpd-ssl.conf` dodano wpis:

```
<Location /http-only>
    Redirect permanent "http://%{HTTP_HOST}%{REQUEST_URI}"
</Location>
```

Umożliwia to przekierowanie zapytań po HTTPS na HTTP.

Następnie, do pliku `httpd-http.conf` dodano wpis, definiujący naszą ścieżkę:

```
AliasMatch ^/http-only\/*(.*) /usr/local/apache2/htdocs/index.html
```

Potem ustawiono reguły przekierowywania, z pomocą dokumentacji [Apache](https://httpd.apache.org/docs/2.2/mod/mod_rewrite.html#rewriteflags), dzięki której zdefiniowano flagi, umożliwiające wykluczenie ścieżki `/http-only` w dalszych przekierowaniach.


```
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/http-only/? [NC]
RewriteCond %{HTTPS} off
RewriteRule ^. https://%{HTTP_HOST}%{REQUEST_URI} [QSA,L]
```

Poprawność konfiguracji widać po wykonaniu `curl`:

```bash
$ curl -k -I https://localhost/http-only
HTTP/1.1 301 Moved Permanently
Date: Fri, 29 Apr 2022 18:53:12 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Location: http://localhost/http-only
Content-Type: text/html; charset=iso-8859-1
```

## Konfiguracja ścieżki /https-only i jej podścieżek do obsługiwania tylko HTTPS

### Nginx

W pliku `locations.conf` umieszczono zapis:

```conf
location /https-only {
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }
    alias    /usr/share/nginx/html/;
}
```
Podobnie jak w przypadku reguły dla `/http-only`, powstała reguła, weryfikująca warunek w `if` - czy klient połączył się po HTTP. Gdy zostanie odnotowane połączenie HTTP na ścieżkę  `/https-only`, wykonywane jest przekierowanie klienta na HTTPs. Ścieżka wykorzystuje domyślny plik `index.html` z folderu `/usr/share/nginx/html/`.

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I http://localhost/https-only
HTTP/1.1 301 Moved Permanently
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 16:53:43 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://ad.baw/https-only
```

### Apache

W pliku `httpd-http.conf` umieszczono wpis:
```
<Location /https-only>
    Redirect permanent "https://%{HTTP_HOST}%{REQUEST_URI}"
</Location>
```
Podobnie jak w przypadku przekierowań z HTTPS na HTTP, powyższy zapis pozwala przekierować zapytanie po HTTP na HTTPS.

Wykorzytano pomoc z tego [linku](https://www.sslshopper.com/apache-redirect-http-to-https.html)
    

Następnie w pliku `httpd-ssl.conf` dodano:

```
AliasMatch ^/https-only\/*(.*) /usr/local/apache2/htdocs/index.html
```

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I http://localhost/https-only
HTTP/1.1 302 Found
Date: Fri, 29 Apr 2022 19:01:27 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Location: https://localhost/https-only
Content-Type: text/html; charset=iso-8859-1
```

## Konfiguracja ścieżki /http-https i jej podścieżek do obsługiwania zarówno HTTP, jak i HTTPS

### Nginx

W pliku `locations.conf` umieszczono wpis:

```
location /http-https {
    alias    /usr/share/nginx/html/;
}
```

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I https://localhost/http-https/
HTTP/2 200
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 17:12:23 GMT
Content-type: text/html
Content-length: 615
Last-modified: Thu, 27 Jan 2022 16:03:52 GMT
Etag: "53g02138-654"
Accept-ranges: bytes

$ curl -k -I http://localhost/http-https/
HTTP/1.1 200 OK
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 17:12:34 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Thu, 27 Jan 2022 16:03:52 GMT
Connection: keep-alive
ETag: "53g02138-654"
Accept-Ranges: bytes
```

### Apache

W obu plikach konfiguracyjnych `httpd-http.conf` oraz `httpd-ssl.conf` umieszczono wpis:
```
AliasMatch ^/http-https\/*(.*) /usr/local/apache2/htdocs/index.html
```

Powyższy zapis definiuje publikacje pliku `/usr/local/apache2/htdocs/index.html` na ścieżce `/http-https`.

Dodatkowo, w pliku `httpd-http.conf` dodano warunek `RewriteCond`:

```
RewriteCond %{REQUEST_URI} !^/http-https/? [NC]
```

Powyższy zapis pozwala zignorować ścieżkę `/http-https` przy wcześniej zdefiniowanym wymuszaniu przekierowań z HTTP na HTTPS.

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I https://localhost/http-https
HTTP/1.1 200 OK
Date: Fri, 29 Apr 2022 19:15:37 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Last-Modified: Mon, 11 Jun 2007 18:53:14 GMT
ETag: "3c-563b2c4a82c44"
Accept-Ranges: bytes
Content-Length: 45
Content-Type: text/html

$ curl -k -I http://localhost/http-https
HTTP/1.1 200 OK
Date: Fri, 29 Apr 2022 19:15:45 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Last-Modified: Mon, 11 Jun 2007 18:53:14 GMT
ETag: "3c-563b2c4a82c44"
Accept-Ranges: bytes
Content-Length: 45
Content-Type: text/html
```

##  Konfiguracja przekierowań z HTTP na HTTPS dla pozostałych ścieżek

### Nginx

W `locations.conf` umieszczono:

```
location / {
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }
    alias    /usr/share/nginx/html/;
    try_files $uri $uri/ /index.html;
}
```

Dla wszystkich ścieżek, poza zdefiniowanymi wcześniej w pliku, zostało ustawione przekierowanie z HTTP na HTTPS.

Dodatkowo, jeśli w folderze `/usr/share/nginx/html/` nie bedzie pliku z nazwą, odpowiadającej ścieżce, to wykorzystany zostanie plik `index.html`.

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I http://localhost/baw
HTTP/1.1 301 Moved Permanently
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 17:34:12 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://ad.baw/baw

$ curl -k -I http://localhost/baw/ubaw
HTTP/1.1 301 Moved Permanently
Server: nginx/1.21.6
Date: Fri, 29 Apr 2022 17:35:02 GMT
Content-Type: text/html
Content-Length: 169
Connection: keep-alive
Location: https://ad.baw/baw/ubaw
```

### Apache

Na końcu pliku konfiguracyjnego wirtualnego hosta w pliku `httpd-ssl.conf` dodano alias:
```
AliasMatch ^/\/*(.*) /usr/local/apache2/htdocs/index.html
```

Wyżej określone wyrażenie regularne dopasowuje każdą ścieżkę, nie wliczając zdefiniowanych wcześniej ścieżek na potrzeby zadania do pliku `/usr/local/apache2/htdocs/index.html`.

Wykorzystano wcześniej określoną regułę przekierowującą w pliku `httpd-http.conf`:

```
RewriteCond %{HTTPS} off
RewriteRule ^. https://%{HTTP_HOST}%{REQUEST_URI} [QSA,L]
```

Reguła dopasuje każdą ścieżkę, dla zapytań, nie spełniających warunków dla wcześniej zdefiniowanych reguł na potrzeby zadania. Wykona się przekierowanie z HTTP na HTTPS, tylko dla połączeń HTTP. W przypadku HTTPS wykorzystany zostanie alias zdefiniowany wyżej.

Poprawność konfiguracji widać po wykonaniu `curl`:

```
$ curl -k -I http://localhost/baw
HTTP/1.1 302 Found
Date: Fri, 29 Apr 2022 19:27:17 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Location: https://localhost/baw
Content-Type: text/html; charset=iso-8859-1

$ curl -k -I http://localhost/baw/ubaw
HTTP/1.1 302 Found
Date: Fri, 29 Apr 2022 19:28:27 GMT
Server: Apache/2.4.53 (Unix) OpenSSL/1.1.1n
Location: https://localhost/baw/ubaw
Content-Type: text/html; charset=iso-8859-1
```
