# Чек-лист верификации: 09-prompt-library

1. В целевом проекте существует `docs/prompts/library/PATTERNS.md` и
   `docs/prompts/library/` с шестью поддиректориями фаз (discover, design,
   build, ship, operate, automate). Существующий `docs/prompts/` (если был) не
   затёрт - меню кита лежит в отдельном `library/`.
2. Каждый файл-меню начинается с YAML frontmatter и содержит поля
   `id`, `phase`, `category`, `roles`. Быстрая проверка:
   `grep -L "^id:" docs/prompts/library/*/*.md` - выхлоп должен быть пустым.
3. `phase` в frontmatter совпадает с именем директории файла.
4. В AI_WORKFLOW.md целевого проекта есть секция-указатель на
   `docs/prompts/library/` и список слэш-команд (если AI_WORKFLOW.md нет -
   строка в CLAUDE.md).
5. Слэш-команды на месте: `ls .claude/commands/` показывает 11 файлов - spec.md,
   precommit.md, session-wrap.md, release-notes.md, security-scan.md,
   edge-cases.md, backlog.md, scope-triage.md, handoff.md, impl-plan.md,
   audit.md. Проверка, что Claude их видит: команда `/precommit` появляется в
   автодополнении или `/help`. Вызвать `/precommit` в чистом дереве - должен
   вернуть "нет изменений".
6. (Опционально) Дайджест использования запускается:
   `bash modules/09-prompt-library/usage-digest/usage-digest.sh` печатает отчёт.
7. Выборочно: открыть 2-3 промпта-меню, подставить слоты под целевой проект,
   отправить агенту - ответ осмысленный (промпт не ссылается на несуществующие
   в проекте вещи; если ссылается, например нет Sentry - промпт помечен
   соответствующим `needs`).
