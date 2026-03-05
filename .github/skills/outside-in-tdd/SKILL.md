---
name: outside-in-tdd
description: Use when writing unit tests for DDD Clean Architecture layers — covers outside-in testing with Gherkin scenarios, Application handler orchestration tests, Domain logic tests, and mocking rules
---

# Outside-In DDD Testing

## Overview

Complete testing guide for Application and Domain layers in Clean Architecture.
Start from observable business behavior (Gherkin), let design emerge from tests.

**Core rule:** Real Domain objects, mocked Infrastructure only, fast in-memory tests.

## Outside-In Approach

1. **Gherkin scenario** (Given/When/Then) — describes WHAT, not HOW
2. **Map to Application test** — test handler entry point, mock only Infrastructure ports
3. **Domain emerges** — test failures guide what Domain objects you need

## Application Tests (Sociable — Handler Level)

Test command/query handlers with real Domain objects. Mock only Infrastructure. Verify orchestration + Domain state.

```csharp
[Fact]
public async Task WhenSubmittingValidApplication_ShouldPersistPendingApplication()
{
    var repository = A.Fake<IApplicationRepository>();
    var handler = new SubmitApplicationCommandHandler(repository);
    var command = new SubmitApplicationCommand(CustomerId.CreateNew(),
        new DriverInfo(Age: 25, LicenseYears: 3), new VehicleInfo(Type: "sedan", Age: 2));

    await handler.Handle(command);

    A.CallTo(() => repository.AddAsync(
        A<Application>.That.Matches(a => a.Status == ApplicationStatus.Pending),
        A<CancellationToken>._)).MustHaveHappenedOnceExactly();
}
```

## Domain Tests (Pure — Logic Level)

Test aggregates, value objects, domain services. No mocks — pure state-based assertions.

```csharp
[Fact]
public void WhenDriverIsUnder18_ShouldBeIneligible()
{
    var policy = new EligibilityPolicy();
    var driver = new DriverInfo(Age: 17, LicenseYears: 0);
    var vehicle = new VehicleInfo(Type: "sedan", Age: 1);

    var result = policy.Evaluate(driver, vehicle);

    Assert.False(result.IsEligible);
    Assert.Equal("driver_under_minimum_age", result.RejectionReason);
}
```

## When to Write Which

| Signal | Route to |
|---|---|
| Orchestration (load/save/publish) | Application test |
| Complex rules, edge matrices, invariants | Domain test |
| Simple rule covered by handler test | Don't duplicate |

**Default:** Application test first. Add Domain tests when complexity warrants it.

## Testing Rules

### DO ✅
- Mock only Infrastructure (repositories, external services)
- Use real Domain objects (aggregates, VOs, services)
- Keep tests fast (< 100ms, no DB, no network)
- Name tests with business language (`WhenCondition_ShouldOutcome`)
- Cover meaningful edge-case combinations

### DON'T ❌
- Don't mock Domain objects (`A.Fake<Order>()` — never)
- Don't centralize strategic rules in handlers
- Don't use Testcontainers in unit tests — Integration only
- Don't test implementation details — test behavior
- Don't use FluentAssertions — use xUnit native `Assert.*` (licensing)

## Anti-Patterns

- Strategic rules in Application handlers instead of Domain
- Over-mocking that hides real business behavior
- Treating coverage percentage as the quality target
- Duplicating Application test coverage with redundant Domain tests

## Project Structure

```
tests/[Project].UnitTests/
  Application/
    [Feature]/
      Commands/
        [Action]CommandHandlerTests.cs
      Queries/
        [Action]QueryHandlerTests.cs
  Domain/
    [Feature]/
      [Policy]Tests.cs
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Mocking Domain objects in Application tests | Use real Domain objects, mock only Infrastructure |
| Writing Domain objects before RED test | Let design emerge from test failures |
| Treating compilation errors as RED | Stub to compile, then confirm behavior failure |
| Skipping Gherkin ("too small") | Even small features benefit from behavior-first thinking |

## References & Templates

- [references/testing-strategy.md](references/testing-strategy.md) — sociable vs solitary philosophy
- [references/cqrs-patterns.md](references/cqrs-patterns.md) — handler structure, commands vs queries
- [references/test-examples.md](references/test-examples.md) — complete code examples (Application + Domain)
- [assets/CommandHandlerTestTemplate.cs](assets/CommandHandlerTestTemplate.cs) — Command handler test starter
- [assets/QueryHandlerTestTemplate.cs](assets/QueryHandlerTestTemplate.cs) — Query handler test starter

## Integration

**REQUIRED PROCESS:** `red-synthesize-green` (follow the 2-step AI TDD cycle)
**REQUIRED CONTEXT:** `clean-architecture-dotnet` (layer boundaries)

