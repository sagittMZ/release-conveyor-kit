# Модуль 7 - smoke-e2e

Минимальный Playwright-smoke: 7 сценариев (запуск, сессия, навигация,
create/edit/delete основной сущности, logout) как шаблон с TODO-метками.

## Происхождение

- **Из работающего the donor project (проверено):** playwright.config (таймауты,
  storageState, webServer, blob/html-репортеры), auth.setup через Supabase
  REST (без UI - быстрее и стабильнее), паттерны спеков, кэш браузеров по
  версии Playwright, отключённый автотриггер ради минут Actions.
- **Изменено китом:** суита урезана с ~22 спеков до smoke-ядра; 1 шард вместо
  2 (blob-merge machinery донора не нужна); сценарии CRUD - обобщённые
  заготовки с TODO(kit), их селекторы ОБЯЗАН адаптировать применяющий агент.

## Файлы (всё в tests/e2e/ целевого проекта)

| Файл | Куда |
|---|---|
| templates/playwright.config.ts | tests/e2e/playwright.config.ts |
| templates/tests/auth.setup.ts | tests/e2e/tests/auth.setup.ts |
| templates/tests/smoke.spec.ts | tests/e2e/tests/smoke.spec.ts |
| templates/package.json | tests/e2e/package.json |
| templates/.env.test.example | tests/e2e/.env.test.example |
| templates/e2e.yml | .github/workflows/e2e.yml |

Плюс tests/e2e/.gitignore: `.auth/`, `playwright-report/`, `test-results/`,
`.env.test`, `node_modules/`.

## Зависимости от других модулей

- Модуль 4 (staging): QA-аккаунт + RPC cleanup_e2e_data (prepare-job в e2e.yml
  вызывает её; если модуль 4 не применён - удалить job prepare и needs).
- Секреты: QA_TEST_EMAIL, QA_TEST_PASSWORD, VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY.

## Применение (для агента)

1. Создать tests/e2e/ как самостоятельный пакет, `npm i` внутри,
   `npx playwright install chromium` (Playwright 1.5x также требует
   chromium-headless-shell - ставится тем же вызовом в CI через --with-deps).
2. ОБЯЗАТЕЛЬНО исключить tests/e2e из vitest, иначе unit-job CI падает на
   playwright-спеках (урок самопроверки кита): в vite.config.ts -
   `import { defineConfig } from 'vitest/config'` и
   `test: { exclude: ['node_modules', 'dist', 'tests/e2e/**/*'] }`
   (паттерн донора).
3. Пройти ВСЕ TODO(kit) в auth.setup.ts и smoke.spec.ts: главный
   авторизованный роут, публичный элемент лендинга, 2-4 навигационных роута,
   селекторы CRUD главной сущности. Детект: роуты из react-router конфига,
   сущность - главная пользовательская таблица.
4. Если в UI нет data-testid - добавить их точечно (create/delete кнопки,
   title input) - это инфраструктурная правка, разрешена с согласия владельца.
5. Mobile-first приложение: переключить проект на Pixel 5 (закомментированный
   блок в конфиге - паттерн донора).
6. Локальный прогон: `cd tests/e2e && npx playwright test` (dev-сервер
   поднимется сам через webServer).

## Чек-лист верификации

См. [checklist.md](checklist.md).
