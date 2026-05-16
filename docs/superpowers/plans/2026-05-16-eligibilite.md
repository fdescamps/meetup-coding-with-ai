# Eligibility Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the `POST /eligibility` endpoint that evaluates auto-insurance subscription eligibility based on driver age, vehicle type, and motorcycle power rules.

**Architecture:** Clean Architecture with CQS (no bus) — domain rules live exclusively in `EligibilityPolicy` (Domain layer), orchestration in `CheckEligibilityQueryHandler` (Application layer), exposed via a minimal Minimal API endpoint. `TimeProvider` is injected into the handler for testable date logic; no framework dependency enters the Domain.

**Tech Stack:** .NET 10 / C#, xUnit, FakeItEasy, `Microsoft.Extensions.TimeProvider.Testing` (FakeTimeProvider), NetArchTest.Rules, WebApplicationFactory (integration tests).

---

## File Map

| File | Layer | Action | Responsibility |
|------|-------|--------|----------------|
| `MonAssurance.Domain/Eligibility/VehicleType.cs` | Domain | Create | Enum: `Car`, `Motorcycle`, `ElectricScooter` |
| `MonAssurance.Domain/Eligibility/Driver.cs` | Domain | Create | Behavioral methods: `Age(today)`, `HasEnoughExperience(years)` |
| `MonAssurance.Domain/Eligibility/Vehicle.cs` | Domain | Create | Behavioral methods: `MinimumAge()`, `IsHighPowerMotorcycle()` |
| `MonAssurance.Domain/Eligibility/EligibilityResult.cs` | Domain | Create | Factory + `Match<T>` — no state exposure |
| `MonAssurance.Domain/Eligibility/EligibilityPolicy.cs` | Domain | Create | Pure domain service: `Evaluate(driver, vehicle, today)` |
| `MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQuery.cs` | Application | Create | Incoming DTO: `DateOfBirth`, `VehicleType`, `Power?`, `LicenseYears` |
| `MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQueryHandler.cs` | Application | Create | Orchestrates `TimeProvider` + `EligibilityPolicy` |
| `MonAssurance.Application/Eligibility/Queries/CheckEligibility/EligibilityViewModel.cs` | Application | Create | Outgoing DTO: `IsEligible`, `RejectionReason?` |
| `MonAssurance.Api/Eligibility/EligibilityEndpoints.cs` | API | Create | Maps `POST /eligibility` |
| `MonAssurance.Api/Program.cs` | API | Modify | Register endpoint + services |
| `MonAssurance.Infrastructure/DependencyInjection.cs` | Infrastructure | Modify | Register `EligibilityPolicy`, `CheckEligibilityQueryHandler` |
| `MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs` | Tests | Create | Acceptance tests (Application layer entry point) |
| `MonAssurance.UnitTests/Eligibility/Domain/EligibilityPolicyTests.cs` | Tests | Create | Boundary value tests (Domain layer entry point) |
| `MonAssurance.IntegrationTests/Eligibility/EligibilityEndpointsTests.cs` | Tests | Create | Walking skeleton: `POST /eligibility` |
| `MonAssurance.IntegrationTests/Architecture/DomainArchitectureTests.cs` | Tests | Create | NetArchTest: Domain has no framework dependency |

---

## Task 0: Setup — Add FakeTimeProvider package

**Files:**
- Modify: `MonAssurance.UnitTests/MonAssurance.UnitTests.csproj`

- [ ] **Step 1: Add the NuGet package**

```bash
cd /Users/sebastiendegodez/Documents/source.nosync/meetup-coding-with-ai
dotnet add MonAssurance.UnitTests/MonAssurance.UnitTests.csproj package Microsoft.Extensions.TimeProvider.Testing
```

Expected output: line ending with `PackageReference` for `Microsoft.Extensions.TimeProvider.Testing`.

- [ ] **Step 2: Verify the build still compiles**

```bash
dotnet build MonAssurance.sln
```

Expected: `Build succeeded.`

- [ ] **Step 3: Commit**

```bash
git add MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
git commit -m "chore(tests): add Microsoft.Extensions.TimeProvider.Testing to UnitTests"
```

---

## Task 1: Application acceptance test — happy path (Car, 18 years old)

**Files:**
- Create: `MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs`

The handler and all domain types do not exist yet. This test will **not compile** — that is expected (Outside-In TDD RED).

- [ ] **Step 1: Create the test file**

