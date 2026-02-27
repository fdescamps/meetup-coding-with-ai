# Skill: Run Tests

Run the project's test suite and report results.

## Description

Executes all unit and integration tests in the repository. Reports pass/fail status, failing test names, and code coverage if available.

## Usage

Invoke this skill when you want to:
- Verify that changes don't break existing tests
- Check test coverage before a PR
- Debug a specific failing test

## Steps

1. Detect the test runner from `package.json` scripts or project files (`jest.config.*`, `vitest.config.*`, `pytest.ini`, etc.).
2. Run the appropriate command for the detected runner.
3. Parse and summarize output: number of tests passed/failed, duration, and coverage percentage.
4. If tests fail, show the failing test names with their error messages.

## Example Commands

| Stack | Command |
|-------|---------|
| Node.js (Jest) | `npx jest --coverage` |
| Node.js (Vitest) | `npx vitest run --coverage` |
| Python (pytest) | `pytest --cov=. --cov-report=term-missing` |
| Java (Maven) | `mvn test` |

## Output Format

```
✅ Tests: 142 passed, 0 failed (8.3s)
📊 Coverage: 87.4% statements, 81.2% branches
```

Or on failure:

```
❌ Tests: 139 passed, 3 failed (9.1s)

Failed:
  - UserService > should reject invalid email
  - OrderController > should return 404 for unknown order
  - PaymentGateway > should retry on timeout
```
