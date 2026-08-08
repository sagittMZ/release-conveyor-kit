# Verification checklist - module 04 staging

Variant B:

- [ ] The QA account(s) exist and can log in through the app's UI.
- [ ] The cleanup_e2e_data migration applied without errors.
- [ ] Under a QA account the RPC deletes only prefixed data and only the
      caller's own: create an "E2E test" record, call the RPC, the record is
      gone; other users' data is intact.
- [ ] Under an ordinary (non-qa) account the RPC returns an error (the guard
      works).
- [ ] anon without a JWT cannot call the RPC.
- [ ] The QA_* secrets exist in GitHub.
- [ ] Analytics (if any) receives no events when VITE_CI=true.

Variant A:

- [ ] The staging project-ref responds, the migrations are applied, and its anon
      key is separate.
- [ ] The Vercel preview environment points at staging and production points at
      prod.
