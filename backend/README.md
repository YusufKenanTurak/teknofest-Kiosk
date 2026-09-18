# Teknofest Kiosk API / PostgreSQL

Kiosk uygulaması offline çalışmaya devam eder. Bu backend, oturum/cevap/sonuç
kalıcılığı, istatistik ve gözlemlenebilirlik içindir.

Kiosk UI, soru metinleri ve skor algoritması (`score-v1-endscan`) değişmez.
Ağ yoksa test yine çözülür; telemetri fire-and-forget gönderilir.

## Roller

| Rol | Amaç | Uygulama runtime? |
|---|---|---|
| `dev_admin` | CREATE DATABASE, migration, seed, index/constraint, GRANT | **Hayır** |
| `appuser` | SELECT katalog, INSERT/UPDATE oturum, INSERT cevap/sonuç/log | **Evet** |

`dev_admin` parolası API process'ine konmaz. Yalnızca `scripts/migrate.py`
ve `scripts/seed.py` `PG_ADMIN_PASSWORD` okur.

Sunucuda `appuser` şu an `pg_read_all_data` / `pg_write_all_data` predefined
rollerini inherit ediyor (cluster geneli). Bu roller tablo ACL'lerini aşar;
yani `DELETE FROM questions` bu kullanıcıyla teknik olarak mümkün olabilir.
Bu veritabanındaki GRANT'ler yine SELECT-only katalog ACL'si tanımlar.
`appuser` yalnızca bu uygulama içinse DBA şunları çalıştırmalıdır:

```sql
REVOKE pg_write_all_data FROM appuser;
REVOKE pg_read_all_data FROM appuser;
```

Sonra `003_grants.sql` yetkileri yeterli olur. DDL (`CREATE TABLE`,
`DROP DATABASE`) zaten kapalıdır.

## Environment

Kopyala: `.env.example` → `.env` (git'e girmez).

Runtime (`appuser`):

```
PG_HOST=10.6.228.154
PG_PORT=5432
PG_DATABASE=teknofestKiosk
PG_USER=appuser
PG_PASSWORD=...
APP_ENV=test
APP_VERSION=1.0.0
```

Migration:

```
PG_ADMIN_USER=dev_admin
PG_ADMIN_PASSWORD=...
```

## Migration

Database oluşturma ile schema uygulaması ayrıdır.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
$env:PG_ADMIN_PASSWORD="..."
$env:PG_PASSWORD="..."   # verify / pytest için appuser
python scripts/migrate.py
python scripts/seed.py
python scripts/verify.py
pytest
```

Dosyalar sırayla, `schema_migrations` ile versiyonlanır. Aynı dosya ikinci
kez çalışmaz. `DROP DATABASE` yoktur.

1. `001_init.sql` — tablolar, FK, CHECK, index, trigger
2. `002_stats_views.sql` — istatistik view'leri
3. `003_grants.sql` — `appuser` least privilege

Seed `db/seed/catalog.json` dosyasından 7 bölüm + 15 soru + 60 şık yazar.
`ON CONFLICT` ile idempotenttir.

## API

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

| Method | Path | Not |
|---|---|---|
| GET | `/health` | process |
| GET | `/health/db` | `SELECT 1`, hata olursa `connection_logs` |
| POST | `/api/v1/tests` | oturum başlat |
| POST | `/api/v1/tests/{id}/answers` | `X-Session-Token` |
| POST | `/api/v1/tests/{id}/complete` | 15 cevap + transaction |
| POST | `/api/v1/tests/{id}/abandon` | yarım bırakma |
| GET | `/api/v1/tests/{id}/result` | sonuç |
| GET | `/api/v1/questions` | katalog |
| GET | `/api/v1/statistics/overview` | `from`, `to` |
| GET | `/api/v1/statistics/departments` | alan dağılımı |
| GET | `/api/v1/statistics/questions` | şık / cevaplanmama |
| GET | `/api/v1/statistics/daily` | günlük |
| GET | `/api/v1/statistics/hourly` | saatlik |
| GET | `/api/v1/statistics/errors` | son 200 hata |
| GET | `/api/v1/statistics/versions` | sürüm |
| GET | `/api/v1/statistics/kiosks` | cihaz |

Her yanıtta `X-Correlation-ID` döner. İstemci gönderirse aynısı kullanılır.

İstatistik uçları kimlik doğrulaması yapmaz. Production'da yalnızca iç ağ /
reverse proxy ACL arkasında yayınlayın.

## Mimari

```
Controller (FastAPI routes)
    → TestService / StatsRepository
        → TestRepository / LogRepository
            → asyncpg pool (appuser)
                → PostgreSQL
```

Complete işlemi tek transaction içindedir: 15 cevap yoksa 409 ve rollback
(oturum `in_progress` kalır, `test_results` yazılmaz). Aynı soruya ikinci
cevap `ON CONFLICT DO NOTHING` (ilk cevap kazanır).

Skor, Flutter `ScoreEngine` ile aynıdır: her şık +1, eşitlikte sondan ilk
maksimum puanlı kod.

## ER

```
engineering_departments 1──* question_options *──1 questions
test_sessions 1──* test_answers *──1 questions
test_sessions 1──1 test_results *──1 engineering_departments
test_answers.selected_option_id → question_options.id
```

Log tabloları domain satırlarına FK tutmaz (oturum silinse bile audit kalır).
`session_id` / `correlation_id` ile izlenir.

## İstatistik

Önce normalize transactional tablolar; ağır dashboard için SQL view:

- `v_session_overview`
- `v_department_distribution`
- `v_question_option_stats`
- `v_question_unanswered`
- `v_daily_sessions`
- `v_hourly_sessions`
- `v_error_overview`

API date-range filtreleri view yerine parametreli aggregate kullanır.
İleride hacim artarsa materialized view veya gece job yeter; şu an gerekmez.

## Logging

| Tablo | Ne zaman |
|---|---|
| `application_events` | TEST_STARTED / QUESTION_ANSWERED / TEST_COMPLETED / TEST_ABANDONED |
| `application_logs` | `/api/*` yanıtları (API_RESPONSE) |
| `application_errors` | yakalanmayan exception |
| `connection_logs` | startup, health failure, reconnect — her query değil |

Password, token, Authorization, secret metadata'dan düşülür.

## Log retention

Kod içinde periyodik DELETE yoktur. Production önerisi:

1. `application_logs` / `application_errors` / `connection_logs` / `application_events` için `occurred_at` ile aylık RANGE partitioning
2. 90 gün (log) / 365 gün (events) sonra `DROP TABLE` partition
3. `pg_cron` veya harici job; uygulama process'ine cleanup koyulmaz

`test_sessions` / `test_answers` / `test_results` iş verisidir, log retention'a dahil edilmez.

## Kiosk

Boş `API_BASE_URL` = tamamen offline (varsayılan).

```
--dart-define=API_BASE_URL=https://kiosk-api.example.internal
--dart-define=KIOSK_ID=stand-1
```

Soru metinleri kiosk APK içinde kalır ki stand ağsız çalışsın. Katalog
değişince hem `lib/data/quiz_catalog.dart` hem `backend/db/seed/catalog.json`
güncellenip seed tekrar çalıştırılır.

## Production öncesi

- İstatistik API'yi internete açmayın
- `APP_ENV=production` (`/api/v1/__debug/boom` kapalı)
- SSL (`PG_SSLMODE`) sunucu sertifikasına göre
- `dev_admin` parolasını yalnızca migration host'unda tutun
- Log partition / retention job'unu bağlayın
- Connection string'i secret store'dan verin