```csharp
// MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs
using Microsoft.Extensions.Time.Testing;
using MonAssurance.Application.Eligibility.Queries.CheckEligibility;
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.UnitTests.Eligibility.Application;

public class CheckEligibilityQueryHandlerTests
{
    // Convention: today is fixed so age calculations are deterministic.
    private static readonly DateOnly Today = new(2026, 1, 1);

    private static CheckEligibilityQueryHandler BuildHandler(DateOnly today)
    {
        var fakeTime = new FakeTimeProvider();
        fakeTime.SetUtcNow(today.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc));
        return new CheckEligibilityQueryHandler(new EligibilityPolicy(), fakeTime);
    }

    [Fact]
    public void Handle_WhenDriverIs18AndHasCar_ReturnsEligible()
    {
        // Arrange — birthday exactly today (just turned 18)
        var handler = BuildHandler(Today);
        var query = new CheckEligibilityQuery(
            DateOfBirth: Today.AddYears(-18),
            VehicleType: VehicleType.Car,
            Power: null,
            LicenseYears: 2);

        // Act
        var result = handler.Handle(query);

        // Assert
        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }
}
```

- [ ] **Step 2: Run — confirm compilation error (RED)**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **compilation error** — `The type or namespace name 'CheckEligibilityQueryHandler' could not be found` (or similar). This is correct.

- [ ] **Step 3: Commit the failing test**

```bash
git add MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs
git commit -m "test(application): add failing acceptance test — eligible driver"
```

---

## Task 2: Create Domain skeleton to compile

**Files:**
- Create: `MonAssurance.Domain/Eligibility/VehicleType.cs`
- Create: `MonAssurance.Domain/Eligibility/Driver.cs`
- Create: `MonAssurance.Domain/Eligibility/Vehicle.cs`
- Create: `MonAssurance.Domain/Eligibility/EligibilityResult.cs`
- Create: `MonAssurance.Domain/Eligibility/EligibilityPolicy.cs`

Minimal stubs: they compile but return wrong values. The test will fail assertion (not compilation).

- [ ] **Step 1: Create VehicleType**

```csharp
// MonAssurance.Domain/Eligibility/VehicleType.cs
namespace MonAssurance.Domain.Eligibility;

public enum VehicleType { Car, Motorcycle, ElectricScooter }
```

- [ ] **Step 2: Create Driver**

```csharp
// MonAssurance.Domain/Eligibility/Driver.cs
namespace MonAssurance.Domain.Eligibility;

public sealed class Driver
{
    private readonly DateOnly _dateOfBirth;
    private readonly int _licenseYears;

    public Driver(DateOnly dateOfBirth, int licenseYears)
    {
        _dateOfBirth = dateOfBirth;
        _licenseYears = licenseYears;
    }

    public int Age(DateOnly today) => 0; // stub

    public bool HasEnoughExperience(int minimumYears) => false; // stub
}
```

- [ ] **Step 3: Create Vehicle**

```csharp
// MonAssurance.Domain/Eligibility/Vehicle.cs
namespace MonAssurance.Domain.Eligibility;

public sealed class Vehicle
{
    private readonly VehicleType _type;
    private readonly int? _power;

    public Vehicle(VehicleType type, int? power)
    {
        _type = type;
        _power = power;
    }

    public int MinimumAge() => 99; // stub — intentionally wrong

    public bool IsHighPowerMotorcycle() => false; // stub
}
```

- [ ] **Step 4: Create EligibilityResult**

```csharp
// MonAssurance.Domain/Eligibility/EligibilityResult.cs
namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityResult
{
    private readonly bool _isEligible;
    private readonly string? _reason;

    private EligibilityResult(bool isEligible, string? reason)
    {
        _isEligible = isEligible;
        _reason = reason;
    }

    public static EligibilityResult Accepted() => new(true, null);
    public static EligibilityResult Refused(string reason) => new(false, reason);

    public T Match<T>(Func<T> onAccepted, Func<string, T> onRefused) =>
        _isEligible ? onAccepted() : onRefused(_reason!);
}
```

- [ ] **Step 5: Create EligibilityPolicy stub**

```csharp
// MonAssurance.Domain/Eligibility/EligibilityPolicy.cs
namespace MonAssurance.Domain.Eligibility;

public sealed class EligibilityPolicy
{
    public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
    {
        return EligibilityResult.Refused("not implemented"); // stub
    }
}
```

- [ ] **Step 6: Create Application layer stubs**

```csharp
// MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQuery.cs
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed record CheckEligibilityQuery(
    DateOnly DateOfBirth,
    VehicleType VehicleType,
    int? Power,
    int LicenseYears);
```

