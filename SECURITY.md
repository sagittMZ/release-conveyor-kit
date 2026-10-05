# Security policy

## Supported versions

Only the latest tagged release receives fixes. Tags are listed on the
repository's releases page.

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Use GitHub's private reporting instead: open the **Security** tab of this
repository and choose **Report a vulnerability**. Include what you found, the
file or module it is in, and the steps to reproduce it.

This is a one-maintainer project, so replies are best effort and there is no
guaranteed response time. Once a fix is released, the report is credited in
the release notes unless you ask otherwise.

## Scope

In scope: the shell scripts, workflow templates, command prompts and example
configuration shipped in this repository - for example a template that leaks
a secret into logs, a script that runs untrusted input, or a workflow with
wider permissions than it needs.

Out of scope: vulnerabilities in a project the kit was applied to, and in
third-party tools the templates call. Report those to their own maintainers.

The kit ships no real credentials. If you find anything that looks like one,
report it the same way.
