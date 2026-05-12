---
name: discovering-bdd-scenarios
description: Use before writing any Gherkin scenario, when business rules need to be explored and edge cases discovered through collaborative example mapping
---

# Discovering BDD Scenarios

## Overview

Discover "what we don't know we don't know" before writing scenarios. Use Example Mapping to surface business rules, edge cases, and open questions through concrete examples.

**Core principle:** If you're not exploring concrete examples, you're not doing BDD. Rules without examples hide assumptions.

## Example Mapping

Map each user story with four card types before writing Gherkin:

| Card | Color | Content |
|------|-------|---------|
| User Story | Yellow | One story per session |
| Business Rule | Blue | "Age must be ≥18 for vehicles" |
| Concrete Example | Green | "16yo requesting car → refused" |
| Open Question | Red | Blockers — **never proceed with unresolved reds** |

### Visual Layout

```
[Yellow] Story: Insurance subscription eligibility
  |
  +-- [Blue] Rule: Must be 18+ for car/motorcycle
  |     +-- [Green] 17yo requesting car → refused
  |     +-- [Green] 18yo requesting car → accepted  ← boundary
  |     +-- [Red] Exactly 18yo: accepted or refused?
  |
  +-- [Blue] Rule: Electric vehicles allowed at 16+
        +-- [Green] 16yo e-scooter → accepted
        +-- [Green] 15yo e-scooter → refused  ← boundary
        +-- [Red] Electric motorcycle: follows age 16 or age 18 rule?
```

Per rule: create **2-3 Green cards** — happy path | boundary | error path.

## Three Amigos Perspectives

Explore each rule from three angles to find blindspots:

| Role | Questions to ask |
|------|-----------------|
| **Problem Owner** (PO/BA) | What is the business intent? What are the acceptance criteria? |
| **Problem Solver** (Dev) | What are the technical constraints? What edge cases exist? |
| **Skeptic** (QA/Tester) | What failure modes exist? What assumptions are we making? |

### Conversational Pattern

Template: *"Is there any other context which, when this event happens, produces a different outcome?"*

```
BA: "When a driver requests eligibility, the request is accepted or refused."
Dev: "What if no vehicle type is specified?"
QA: "What if the birthdate is in the future?"
BA: "What if the driver has no license information?"
→ Three new Red cards discovered.
```

## Output

Before moving to Gherkin, verify:

- [ ] Every Blue card has at least one Green card
- [ ] Boundary conditions identified for each rule (≥ vs >)
- [ ] All Red cards resolved or explicitly deferred
- [ ] Domain vocabulary agreed (ubiquitous language for Given/When/Then)

## Red Flags — STOP Discovery

- Blue cards without Green cards (rules without examples)
- More than 5-6 Blue cards (story too large — split)
- Proceeding to write Gherkin with unresolved Red cards
- Examples use implementation language (class names, HTTP verbs, status codes)

## Next Step

**REQUIRED:** `designing-bdd-scenarios` — structure the discovered examples as Gherkin
