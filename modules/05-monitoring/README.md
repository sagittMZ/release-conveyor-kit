# Модуль 5 - monitoring

Sentry (ошибки + release-теги + sourcemaps) и периодический health-чек прода.

Это единственный модуль, которому разрешено трогать прикладной код - строго
по шаблону: импорт + вызов `initSentry()` в main.tsx (исключение из принципа
4 ТЗ, оговорено там же).

## Происхождение

- **Из работающего the donor project (проверено):** templates/sentry.ts - init c
  enabled-только-в-PROD, tracesSampleRate 0.1, редакцией apikey в breadcrumbs;
  Telegram-алерт паттерн.
- **Добавлено китом (НЕ проверено в доноре, гэпы найдены аудитом):**
  - define VITE_APP_VERSION в vite.config (в доноре release-тег был пустым);
  - sourcemaps upload через @sentry/vite-plugin;
  - templates/health-check.yml (cron-пинг web + Supabase REST).

## Файлы

| Файл | Куда |
|---|---|
| templates/sentry.ts | src/shared/lib/sentry.ts (путь подогнать под проект) |
| templates/vite-sentry.snippet.ts | вмержить в vite.config.ts (2 блока, второй опционален) |
| templates/health-check.yml | .github/workflows/health-check.yml |

## Применение (для агента)

1. `npm i @sentry/react` (+ `npm i -D @sentry/vite-plugin` для sourcemaps).
2. Положить sentry.ts; в src/main.tsx добавить две строки СТРОГО по шаблону:
   `import { initSentry } from '<путь>/sentry'` и `initSentry();` до рендера.
   Идемпотентность: если Sentry.init уже есть где-то - не дублировать,
   только сверить паттерн (enabled, release, beforeSend).
3. Вмержить define-блок в vite.config.ts.
4. ErrorBoundary: если в приложении его нет - предложить Sentry.ErrorBoundary
   вокруг корня (опционально, записать в отчёт).
5. VITE_SENTRY_DSN добавить в .env.example (модуль 6) и в env прод-сборок
   (Vercel env, секреты Android-workflow, Codemagic group).

## Настройка Sentry (Владелец, в UI - агент не может)

1. sentry.io -> создать проект (react). DSN -> в env/секреты.
2. Алерты: Alerts -> Create Alert -> "Issues": new issue в production ->
   email/Telegram-интеграция. Рекомендуемый минимум: алерт на новые ошибки
   и на всплеск (>10 событий/час).
3. Для sourcemaps: Settings -> Auth Tokens -> токен со scope project:releases
   -> секрет SENTRY_AUTH_TOKEN (в CI, НЕ с префиксом VITE_).

## Требуемые секреты/env

| Имя | Где |
|---|---|
| VITE_SENTRY_DSN | Vercel env + GH secrets + Codemagic group |
| SENTRY_AUTH_TOKEN | GH secrets (только если sourcemaps) |
| TELEGRAM_BOT_TOKEN_REPORTS, TELEGRAM_CHAT_ID_REPORTS | опционально, алерт health-чека |

## Чек-лист верификации

См. [checklist.md](checklist.md). Ключевая проверка из критериев ТЗ:
Sentry ловит тестовую ошибку.
