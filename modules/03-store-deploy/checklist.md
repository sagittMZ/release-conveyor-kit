# Чек-лист верификации - модуль 3 store-deploy

Агентом (статически):

- [ ] google-play.md / app-store.md скопированы в docs/ целевого проекта,
      плейсхолдеры заменены значениями из conveyor.config.json.
- [ ] assetlinks.json / apple-app-site-association созданы (если есть deep links);
      vercel.json в корне проекта существует (из templates/vercel.json кита или
      вмержен) и отдаёт их с Content-Type application/json, SPA-rewrite их
      не перехватывает.
- [ ] В репо нет кредов ревьюера и реальных fingerprints до получения от владельца.
- [ ] (Если автозагрузка) play-upload-step.yml вмержен в android-build.yml,
      YAML валиден.

Владельцем (ручные шаги, агент только напоминает):

- [ ] Google Play: приложение создано, AAB прошёл Internal Testing.
- [ ] Data Safety form заполнена.
- [ ] (iOS) Apple Developer активен, ios-testflight доведён, сборка в TestFlight.

НЕ верифицируемо локально и в Actions: всё, что внутри Play Console /
App Store Connect / Codemagic - помечать в отчёте применения как "ручной шаг".
