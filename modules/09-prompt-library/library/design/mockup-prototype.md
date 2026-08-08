---
id: mockup-prototype
phase: design
category: prototype
roles: [design, pm, marketing]
needs: [browser]
module: null
---

## Prompt

Paste or @-mention the mockup image, then:

```
here is the mockup. build a working prototype I can click through, reproducing
the layout and states from the image. then open it in my browser
```

## Why it works

A clickable prototype answers questions a static mockup cannot. Development
receives working code instead of a document describing interactions.

`needs: browser` - the agent needs a way to render and check the result: the
Claude desktop app, the Chrome extension, or Playwright MCP. Without one the
prototype still gets built, but there is no screenshot self-check.

## How to escalate it

For an exact match with the mockup, add to the prompt: "take a screenshot of the
result, compare it with the original and fix the differences" - that gives the
agent a self-check loop (pattern 2).
