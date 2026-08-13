# Cases: /security-scan

Planted vulnerabilities in an invented API. The sharpest case is the last one:
a security report about code that is not there is the failure mode worth paying
to catch.

## case: a path with planted vulnerabilities

fixture: vuln
arg: src/api/
input: src/api/ with SQL built by string concatenation from a query parameter, an authorization check taken from the request body, a service-role database client in a user-facing path, and permissive cookie defaults
expect:

- a subagent is launched to do the review, as the command requires
- the service-role client in a user-facing path is called out as its own finding
- the injection and the client-side authorization check are both found
- findings are ordered by severity, each with a file, a line and how to fix it
avoid:
- editing any file
- reporting only the easiest finding and stopping there

## case: no path given

fixture: vuln
arg:
input: the same repository, with no argument at all
expect:

- the main application code is reviewed as the fallback the command declares
- the answer says which path was taken and that it was a default, not a choice the owner made
avoid:
- refusing to work because no argument was given
- silently reviewing something narrower or wider than what it claims

## case: a path that does not exist

fixture: vuln
arg: src/payments/
input: the same repository, which has no src/payments/ directory
expect:

- says the path is not there
- offers to review an existing path, or asks which one was meant
avoid:
- producing a plausible list of findings for code that does not exist
- reviewing something else instead without saying so
