# Чек-лист верификации - модуль 2 mobile-build

Локально / статически:

- [ ] YAML обоих шаблонов валиден.
- [ ] android/app/build.gradle содержит appVersionCode/appVersionName паттерн.
- [ ] .gitignore закрывает google-services.json и keystore (см. модуль 6).
- [ ] Все секреты из README заведены в GitHub (Settings -> Secrets).

В CI:

- [ ] workflow_dispatch прогона Android Build зелёный, артефакты .aab и .apk
      появились в прогоне.
- [ ] versionCode в собранном AAB = run_number (видно в логе gradle).
- [ ] (Если Firebase включён) сборка пришла тестерам группы.

Codemagic (ручной шаг, без Mac недоступно локально):

- [ ] ios-bootstrap прогнан, ios-project.zip скачан, ios/ закоммичен.
- [ ] Unsigned compile check зелёный.
- [ ] ios-testflight - НЕ верифицируется до выполнения модуля 3 (подпись).
