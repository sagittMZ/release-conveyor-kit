# Модуль 2 - mobile-build

Мобильные сборки: Android (подписанный AAB+APK в GitHub Actions, по тегу v*)
и iOS (Codemagic, Capacitor 8 на SPM - без CocoaPods).

## Происхождение

- **Из работающего the donor project (проверено):** android-build.yml целиком
  (включая подпись через injected-параметры gradle и опциональную выгрузку в
  Firebase App Distribution); codemagic workflow `ios-bootstrap` (генерация
  ios/ + unsigned compile check); сниппет версионирования build.gradle.
- **Каркас, в доноре не доведён (НЕ проверено):** codemagic `ios-testflight` -
  подпись и publishing помечены TODO; завершение - по инструкции модуля 3.

## Файлы

| Файл | Куда кладётся |
|---|---|
| templates/android-build.yml | .github/workflows/android-build.yml |
| templates/codemagic.yaml | codemagic.yaml (корень проекта) |
| templates/build.gradle.snippet | вручную вмержить в android/app/build.gradle |

## Ключевые паттерны (зачем так)

- **versionCode = github.run_number** через `-PVERSION_CODE`: монотонный,
  без коммитов с bump-ами; локальные сборки получают fallback 1.
- **versionName из package.json** - единая версия web/Android.
- **Подпись через -Pandroid.injected.signing.\*** - keystore не лежит в репо
  и не требует signingConfig в build.gradle.
- **Capacitor 8 iOS = SPM:** собирать App.xcodeproj, НЕ искать App.xcworkspace.
- **ios/ коммитится в репо** (как android/): генерация через ios-bootstrap,
  артефакт ios-project.zip скачать и закоммитить.

## Предусловия в целевом проекте

1. `npx cap add android` выполнен, android/ закоммичен.
2. build.gradle читает VERSION_CODE (сниппет приложен).
3. Upload-keystore сгенерирован:
   `keytool -genkeypair -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <alias>`
   и закодирован: `base64 -w0 release.jks` -> в секрет.
4. Для iOS: аккаунт Codemagic, приложение подключено к репо, env group "ios".

## Требуемые секреты

GitHub Actions (Android):

| Секрет | Что это |
|---|---|
| VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY | env для web-сборки внутри AAB |
| ANDROID_KEYSTORE_BASE64 | base64 от release.jks |
| ANDROID_KEYSTORE_PASSWORD | пароль keystore |
| ANDROID_KEY_ALIAS | alias ключа |
| ANDROID_KEY_PASSWORD | пароль ключа |
| GOOGLE_SERVICES_JSON | base64 google-services.json (только если есть Firebase) |
| FIREBASE_APP_ID, FIREBASE_SERVICE_ACCOUNT | только если включена Firebase App Distribution |

Codemagic env group "ios": VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY и прочие
VITE_*, нужные сборке.

## Применение (для агента)

1. Проверить наличие android/ и Capacitor; если платформы нет - сначала
   `npx cap add android`, прогнать локальную debug-сборку нельзя без SDK -
   тогда пометить "проверка только в CI".
2. Вмержить сниппет версионирования в android/app/build.gradle (идемпотентно:
   если appVersionCode уже читается из property - не трогать).
3. Скопировать оба шаблона, заменить значения по маркерам `# conveyor:`.
4. Шаги Firebase (google-services.json, App Distribution) удалить, если
   проект не использует Firebase.
5. iOS: если mobile.ios.enabled = false в конфиге - codemagic.yaml не класть.

## Чек-лист верификации

См. [checklist.md](checklist.md).
