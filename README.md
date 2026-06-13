# Release Conveyor Kit (v0)

Поставляемый релизный конвейер для стека React/TS + Vite + Capacitor + Supabase +
Vercel + GitHub Actions + Codemagic. Применяется AI-агентом владельца проекта к
уже существующему приложению. Донор паттернов - работающий пайплайн the donor project.

ТЗ: [TZ.md](TZ.md). Опись донора: [AUDIT.md](AUDIT.md).
Состояние: [PROGRESS.md](PROGRESS.md).

## Модули

| # | Модуль | Что даёт |
|---|---|---|
| 1 | [ci-core](modules/01-ci-core/) | Lint + typecheck + unit + build на PR |
| 2 | [mobile-build](modules/02-mobile-build/) | Android AAB/APK (Actions) + iOS (Codemagic, Capacitor 8 SPM) |
| 3 | [store-deploy](modules/03-store-deploy/) | Google Play + TestFlight: автоматизация и пошаговые инструкции |
| 4 | [staging](modules/04-staging/) | Окружения для Supabase: второй проект или QA-аккаунты на free tier |
| 5 | [monitoring](modules/05-monitoring/) | Sentry: init, release-теги, sourcemaps, алерты; health-чек |
| 6 | [secrets](modules/06-secrets/) | .env-паттерны, .gitignore, gitleaks в CI |
| 7 | [smoke-e2e](modules/07-smoke-e2e/) | Playwright smoke (5-8 сценариев) как шаблон |
| 8 | [agent-layer](modules/08-agent-layer/) | Промпты применения: интервью -> детект -> применение -> верификация |

## Применение (кратко)

1. Скопировать `conveyor.config.example.json` в корень целевого проекта как
   `conveyor.config.json`, заполнить.
2. Дать агенту промпт из `modules/08-agent-layer/` - он применит модули 1-7
   по конфигу и прогонит верификацию.
3. Каждый модуль самостоятелен: можно применять по одному, в каждом README -
   список нужных секретов и чек-лист верификации.

README дополняется по мере извлечения модулей (см. PROGRESS.md).
