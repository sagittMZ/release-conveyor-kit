# Release Conveyor Kit (v0)

Поставляемый релизный конвейер для стека React/TS + Vite + Capacitor + Supabase +
Vercel + GitHub Actions + Codemagic. Применяется AI-агентом владельца проекта к
уже существующему приложению. Донор паттернов - работающий пайплайн the donor project.

ТЗ: [TZ.md](TZ.md). Опись донора: [AUDIT.md](AUDIT.md).
Состояние: [PROGRESS.md](PROGRESS.md).
Объяснения "что/как/зачем" на разных уровнях + сценарий "есть только идея":
[docs/EXPLAIN.md](docs/EXPLAIN.md).

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
| 9 | [prompt-library](modules/09-prompt-library/) | Библиотека стартовых промптов владельцу: 6 паттернов + 21 промпт по фазам + 13 слэш-команд. Стеко-независимый - применим к ЛЮБОМУ проекту |
| 10 | coverage-matrix | Матрица покрытия автотестами. Зарезервирован, см. [BACKLOG.md](BACKLOG.md) |
| 11 | [command-evals](modules/11-command-evals/) | Измеримое качество команд: структурные проверки + LLM-судья. Стеко-независимый |
| 12 | [memory-consolidation](modules/12-memory-consolidation/) | Консолидация памяти в ревьюабельные инсайты (файловый аналог Dreaming). Стеко-независимый |

Стеко-независимый слой (09 + 11 + 12) и как им пользоваться - в
[docs/prompt-kit-guide.md](docs/prompt-kit-guide.md) (юзергайд + витрина).

## Применение (кратко)

1. Скопировать `conveyor.config.example.json` в корень целевого проекта как
   `conveyor.config.json`, заполнить.
2. Дать агенту промпт из `modules/08-agent-layer/` - он применит модули 1-7 и 9
   по конфигу и прогонит верификацию.
3. Каждый модуль самостоятелен: можно применять по одному, в каждом README -
   список нужных секретов и чек-лист верификации.

## Секреты

Сводная карта всех секретов конвейера (что, где хранится, какому модулю
нужно) - в [modules/06-secrets/README.md](modules/06-secrets/README.md).
В репозитории кита и целевого проекта - только плейсхолдеры.

## Что остаётся руками (владелец)

Создание аккаунтов и оплаты (Google Play $25, Apple Developer $99/год,
Codemagic, Sentry), ввод секретов в GitHub/Codemagic/Vercel, кнопки в
консолях сторов и Submit на ревью, алерт-правила в Sentry UI. На каждый
такой шаг модули выдают короткую нумерованную инструкцию.

## Что взято из донора, а что добавлено китом

Каждый README модуля содержит раздел "Происхождение": что извлечено из
работающего the donor project (проверено), а что добавлено китом (помечено
"не проверено" до прогона Этапа 1). Сводно - в [AUDIT.md](AUDIT.md).
