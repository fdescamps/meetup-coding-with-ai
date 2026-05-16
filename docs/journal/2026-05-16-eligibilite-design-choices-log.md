# Journal des choix de design — Éligibilité

**Date :** 2026-05-16  
**Contexte :** Session de design pour la fonctionnalité d'éligibilité (assurance auto). Ce journal documente uniquement les choix qui ont nécessité une délibération. Les conventions triviales sont listées en tête de document et n'apparaissent pas dans les décisions.

---

## Conventions retenues (non débattues)

Les points suivants ont été appliqués sans délibération : ils découlent directement des skills chargés ou du standard .NET 10.

- **CQS sans bus** — règle explicite du skill `clean-architecture-dotnet` : *"< 3 use cases, pas de cross-cutting pipeline → pas de bus"*
- **`TimeProvider`** — abstraction standard .NET 8+, aucune alternative légitime sur .NET 10 ; `FakeTimeProvider` fourni par `Microsoft.Extensions.TimeProvider.Testing`
- **Nommage `*QueryHandler` / `*Query` / `*ViewModel`** — conséquence naturelle de la convention CQS ; rend explicite la nature lecture vs écriture de chaque cas d'usage
- **Object Calisthenics (9 règles)** — instruction projet `.github/instructions/object-calisthenics.instructions.md` présente dès le départ (`applyTo: **/*.{cs,ts,java}`). Non chargée par l'assistant en début de session — l'utilisateur a dû la rappeler explicitement. Conséquence : `Driver` et `Vehicle` sont des classes comportementales (pas des records), `EligibilityResult` utilise `Match<T>` (voir Choix 4)
- **Skills chargés :** `clean-architecture-dotnet`, `clean-architecture-testing`, `outside-in-tdd`
- **Instruction manquée :** `object-calisthenics.instructions.md` — présente dans le projet, non chargée en début de session

---

## Choix 1 — Modèle de réponse

> **Question :** Quelle structure retourner en réponse à une évaluation d'éligibilité ?

| Option | Description | Statut |
|--------|-------------|--------|
| A | Résultat simple : `{ isEligible: bool, rejectionReason: string? }` | ✅ Choisi |
| B | Résultat enrichi : résultat global + détail de chaque règle évaluée | ❌ Rejeté |
| C | Résultat avec audit trail : résultat + règles + timestamp + version des règles | ❌ Rejeté |

---

### Option A — Résultat simple

**Explication :** Retourne uniquement un booléen `isEligible` et, en cas de refus, le motif sous forme de chaîne optionnelle `rejectionReason`. Le contrat est minimal et auto-explicatif.

- ✅ Simple à implémenter et à consommer côté frontend
- ✅ Contrat minimal — pas de couplage fort sur la structure interne des règles
- ✅ Évolutif : on peut enrichir plus tard sans casser les consommateurs existants
- ❌ Ne permet pas d'inspecter quelles règles ont été évaluées et pourquoi

---

### Option B — Résultat enrichi

**Explication :** Retourne le résultat global (`isEligible`) ainsi que la liste de toutes les règles évaluées avec leur verdict individuel (ex : `{ ruleName: "AgeMinimum", passed: false }`).

- ✅ Utile pour le debugging, les logs, et un affichage détaillé côté UI
- ✅ Permet à l'appelant de comprendre précisément ce qui a bloqué
- ❌ Complexifie le contrat de réponse — le consommateur doit comprendre la structure interne des règles
- ❌ Sur-ingénierie pour le besoin actuel : le frontend n'a pas besoin du détail règle par règle

---

### Option C — Résultat avec audit trail

**Explication :** Ajoute une traçabilité complète de la décision : résultat, règles évaluées, timestamp de la décision et version du référentiel de règles appliqué. Répond à des exigences de compliance ou d'audit réglementaire.

