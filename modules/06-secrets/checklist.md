# Чек-лист верификации - модуль 6 secrets

- [ ] `git status` после копирования .env.local не показывает env-файлы.
- [ ] `git ls-files | grep -E '\.env$|\.env\.local|\.jks|google-services\.json|GoogleService-Info\.plist'` - пусто.
- [ ] .env.example покрывает все import.meta.env.* переменные из src/.
- [ ] Workflow Secret Scan зелёный на чистом репо.
- [ ] Негативный тест: добавить в ветку файл с фейковым ключом формата AWS
      (AKIA + 16 символов), gitleaks падает; удалить тестовый коммит.
- [ ] .env.example и шаблоны кита не триггерят скан (allowlist работает).
