# Conveyor Kit - application report

Project: <name> | Date: <date> | Kit version: <git sha of kit checkout>
Branch/PR: <link>

## Applied and verified

| Module | What was added | Verification evidence |
|---|---|---|
| 01-ci-core | .github/workflows/ci.yml | PR run <link>: lint/unit/build green |

## Applied, NOT verified (and why)

| Module | Item | Why not verified |
|---|---|---|
| 02-mobile-build | codemagic.yaml | no Codemagic account connected yet |

## Manual steps for the owner (ordered)

1. Create GitHub secrets: <list> (module READMEs explain each).
2. ...

## Skipped

| Module | Reason |
|---|---|
| 03-store-deploy (iOS) | mobile.ios.enabled = false |

## Secrets inventory status

| Secret | Status (exists / owner must create) |
|---|---|
