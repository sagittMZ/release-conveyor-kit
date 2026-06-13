# Чек-лист верификации - модуль 7 smoke-e2e

Локально:

- [ ] В шаблонах не осталось TODO(kit).
- [ ] `npx playwright test` локально: setup зелёный (.auth/user.json создан),
      все смоук-сценарии проходят.
- [ ] Данные тестов имеют префикс E2E и исчезают после прогона/cleanup.
- [ ] tests/e2e/.gitignore закрывает .auth, отчёты, .env.test.

В CI:

- [ ] Секреты QA_* заведены; workflow E2E Smoke (workflow_dispatch) зелёный.
- [ ] prepare-job отработал (cleanup status 2xx в логе).
- [ ] Артефакт playwright-report скачивается и открывается.
- [ ] Повторный прогон попадает в кэш браузеров.
