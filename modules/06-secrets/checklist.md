# Verification checklist - module 06 secrets

- [ ] After copying .env.local, `git status` shows no env files.
- [ ] `git ls-files | grep -E '\.env$|\.env\.local|\.jks|google-services\.json|GoogleService-Info\.plist'` is empty.
- [ ] .env.example covers every import.meta.env.* variable used in src/.
- [ ] The Secret Scan workflow is green on a clean repo.
- [ ] Negative test: add a file with a fake AWS-format key (AKIA plus 16
      characters) to a branch - gitleaks fails; then delete the test commit.
- [ ] .env.example and the kit's templates do not trigger the scan (the
      allowlist works).