```csharp
// MonAssurance.Application/Eligibility/Queries/CheckEligibility/EligibilityViewModel.cs
namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class EligibilityViewModel
{
    public bool IsEligible { get; }
    public string? RejectionReason { get; }

    private EligibilityViewModel(bool isEligible, string? reason)
    {
        IsEligible = isEligible;
        RejectionReason = reason;
    }

    public static EligibilityViewModel Accepted() => new(true, null);
    public static EligibilityViewModel Refused(string reason) => new(false, reason);
}
```

```csharp
// MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQueryHandler.cs
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class CheckEligibilityQueryHandler
{
    private readonly EligibilityPolicy _policy;
    private readonly TimeProvider _timeProvider;

    public CheckEligibilityQueryHandler(EligibilityPolicy policy, TimeProvider timeProvider)
    {
        _policy = policy;
        _timeProvider = timeProvider;
    }

    public EligibilityViewModel Handle(CheckEligibilityQuery query)
    {
        var today = DateOnly.FromDateTime(_timeProvider.GetUtcNow().UtcDateTime);
        var driver = new Driver(query.DateOfBirth, query.LicenseYears);
        var vehicle = new Vehicle(query.VehicleType, query.Power);

        return _policy
            .Evaluate(driver, vehicle, today)
            .Match(
                onAccepted: () => EligibilityViewModel.Accepted(),
                onRefused: reason => EligibilityViewModel.Refused(reason)
            );
    }
}
```

- [ ] **Step 7: Run test — confirm assertion RED (compiles, fails)**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **1 test FAILED** — `Assert.True() Failure: Expected: True, Actual: False`. Compilation succeeds.

- [ ] **Step 8: Commit**

```bash
git add MonAssurance.Domain/Eligibility/ MonAssurance.Application/Eligibility/
git commit -m "feat(domain): add domain skeleton for eligibility"
```

---

## Task 3: Implement EligibilityPolicy — age rule (GREEN first test)

**Files:**
- Modify: `MonAssurance.Domain/Eligibility/Driver.cs`
- Modify: `MonAssurance.Domain/Eligibility/Vehicle.cs`
- Modify: `MonAssurance.Domain/Eligibility/EligibilityPolicy.cs`

- [ ] **Step 1: Implement `Driver.Age()`**

Replace the stub body:

```csharp
// MonAssurance.Domain/Eligibility/Driver.cs
public int Age(DateOnly today)
{
    var age = today.Year - _dateOfBirth.Year;
    if (today < _dateOfBirth.AddYears(age)) age--;
    return age;
}
```

- [ ] **Step 2: Implement `Vehicle.MinimumAge()`**

Replace the stub body:

```csharp
// MonAssurance.Domain/Eligibility/Vehicle.cs
public int MinimumAge() => _type == VehicleType.ElectricScooter ? 16 : 18;
```

- [ ] **Step 3: Implement age guard in `EligibilityPolicy.Evaluate()`**

Replace the stub body:

```csharp
// MonAssurance.Domain/Eligibility/EligibilityPolicy.cs
public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
{
    if (driver.Age(today) < vehicle.MinimumAge())
        return EligibilityResult.Refused("Conducteur trop jeune pour ce véhicule");

    return EligibilityResult.Accepted();
}
```

- [ ] **Step 4: Run test — confirm GREEN**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **1 test PASSED**.

- [ ] **Step 5: Commit**

```bash
git add MonAssurance.Domain/Eligibility/Driver.cs \
        MonAssurance.Domain/Eligibility/Vehicle.cs \
        MonAssurance.Domain/Eligibility/EligibilityPolicy.cs
git commit -m "feat(domain): implement age minimum rule"
```

---

## Task 4: Application acceptance tests — age refusal scenarios

**Files:**
- Modify: `MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs`

Four new tests: Car 17yo refused, Motorcycle 17yo refused, ElectricScooter 15yo refused, ElectricScooter 16yo accepted.

> These tests are added **after** Task 3 fully implements the age rule — they go straight to GREEN. No cosmetic RED step.

- [ ] **Step 1: Add the three test cases**

Append inside the `CheckEligibilityQueryHandlerTests` class:

