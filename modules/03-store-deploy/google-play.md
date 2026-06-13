# Google Play - пошаговый сценарий публикации

Источник: проверенный процесс the donor project (Google Play пройден). Все значения -
плейсхолдеры, подставлять из conveyor.config.json (mobile.android.appId и т.д.).

Роли: "Владелец" - человек (аккаунты, оплаты, кнопки в консолях),
"Агент" - AI-агент (файлы в репо, секреты-инструкции, проверки).

## Шаг 1 - Upload key (Владелец, одноразово)

Upload key не равен signing key: при включённом Play App Signing Google
переподписывает AAB своим ключом, upload key нужен только для загрузки.

```bash
keytool -genkey -v \
  -keystore <app>-upload-key.jks \
  -alias <app>-upload \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

- Все пароли - случайные, сразу в менеджер паролей (keystore-файл - вложением).
- Убедиться, что `*.jks` в .gitignore (модуль 6).
- После добавления в секреты - удалить файл с машины.

## Шаг 2 - Секреты GitHub Actions (Владелец)

Settings -> Secrets and variables -> Actions:

| Секрет | Откуда |
|---|---|
| ANDROID_KEYSTORE_BASE64 | `base64 -w0 <app>-upload-key.jks` |
| ANDROID_KEYSTORE_PASSWORD | store password |
| ANDROID_KEY_ALIAS | alias |
| ANDROID_KEY_PASSWORD | key password |

## Шаг 3 - Play Console: создать приложение (Владелец)

1. [play.google.com/console](https://play.google.com/console) -> Create app
   (имя, язык, тип App, Free; аккаунт разработчика - $25 одноразово).
2. Setup -> App integrity -> App signing: Play App Signing включён по
   умолчанию - не менять.
3. Скопировать SHA-256 fingerprint из "App signing key certificate" и
   передать агенту.

## Шаг 4 - assetlinks.json для App Links (Агент)

Если у приложения есть deep links: `public/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "<mobile.android.appId>",
    "sha256_cert_fingerprints": [
      "<SHA256_OF_UPLOAD_KEY>",
      "<SHA256_FROM_PLAY_CONSOLE>"
    ]
  }
}]
```

Заголовок Content-Type для Vercel уже в vercel.json-паттерне кита (модуль 1
README корня / донор). Проверка: `curl https://<домен>/.well-known/assetlinks.json`.

## Шаг 5 - Store listing (Владелец, агент помогает текстами)

| Asset | Требования |
|---|---|
| App icon | 512x512 PNG, БЕЗ прозрачности |
| Feature graphic | 1024x500 PNG/JPG |
| Скриншоты | мин. 2 (лучше 4-8), 16:9 или 9:16, 320-3840 px |
| Название | до 30 символов |
| Краткое описание | до 80 символов |
| Полное описание | до 4000 символов |

## Шаг 6 - Privacy Policy (Владелец + Агент)

Обязательна. Сгенерировать (например, app-privacy-policy-generator.nisrulz.com),
разместить статикой на своём домене (`/privacy`), URL указать в консоли.

## Шаг 7 - Data Safety form (Владелец, агент готовит ответы)

ДОБАВЛЕНО КИТОМ (в чек-листе донора шаг был пройден в консоли без конспекта):
Play Console -> App content -> Data safety. Для стека кита типовые ответы:

- Collected: email + имя (Account info), user content (задачи/данные приложения),
  device IDs если есть push (FCM token).
- Shared: обычно "No" (Supabase/Sentry - service providers, не "sharing"
  в терминах Google, если данные не продаются).
- Encrypted in transit: Yes (HTTPS). Deletion mechanism: обязателен -
  нужна страница/флоу удаления аккаунта.
- Если есть Sentry: указать сбор crash logs / diagnostics.

## Шаг 8 - Тестовый аккаунт для ревьюера (Владелец)

Создать выделенный аккаунт в production-базе с демо-данными. В Play Console ->
App access -> "All or some functionality is restricted" -> приложить инструкцию:

```
This app uses email/password login. No Google account required.
1. Open the app
2. Tap "Sign In"
3. Email: <reviewer email>
4. Password: <reviewer password>
```

Креды ревьюера - НЕ в репозиторий, только в консоль и менеджер паролей.

## Шаг 9 - Первая сборка и Internal Testing

1. Actions -> Android Build & Distribute -> Run workflow (модуль 2).
2. Скачать артефакт app-release-signed.aab.
3. Play Console -> Testing -> Internal testing -> Create new release ->
   загрузить AAB, добавить тестеров по email.
4. Прогнать основной флоу + deep links + push на реальном устройстве.

## Шаг 10 - Production

Internal -> Closed -> (Open) -> Production; на каждом переходе - release notes.
Ревью Google: обычно 1-3 дня. Каждый релиз требует большего versionCode
(в ките это github.run_number - растёт сам).

## Опция: автозагрузка AAB в Play Console из CI

Шаблон templates/play-upload-step.yml (Google Play Developer API).
ДОБАВЛЕНО КИТОМ, в доноре НЕ использовалось (там загрузка руками + Firebase
App Distribution для QA). Требует:

1. Service account в Google Cloud + JSON-ключ.
2. Play Console -> Users and permissions -> пригласить service account
   с правом "Release to testing tracks".
3. Секрет PLAY_SERVICE_ACCOUNT_JSON.
4. Минимум один релиз, загруженный РУКАМИ, прежде чем API начнёт работать -
   ограничение Google.

## Важное

- Потеря upload key - не катастрофа (Play App Signing выдаст новый);
  потеря Google-аккаунта - катастрофа: 2FA + backup-коды обязательно.
- versionName = package.json, versionCode = run_number (модуль 2).
