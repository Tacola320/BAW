<p align="center">
    <img width="20%" src="..\Logo\logo-pwr.png">
    <h1 align="center">Bezpieczna konfiguracja serwera webowego - zadanie 3</h1>
    <h3 align="center">Bezpieczeństwo aplikacji webowych (projekt)</h3>
    <h3 align="center">piątek 8:15</h3>
</p>

---

Wykonano raport bezpiecznej konfiguracji serwera webowego. Uwzględniono w nim konfigurację dla serwerów Nginx oraz Apache. Zadanie wykonano w oparciu o środowisko Docker. W [Readme](../Bezpieczna_konfig_serwera/infrastructure/Readme.md) opublikowano instrukcję uruchomienia serwerów Nginx i Apache z DockerFile.

## Limitowanie liczby zapytań (`rate limitting`)

Aby ograniczyć liczbę zapytań na serwer WWW należy zaimplementować `rate limitting`. Limity zapytań zostały ustawione globalnie dla wybranej ścieżki `/limit-a` - 100 zapytań na minutę jest globalnie możliwych do wykonania. Dodatkowo ustawiono 10 zapytań na minutę dla danego user-agenta.

### Nginx

W przypadku Nginx nie potrzeba instalowania dodatkowych modułów, aby `rate-limitting` ustawić. W pliku `rate-limitting.conf` ustawiono zmienną globalną (100 zapytań na minutę dla każdej podstrony) oraz lokalną (10 zapytań na minutę dla User-Agent `xx-agent`).

```bash
map $http_user_agent $ua_const_map {
    default     "";
    xx-agent   $binary_remote_addr;
}

limit_req_zone $binary_remote_addr zone=global_limit:10m rate=100r/m;

limit_req_zone $ua_const_map zone=local_limit:10m rate=10r/m;
```

Plik konfiguracyjny `rate-limitting.conf` włączono do głównego pliku konfiguracyjnego `nginx.conf`.

Do DockerFile dodano linię, dołączającą nowy plik konfiguracyjny.

### Apache

W porównaniu do Nginx, `rate-limitting` w Apache był zdecydowanie trudniejszy do implementacji. Potrzebna była instalacja dodatkowych modułów `mod_security`.

Do plików konfiguracyjnych należało uwzględnić nowo powstałe pliki konfiguracyjne `mod_security`, w tym plik konfiguracyjny `modsecurity.conf`, który definiuje bazowe działanie modułu.

Następnie utworzono plik konfiguracyjny  `modsecurity_global_rule.conf`, który definiuje globalny `rate-limitting`(100 zapytań na minutę dla każdej podstrony). Status zgodnie ze standardem ustawiono na `429` ("Too Many Requests"). Pola `id` oraz `msg` można dowolnie modyfikować. Określony `rate-limiting` ustawia się przy zmiennej `SecRule IP:RATE_LIMIT` oraz w `expirevar:ip.rate_limit` (ta zmienna definiuję co ile sekund spada limit)

```bash
SecAction "id:99000, log, pass, setuid:%{tx.ua_hash}, initcol:ip=%{REMOTE_ADDR}, setvar:ip.rate_limit=+1, expirevar:ip.rate_limit=60"
SecRule IP:RATE_LIMIT "@gt 100" \
    "id:99001, deny, status:429, log, msg:'Too many requests in a given amount of time!'"
```

W pliku `httpd.conf` dodano linie wgrywające moduł oraz uwzględniające jego pliki konfiguracyjne:
```bash
# Part 3 - add module modsecurity
LoadModule ratelimit_module modules/mod_ratelimit.so
LoadModule unique_id_module modules/mod_unique_id.so
LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so

...

# Rate limitting 
Include "/etc/modsecurity/modsecurity.conf"
Include "/etc/modsecurity/crs/crs-setup.conf"
```

W pliku `httpd-http.conf` dodano linie uwzględniające plik konfiguracyjny `modsecurity_global_rule.conf`, co pozwala uwzględniać ją przy odwiedzaniu ścieżek.

