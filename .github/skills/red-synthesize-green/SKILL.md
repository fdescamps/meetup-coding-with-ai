---
name: red-synthesize-green
description: Use when following TDD to implement any feature or fix — defines the AI-optimized 2-step cycle where RED means behavior failure only and SYNTHESIZE GREEN produces clean code without a refactor phase
---

# RED → SYNTHESIZE GREEN (AI TDD Cycle)

## Overview

2-step cycle replacing traditional 3-step TDD. Optimized for AI synthesis.

- **Traditional (3 steps):** RED → green (dirty) → Refactor
- **AI-Optimized (2 steps):** RED (behavior failure) → SYNTHESIZE GREEN (clean synthesis)

Architectural guidance is **mandatory** between steps.

**Hard rule:** No implementation code before RED is a clean behavior failure.

## Step 1: RED (Behavior Failure Only)

Write the failing test. Run it.

- Compilation errors = **wishful thinking phase** → implement stubs/empty returns to compile, rerun
- Assertion/behavior failure = **RED** ✓ → proceed to Step 2
- Never treat compilation errors as RED

**Programming by Wishful Thinking:** When your test won't compile, you're discovering the API you need. Stub just enough to compile, then confirm the test fails on behavior.

## Between Steps: Architectural Guidance (MANDATORY)

**Hard rule:** This step is not skippable. Do not proceed to SYNTHESIZE GREEN without completing it.

**Developer must review and explicitly validate the test before continuing.**
AI pauses here and waits for developer confirmation that the test correctly captures the intended behavior.

Orient design before synthesis:

- Which pattern? (specification, factory, builder)
- Which layer owns the logic?
- Immutability, return values vs mutations?

## Step 2: SYNTHESIZE GREEN (Clean Synthesis)

Implement complete, clean, production-ready solution in one shot.

- Follows all architectural rules and coding standards
- No dirty-then-refactor — synthesize properly from the start
- Idiomatic code, domain semantics, SOLID principles
- If test was misunderstood → revise test, restart from RED

**No iteration after SYNTHESIZE GREEN** unless RED was wrong or architectural guidance changed.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Compilation error IS red" | No. Compilation = wishful thinking. RED = behavior failure. |
| "I'll write dirty code then refactor" | That's 3-step TDD. SYNTHESIZE GREEN produces clean code. |
| "I can skip RED, I know it'll fail" | Run it. RED proves your test catches real failures. |

## Red Flags — STOP and Restart

- Implementation code before RED is a behavior failure
- Compilation errors treated as RED
- Skipping RED entirely
- Skipping the Between Steps architectural guidance
- Proceeding to SYNTHESIZE GREEN without developer test validation
- Refining code after SYNTHESIZE GREEN instead of revising RED

**Any of these mean:** Delete code, start over with proper RED.

## Quick Reference

| Phase | What | Success Criteria |
|---|---|---|
| **RED** | Write test, stub until compiles, run | Test fails on **behavior** (assertion), not compilation |
| **Guidance** (**MANDATORY**) | Orient architectural approach + **developer validates test** | Design direction clear, developer has confirmed test |
| **SYNTHESIZE GREEN** | Synthesize complete clean solution | Tests green, architecture respected, production-ready |

## Integration

**REQUIRED BACKGROUND:** `test-driven-development` skill (TDD discipline foundation — this skill supersets it).
Pair with domain-specific testing skills for patterns and examples.
