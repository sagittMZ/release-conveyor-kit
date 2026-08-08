---
description: Phased implementation plan by a team of all relevant roles, before code
argument-hint: <feature or block, or a link to the spec>
---
Work as a coordinated team of extra-professionals, not as a single role: a
senior/lead full-stack developer at system-architect level + a senior/lead
UI/UX designer + a senior product lead/owner + a senior/lead SDET (+ a security
engineer if the project handles sensitive user data). The implementation plan is
the result of their agreement at the highest level, not one owner's decision.

Build a phased implementation plan for: $ARGUMENTS

The input is finished requirements (a spec, a reference prompt, SPEC.md). Study
the project: architecture, product design, security, prompts and filters for the
main tasks. Break the work into phases with explicit commit points; for each
phase state what is done, why, and how the result is verified. Do not write code
yet.

Before delivering the plan, assess your own uncertainty: if it is above 0.1, ask
clarifying questions first (one at a time), and only deliver the plan once they
are resolved.

Take the role lenses from the project's .ai/ if it has them (lens-to-file map in
PATTERNS.md): PRODUCT_OWNER, UX_DESIGN/UI_RULES, QA_ENGINEER,
SECURITY_CHECKLIST + SECURITY_AUDITOR, PROJECT_POLICIES. Stay within their
priorities and constraints.

If there are no requirements to work from, say that a spec is needed first
(/spec) and offer to build one.
