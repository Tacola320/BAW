<p align="center">
    <img width="20%" src="..\Logo\logo-pwr.png">
    <h1 align="center">Bezpieczna konfiguracja serwera webowego - mini-projekt</h1>
    <h3 align="center">Bezpieczeństwo aplikacji webowych (projekt)</h3>
    <h3 align="center">piątek 8:15</h3>
</p>

---

## Polecenia

Proszę przygotować konfigurację dla serwera Apache ORAZ Nginx spełniające następujące kryteria:

- Zadanie 1:
    - Proszę wygenerować self-signed certyfikat oraz skonfigurować obsługę HTTPS
    - Ścieżka `/http-only` (wraz ze wszystkimi podścieżkami) ma działać wyłącznie w trybie HTTP (nieszyfrowanym)
    - Ścieżka `/https-only` (wraz ze wszystkimi podścieżkami) ma działać wyłącznie w trybie HTTPS (szyfrowanym)
    - Ścieżka `/http-https` (wraz ze wszystkimi podścieżkami) ma działać w oby trybach, HTTP i HTTPS
    - Wszystkie pozostałe ścieżki mają mieć automatyczne przekierowanie na tryb HTTPS, czyli np. kiedy przyjdzie zapytanie po HTTP dla `/inna-sciezka` ma zostać wykonane przekierowanie na wersję HTTPS dla tej samej ścieżki
- Zadanie 2: (kontynuacja zadania 1)
    - Proszę przygotować dwa certyfikaty klienckie dla certyfikatu serwera z Zadania 1 p.1 - User A, User B
    - Ścieżka `/only-user-a` (wraz ze wszystkimi podścieżkami) ma być dostępna wyłącznie dla klientów z certyfikatem User A
    - Ścieżka `/only-user-b` (wraz ze wszystkimi podścieżkami)  ma być dostępna wyłącznie dla klientów z certyfikatem User B
    - Ścieżka `/user-a-or-b` (wraz ze wszystkimi podścieżkami)  ma być dostępna wyłącznie dla klientów z certyfikatem User A lub User B
    - (punkt dodatkowy, nieobowiązkowy) Podścieżka `/info` dla ścieżek z p. 2,3,4 (czyli np. `/only-user-a/info`) wyświetli informacje o użytkowniku odczytane z jego certyfikatu klienckiego
- Zadanie 3: (kontynuacja zadań 1 i 2)
    - Proszę przygotować rozwiązanie zapewniające limitowanie liczby zapytań (`rate limitting`), tak aby
    - Dla wybranej ścieżki można było ustawić osobny globalny  (czyli niezależny od tego kto wykonuje zapytanie) limit
    - Limit można było zdefiniować dla danej ścieżki dla wszystkich zapytań, albo osobny limit dla zapytań z wybranym nagłówkiem HTTP (np. user agent). Np ścieżka `/limit-a` pozwala na 100 zapytań na minutę globalnie, ale tylko 10 zapytań na minutę dla danego user-agenta

Każde zadanie musi zostać wykonane w oparciu o środowisko Docker. Wynikiem zadania jest plik Dockerfile (względnie docker-compose) i wszystkie pliki konfiguracyjne, które powinny być dynamicznie załączone do kontenera Docker.

## Odnośniki do części projektu

- [Część 1](part1)
- [Część 2](part2)
- [Część 3](part3)