```csharp
[Fact]
public void Handle_WhenDriverIs17AndHasCar_ReturnsRefused()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-17),
        VehicleType: VehicleType.Car,
        Power: null,
        LicenseYears: 1);

    var result = handler.Handle(query);

    Assert.False(result.IsEligible);
    Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
}

[Fact]
public void Handle_WhenDriverIs17AndHasMotorcycle_ReturnsRefused()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-17),
        VehicleType: VehicleType.Motorcycle,
        Power: null,
        LicenseYears: 1);

    var result = handler.Handle(query);

    Assert.False(result.IsEligible);
    Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
}

[Fact]
public void Handle_WhenDriverIs15AndHasElectricScooter_ReturnsRefused()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-15),
        VehicleType: VehicleType.ElectricScooter,
        Power: null,
        LicenseYears: 0);

    var result = handler.Handle(query);

    Assert.False(result.IsEligible);
    Assert.Equal("Conducteur trop jeune pour ce véhicule", result.RejectionReason);
}

[Fact]
public void Handle_WhenDriverIs16AndHasElectricScooter_ReturnsEligible()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-16),
        VehicleType: VehicleType.ElectricScooter,
        Power: null,
        LicenseYears: 0);

    var result = handler.Handle(query);

    Assert.True(result.IsEligible);
    Assert.Null(result.RejectionReason);
}
```

- [ ] **Step 2: Run — confirm GREEN (age rule already complete from Task 3)**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **5 tests PASSED** (1 from Task 1 + 4 new).

- [ ] **Step 3: Commit**

```bash
git add MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs
git commit -m "test(application): add age boundary scenarios — Car/Motorcycle 17yo, ElectricScooter 15yo/16yo"
```

---

## Task 5: Application acceptance tests — powerful motorcycle rule

**Files:**
- Modify: `MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs`
- Modify: `MonAssurance.Domain/Eligibility/Vehicle.cs`
- Modify: `MonAssurance.Domain/Eligibility/Driver.cs`
- Modify: `MonAssurance.Domain/Eligibility/EligibilityPolicy.cs`

Three scenarios: Motorcycle 101hp 4y license refused; Motorcycle 101hp 5y license accepted; Motorcycle 100hp 4y license accepted.

- [ ] **Step 1: Add the three test cases**

Append inside `CheckEligibilityQueryHandlerTests`:

```csharp
[Fact]
public void Handle_WhenMotorcycleIsHighPowerAndDriverHas4YearsLicense_ReturnsRefused()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-25),
        VehicleType: VehicleType.Motorcycle,
        Power: 101,
        LicenseYears: 4);

    var result = handler.Handle(query);

    Assert.False(result.IsEligible);
    Assert.Equal("Expérience insuffisante pour la puissance", result.RejectionReason);
}

[Fact]
public void Handle_WhenMotorcycleIsHighPowerAndDriverHas5YearsLicense_ReturnsEligible()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-25),
        VehicleType: VehicleType.Motorcycle,
        Power: 101,
        LicenseYears: 5);

    var result = handler.Handle(query);

    Assert.True(result.IsEligible);
    Assert.Null(result.RejectionReason);
}

[Fact]
public void Handle_WhenMotorcycleIsExactly100HpAndDriverHas4YearsLicense_ReturnsEligible()
{
    var handler = BuildHandler(Today);
    var query = new CheckEligibilityQuery(
        DateOfBirth: Today.AddYears(-25),
        VehicleType: VehicleType.Motorcycle,
        Power: 100,
        LicenseYears: 4);

    var result = handler.Handle(query);

    Assert.True(result.IsEligible);
    Assert.Null(result.RejectionReason);
}
```

- [ ] **Step 2: Run — confirm RED for new tests**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: first new test FAILED (refused but policy returns accepted — second rule not implemented), others may pass or fail. Existing 4 tests still PASSED.

- [ ] **Step 3: Implement `Vehicle.IsHighPowerMotorcycle()`**

Replace the stub body:

```csharp
// MonAssurance.Domain/Eligibility/Vehicle.cs
// Convention: null power treated as < 100hp — no experience rule triggered.
public bool IsHighPowerMotorcycle() => _type == VehicleType.Motorcycle && _power > 100;
```

- [ ] **Step 4: Implement `Driver.HasEnoughExperience()`**

Replace the stub body:

```csharp
// MonAssurance.Domain/Eligibility/Driver.cs
public bool HasEnoughExperience(int minimumYears) => _licenseYears >= minimumYears;
```

- [ ] **Step 5: Add second guard in `EligibilityPolicy.Evaluate()`**

```csharp
// MonAssurance.Domain/Eligibility/EligibilityPolicy.cs
public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
{
    if (driver.Age(today) < vehicle.MinimumAge())
        return EligibilityResult.Refused("Conducteur trop jeune pour ce véhicule");

    if (vehicle.IsHighPowerMotorcycle() && !driver.HasEnoughExperience(5))
        return EligibilityResult.Refused("Expérience insuffisante pour la puissance");

    return EligibilityResult.Accepted();
}
```

