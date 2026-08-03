# Раскатка блока А в проект (ТЗ для сессии проекта)

Полное внедрение стеко-независимого слоя кита (модули **09 + 11 + 12**) в целевой
проект. Исполняется агентом в сессии САМОГО проекта - он берёт исходники из кита
и интегрирует их ОРГАНИЧНО, по конвенциям проекта, а не «кусками кита».

Путь к киту на машине: `$KIT`

**Что входит и почему только это:**
- 09 (команды + меню), 11 (evals), 12 (консолидация памяти) - стеко-независимы.
- 01-08 - релизный пайплайн под React/Vite/Supabase, к другим стекам не едут.
- 10 (coverage-matrix) - не построен, только в бэклоге. Раскатывать нечего.

Вставь промпт ниже в сессию проекта.

## Промпт раскатки (любой стек)

```
Внедри в этот проект стеко-независимый слой релиз-кита (модули 09+11+12) из:
$KIT

Цель: проект должен стать САМОДОСТАТОЧНЫМ и ОРГАНИЧНЫМ - никаких «кусков кита»,
всё лежит по конвенциям проекта. Ничего из прикладного кода не трогай. Покажи
git diff и жди моего слова перед коммитом.

KIT=$KIT

1. КОМАНДЫ (13) -> .claude/commands/ РЕАЛЬНЫМИ файлами (не симлинки на кит):
   скопируй $KIT/modules/09-prompt-library/commands/*.md.
   Список: spec, precommit, session-wrap, release-notes, security-scan,
   edge-cases, backlog, scope-triage, handoff, impl-plan, audit, eval-command,
   consolidate-memory.

2. МЕНЮ-БИБЛИОТЕКА -> docs/prompts/library/ этого проекта:
   скопируй $KIT/modules/09-prompt-library/PATTERNS.md и .../library/.
   ИДЕМПОТЕНТНОСТЬ: если docs/prompts/ уже занят (напр. большими PROMPT_*.md) -
   НЕ затирай, клади меню в отдельный docs/prompts/library/, только мержь.

3. ГАЙД -> docs/prompt-kit-guide.md: скопируй $KIT/docs/prompt-kit-guide.md
   (то же относительное место, что и в ките).

4. ТУЛИНГ (харнесс evals/консолидации) -> tools/prompt-kit/ ВЕНДОРИНГОМ:
   tools/prompt-kit/
     lib-transcripts.sh            <- $KIT/modules/09-prompt-library/usage-digest/lib-transcripts.sh
     usage-digest.sh               <- $KIT/modules/09-prompt-library/usage-digest/usage-digest.sh
     command-evals/                <- всё из $KIT/modules/11-command-evals/
       (eval.sh, expectations.tsv, RUBRIC.md, cases/, judge/)
     memory-consolidation/         <- consolidate.sh, DISTILL_RUBRIC.md из $KIT/modules/12-memory-consolidation/
     PROVENANCE                    <- запиши: "vendored from release-conveyor-kit @ <git -C $KIT rev-parse HEAD>, <дата>"

5. ПОДГОНИ ПУТИ в двух скопированных мета-командах (.claude/commands/):
   в eval-command.md и consolidate-memory.md замени префиксы путей харнесса:
     modules/11-command-evals/      -> tools/prompt-kit/command-evals/
     modules/12-memory-consolidation/ -> tools/prompt-kit/memory-consolidation/
   (Скрипты сами находят корень проекта через git и lib рядом с собой - править
   их не надо, только ссылки в текстах команд.)

6. ПРОВОДКА -> секция в AI_WORKFLOW.md проекта (по иерархии - именно там, не в
   CLAUDE.md; если AI_WORKFLOW.md нет - строку в CLAUDE.md):
   "Prompt-kit слой: гайд docs/prompt-kit-guide.md; меню docs/prompts/library/
   (начни с PATTERNS.md); тулинг tools/prompt-kit/. Слэш-команды: /spec /precommit
   /session-wrap /release-notes /security-scan /edge-cases /backlog /scope-triage
   /handoff /impl-plan /audit /eval-command /consolidate-memory."

7. GITIGNORE (публикуемость): добавь в .gitignore проекта, если ещё нет:
   docs/evals/
   docs/consolidation/
   (docs/evals/ - карточки evals, приватно и регенерируемо. Сырьё консолидации
   по умолчанию пишется ВНЕ дерева, в <claude-config>/projects/<enc>/consolidation/
   (база: CLAUDE_CONFIG_DIR, иначе ~/.claude - едино на всех платформах);
   строка docs/consolidation/ - страховка на случай CONSOLIDATE_OUT_DIR-override.)

8. БЛОК Б -> BACKLOG проекта (план масштабирования, НЕ реализовывать):
   - Multi-agent оркестрация (координатор + параллельные sub-agents) - под широкие
     декомпозируемые задачи (аудиты, research). Условие: появление таких задач.
   - Облачные Managed Agents + Dreaming-as-service + hosted-evals - при
     деньгах+масштабе и потребности в unattended-агентах.
   (Первоисточник: $KIT/docs/analysis-agentic-patterns-2026-07-08.md.)

9. ВЕРИФИКАЦИЯ (прогони и покажи результат):
   - bash tools/prompt-kit/command-evals/eval.sh --all  -> должно быть 100%
     (харнесс сам читает .claude/commands этого проекта);
   - bash tools/prompt-kit/memory-consolidation/consolidate.sh --days 7  ->
     создаёт material-<дата>.md в <claude-config>/projects/<enc>/consolidation/
     (путь печатает сам скрипт) без ошибок, В ДЕРЕВЕ проекта файл не появляется;
   - git status  -> чист от артефактов evals/консолидации (docs/evals/ скрыт
     gitignore-ом, сырьё консолидации физически вне дерева);
   - чек-листы: $KIT/modules/09-prompt-library/checklist.md,
     $KIT/modules/11-command-evals/checklist.md,
     $KIT/modules/12-memory-consolidation/checklist.md.

10. ОТЧЁТ: что скопировано куда, результат верификации, что ушло в BACKLOG.
    Стеко-специфичные команды оставь как есть (security-scan сам определит
    Supabase; release-notes работает с любым git). Команде, которой в этом
    проекте нечего делать, - отметь в отчёте, не удаляй. Жди моего слова перед
    коммитом.
```

## Заметки по конкретным проектам

- **project-alpha (Python):** первый эталон раскатки. Модули 1-8 кита не
  применяются (стек вне скоупа). Полезны все 13 команд; /eval-command особенно -
  если будешь править/добавлять свои команды. Есть .ai/ - команды подхватят роли.
- **project-beta (Next.js + Supabase):** блок А целиком; позже можно добавить
  релизные модули (CI, secrets, monitoring). ВНИМАНИЕ: PHI в gitignore -
  security-scan уместен; consolidate.sh читает MEMORY.md/.ai/, его сырьё по
  умолчанию пишется вне git-дерева (приватная зона Claude-конфига),
  строка docs/consolidation/ в .gitignore - обязательная страховка.
- **donor-project:** позже, после двух других (донор кита, трогать осторожно).

## После раскатки

- Через неделю-две - `tools/prompt-kit/usage-digest.sh`: что реально пошло в дело.
- Обновление кита -> проекта: сравни PROVENANCE-коммит с текущим китом, перенеси
  нужные правки (вендоринг, не submodule - проект владеет своей копией).
- Схема выше одинакова для всех проектов - это и есть «та же схема» раскатки.