- ✅ Nécessaire pour des contextes réglementaires stricts (ex : assurance soumise à obligation d'explication)
- ✅ Permet de rejouer ou de contester une décision a posteriori
- ❌ Prématuré : ajoute de la persistance et de la complexité non demandées à ce stade
- ❌ Implique des décisions de stockage et de rétention qui sortent du scope de la feature

---

> **Recommandation :** **Option A** — répond au besoin sans complexité inutile. L'option B peut être envisagée si un besoin de debugging en production émerge. L'option C est à réserver à un contexte réglementaire explicite.

---

## Choix 2 — Surface API

> **Question :** Quel verbe HTTP et quelle structure d'URL pour exposer l'évaluation d'éligibilité ?

| Option | Description | Statut |
|--------|-------------|--------|
| A | `POST /eligibility` avec payload JSON | ✅ Choisi |
| B | `GET /eligibility?age=18&vehicule=Voiture` | ❌ Rejeté |
| C | Pas d'API — uniquement domaine et tests | ⬜ Non retenu |

---

### Option A — `POST /eligibility` avec payload JSON

**Explication :** Un seul endpoint `POST` qui reçoit toutes les données du conducteur et du véhicule dans le corps de la requête en JSON (ex : `{ "driverBirthDate": "2008-01-01", "vehicleType": "Car" }`).

- ✅ Payload structuré et extensible — on peut ajouter des champs sans changer l'URL
- ✅ Données sensibles (date de naissance) non exposées dans l'URL ni dans les logs serveur — conformité RGPD
- ✅ Aligné sur la sémantique REST pour une opération d'évaluation (action métier, pas une ressource CRUD)
- ✅ Taille de payload non limitée contrairement aux query strings
- ❌ Sémantiquement discutable au sens RESTful strict : un `POST` implique généralement un effet de bord persistant

---

### Option B — `GET /eligibility?age=18&vehicule=Voiture`

**Explication :** Les paramètres d'entrée sont passés en query string, ce qui est idiomatique pour une opération de lecture sans effet de bord.

- ✅ RESTful pur pour une opération sans effet de bord — idempotent par nature
- ✅ Facile à appeler depuis un navigateur ou un outil de test sans corps de requête
- ❌ Données personnelles (date de naissance) visibles dans l'URL, les logs, l'historique du navigateur → problème de confidentialité (RGPD)
- ❌ Limite de taille des query strings selon les serveurs et proxies
- ❌ Moins extensible : ajouter un champ structuré (ex : liste de conducteurs) devient compliqué

---

### Option C — Pas d'API

**Explication :** Implémenter uniquement la logique métier (Domain + Application) sans exposer de couche HTTP. Utile pour valider le design du domaine avant de s'engager sur une surface API.

- ✅ Focalise sur le domain-first — idéal pour une première itération TDD
- ✅ Évite les décisions prématurées sur l'API
- ❌ Insuffisant pour un contexte d'intégration réel — un consommateur doit pouvoir appeler le service
- ❌ Retarde l'intégration et les tests end-to-end

---

> **Recommandation :** **Option A** — `POST` évite l'exposition de données personnelles dans l'URL et offre un payload extensible. La légère entorse à la pureté REST est acceptable pour des raisons de sécurité et de conformité RGPD.

---

## Choix 3 — Approche architecturale

> **Décision guidée par la skill `clean-architecture-dotnet`** — pas de délibération.

Le skill énonce sans ambiguïté : *"Business rules belong in Domain."* Les options A (règles dans Application) et C (Value Objects auto-validants) sont toutes deux exclues par deux règles explicites du skill :
- Option A rejetée : *"If domain has business rules → they belong in Domain, not Application"*
- Option C rejetée : *"If you never need `if (condition) throw` to protect state → plain `sealed record`, not DDD"*

**Option B retenue directement** : `EligibilityPolicy` (domain service pur) + `CheckEligibilityQueryHandler` (orchestrateur Application).

| Option | Description | Statut |
|--------|-------------|--------|
| A | Règles dans Application, Domain = données pures | ❌ Exclu par la skill |
| B | `EligibilityPolicy` Domain Service + `CheckEligibilityQueryHandler` | ✅ Retenu par la skill |
| C | Value Objects auto-validants avec factory methods | ❌ Exclu par la skill |

---

## Choix 4 — Design de `EligibilityResult`

Ce choix est apparu après l'introduction de la contrainte Object Calisthenics. Les positions des auteurs de référence ont été consultées pour trancher entre les options.

> **Question :** La règle 9 Object Calisthenics (no getters/setters, Tell Don't Ask) exclut d'exposer l'état d'`EligibilityResult` via des propriétés directes. Quel pattern utiliser pour qu'`EligibilityPolicy` communique son résultat à la couche Application — et comment l'Application branche-t-elle sur accepté / refusé — sans que le Domain expose son état interne ?

| Option | Description | Statut |
|--------|-------------|--------|
| A | Propriétés `get`-only (`IsEligible`, `RejectionReason`) | ⬜ Acceptable (Vernon) |
| B | Pattern `Match<T>` — zéro getter, branchement délégué | ✅ Choisi |
| C | Domain Exception (`EligibilityRefusedException`) | ❌ Rejeté |
| D | `EligibilityResult` déplacé dans Application | ⬜ Non retenu |

---

### Option A — Propriétés `get`-only

**Explication :** Exposer `IsEligible` et `RejectionReason` en lecture seule — style Vaughn Vernon. L'Application lit l'état du résultat et branche en conséquence (`if (result.IsEligible) ...`).

- ✅ Familier, idiomatique C#, acceptable per DDD Vernon
- ✅ Aucune connaissance de patterns fonctionnels requise par l'équipe
- ❌ L'Application lit l'état du Domain (`if result.IsEligible`) → viole Object Calisthenics et "Tell, Don't Ask"
- ❌ Le branchement `if/else` dans le handler duplique implicitement la logique du résultat

---

### Option B — Pattern `Match<T>` ✅

**Explication :** `EligibilityResult` expose `Match<T>(Func<T> onAccepted, Func<string, T> onRefused)`. L'appelant fournit les deux branches, le Domain choisit laquelle exécuter. L'état reste totalement encapsulé.

- ✅ Zéro getter sur les objets Domain — état totalement encapsulé
- ✅ Point de convergence entre Object Calisthenics, Uncle Bob (Output Boundary) et Railway Oriented Programming
- ✅ L'Application ne lit jamais l'état du Domain — le Domain pilote le branchement
- ❌ Moins familier pour des équipes non habituées au style fonctionnel

---

### Option C — Domain Exception

**Explication :** `EligibilityPolicy.Evaluate()` lève `EligibilityRefusedException(reason)` en cas de refus, retourne `void` si accepté. Zéro result type, zéro getter.

- ✅ Zéro getter, zéro result type — le plus simple à implémenter
- ❌ Anti-pattern : utiliser les exceptions pour du flow métier normal (les exceptions sont pour les cas exceptionnels, pas les refus d'éligibilité)
- ❌ Cache le refus dans le mécanisme d'exception — invisible dans la signature de la méthode

---

### Option D — `EligibilityResult` dans Application

**Explication :** Le Domain retourne un type primitif (`string?` ou `enum`) et c'est la couche Application qui encapsule ce résultat dans un objet `EligibilityResult`.

- ✅ Domain encore plus pur — aucun objet résultat à maintenir
- ❌ Le motif de refus remonte du Domain sous forme de primitif — perd l'expressivité
- ❌ La distinction accepté/refusé n'est plus portée par le type — retour à un booléen déguisé

---

#### Références consultées pour ce choix

> Positions des auteurs de référence sur les getters et les result types, ayant influencé ce choix.

| Auteur | Position sur les getters / result types |
|--------|-----------------------------------------|
| Vaughn Vernon | Propriétés `get`-only acceptables sur les Value Objects — encapsulation suffisante si l'état ne fuit pas en dehors du Domain |
| Uncle Bob (Robert C. Martin) | Output Boundary / Presenter — le use case appelle une interface de présentation, ne retourne pas de données brutes ; `Match` est l'équivalent inline de ce principe |
| Greg Young / Udi Dahan | Domain Events pour le write side uniquement ; les queries retournent des DTOs directs sans logique — pas de position sur les getters dans les résultats de policy |
| Object Calisthenics (Jeff Bay) | Règle 9 : no getters/setters → Tell Don't Ask. L'objet expose un comportement, pas son état. `Match<T>` est une application possible de ce principe, mais non prescrite par la règle elle-même. |

**Conclusion :** `Match` est compatible avec l'ensemble de ces positions et constitue le point de convergence le plus rigoureux pour un contexte Object Calisthenics + Clean Architecture.

> **Recommandation :** **Option B** — le `Match` est le pont le plus propre entre Domain et Application sans getter. Compatible avec tous les styles de référence (tableau ci-dessus).

---

## Choix 5 — Stratégie de test

> **Décision guidée par la skill `clean-architecture-testing`** — application directe d'un critère.

Le skill pose : *"Extract a Domain test ONLY when a business rule has a large edge-case matrix AND is extracted into a reusable Policy / Domain Service."*

`EligibilityPolicy` remplit les deux conditions :
- Policy extraite dans le Domain ✅
- Matrice de cas complexe : 3 règles indépendantes, valeurs limites multiples (16/18 ans selon véhicule, 100/101 ch, 5 ans de permis), ≥ 12 scénarios Gherkin ✅

**Décision appliquée directement** :
- Tests Domain sur `EligibilityPolicy` (critère rempli)
- Tests Application via `CheckEligibilityQueryHandler` + `FakeTimeProvider` (scénarios représentatifs d'orchestration)
- `Driver` et `Vehicle` non testés isolément — couverts par les tests d'`EligibilityPolicy`

---

## Revue de spec — `spec-document-reviewer` (subagent)

**Artefact reviewé :** `docs/superpowers/specs/2026-05-16-eligibilite-design.md`  
**Agent :** subagent `spec-document-reviewer` (skill `brainstorming` étape 7)  
**Itérations :** 2 (1 × CHANGES_REQUESTED → corrections → 1 × APPROVED)

### Itération 1 — CHANGES_REQUESTED

Le reviewer a identifié un problème réel : la section `### Calcul de DateOfBirth dans les tests` utilisait `new DateOnly(2026, 5, 16)` (date du jour de la session) au lieu de `new DateOnly(2026, 1, 1)` (date de référence du `Contexte` Gherkin). Cette incohérence aurait propagé une date erronée dans tous les tests qui copient ce snippet.

Les 3 autres points soulevés (définition de `CheckEligibilityQuery`, convention null sur `IsHighPowerMotorcycle()`, formule `Driver.Age()`) étaient déjà présents dans la spec — le reviewer les avait manqués lors du premier passage.

### Correction appliquée

Date remplacée dans le snippet de test :
```csharp
// Avant
var today = new DateOnly(2026, 5, 16);

// Après
var today = new DateOnly(2026, 1, 1); // date injectée via FakeTimeProvider (= Contexte Gherkin)
```

### Itération 2 — APPROVED

Spec approuvée sans réserve.

---

## Revue du plan — `plan-document-reviewer` (subagent)

- **Trigger**: plan écrit via skill `writing-plans`. Review obligatoire avant exécution.
- **Mode**: skill-guided
- **Agent**: subagent `plan-document-reviewer` (skill `writing-plans` — loop review)
- **Itérations**: 2 (1 × CHANGES_REQUESTED → corrections → re-dispatch prévu)

### Problèmes trouvés (itération 1)

| # | Problème | Correction |
|---|----------|------------|
| 1 | Aucun test Motorcycle 17yo refusé — règle 1 couvre Car ET Motorcycle | Ajout `Handle_WhenDriverIs17AndHasMotorcycle_ReturnsRefused` dans Task 4 |
| 2 | Task 4 Step 2 cosmétique — tests ajoutés après implémentation complète → pas de vrai RED | Suppression du faux RED step ; tests vont directement en GREEN ; description clarifiée |

---

## Exécution — subagent-driven-development

- **Trigger**: plan approuvé. Skill `writing-plans` → skill `subagent-driven-development`.
- **Mode**: skill-guided

| Task | Statut | Commit | Résultat compilation/test |
|------|--------|--------|--------------------------|
| 0 — setup `FakeTimeProvider` | ✅ DONE | `a66fd35` | `Build succeeded. 0 Error(s)` — package v10.6.0 |
| 1 — premier test acceptance (RED) | ✅ DONE | `4fcae4c` | `CS0234: The type or namespace name 'CheckEligibilityQueryHandler' could not be found` — compile error confirmé |
| 2 — Domain + Application skeleton | ✅ DONE | `387c79d` | `Assert.True() Failure — Expected: True / Actual: False` — compilation OK, assertion RED confirmé |
| 3 — règle âge minimum (GREEN) | ✅ DONE | `bc6cabd` | `1 passed, 0 failed` |
| 4 — boundary âge (Car/Motorcycle 17yo, ElectricScooter 15yo/16yo) | ✅ DONE | `5683f6a` | `5 passed, 0 failed` |
| 5 — règle moto puissante (RED→GREEN) | ✅ DONE | `ae78bd0` | RED: `7 passed, 1 failed` → GREEN: `8 passed, 0 failed` |
| 6 — boundary values Domain (`EligibilityPolicy`) | ✅ DONE | `0e1926c` | `17 passed, 0 failed` — 9 nouveaux tests, zéro nouveau code |
| 7 — checkpoint Application layer | ✅ DONE | — | Fichiers conformes à la spec, aucune correction. `17 passed` |
| 8 — DI registration | ✅ DONE | `5bc4c12` | `Build succeeded. 0 Error(s)` — `EligibilityPolicy`, `CheckEligibilityQueryHandler`, `TimeProvider.System` |
| 10 — test integration POST /eligibility [RED] | 🔴 RED | `8b757a0` | `Expected: OK — Actual: NotFound` — endpoint absent, test commit avant implémentation |
| 9+10 — endpoint GREEN + fix archi test | ✅ DONE | `49a1d45` | `9 passed, 0 failed` — `EligibilityEndpoints.cs` + règle architecture corrigée |
| 11 — architecture test Domain no framework deps | ✅ DONE | `7788e00` | `10 passed, 0 failed` — `DomainArchitectureTests.cs` |


### Task 4 - Driver.Age() — avant / après

Stub → implémentation réelle. Formule : années civiles complètes. Si anniversaire pas encore passé cette année, soustrait 1.

```csharp
// ❌ Avant (stub Task 2)
public int Age(DateOnly today) => 0;

// ✅ Après (Task 3)
public int Age(DateOnly today)
{
    var age = today.Year - _dateOfBirth.Year;
    if (today < _dateOfBirth.AddYears(age)) age--;
    return age;
}
```

Exemple boundary : `today = 2026-01-01`, `dob = 2008-01-01` → `age = 18` (anniversaire aujourd'hui = 18 ans révolus → éligible). `dob = 2008-01-02` → `age = 17` → refusé.

### Task 5 — pourquoi 7 passed / 1 failed au RED ?

Step 1 ajoute 3 tests. Step 2 lance les tests avant implémentation.

- `Handle_WhenMotorcycleIsHighPowerAndDriverHas4YearsLicense_ReturnsRefused` → **FAILED** : stub `IsHighPowerMotorcycle()` retourne `false` → policy retourne `Accepted()` → assertion `Assert.False(result.IsEligible)` échoue. RED confirmé.
- `Handle_WhenMotorcycleIsHighPowerAndDriverHas5YearsLicense_ReturnsEligible` → **PASSED** par accident : stub retourne `Accepted()` et le test attendait `IsEligible = true`. Mauvaise raison, bon résultat.
- `Handle_WhenMotorcycleIsExactly100HpAndDriverHas4YearsLicense_ReturnsEligible` → **PASSED** par accident : même situation, stub accepte tout.

Total : 5 tests existants (Tasks 1-4) + 2 accidents = 7 passed, 1 genuine failure.

### Task 6 — 17 passed, zéro nouveau code

9 tests boundary directs sur `EligibilityPolicy.Evaluate()` — no `TimeProvider`, objets réels, no doubles. Tous passent immédiatement : domain déjà complet depuis Task 5. Valeur : documente les limites exactes (18yo aujourd'hui = éligible, demain = refusé ; 100hp = OK, 101hp = refusé ; 5 ans permis = OK, 4 ans = refusé). Ces tests utilisent `Match<T>` directement — aucun getter sur `EligibilityResult`.

**Dette TDD identifiée post-implémentation :** tests jamais passés RED → capacité à détecter une régression non prouvée. De plus, le pattern initial `() => true` discardait le retour de `Match<T>` sans `Assert`. Corrigé en commit `e047894` : assertions explicites via capture du résultat et `Assert.True/False`.

```csharp
// ❌ Avant — valeur discardée, pas d'Assert
result.Match(onAccepted: () => true, onRefused: _ => throw new Exception("Expected Accepted"));

// ✅ Après — assertion explicite
var wasAccepted = result.Match(onAccepted: () => true, onRefused: _ => false);
Assert.True(wasAccepted);

// ✅ Après — cas Refused avec capture de raison
var (wasAccepted, capturedReason) = result.Match(
    onAccepted: () => (true, (string?)null),
    onRefused: r => (false, (string?)r));
Assert.False(wasAccepted);
Assert.Equal("Conducteur trop jeune pour ce véhicule", capturedReason);
```

### Task 8 — DI : pourquoi ces scopes ?

`EligibilityPolicy` → `AddSingleton` : service Domain stateless, aucun état mutable, un seul objet pour toute l'app suffit.  
`CheckEligibilityQueryHandler` → `AddScoped` : reçoit `TimeProvider` en injection, scope cohérent avec le cycle HTTP.  
`TimeProvider.System` → `AddSingleton` : une horloge système par app. En tests, remplacée par `FakeTimeProvider`.

### Task 10 — RED avant Task 9 (endpoint) : TDD appliqué

Session précédente avait Task 9 (endpoint) avant Task 10 (test). Utilisateur a corrigé. On a fait `git reset --hard 5bc4c12` pour revenir à l'état après Task 8. Ordre correct :
1. Test créé → `8b757a0` [RED] : `Expected: OK — Actual: NotFound` (404, route absente)
2. Endpoint implémenté → `49a1d45` [GREEN] : `9 passed, 0 failed`

### Détection d'un bug dans `CleanArchitectureTests.cs`

Test préexistant `Api_ShouldNotHaveDependencyOn_Application` supposait un design CQRS avec mediator (où l'API n'importe jamais les handlers). Notre design : CQS sans bus = handlers injectés directement dans les endpoints. L'API référence `CheckEligibilityQueryHandler` par construction.

Règle incorrecte. Règle correcte : API ne doit pas dépendre du **Domain directement** (doit passer par Application). API → Application → Domain est la chaîne normale. Test renommé `Api_ShouldNotHaveDependencyOn_Domain_Directly`.

### Task 11 — architecture test Domain sans dépendances framework

Architecture tests ne passent pas par une phase RED classique : ils valident une invariante existante. Domain est déjà pur depuis Task 2 (skeleton). Test écrit, run immédiatement GREEN.

Gardes vérifiées : pas de `Microsoft.AspNetCore`, `Microsoft.Extensions.DependencyInjection`, `Microsoft.EntityFrameworkCore`, `System.Net.Http`, ni aucun autre layer MonAssurance.

**Résultat final :** `17 passed` (UnitTests) + `10 passed` (IntegrationTests) = **27 tests, 0 failures**.