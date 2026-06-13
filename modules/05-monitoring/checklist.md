# Чек-лист верификации - модуль 5 monitoring

- [ ] `npm run build` проходит после правок vite.config/main.tsx.
- [ ] В прод-сборке (vite preview --mode production c заданным VITE_SENTRY_DSN)
      вызвать тестовую ошибку, например временной кнопкой
      `throw new Error('sentry-test')` - событие видно в Sentry в течение минуты.
- [ ] У события заполнен release (= версия из package.json) и environment.
- [ ] В dev-режиме события НЕ уходят (enabled: PROD only).
- [ ] (Если sourcemaps) стектрейс в Sentry показывает исходники, а не минифицированный код.
- [ ] Health Check workflow: ручной запуск зелёный; при подмене URL на
      несуществующий - красный (+ Telegram-сообщение, если настроено).
- [ ] Алерт-правило в Sentry создано (ручной шаг владельца).
