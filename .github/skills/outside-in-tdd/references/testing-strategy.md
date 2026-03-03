# Testing Strategy: Sociable Tests for DDD

## Philosophy

This testing strategy follows Martin Fowler's **sociable testing** approach:

- **Sociable tests** use real collaborators from within the same layer or below
- **Solitary tests** (with mocks) are used only for external dependencies

## What to Test Where

### Application Layer Tests (primary focus)
- Test use cases (Command/Query handlers) with real Domain objects
- Mock only Infrastructure dependencies (repositories, external services)
- Validate the entire business flow including Domain logic
- Located in: `tests/[Project].UnitTests/Application/`

### Domain Layer Tests (when needed)
- Test complex domain logic that needs isolated validation
- Test specifications, complex calculations, or critical invariants
- Most Domain logic is already tested through Application tests
- Located in: `tests/[Project].UnitTests/Domain/`

### Integration Tests (full stack)
- Test API endpoints with real infrastructure (Testcontainers)
- Located in: `tests/[Project].IntegrationTests/`

## When Application vs Domain Tests

| Signal | Route to |
|---|---|
| Orchestration (load/save/publish/map) | Application test |
| Complex business rules with edge-case matrices | Domain test |
| Aggregate invariants across state transitions | Domain test |
| Value object validation with boundary conditions | Domain test |
| Domain service with non-trivial policy logic | Domain test |
| Simple rule adequately covered by handler test | Don't duplicate — Application test is enough |

**Default:** Start with Application test. Add Domain test only when complexity warrants it.

## Testing Rules

### DO ✅
- Test handlers with real Domain objects (aggregates, VOs, services)
- Mock only Infrastructure layer (repositories, external services)
- Keep tests fast (no Testcontainers, no DB, no network, < 100ms)
- Name tests with business language (`WhenDoingSomething_ShouldExpectedBehavior`)
- Verify Domain state changes through observable outcomes

### DON'T ❌
- Don't mock Domain objects (`A.Fake<Order>()` — never)
- Don't centralize strategic rules in handlers — keep them in Domain
- Don't use Testcontainers in unit tests — save for Integration
- Don't test implementation details — test behavior

## Benefits

1. **Fast execution**: No external dependencies in unit tests
2. **Real behavior**: Tests verify actual Domain logic, not mocks
3. **Refactoring safety**: Tests break only when behavior changes
4. **Clear intent**: Tests show how Domain and Application work together
5. **Maintainability**: Fewer mocks = less maintenance overhead