- [ ] **Step 6: Run — confirm all GREEN**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **7 tests PASSED**.

- [ ] **Step 7: Commit**

```bash
git add MonAssurance.UnitTests/Eligibility/Application/CheckEligibilityQueryHandlerTests.cs \
        MonAssurance.Domain/Eligibility/Vehicle.cs \
        MonAssurance.Domain/Eligibility/Driver.cs \
        MonAssurance.Domain/Eligibility/EligibilityPolicy.cs
git commit -m "feat(domain): implement high-power motorcycle experience rule"
```

---

## Task 6: Domain boundary value tests on EligibilityPolicy

**Files:**
- Create: `MonAssurance.UnitTests/Eligibility/Domain/EligibilityPolicyTests.cs`

Direct tests on `EligibilityPolicy.Evaluate()` — no `TimeProvider`, real domain objects, no doubles. Covers exact boundary values: exactly 18yo today, not-yet-18, exactly 100hp, 101hp, exactly 5y license, 4y license.

- [ ] **Step 1: Create the test file**

```csharp
// MonAssurance.UnitTests/Eligibility/Domain/EligibilityPolicyTests.cs
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.UnitTests.Eligibility.Domain;

public class EligibilityPolicyTests
{
    private static readonly DateOnly Today = new(2026, 1, 1);
    private readonly EligibilityPolicy _policy = new();

    // ── Age boundaries ──────────────────────────────────────────────────────

    [Fact]
    public void Evaluate_WhenDriverTurns18ExactlyToday_ReturnsAccepted()
    {
        var driver = new Driver(Today.AddYears(-18), licenseYears: 2);
        var vehicle = new Vehicle(VehicleType.Car, power: null);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => true,
            onRefused: _ => throw new Exception("Expected Accepted"));
    }

    [Fact]
    public void Evaluate_WhenDriverTurns18Tomorrow_ReturnsRefused()
    {
        // birthday is tomorrow → not yet 18 today
        var driver = new Driver(Today.AddYears(-18).AddDays(1), licenseYears: 2);
        var vehicle = new Vehicle(VehicleType.Car, power: null);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => throw new Exception("Expected Refused"),
            onRefused: reason =>
            {
                Assert.Equal("Conducteur trop jeune pour ce véhicule", reason);
                return true;
            });
    }

    [Fact]
    public void Evaluate_WhenElectricScooterDriverTurns16ExactlyToday_ReturnsAccepted()
    {
        var driver = new Driver(Today.AddYears(-16), licenseYears: 0);
        var vehicle = new Vehicle(VehicleType.ElectricScooter, power: null);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => true,
            onRefused: _ => throw new Exception("Expected Accepted"));
    }

    [Fact]
    public void Evaluate_WhenElectricScooterDriverTurns16Tomorrow_ReturnsRefused()
    {
        var driver = new Driver(Today.AddYears(-16).AddDays(1), licenseYears: 0);
        var vehicle = new Vehicle(VehicleType.ElectricScooter, power: null);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => throw new Exception("Expected Refused"),
            onRefused: reason =>
            {
                Assert.Equal("Conducteur trop jeune pour ce véhicule", reason);
                return true;
            });
    }

    // ── Power boundaries ─────────────────────────────────────────────────────

    [Fact]
    public void Evaluate_WhenMotorcycleIsExactly100HpAnd4YearsLicense_ReturnsAccepted()
    {
        var driver = new Driver(Today.AddYears(-25), licenseYears: 4);
        var vehicle = new Vehicle(VehicleType.Motorcycle, power: 100);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => true,
            onRefused: _ => throw new Exception("Expected Accepted"));
    }

    [Fact]
    public void Evaluate_WhenMotorcycleIs101HpAnd4YearsLicense_ReturnsRefused()
    {
        var driver = new Driver(Today.AddYears(-25), licenseYears: 4);
        var vehicle = new Vehicle(VehicleType.Motorcycle, power: 101);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => throw new Exception("Expected Refused"),
            onRefused: reason =>
            {
                Assert.Equal("Expérience insuffisante pour la puissance", reason);
                return true;
            });
    }

    // ── Experience boundaries ─────────────────────────────────────────────────

    [Fact]
    public void Evaluate_WhenMotorcycleIs101HpAndExactly5YearsLicense_ReturnsAccepted()
    {
        var driver = new Driver(Today.AddYears(-25), licenseYears: 5);
        var vehicle = new Vehicle(VehicleType.Motorcycle, power: 101);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => true,
            onRefused: _ => throw new Exception("Expected Accepted"));
    }

    [Fact]
    public void Evaluate_WhenMotorcycleIs101HpAndExactly4YearsLicense_ReturnsRefused()
    {
        var driver = new Driver(Today.AddYears(-25), licenseYears: 4);
        var vehicle = new Vehicle(VehicleType.Motorcycle, power: 101);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => throw new Exception("Expected Refused"),
            onRefused: reason =>
            {
                Assert.Equal("Expérience insuffisante pour la puissance", reason);
                return true;
            });
    }

    // ── Null power ─────────────────────────────────────────────────────────────

    [Fact]
    public void Evaluate_WhenMotorcycleHasNullPowerAnd4YearsLicense_ReturnsAccepted()
    {
        // null power → not a high-power motorcycle → experience rule does not apply
        var driver = new Driver(Today.AddYears(-25), licenseYears: 4);
        var vehicle = new Vehicle(VehicleType.Motorcycle, power: null);

        var result = _policy.Evaluate(driver, vehicle, Today);

        result.Match(
            onAccepted: () => true,
            onRefused: _ => throw new Exception("Expected Accepted"));
    }
}
```

