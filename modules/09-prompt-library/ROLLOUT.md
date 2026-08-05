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
KIT_STAMP="release-conveyor-kit@$(git -C $KIT rev-parse --short HEAD) $(date +%F)"

0. ПРОВЕНАНС (сквозное правило): каждый копируемый артефакт получает штамп
   $KIT_STAMP - иначе при 3+ проектах копии разъедутся без шанса это заметить.
   Как штамповать - в шагах ниже; сверка потом: tools/prompt-kit/check-provenance.sh.

1. КОМАНДЫ (14) -> .claude/commands/ РЕАЛЬНЫМИ файлами (не симлинки на кит):
   скопируй $KIT/modules/09-prompt-library/commands/*.md.
   Список: spec, precommit, session-wrap, release-notes, security-scan,
   edge-cases, backlog, scope-triage, handoff, impl-plan, audit, eval-command,
   consolidate-memory, arch-viz.
   В каждый скопированный файл добавь во frontmatter (после description:)
   строку:  provenance: $KIT_STAMP

2. МЕНЮ-БИБЛИОТЕКА -> docs/prompts/library/ этого проекта:
   скопируй $KIT/modules/09-prompt-library/PATTERNS.md и .../library/.
   ИДЕМПОТЕНТНОСТЬ: если docs/prompts/ уже занят (напр. большими PROMPT_*.md) -
   НЕ затирай, клади меню в отдельный docs/prompts/library/, только мержь.
   В PATTERNS.md и каждый файл library/ добавь ПЕРВОЙ строкой:
   <!-- provenance: $KIT_STAMP -->

3. ГАЙД -> docs/prompt-kit-guide.md: скопируй $KIT/docs/prompt-kit-guide.md
   (то же относительное место, что и в ките) и добавь первой строкой тот же
   <!-- provenance: $KIT_STAMP -->

4. ТУЛИНГ (харнесс evals/консолидации) -> tools/prompt-kit/ ВЕНДОРИНГОМ:
   tools/prompt-kit/
     lib-transcripts.sh            <- $KIT/modules/09-prompt-library/usage-digest/lib-transcripts.sh
     usage-digest.sh               <- $KIT/modules/09-prompt-library/usage-digest/usage-digest.sh
     command-evals/                <- всё из $KIT/modules/11-command-evals/
       (eval.sh, expectations.tsv, RUBRIC.md, cases/, judge/)
     memory-consolidation/         <- consolidate.sh, DISTILL_RUBRIC.md из $KIT/modules/12-memory-consolidation/
     arch-viz/                     <- template.html, build-arch-viz.sh, freshness-hook.sh, README.md, checklist.md из $KIT/modules/13-arch-viz/
     check-provenance.sh           <- $KIT/modules/09-prompt-library/check-provenance.sh
     PROVENANCE                    <- две строки:
                                      vendored from $KIT_STAMP
                                      kit path: $KIT

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
   /handoff /impl-plan /audit /eval-command /consolidate-memory /arch-viz."

7. GITIGNORE (публикуемость): добавь в .gitignore проекта, если ещё нет:
   docs/evals/
   docs/consolidation/
   (docs/evals/ - карточки evals, приватно и регенерируемо. Сырьё консолидации
   по умолчанию пишется ВНЕ дерева, в <claude-config>/projects/<enc>/consolidation/
   (база: CLAUDE_CONFIG_DIR, иначе ~/.claude - едино на всех платформах);
   строка docs/consolidation/ - страховка на случай CONSOLIDATE_OUT_DIR-override.)

7b. ARCH-VIZ WORKFLOW: скопируй $KIT/modules/13-arch-viz/templates/arch-viz.yml
   в .github/workflows/arch-viz.yml и подгони conveyor-маркеры: ветка main,
   путь builder-а (tools/prompt-kit/arch-viz/build-arch-viz.sh), пути исходников
   для staleness (напр. src/). Первичную генерацию данных сделай командой
   /arch-viz в сессии (LLM-шаг, не CI) и закоммить docs/arch/ вместе с раскаткой.
   АВТОТРИГГЕР (главный контур, без участия владельца): добавь в
   .claude/settings.json проекта (мержем, не затирая существующие hooks)
   hooks.UserPromptSubmit -> command:
   ARCHVIZ_SRC_PATHS="src/" bash tools/prompt-kit/arch-viz/freshness-hook.sh
   (пути = те же, что в workflow). Хук при устаревании сам ставит сессии
   задачу обновить визуализацию в текущем ходе; нудж не чаще раза в сутки.
   ЖЁСТКАЯ ГАРАНТИЯ СВЕЖЕСТИ (внешняя страховка, шаг владельца): положи в
   Settings -> Secrets and variables -> Actions три секрета -
   TELEGRAM_BOT_TOKEN (тот же бот), TELEGRAM_CHAT_ID (<telegram-chat-id>),
   TELEGRAM_THREAD_ID (топик ЭТОГО проекта в форум-группе). Тогда CI при
   устаревании визуализации шлёт пинг прямо в топик проекта (один раз на
   эпизод). Проверка связки: Run workflow с test_notify=true.

8. БЛОК Б -> BACKLOG проекта (план масштабирования, НЕ реализовывать):
   - Multi-agent оркестрация (координатор + параллельные sub-agents) - под широкие
     декомпозируемые задачи (аудиты, research). Условие: появление таких задач.
   - Облачные Managed Agents + Dreaming-as-service + hosted-evals - при
     деньгах+масштабе и потребности в unattended-агентах.
   (Первоисточник: $KIT/docs/analysis-agentic-patterns-2026-07-08.md.)

9. ВЕРИФИКАЦИЯ (прогони и покажи результат):
   - bash tools/prompt-kit/command-evals/eval.sh --all  -> слой 1 = 100% по
     13 командам кита (харнесс сам читает .claude/commands этого проекта);
     СВОИ команды проекта попадут в раздел «вне ожиданий» - это норма, не
     провал; чтобы включить их в скоринг, добавь им строки в
     tools/prompt-kit/command-evals/expectations.tsv. Строка «слой 2» честно
     скажет «не прогнан» - поведенческий прогон в целевом проекте по желанию
     (/eval-command --judge);
   - bash tools/prompt-kit/memory-consolidation/consolidate.sh --days 7  ->
     создаёт material-<дата>.md в <claude-config>/projects/<enc>/consolidation/
     (путь печатает сам скрипт) без ошибок, В ДЕРЕВЕ проекта файл не появляется;
   - git status  -> чист от артефактов evals/консолидации (docs/evals/ скрыт
     gitignore-ом, сырьё консолидации физически вне дерева);
   - bash tools/prompt-kit/check-provenance.sh --strict  -> все артефакты со
     штампом, дрейфа нет (свежая раскатка = на HEAD кита);
   - rtk --version отвечает (машинный уровень обвязки; если нет - поставить
     rtk ДО работы в проекте, см. ~/.claude/RTK.md);
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

## Агентная среда проекта - нулевая обвязка (решение the owner 2026-08-03, DECISIONS #9)

Кит - аккумулятор принятых наработок: КАЖДЫЙ проект (новый или существующий)
при обвязке получает весь принятый инфра-слой. Иначе находки теряются со
сменой повестки. Два уровня:

- **Проектный** (вендорится раскаткой в репо проекта): команды, меню, гайд,
  тулинг (шаги 1-9), принятые плагины - через enabledPlugins в
  `.claude/settings.json` проекта.
- **Машинный** (ставится один раз на машину, раскатка только ПРОВЕРЯЕТ):
  rtk (хук глобальный - новые проекты под ним автоматически), локальные
  клоны-пины плагинов.

Реестр обвязки на 2026-08-03:

| Компонент | Уровень | Статус |
|---|---|---|
| 13 команд + меню + гайд + evals + консолидация | проект | в обвязке (шаги 1-9) |
| rtk | машина | в обвязке: проверить `rtk --version` в шаге 9; если нет - установить до раскатки |
| ponytail (пин v4.8.4, bc9ee94) | проект + машина (клон `~/antigravity/vendor/ponytail`) | ПИЛОТ до ~2026-08-10; при вердикте «оставить» перенести шаг ниже в основной промпт |
| arch-viz (модуль 13) | проект (шаги 1, 4, 7b) | в обвязке: испытан на ките 2026-08-04 (браузерный смоук чистый, свой workflow) |

Вход нового компонента в обвязку - только через вердикт пилота/аудит (как у
ponytail), не через хайп. Принято = добавлено в реестр и в промпт раскатки.

**Шаг-заготовка PONYTAIL (активировать после вердикта Фазы 4):**

```
11. PONYTAIL (агентная дисциплина «минимум кода»):
    - машинный уровень: локальный клон-пин должен существовать -
      ~/antigravity/vendor/ponytail на теге v4.8.4 (аудит безопасности:
      project-alpha/docs/backlog/ponytail-pilot-plan.md, Результаты);
      если marketplace ещё не добавлен: claude plugin marketplace add ~/antigravity/vendor/ponytail
    - проектный уровень: claude plugin install ponytail@ponytail --scope project
      (пропишет enabledPlugins в .claude/settings.json проекта);
    - их statusline-хук НЕ ставить (ccgram парсит терминал);
    - режим: full для проектов с тестовой сеткой, lite для проектов без тестов.
```

## После раскатки

- Через неделю-две - `tools/prompt-kit/usage-digest.sh`: что реально пошло в дело.
- Обновление кита -> проекта: `bash tools/prompt-kit/check-provenance.sh` -
  покажет отставание штампов от HEAD кита и какие исходники изменились;
  перенеси нужные правки и обнови штампы (вендоринг, не submodule - проект
  владеет своей копией).
- Схема выше одинакова для всех проектов - это и есть «та же схема» раскатки.
