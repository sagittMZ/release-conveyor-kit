# App Store / TestFlight - пошаговый сценарий

Источник: процесс the donor project (волны A-C). Статус честно: волна A проверена в
доноре, волны B-C в доноре были В РАБОТЕ на момент извлечения - сценарий
собран из плейбука донора и документации Codemagic, помечен "не проверено".

Ограничение, под которое построен процесс: Mac НЕ нужен вообще -
вся сборка и подпись в облаке Codemagic.

## Волна A - подготовка кода (Агент, без Apple Developer) - ПРОВЕРЕНО в доноре

- [ ] Блок `ios` в capacitor.config.ts (contentInset: 'never',
      backgroundColor под сплэш - см. паттерн донора в AUDIT.md).
- [ ] Платформо-зависимые вызовы (StatusBar и т.п.) - только под Android-гардом.
- [ ] `public/.well-known/apple-app-site-association` + Content-Type заголовок
      в vercel.json - скопируй шаблон кита
      `modules/03-store-deploy/templates/vercel.json` в корень проекта (или
      вмержь его секции headers/rewrites в существующий). Содержимое AASA
      (для universal links):

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAM_ID>.<mobile.ios.bundleId>",
      "paths": ["*"]
    }]
  }
}
```

- [ ] .gitignore: GoogleService-Info.plist (модуль 6).
- [ ] codemagic.yaml из модуля 2 в корне репо.

## Волна B - Apple Developer + Codemagic (Владелец) - НЕ проверено в доноре

### Apple Developer Portal ($99/год)

1. Оформить Apple Developer Program.
2. Identifiers -> App ID = bundleId из конфига; capabilities (Push и т.д.).
3. Если push: APNs Auth Key (.p8) - скачать ОДИН раз, в менеджер паролей.

### Codemagic

1. Подключить репозиторий, создать env group "ios" (переменные из модуля 2).
2. Teams -> Integrations -> Developer Portal: подключить App Store Connect
   API key (Issuer ID, Key ID, .p8) - это интеграция `app_store_connect`.
3. Прогнать workflow `ios-bootstrap`: скачать ios-project.zip, закоммитить ios/.
4. Доделать в ios/ (агент): Info.plist usage descriptions (camera, mic,
   location - что использует приложение), URL schemes, capabilities.
5. Заменить TODO-шаги в `ios-testflight` на штатные команды Codemagic CLI:

```yaml
      - name: Set up code signing
        script: |
          keychain initialize
          app-store-connect fetch-signing-files "$BUNDLE_ID" \
            --type IOS_APP_STORE --create
          keychain add-certificates
          xcode-project use-profiles
      - name: Build IPA
        script: |
          xcode-project build-ipa \
            --project "$XCODE_PROJECT" \
            --scheme "$XCODE_SCHEME"
```

6. Раскомментировать блоки `integrations` + `publishing` (submit_to_testflight).

## Волна C - App Store Connect (Владелец) - НЕ проверено в доноре

1. App record (имя, bundleId, SKU).
2. Privacy Policy URL + Support URL.
3. Privacy Nutrition Labels (аналог Data Safety - см. google-play.md шаг 7,
   набор данных тот же).
4. Скриншоты (6.7" обязательно; единый набор допустим).
5. App Review notes + демо-аккаунт ревьюера (НЕ в репо).
6. Export compliance: для HTTPS-only обычно "No".
7. TestFlight: internal group -> установка по invite -> closed beta.
8. Submit for Review.

## Чего агент НЕ делает сам

Оплаты, создание аккаунтов, скачивание .p8/.plist, нажатие Submit -
только человек. Агент готовит файлы, тексты, конфиги и проверяет их.