- [ ] **Step 2: Run — confirm all GREEN (no new implementation needed)**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **16 tests PASSED** (7 existing + 9 new boundary tests). If any fail, fix the domain logic before committing.

- [ ] **Step 3: Commit**

```bash
git add MonAssurance.UnitTests/Eligibility/Domain/EligibilityPolicyTests.cs
git commit -m "test(domain): add boundary value tests for EligibilityPolicy"
```

---

## Task 7: Application layer — finalize files

> The Application layer files were created as stubs in Task 2. Verify they match the final design. No change should be needed; this task is a checkpoint.

**Files:**
- Verify: `MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQuery.cs`
- Verify: `MonAssurance.Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQueryHandler.cs`
- Verify: `MonAssurance.Application/Eligibility/Queries/CheckEligibility/EligibilityViewModel.cs`

- [ ] **Step 1: Confirm final form of each file matches spec**

`CheckEligibilityQuery.cs` must be:

```csharp
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed record CheckEligibilityQuery(
    DateOnly DateOfBirth,
    VehicleType VehicleType,
    int? Power,
    int LicenseYears);
```

`EligibilityViewModel.cs` must be:

```csharp
namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class EligibilityViewModel
{
    public bool IsEligible { get; }
    public string? RejectionReason { get; }

    private EligibilityViewModel(bool isEligible, string? reason)
    {
        IsEligible = isEligible;
        RejectionReason = reason;
    }

    public static EligibilityViewModel Accepted() => new(true, null);
    public static EligibilityViewModel Refused(string reason) => new(false, reason);
}
```

`CheckEligibilityQueryHandler.cs` must be:

```csharp
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Application.Eligibility.Queries.CheckEligibility;

public sealed class CheckEligibilityQueryHandler
{
    private readonly EligibilityPolicy _policy;
    private readonly TimeProvider _timeProvider;

    public CheckEligibilityQueryHandler(EligibilityPolicy policy, TimeProvider timeProvider)
    {
        _policy = policy;
        _timeProvider = timeProvider;
    }

    public EligibilityViewModel Handle(CheckEligibilityQuery query)
    {
        var today = DateOnly.FromDateTime(_timeProvider.GetUtcNow().UtcDateTime);
        var driver = new Driver(query.DateOfBirth, query.LicenseYears);
        var vehicle = new Vehicle(query.VehicleType, query.Power);

        return _policy
            .Evaluate(driver, vehicle, today)
            .Match(
                onAccepted: () => EligibilityViewModel.Accepted(),
                onRefused: reason => EligibilityViewModel.Refused(reason)
            );
    }
}
```

- [ ] **Step 2: Run all unit tests — confirm still GREEN**

```bash
dotnet test MonAssurance.UnitTests/MonAssurance.UnitTests.csproj
```

Expected: **16 tests PASSED**.

- [ ] **Step 3: Commit if any corrections were made**

```bash
git add MonAssurance.Application/Eligibility/
git commit -m "feat(application): add CheckEligibilityQueryHandler"
```

---

## Task 8: DI registration

