---
description: "Enforces Object Calisthenics principles for business domain code to ensure clean, maintainable, and robust code"
applyTo: "**/*.Domain/**/*.{cs,ts,java}"
---

# Object Calisthenics Rules

> ⚠️ **Warning:** These are the 9 original Object Calisthenics rules. No rule may be added, removed, or replaced.

## Scope

- **Apply strictly:** Domain layer — aggregates, entities, value objects, domain services, domain events
- **Apply with judgment:** Application layer — use case handlers
- **Exempt:** `*Query`, `*Command`, `*ViewModel`, `*Dto`, Infrastructure classes, test classes

---

## Rules

### 1. One Level of Indentation per Method

Extract inner logic into private methods. Methods must remain flat.

```csharp
// ❌
public void Process() {
    foreach (var item in items) {
        if (item.IsActive) {
            DoSomething(item);
        }
    }
}

// ✅
public void Process() {
    foreach (var item in ActiveItems()) {
        DoSomething(item);
    }
}
```

---

### 2. Don't Use the ELSE Keyword

Use early returns and guard clauses. Fail fast.

```csharp
// ❌
public void Execute(Order order) {
    if (order.IsValid) {
        Process(order);
    } else {
        throw new InvalidOperationException();
    }
}

// ✅
public void Execute(Order order) {
    if (!order.IsValid) throw new InvalidOperationException(nameof(order));
    Process(order);
}
```

---

### 3. Wrap All Primitives and Strings

Domain concepts must not be raw primitives. Wrap them.

```csharp
// ❌
public void Create(string email, int age) { }

// ✅
public void Create(Email email, Age age) { }

public sealed class Age {
    private readonly int _value;
    public Age(int value) {
        if (value < 0) throw new ArgumentOutOfRangeException(nameof(value));
        _value = value;
    }
    public bool IsAtLeast(int minimum) => _value >= minimum;
}
```

---

### 4. First Class Collections

A class with a collection must contain only that collection — no other fields.

```csharp
// ❌
public sealed class Order {
    public int Id { get; }
    public List<OrderLine> Lines { get; }
}

// ✅
public sealed class Order {
    public int Id { get; }
    public OrderLines Lines { get; }
}

public sealed class OrderLines {
    private readonly List<OrderLine> _lines;
    public decimal TotalAmount() => _lines.Sum(l => l.Amount());
}
```

---

### 5. One Dot per Line

Do not chain calls across object boundaries (Law of Demeter).

```csharp
// ❌
var email = order.Customer.GetContact().Email.ToUpper();

// ✅
var email = order.ConfirmationEmail();
```

---

### 6. Don't Abbreviate

Use full, meaningful names.

```csharp
// ❌
var usr = new Usr(nm, ag);

// ✅
var user = new User(name, age);
```

---

### 7. Keep Entities Small

- Max 10 methods per class
- Max 50 lines per class
- Max 10 classes per namespace

---

### 8. No Classes with More Than Two Instance Variables

The target is **2 instance variables**. Start there and challenge yourself: if you need more, ask whether several fields belong together as a concept and can be grouped into a value object. More than 2 is sometimes acceptable, but it must be justified — it signals a missing abstraction.

```csharp
// ❌ — 4 fields: Driver has too much to know about itself
public sealed class Driver {
    private readonly DateOnly _birthDate;
    private readonly int _licenseYears;
    private readonly VehicleType _lastVehicleType;
    private readonly int _accidentCount;
}

// 🤔 Challenge: do _lastVehicleType and _accidentCount belong together?
// They describe the driver's driving history — a concept of its own.

// ✅ — compose the hidden concept
public sealed class Driver {
    private readonly DateOnly _birthDate;
    private readonly DrivingHistory _history;
}

public sealed class DrivingHistory {
    private readonly VehicleType _lastVehicleType;
    private readonly int _accidentCount;

    public bool IsExperiencedWith(VehicleType type) => _lastVehicleType == type;
    public bool HasCleanRecord() => _accidentCount == 0;
}
```

---

### 9. No Getters/Setters in Domain Classes

Domain objects must not expose their internal state. Expose behavior instead — **Tell, Don't Ask**.

```csharp
// ❌ — exposes state, caller decides
public sealed class User {
    public DateOnly BirthDate { get; init; }
    public int LicenseYears { get; init; }
}
// caller asks state and decides:
if (user.LicenseYears >= 5) { ... }

// ✅ — object exposes behavior, caller delegates decision
public sealed class User {
    private readonly DateOnly _birthDate;
    private readonly int _licenseYears;

    public User(DateOnly birthDate, int licenseYears) {
        _birthDate = birthDate;
        _licenseYears = licenseYears;
    }

    public int Age(DateOnly today) => /* calculate */;
    public bool HasEnoughExperience(int minimumYears) => _licenseYears >= minimumYears;
}
// caller tells:
if (user.HasEnoughExperience(5)) { ... }
```

---

## Exemptions

The following types may use public get-only properties (no setters) for serialization and binding:

- `*Query`, `*Command` — inbound DTOs
- `*ViewModel`, `*Dto`, `*Response` — outbound data carriers
- Infrastructure classes — persistence, HTTP clients
- Test classes — readability over discipline

## References

- [Object Calisthenics — Jeff Bay (original)](https://www.cs.helsinki.fi/u/luontola/tdd-2009/ext/ObjectCalisthenics.pdf)
- [ThoughtWorks — Object Calisthenics](https://www.thoughtworks.com/insights/blog/object-calisthenics)
