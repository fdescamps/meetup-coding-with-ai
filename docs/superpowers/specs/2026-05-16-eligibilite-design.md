# Design — Éligibilité à la souscription

**Date :** 2026-05-16  
**Statut :** Approuvé  
**Projet :** MonAssurance (.NET 10, Clean Architecture)

---

## Contexte

La fonctionnalité **Éligibilité** détermine si un conducteur peut souscrire à une assurance auto. Le point d'entrée est un endpoint HTTP unique qui évalue les règles métier et retourne un résultat binaire avec, le cas échéant, un motif de refus.

---

## Décisions

### 1. Modèle de réponse
Résultat simple : `{ isEligible: bool, rejectionReason: string? }`. Pas de trace d'audit, pas de liste de règles détaillées.

### 2. Patron d'architecture applicative
**CQS** sans bus (`ICommandBus`/`IQueryBus` non utilisés). Handlers injectés directement dans l'endpoint.

### 3. Surface API
`POST /eligibility` avec toutes les données dans le corps de la requête.

### 4. Abstraction du temps
`TimeProvider` (.NET built-in) injecté dans `CheckEligibilityQueryHandler`.

### 5. Approche architecturale
Domain Service pour les règles (`EligibilityPolicy`) + Application orchestrateur (`CheckEligibilityQueryHandler`).

### 6. Nommage CQS
`CheckEligibilityQuery` / `CheckEligibilityQueryHandler`. DTOs de sortie nommés `*ViewModel`.

### 7. Object Calisthenics
Pas de getters/setters sur les objets Domain. `Driver` et `Vehicle` exposent des méthodes comportementales. `EligibilityResult` utilise le pattern `Match<T>` — aucun getter, la branche est déléguée à l'appelant.

---

## Organisation des fichiers

```
Domain/
  Eligibility/
    VehicleType.cs           ← enum (Car, Motorcycle, ElectricScooter)
    Driver.cs                ← sealed class, méthodes Age(today) et HasEnoughExperience(years)
    Vehicle.cs               ← sealed class, méthodes MinimumAge() et IsHighPowerMotorcycle()
    EligibilityResult.cs     ← sealed class, factory Accepted()/Refused(reason), méthode Match<T>
    EligibilityPolicy.cs     ← domain service pur, Evaluate(driver, vehicle, today)

Application/
  Eligibility/
    Queries/
      CheckEligibility/
        CheckEligibilityQuery.cs         ← DTO entrant (DateOfBirth, VehicleType, Power?, LicenseYears)
        CheckEligibilityQueryHandler.cs  ← orchestre TimeProvider + EligibilityPolicy
        EligibilityViewModel.cs          ← DTO sortant (IsEligible, RejectionReason?), factory Accepted()/Refused()

Api/
  Eligibility/
    EligibilityEndpoints.cs  ← POST /eligibility → injecte CheckEligibilityQueryHandler
```

---

## Design des objets domaine

```csharp
// Domain/Eligibility/VehicleType.cs
public enum VehicleType { Car, Motorcycle, ElectricScooter }

// Domain/Eligibility/Driver.cs
public sealed class Driver
{
    private readonly DateOnly _dateOfBirth;
    private readonly int _licenseYears;

    public Driver(DateOnly dateOfBirth, int licenseYears)
    {
        _dateOfBirth = dateOfBirth;
        _licenseYears = licenseYears;
    }

    public int Age(DateOnly today) => /* calcul anniversaire */;
    public bool HasEnoughExperience(int minimumYears) => _licenseYears >= minimumYears;
}

// Domain/Eligibility/Vehicle.cs
public sealed class Vehicle
{
    private readonly VehicleType _type;
    private readonly int? _power;

    public Vehicle(VehicleType type, int? power)
    {
        _type = type;
        _power = power;
    }

    public int MinimumAge() => _type == VehicleType.ElectricScooter ? 16 : 18;
    public bool IsHighPowerMotorcycle() => _type == VehicleType.Motorcycle && _power > 100;
}

// Domain/Eligibility/EligibilityResult.cs
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

// Domain/Eligibility/EligibilityPolicy.cs
public sealed class EligibilityPolicy
{
    public EligibilityResult Evaluate(Driver driver, Vehicle vehicle, DateOnly today)
    {
        if (driver.Age(today) < vehicle.MinimumAge())
            return EligibilityResult.Refused("Conducteur trop jeune pour ce véhicule");

        if (vehicle.IsHighPowerMotorcycle() && !driver.HasEnoughExperience(5))
            return EligibilityResult.Refused("Expérience insuffisante pour la puissance");

        return EligibilityResult.Accepted();
    }
}
```