```bash
# Part 3 - global rate-limitting
Include "/etc/modsecurity/modsecurity_global_rule.conf"
```

Dla lokalnego `rate-limitting` na ścieżcę `\limit-a` utworzono regułę w pliku `httpd-ssl.conf`. Wykrywa ona User-Agent `xx-agent`, a następnie jeśli on przekroczy 10 zapytań na minutę, użytkownik otrzymuje w odpowiedzi kod `429`. Jeśli nie - zostanie on przekierowany na stronę główną.

```bash
<Location /limit-a>
        SecRule REQUEST_HEADERS:User-Agent "@streq xx-agent" \
            "id:99008, phase:2, log, pass, setuid:%{tx.ua_hash}, setvar:user.useragent_matched=+1, expirevar:user.useragent_matched=60"
        SecRule USER:USERAGENT_MATCHED "@gt 10" \
            "chain, phase:2, id:99009, deny, status:429, log, msg:'Request blocked for specific User-Agent'" 
            SecRule REQUEST_HEADERS:User-Agent "@streq xx-agent"
        ErrorDocument 429 "Too many requests in a given amount of time!"
        ErrorDocument 200 'Accessing website\n'
        Redirect 200 /
    </Location>
```

Nowo powstałe pliki konfiguracyjne oraz instalację `mod_security` uwzględniono w DockerFile.

## Weryfikacja działania ustawień `rate limitting`

W tym celu wykorzystano skrypt `wrk`, który został udostępniony na [Githubie](https://github.com/wg/wrk).
Wysyła on zapytania GET i zestawia statystyki odpowiedzi strony.

```bash
./wrk -H "User-Agent: xx-agent" -t 1 -d 60 https://localhost/limit-a/
```
gdzie:
 - `-t` - liczba wątków
 - `-d ` - czas trwania w sekundach
 - `-H` - nagłówek


### Nginx

Zweryfikowano działanie reguł `rate limitting` dla ścieżki `limit-a`.

Reguła lokalna - `xx-agent` jako User-Agent:
![lok](/Bezpieczna_konfig_serwera/infrastructure/Images/limit-a-useragent-nginx.PNG)

Uzyskano łącznie 218810 żądań, z czego 218800 zwracały status inny niż `2XX` lub `3XX`. 10 żądań pomyślnie nawiązało kontakt z serwerem, a pozostała reszta została odrzucona. Reguła zadziałała zgodnie z konfiguracją.

Reguła globalna - zmieniono User-Agent na `xx-agent_other`:

![glob](/Bezpieczna_konfig_serwera/infrastructure/Images/limit-a-nginx.PNG)

Uzyskano łącznie 280009 żądań, z czego 279909 zwracały status inny niż `2XX` lub `3XX`. 100 żądań pomyślnie nawiązało kontakt z serwerem, a pozostała reszta została odrzucona. Reguła zadziałała zgodnie z konfiguracją.

### Apache

Zweryfikowano działanie reguł `rate limitting` dla ścieżki `limit-a`.

Reguła lokalna - `xx-agent` jako User-Agent:
![loka](/Bezpieczna_konfig_serwera/infrastructure/Images/limit-a-useragent-apache.PNG)

Uzyskano łącznie 48253 żądań, z czego 48243 zwracały status inny niż `2XX` lub `3XX`. 10 żądań pomyślnie nawiązało kontakt z serwerem, a pozostała reszta została odrzucona. Reguła zadziałała zgodnie z konfiguracją.

Reguła globalna - zmieniono User-Agent na `xx-agent_other`:

![globa](/Bezpieczna_konfig_serwera/infrastructure/Images/limit-a-apache.PNG)

Uzyskano łącznie 86807 żądań, z czego 86707 zwracały status inny niż `2XX` lub `3XX`. 100 żądań pomyślnie nawiązało kontakt z serwerem, a pozostała reszta została odrzucona. Reguła zadziałała zgodnie z konfiguracją.
