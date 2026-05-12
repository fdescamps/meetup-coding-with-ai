---
name: designing-bdd-scenarios
description: Use when writing or improving Gherkin .feature files, after business rules and examples have been discovered
---

# Designing BDD Scenarios

## Overview

Structure discovered examples as executable Gherkin. Covers Background, Scenario Outline + Examples, and scenario writing rules.

**Prerequisite:** `discovering-bdd-scenarios` — rules and examples must be known before structuring.  
**Core principle:** Representative selection over exhaustive enumeration.

## Scenario Writing Rules

| Rule | Check |
|------|-------|
| One scenario, one behavior | Split multi-behavior scenarios |
| Declarative, not imperative | Business outcomes, not UI/API/HTTP details |
| Concrete examples | Specific values ("$500", "17 ans"), not abstractions |
| Short (3-5 steps) | Longer = testing multiple behaviors |
| Background for shared Given | Factorize repeated preconditions only |

### Spec-Leakage Rule (CRITICAL)

Scenarios describe **external observables only**:

| ❌ Forbidden | ✅ Allowed |
|---|---|
| Class names, method names | Business actions and actors |
| HTTP endpoints, status codes | Business outcomes |
| Repository, database tables | Data in business terms |

### Scenario Titles: Business Outcomes Only

| ❌ BAD (implementation) | ✅ GOOD (business outcome) |
|---|---|
| `POST /api/eligibility returns 200` | `Eligibility request is accepted` |
| `EligibilityHandler returns rejected` | `Driver is refused for being too young` |

## Structure Patterns

### Background — Shared Preconditions

```gherkin
Contexte:
  Étant donné nous sommes le "01/01/2026"
```

**Only Given steps.** Never When/Then.

### Scenario Outline + Examples — Boundary Testing

```gherkin
Plan du Scénario: Vérification de l'âge minimum
  Étant donné un conducteur âgé de <age> ans
  Et le véhicule est une "<vehicule>"
  Quand je demande une éligibilité
  Alors la demande est <resultat>

  Exemples: Conducteurs refusés
    | age | vehicule | resultat                                                       |
    | 17  | Voiture  | refusée avec le motif "Conducteur trop jeune pour ce véhicule" |

  Exemples: Conducteurs acceptés
    | age | vehicule | resultat |
    | 18  | Voiture  | acceptée |
```

**Group Examples by intent** (accepted vs rejected), not by data shape.  
Use outlines for boundary conditions. Avoid when scenarios diverge structurally.

### Individual Scenario — Unique Cases

Use when Given steps are unique and not shared with other scenarios.

## Coverage Check

Per business rule, target **3-4 cases** (not 10+):

| Type | Count | Target |
|------|-------|--------|
| Happy path | 1 | Most common success |
| Key alternatives | 1-2 | Boundary values, rejections |
| Error path | 1+ | Target **40%+** of total scenarios |

### Boundary Testing

For each threshold, test **both sides**:

| Rule | Below boundary | At boundary | Above boundary |
|------|---------------|-------------|----------------|
| Age ≥18 | 17 (rejected) | 18 (accepted) | — |
| Power >100ch | 100 (accepted) | — | 101 (rejected) |

**Clarify the operator** (≥ vs >) before writing scenarios.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Exhaustive enumeration (20+ scenarios) | Select representative examples per rule |
| No Background | Factorize shared Given steps |
| Individual scenarios for boundary variations | Use Scenario Outline + Examples |
| Only rejection scenarios, no acceptance | Include Golden Path per rule |
| Boundary operator ambiguous | Clarify with boundary pair (100ch OK, 101ch KO) |
| Implementation details in titles or steps | Business language only — spec-leakage rule |
| Proceeding without explicit approval | Present scenarios, wait for explicit validation |

## Red Flags — STOP and Restructure

- More than 5 scenarios per rule
- Duplicated Given steps (→ Background)
- Same structure with different values (→ Scenario Outline)
- Class/method/endpoint names in scenarios (→ spec-leakage)
- Only acceptance OR rejection per rule (→ missing path)

## Integration

**REQUIRED:** `discovering-bdd-scenarios` — run first to discover rules and examples  
**PAIRS WITH:** `outside-in-tdd` — scenarios feed acceptance tests  
**PAIRS WITH:** `red-synthesize-green` — TDD cycle after approval
