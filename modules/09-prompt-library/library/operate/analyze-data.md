---
id: analyze-data
phase: operate
category: data
roles: [data, pm, marketing]
needs: []
module: null
---

## Prompt

```
read {file}, pull out the key patterns and present the result as {output}
```

Slots: `file` = @reports/q1-signups.csv; `output` = an HTML page with charts,
open it in the browser.

## Why it works

A one-off question does not need a one-off script. You point at the file
(pattern 5: the artifact) and the answer's format (pattern 6) - the agent reads
the data directly and puts the result where you will use it.

## How to escalate it

If the data source is permanent, connect it through MCP instead of exporting
files.