---

## Design Application

```csharp
// Application/Eligibility/Queries/CheckEligibility/CheckEligibilityQueryHandler.cs
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
                onRefused:  reason => EligibilityViewModel.Refused(reason)
            );
    }
}

// Application/Eligibility/Queries/CheckEligibility/EligibilityViewModel.cs
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

---

## Design API

```csharp
// Api/Eligibility/EligibilityEndpoints.cs
app.MapPost("/eligibility", (CheckEligibilityQuery query, CheckEligibilityQueryHandler handler) =>
    Results.Ok(handler.Handle(query)));
```

---

## Flux d'appel

```
POST /eligibility
  → CheckEligibilityQueryHandler.Handle(query)
      → TimeProvider.GetUtcNow() → calcul de l'âge
      → new Driver(dateOfBirth, licenseYears)
      → new Vehicle(vehicleType, power)
      → EligibilityPolicy.Evaluate(driver, vehicle, today)
          → EligibilityResult.Refused(...) ou Accepted()
      → .Match(onAccepted, onRefused)
          → EligibilityViewModel
  → 200 OK
```

Aucun getter lu sur les objets Domain. `Match` est le seul pont entre Domain et Application.

---

## Règles métier

| # | Règle | Condition | Motif de refus |
|---|-------|-----------|----------------|
| 1 | Âge minimum — voiture / moto | Conducteur < 18 ans | `"Conducteur trop jeune pour ce véhicule"` |
| 2 | Âge minimum — trottinette électrique | Conducteur < 16 ans | `"Conducteur trop jeune pour ce véhicule"` |
| 3 | Expérience pour moto puissante | Moto > 100 ch ET permis < 5 ans | `"Expérience insuffisante pour la puissance"` |

Un conducteur est **éligible** si aucune règle de refus ne s'applique.

---

## Principes appliqués

- **Object Calisthenics** : pas de getters/setters sur les objets Domain
- **Tell, Don't Ask** : `Driver` et `Vehicle` exposent des comportements, pas de l'état
- **Match pattern** : `EligibilityResult` délègue le branchement à l'appelant sans exposer son état
- **Iron Law Clean Architecture** : Domain zéro dépendance framework ; Application dépend uniquement de Domain

---

## Stratégie de test

Basée sur les skills `clean-architecture-testing` et `outside-in-tdd`.

### Règle fondamentale

**Par défaut : Acceptance test au niveau Application** — entrée par `CheckEligibilityQueryHandler.Handle()`, pas par `EligibilityPolicy` directement.  
Tests Domain extraits uniquement pour `EligibilityPolicy` car la matrice de scénarios Gherkin justifie des tests unitaires ciblés sur les règles complexes.

### Matrice de couverture

| Couche | Projet de test | Point d'entrée | Doubles | Ce qui est couvert |
|--------|---------------|----------------|---------|-------------------|
| **Application** | `MonAssurance.UnitTests` | `CheckEligibilityQueryHandler.Handle()` | `FakeTimeProvider` (Microsoft.Extensions.TimeProvider.Testing) | Tous les scénarios Gherkin (âge, véhicule, puissance) |
| **Domain** | `MonAssurance.UnitTests` | `EligibilityPolicy.Evaluate()` | Aucun — objets réels | Règles métier isolées, boundary values |
| **API** | `MonAssurance.IntegrationTests` | `POST /eligibility` via in-process app host | Stack réelle | Walking skeleton — happy path |
| **Architecture** | `MonAssurance.IntegrationTests` | Assembly scan (NetArchTest) | Aucun | Iron Law : Domain zéro dépendance framework |

### Ce qu'on ne teste PAS directement

- `Driver`, `Vehicle` : couverts indirectement par les tests Application et Domain
- `EligibilityViewModel` : DTO de sortie, pas de logique à tester
- `CheckEligibilityQuery` : DTO entrant, pas de logique à tester
- Constructeurs simples

### Approche Outside-In

Les classes Domain (`Driver`, `Vehicle`, `EligibilityPolicy`, `EligibilityResult`, `VehicleType`) **ne sont PAS créées avant le premier test en rouge**. Le design émerge de la compilation échouée des tests, conformément au skill `outside-in-tdd`.

Ordre d'implémentation :
1. Acceptance test Application (RED — ne compile pas)
2. Création des classes Domain minimales pour compiler
3. GREEN sur le premier scénario
4. Itération sur les scénarios suivants
5. Tests Domain pour les boundary values
6. Test API walking skeleton
7. Test architecture