**Files:**
- Modify: `MonAssurance.Infrastructure/DependencyInjection.cs` (or create if it doesn't exist)
- Modify: `MonAssurance.Api/Program.cs`

- [ ] **Step 1: Check if DependencyInjection.cs exists**

```bash
find /Users/sebastiendegodez/Documents/source.nosync/meetup-coding-with-ai/MonAssurance.Infrastructure \
  -name "DependencyInjection.cs"
```

- [ ] **Step 2a: If the file exists — add the registrations**

Open `MonAssurance.Infrastructure/DependencyInjection.cs` and add inside the service registration method:

```csharp
// Inside the existing registration method
services.AddSingleton<EligibilityPolicy>();
services.AddScoped<CheckEligibilityQueryHandler>();
```

Add the necessary `using` directives at the top:

```csharp
using MonAssurance.Application.Eligibility.Queries.CheckEligibility;
using MonAssurance.Domain.Eligibility;
```

- [ ] **Step 2b: If the file does not exist — create it**

```csharp
// MonAssurance.Infrastructure/DependencyInjection.cs
using Microsoft.Extensions.DependencyInjection;
using MonAssurance.Application.Eligibility.Queries.CheckEligibility;
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddSingleton<EligibilityPolicy>();
        services.AddScoped<CheckEligibilityQueryHandler>();
        return services;
    }
}
```

Then call it in `Program.cs`:

```csharp
builder.Services.AddInfrastructure();
```

- [ ] **Step 3: Ensure `TimeProvider` is registered**

In `Program.cs`, verify `TimeProvider.System` is registered (add if missing):

```csharp
builder.Services.AddSingleton(TimeProvider.System);
```

- [ ] **Step 4: Build to confirm no errors**

```bash
dotnet build MonAssurance.sln
```

Expected: `Build succeeded.`

- [ ] **Step 5: Commit**

```bash
git add MonAssurance.Infrastructure/DependencyInjection.cs MonAssurance.Api/Program.cs
git commit -m "feat(infra): register eligibility services"
```

---

## Task 9: API endpoint

**Files:**
- Create: `MonAssurance.Api/Eligibility/EligibilityEndpoints.cs`
- Modify: `MonAssurance.Api/Program.cs`

- [ ] **Step 1: Create the endpoint file**

```csharp
// MonAssurance.Api/Eligibility/EligibilityEndpoints.cs
using MonAssurance.Application.Eligibility.Queries.CheckEligibility;

namespace MonAssurance.Api.Eligibility;

public static class EligibilityEndpoints
{
    public static IEndpointRouteBuilder MapEligibilityEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/eligibility", (
            CheckEligibilityQuery query,
            CheckEligibilityQueryHandler handler) =>
            Results.Ok(handler.Handle(query)));

        return app;
    }
}
```

- [ ] **Step 2: Register the endpoint in Program.cs**

In `MonAssurance.Api/Program.cs`, after `app` is built, add:

```csharp
using MonAssurance.Api.Eligibility;

// ...

app.MapEligibilityEndpoints();
```

- [ ] **Step 3: Build and run a quick smoke test**

```bash
dotnet build MonAssurance.sln
```

Expected: `Build succeeded.`

- [ ] **Step 4: Commit**

```bash
git add MonAssurance.Api/Eligibility/EligibilityEndpoints.cs MonAssurance.Api/Program.cs
git commit -m "feat(api): add POST /eligibility endpoint"
```

---

## Task 10: API walking skeleton integration test

**Files:**
- Create: `MonAssurance.IntegrationTests/Eligibility/EligibilityEndpointsTests.cs`

Uses `WebApplicationFactory<Program>` (in-process). Sends a real HTTP POST and asserts 200 + `isEligible: true`.

- [ ] **Step 1: Verify WebApplicationFactory is available**

Check `MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj` for:

```xml
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="*" />
```

If missing, add it:

```bash
dotnet add MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj \
  package Microsoft.AspNetCore.Mvc.Testing
```

- [ ] **Step 2: Ensure Program is accessible**

In `MonAssurance.Api/Program.cs`, add at the bottom (after all registrations):

```csharp
public partial class Program { } // make Program accessible from test projects
```

- [ ] **Step 3: Create the integration test**

```csharp
// MonAssurance.IntegrationTests/Eligibility/EligibilityEndpointsTests.cs
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using MonAssurance.Domain.Eligibility;

namespace MonAssurance.IntegrationTests.Eligibility;

public class EligibilityEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public EligibilityEndpointsTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task PostEligibility_WhenDriverIs25AndHasCar_Returns200AndIsEligibleTrue()
    {
        var payload = new
        {
            dateOfBirth = new DateOnly(2001, 1, 1).ToString("yyyy-MM-dd"),
            vehicleType = VehicleType.Car,
            power = (int?)null,
            licenseYears = 5
        };

        var response = await _client.PostAsJsonAsync("/eligibility", payload);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<EligibilityResponse>();
        Assert.NotNull(result);
        Assert.True(result.IsEligible);
        Assert.Null(result.RejectionReason);
    }

    // Local DTO for deserialization — mirrors EligibilityViewModel shape
    private sealed record EligibilityResponse(bool IsEligible, string? RejectionReason);
}
```

- [ ] **Step 4: Run integration tests**

```bash
dotnet test MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj
```

Expected: **1 test PASSED** — `PostEligibility_WhenDriverIs25AndHasCar_Returns200AndIsEligibleTrue`.

If test fails with 404: confirm `app.MapEligibilityEndpoints()` is called in `Program.cs` before `app.Run()`.

- [ ] **Step 5: Commit**

```bash
git add MonAssurance.IntegrationTests/Eligibility/EligibilityEndpointsTests.cs \
        MonAssurance.Api/Program.cs
git commit -m "test(integration): add POST /eligibility walking skeleton test"
```

---

## Task 11: Architecture test — Domain has no framework dependencies

**Files:**
- Create: `MonAssurance.IntegrationTests/Architecture/DomainArchitectureTests.cs`

Uses NetArchTest to assert the Domain assembly has zero dependency on any non-`System` / non-`MonAssurance.Domain` assembly.

- [ ] **Step 1: Verify NetArchTest is referenced**

Check `MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj` for:

```xml
<PackageReference Include="NetArchTest.Rules" Version="*" />
```

If missing:

```bash
dotnet add MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj \
  package NetArchTest.Rules
```

- [ ] **Step 2: Create the architecture test**

```csharp
// MonAssurance.IntegrationTests/Architecture/DomainArchitectureTests.cs
using MonAssurance.Domain.Eligibility;
using NetArchTest.Rules;

namespace MonAssurance.IntegrationTests.Architecture;

public class DomainArchitectureTests
{
    [Fact]
    public void Domain_ShouldHaveNoFrameworkDependencies()
    {
        // The Domain assembly is identified via a type it contains.
        var result = Types.InAssembly(typeof(EligibilityPolicy).Assembly)
            .ShouldNot()
            .HaveDependencyOnAny(
                "Microsoft.AspNetCore",
                "Microsoft.Extensions.DependencyInjection",
                "Microsoft.EntityFrameworkCore",
                "System.Net.Http",
                "MonAssurance.Application",
                "MonAssurance.Infrastructure",
                "MonAssurance.Api"
            )
            .GetResult();

        Assert.True(result.IsSuccessful,
            $"Domain has forbidden dependencies: {string.Join(", ", result.FailingTypeNames ?? [])}");
    }
}
```

- [ ] **Step 3: Run architecture tests**

```bash
dotnet test MonAssurance.IntegrationTests/MonAssurance.IntegrationTests.csproj
```

Expected: **2 tests PASSED** (walking skeleton + architecture test).

- [ ] **Step 4: Commit**

```bash
git add MonAssurance.IntegrationTests/Architecture/DomainArchitectureTests.cs
git commit -m "test(architecture): assert Domain has no framework dependencies"
```

---

## Final verification

- [ ] **Run the full test suite**

```bash
dotnet test MonAssurance.sln
```

Expected summary:
- `MonAssurance.UnitTests`: **16 tests PASSED** (7 application acceptance + 9 domain boundary)
- `MonAssurance.IntegrationTests`: **2 tests PASSED** (walking skeleton + architecture)
- Total: **18 tests, 0 failures**

- [ ] **Verify the feature branch is clean**

```bash
git log --oneline feat/eligibilite-scenarios
```

Expected commits (bottom to top):
```
test(architecture): assert Domain has no framework dependencies
test(integration): add POST /eligibility walking skeleton test
feat(api): add POST /eligibility endpoint
feat(infra): register eligibility services
feat(application): add CheckEligibilityQueryHandler
test(domain): add boundary value tests for EligibilityPolicy
feat(domain): implement high-power motorcycle experience rule
test(application): add age boundary scenarios
feat(domain): implement age minimum rule
feat(domain): add domain skeleton for eligibility
test(application): add failing acceptance test — eligible driver
chore(tests): add Microsoft.Extensions.TimeProvider.Testing to UnitTests
```
