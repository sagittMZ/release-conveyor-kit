# Модуль 6 - secrets

Гигиена секретов: .env-паттерн, .gitignore-набор, скан утечек в CI.

## Происхождение

- **Из работающего донора (проверено):** структура .env.example
  (Required / Optional с комментариями "где живут значения"), секретный
  поднабор .gitignore.
- **Добавлено китом (НЕ было в доноре):** gitleaks workflow + .gitleaks.toml.

## Файлы

| Файл | Куда |
|---|---|
| templates/.env.example | .env.example (дополнить переменными проекта) |
| templates/gitignore.snippet | вмержить в .gitignore (без дублей) |
| templates/gitleaks.yml | .github/workflows/gitleaks.yml |
| templates/.gitleaks.toml | .gitleaks.toml (корень) |

## Карта секретов конвейера (все модули, сводно)

| Секрет | Хранилище | Модуль |
|---|---|---|
| VITE_SUPABASE_URL / ANON_KEY | GH secrets + Vercel + Codemagic | 1,2,4,5 |
| ANDROID_KEYSTORE_BASE64 / _PASSWORD, ANDROID_KEY_ALIAS / _PASSWORD | GH secrets (+ keystore в менеджере паролей) | 2 |
| GOOGLE_SERVICES_JSON | GH secrets (если Firebase) | 2 |
| FIREBASE_APP_ID / FIREBASE_SERVICE_ACCOUNT | GH secrets (если App Distribution) | 2 |
| PLAY_SERVICE_ACCOUNT_JSON | GH secrets (если автозагрузка в Play) | 3 |
| APNs .p8, App Store Connect API key | менеджер паролей + Codemagic интеграция | 3 |
| QA_TEST_EMAIL / QA_TEST_PASSWORD (и доп. роли) | GH secrets | 4,7 |
| VITE_SENTRY_DSN | Vercel + GH + Codemagic | 5 |
| SENTRY_AUTH_TOKEN | GH secrets (без VITE_!) | 5 |
| TELEGRAM_BOT_TOKEN_REPORTS / TELEGRAM_CHAT_ID_REPORTS | GH secrets (опционально) | 5,7 |

Правила:

- Префикс VITE_ = значение попадает в клиентский бандл. Токены с правами
  записи (SENTRY_AUTH_TOKEN, service accounts) - НИКОГДА с VITE_.
- Anon key Supabase - публичный по дизайну (защита = RLS), но в репо не
  коммитится, чтобы не приучать к плохому.
- Service role key в CI и фронтенде не используется вообще (см. модуль 4 -
  очистка через RPC под JWT пользователя).

## Применение (для агента)

1. Вмержить gitignore.snippet; проверить, что уже закоммиченные секретные
   файлы не остались в индексе (`git ls-files | grep -E '\.env$|\.jks'`) -
   если остались, сообщить владельцу (нужна ротация, не просто удаление).
2. Создать/дополнить .env.example по фактическим переменным проекта
   (`grep -rh "import.meta.env" src/ | sort -u`).
3. Положить gitleaks.yml и .gitleaks.toml, прогнать gitleaks локально, если
   установлен: `gitleaks detect --source . -v`.
4. Если скан нашёл утечку в истории - НЕ переписывать историю автоматически:
   отчёт владельцу + ротация ключа.

## Чек-лист верификации

См. [checklist.md](checklist.md).
