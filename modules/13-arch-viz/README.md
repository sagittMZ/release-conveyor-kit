# Модуль 13 - arch-viz

Интерактивная визуализация архитектуры проекта: один самодостаточный HTML
(SVG + vanilla JS, тёмная тема, без внешних зависимостей и CDN). Человек за
10 секунд понимает структуру системы и прыгает к любому компоненту через
боковое меню.

Стеко-независим (как 09/11/12): работает для любого репозитория.

## Гибридная механика (решение the owner 2026-08-04)

Семантический анализ кода - LLM-работа, она бесплатна в сессии и платна в CI.
Поэтому:

1. **Данные** (`docs/arch/arch-data.json`) обновляет слэш-команда `/arch-viz`
   внутри сессии: глубокий анализ репо -> nodes/edges/flows.
2. **Сборка** детерминирована и бесплатна: `build-arch-viz.sh` инлайнит JSON в
   `template.html` -> самодостаточный `docs/arch/index.html`. Запускается
   командой сразу после обновления данных и в CI.
3. **CI** (`templates/arch-viz.yml`): при пуше в main пересобирает HTML из
   JSON (автокоммит только если HTML отстал от JSON; обычно no-op) и проверяет
   СВЕЖЕСТЬ: если исходники проекта менялись позже arch-data.json - пишет в
   summary «визуализация устарела, прогони /arch-viz». Ручной запуск -
   workflow_dispatch. В проектах с develop: авто на main, dispatch на develop.

## Схема данных (arch-data.json)

```json
{
  "meta":  { "project": "...", "updated": "YYYY-MM-DD", "commit": "sha7" },
  "groups": [ { "id": "layer-id", "label": "Слой/категория", "color": "#8fbfa3" } ],
  "nodes": [ { "id": "node-id", "label": "Имя", "group": "layer-id",
               "desc": "1-3 предложения ответственности",
               "files": ["path/one", "path/two"], "tech": ["bash", "SVG"] } ],
  "edges": [ { "from": "node-id", "to": "node-id", "label": "что течёт",
               "kind": "data|control|build" } ],
  "flows": [ { "id": "flow-id", "name": "Имя потока", "desc": "зачем",
               "steps": [ { "node": "node-id", "text": "что происходит" } ] } ]
}
```

Инварианты (builder проверяет, битое = exit 1): id уникальны; group каждой
ноды существует в groups; from/to каждого ребра и node каждого шага flow
существуют в nodes.

## Состав

| Файл | Что это |
|---|---|
| template.html | UI-шаблон: sidebar с поиском и сворачиванием, SVG-граф (pan/zoom/drag, позиции в localStorage), tooltips, карточки компонентов, панель flows с подсветкой пути и нумерацией шагов, легенда, тёмная тема, responsive. Плейсхолдер `__ARCH_DATA__` |
| build-arch-viz.sh | Детерминированная сборка: валидация инвариантов + инлайн JSON в шаблон -> docs/arch/index.html (python3 stdlib, без node) |
| templates/arch-viz.yml | GitHub Actions: rebuild на push в main + staleness-репорт + workflow_dispatch |
| checklist.md | Верификация (структурная + браузерный смоук) |
| команда /arch-viz | единый дом - modules/09-prompt-library/commands/arch-viz.md |

## Языки (решение the owner 2026-08-04)

Каноника - АНГЛИЙСКАЯ: docs/arch/arch-data.json (meta.lang: en) и
docs/arch/index.html - это часть портфолио и публичного репо. UI шаблона
двуязычный: словарь EN/RU внутри, переключается полем meta.lang данных.
Русская версия - личный слой владельца: arch-data.ru.json + index.ru.html,
в .gitignore, регенерируются по запросу
(`build-arch-viz.sh --data docs/arch/arch-data.ru.json --out docs/arch/index.ru.html`).

## Публикуемость

В данных - только то, что есть в самом репозитории. Никаких приватных путей
машины, имён других проектов и личных данных (правило зашито в команду;
для кита это условие паблика).

## Испытание (полигон - сам кит)

Статус: в работе с 2026-08-04. Данные кита -> docs/arch/index.html, браузерная
верификация по чек-листу, затем вход в реестр обвязки (ROLLOUT) и раскатка
в проекты по «го» the owner. Вердикт испытания фиксируется здесь.
