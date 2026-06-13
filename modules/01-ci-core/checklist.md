# Чек-лист верификации - модуль 1 ci-core

Локально (до пуша):

- [ ] YAML валиден: `node -e "require('js-yaml')"` недоступен - достаточно
      `npx --yes yaml-lint .github/workflows/ci.yml` или `actionlint` если установлен.
- [ ] `npm run lint` проходит локально.
- [ ] `npx vitest run` проходит локально (или job unit отключён с TODO).
- [ ] `npm run build` проходит локально.

В CI (после пуша ветки/PR):

- [ ] Workflow "CI" запустился на PR.
- [ ] Все три job (Lint, Unit tests, Build) зелёные.
- [ ] В summary прогона виден отчёт "N/N tests passed".
- [ ] Повторный прогон использует кэш npm (шаг setup-node: "Cache restored").
- [ ] (Опционально) В Settings -> Branches добавить required status checks:
      Lint, Unit tests (Vitest), Build.
