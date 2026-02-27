---
applyTo: '**/*.{js,ts,jsx,tsx}'
---

# Object Calisthenics Rules — JavaScript / TypeScript

## Objective

This rule enforces the principles of Object Calisthenics to ensure clean, maintainable, and robust code in JavaScript and TypeScript codebases.

> **Note de traduction depuis Java** : Certaines règles sont adaptées au paradigme JS/TS (dynamique, fonctionnel, orienté module). Les exemples utilisent les idiomes modernes ES2022+ et TypeScript strict.

---

## Key Principles

### 1. One Level of Indentation per Method

- Extract logic into well-named helper functions.
- Prefer array methods (`filter`, `map`, `reduce`, `flatMap`) over nested loops.
- Callbacks/arrow functions **count** as a level of indentation.
- En async, chaque `await` doit rester au premier niveau — extrayez les traitements imbriqués.

> **ESLint** : [`max-depth`](https://eslint.org/docs/rules/max-depth) (max: 1)

```js
// ❌ Bad — multiple levels of indentation
function sendNewsletter(users) {
  for (const user of users) {
    if (user.isActive()) {
      mailer.send(user.email);
    }
  }
}

// ✅ Good — extracted method
function sendNewsletter(users) {
  users.forEach(sendEmailToUser);
}

function sendEmailToUser(user) {
  if (!user.isActive()) return;
  mailer.send(user.email);
}

// ✅ Good — functional style (preferred in JS)
function sendNewsletter(users) {
  users
    .filter(user => user.isActive())
    .forEach(user => mailer.send(user.email));
}
```

```js
// ❌ Bad — async avec niveaux imbriqués
async function notifyUsers(userIds) {
  for (const id of userIds) {
    const user = await userRepository.findById(id);
    if (user.isActive()) {
      await mailer.send(user.email);
    }
  }
}

// ✅ Good — async extrait
async function notifyUsers(userIds) {
  const users = await Promise.all(userIds.map(id => userRepository.findById(id)));
  await Promise.all(users.filter(u => u.isActive()).map(notifyUser));
}

async function notifyUser(user) {
  await mailer.send(user.email);
}
```

---

### 2. Don't Use the ELSE Keyword

- Avoid `else` to reduce cognitive complexity.
- Use **early returns** (guard clauses) and the **fail-fast** principle.
- In async code, prefer `throw` over fallback branches — `try/catch` ne remplace pas les guard clauses.

> **ESLint** : [`no-else-return`](https://eslint.org/docs/rules/no-else-return)

```js
// ❌ Bad
function processOrder(order) {
  if (order.isValid()) {
    // process
  } else {
    // handle invalid
  }
}

// ✅ Good — guard clause
function processOrder(order) {
  if (!order.isValid()) return;
  // process
}

// ✅ Good — fail fast (recommended for critical paths)
function processOrder(order) {
  if (!order) throw new Error('order is required');
  if (!order.isValid()) throw new Error('Invalid order');
  // process
}
```

```js
// ❌ Bad — else dans du async
async function getUser(id) {
  const user = await userRepository.findById(id);
  if (user) {
    return user;
  } else {
    return null;
  }
}

// ✅ Good — early return async
async function getUser(id) {
  if (!id) throw new Error('id is required');
  const user = await userRepository.findById(id);
  if (!user) throw new Error(`User ${id} not found`);
  return user;
}
```

> **TypeScript bonus** : Combine avec `never` et exhaustive checks pour les unions discriminantes.
> ```ts
> function assertNever(value: never): never {
>   throw new Error(`Unhandled case: ${value}`);
> }
> ```

---

### 3. Wrap Primitives and Strings in Value Objects

- Avoid raw primitives flowing through the domain.
- Use **Value Objects** (classes ou objects immutables) pour donner du sens et de la validation.
- En TypeScript, les **Branded Types** sont une alternative légère.

```js
// ❌ Bad — raw primitives
class User {
  constructor(name, age) {
    this.name = name;
    this.age = age;
  }
}

// ✅ Good — Value Objects
class Age {
  #value;
  constructor(value) {
    if (typeof value !== 'number' || value < 0) throw new Error('Age must be a positive number');
    this.#value = value;
  }
  valueOf() { return this.#value; }
}

class UserName {
  #value;
  constructor(value) {
    if (!value || typeof value !== 'string') throw new Error('Name cannot be empty');
    this.#value = value.trim();
  }
  toString() { return this.#value; }
}

class User {
  #name;
  #age;
  constructor(name, age) {
    this.#name = new UserName(name);
    this.#age = new Age(age);
  }
}
```

```ts
// ✅ TypeScript — Branded Types (alternative légère)
type Age = number & { readonly __brand: 'Age' };
type UserName = string & { readonly __brand: 'UserName' };

function createAge(value: number): Age {
  if (value < 0) throw new Error('Age cannot be negative');
  return value as Age;
}
```

---

### 4. First Class Collections

- Une classe qui contient un tableau comme propriété principale **ne doit contenir aucune autre propriété**.
- Encapsulez les opérations sur collections dans des classes dédiées.
- Exploitez les méthodes natives JS (`filter`, `map`, `find`, `some`, `every`) **à l'intérieur** de la classe collection.

```js
// ❌ Bad — raw array mixed with other properties
class Group {
  constructor(id, name, users) {
    this.id = id;
    this.name = name;
    this.users = users; // raw array exposed
  }

  getActiveCount() {
    return this.users.filter(u => u.isActive()).length;
  }
}

// ✅ Good — First Class Collection
class UserCollection {
  #users;
  constructor(users) {
    this.#users = [...users];
  }
  getActive() {
    return this.#users.filter(user => user.isActive());
  }
  count() { return this.#users.length; }
}

class Group {
  #id;
  #userCollection;
  constructor(id, name, users) {
    this.#id = id;
    this.#userCollection = new UserCollection(users);
  }
  getActiveCount() {
    return this.#userCollection.getActive().length;
  }
}
```

---

### 5. Keep Method Chains Readable

- Décomposez les objets traversés (navigation inter-objets) en variables intermédiaires.
- **Le chaining sur un même objet est idiomatique en JS** (arrays, Promises, builders) : autorisé si chaque appel est sur **sa propre ligne** avec une **responsabilité claire**.
- Une chaîne trop longue (> 4 appels) est un signal de refactoring, pas de reformatage.

> **Règle pratique** : traverser des objets différents = variables intermédiaires. Transformer le même flux = chaining multi-ligne.

```js
// ❌ Bad — navigation inter-objets sur une ligne
const email = order.getUser().getContact().getEmail().toUpperCase().trim();

// ✅ Good — navigation décomposée
const user = order.getUser();
const contact = user.getContact();
const email = contact.getEmail().toUpperCase().trim();

// ✅ Good — chaining sur le même flux (array) : idiomatique JS
const activeEmails = users
  .filter(user => user.isActive())
  .map(user => user.email)
  .filter(Boolean);

// ✅ Good — chaining Promise
const result = await fetch(url)
  .then(response => response.json())
  .then(data => transform(data));
```

---

### 6. Don't Abbreviate

- Utilisez des noms complets, expressifs et sans ambiguïté.
- Les noms doivent être lisibles à voix haute et compréhensibles sans commentaire.

```js
// ❌ Bad
const u = getUsr();
function calcTtl(arr) { return arr.reduce((a, b) => a + b, 0); }

// ✅ Good
const user = getUser();
function calculateTotal(amounts) { return amounts.reduce((sum, amount) => sum + amount, 0); }
```

---

### 7. Keep Entities Small (Class, Function, Module)

- Responsabilité unique par entité.
- Préférez plusieurs petits modules à un seul gros fichier.

**Contraintes JS/TS :**
- Maximum **10 méthodes** par classe
- Maximum **50 lignes** par classe (hors commentaires)
- Maximum **10 exports** par module/fichier
- Maximum **20 lignes** par fonction

```js
// ❌ Bad — class doing too much
class UserManager {
  createUser(name) { /*...*/ }
  deleteUser(id) { /*...*/ }
  sendEmail(email) { /*...*/ }
  generateReport() { /*...*/ }
}

// ✅ Good — split by responsibility
class UserCreator {
  create(name) { /*...*/ }
}

class UserRemover {
  remove(id) { /*...*/ }
}

// In a separate module: emailService.js, reportService.js
```

---

### 8. No Classes with More Than Four Instance Variables

- Limite à **4 propriétés d'instance** par classe (hors logger/observabilité).
  > Adapté à JS/TS : la limite Java de 2 est trop restrictive dans un langage sans modificateurs d'accès natifs et avec des patterns de composition plus souples.
- Au-delà de 4, c'est le signal d'une classe qui fait trop — refactorisez vers des Value Objects ou des services dédiés.
- Regroupez les propriétés liées sémantiquement (ex: `emailService + smsService → NotificationService`).

```js
// ❌ Bad — trop de responsabilités
class OrderHandler {
  constructor(orderRepo, emailService, smsService, pdfService, logger) {
    this.orderRepo = orderRepo;
    this.emailService = emailService;
    this.smsService = smsService;
    this.pdfService = pdfService;
    this.logger = logger;
  }
}

// ✅ Good — regroupement sémantique (max 4, logger hors quota)
class OrderHandler {
  #orderRepository;
  #notificationService; // encapsule email + sms
  #documentService;     // encapsule pdf
  #logger;              // ne compte pas

  constructor(orderRepository, notificationService, documentService, logger) {
    this.#orderRepository = orderRepository;
    this.#notificationService = notificationService;
    this.#documentService = documentService;
    this.#logger = logger;
  }
}
```

---

### 9. No Getters/Setters in Domain Classes

- Évitez d'exposer l'état interne via des getters/setters.
- Utilisez des **factory methods** statiques et des méthodes comportementales.
- En JS, `get`/`set` est **autorisé uniquement** pour les Value Objects en lecture seule (`get value()`).
- Pour l'async, utilisez des **static async factory methods**.

```js
// ❌ Bad — leaky state
class User {
  constructor(name) { this.name = name; }
  getName() { return this.name; }      // avoid
  setName(name) { this.name = name; }  // avoid
}

// ✅ Good — factory method + private fields
class User {
  #name;
  #email;

  constructor(name, email) {
    this.#name = name;
    this.#email = email;
  }

  static create(name, email) {
    if (!name || !email) throw new Error('Name and email are required');
    return new User(name, email);
  }

  // Behavior, not state exposure
  sendWelcomeEmail(mailer) {
    mailer.send(this.#email, `Welcome, ${this.#name}!`);
  }

  // ✅ Read-only getter acceptable on Value Objects
  get value() { return this.#name; }
}
```

```js
// ✅ Good — async static factory method
class UserProfile {
  #data;

  constructor(data) {
    this.#data = data;
  }

  // Async construction via factory, pas de setters
  static async fromId(id, repository) {
    if (!id) throw new Error('id is required');
    const data = await repository.findById(id);
    if (!data) throw new Error(`UserProfile ${id} not found`);
    return new UserProfile(data);
  }

  displayName() {
    return `${this.#data.firstName} ${this.#data.lastName}`;
  }
}
```

---

---

### 10. Prefer Immutability

- Évitez de muter les objets reçus en paramètre — retournez de nouvelles instances.
- Utilisez `const` par défaut, `let` uniquement si la réassignation est inévitable. Jamais `var`.
- Protégez les objets exposés avec `Object.freeze()` ou les champs privés `#field`.
- En TypeScript, utilisez `readonly` sur les propriétés et `Readonly<T>` / `ReadonlyArray<T>` sur les types.

> **ESLint** : [`prefer-const`](https://eslint.org/docs/rules/prefer-const), [`no-param-reassign`](https://eslint.org/docs/rules/no-param-reassign)

```js
// ❌ Bad — mutation d'un paramètre
function addDiscount(order, discount) {
  order.price = order.price - discount; // mutates external object
  return order;
}

// ✅ Good — nouvelle instance
function addDiscount(order, discount) {
  return { ...order, price: order.price - discount };
}
```

```ts
// ✅ TypeScript — readonly partout dans le domaine
class OrderLine {
  constructor(
    readonly productId: string,
    readonly quantity: number,
    readonly unitPrice: number
  ) {}

  total(): number {
    return this.quantity * this.unitPrice;
  }
}

// ✅ Immutable collection
function applyPromotion(lines: ReadonlyArray<OrderLine>): ReadonlyArray<OrderLine> {
  return lines.map(line => new OrderLine(line.productId, line.quantity, line.unitPrice * 0.9));
}
```

---

### 11. No `any` in TypeScript

- `any` désactive le compilateur TypeScript — c'est l'équivalent d'un `// @ts-ignore` global.
- Préférez `unknown` (+ type guard) quand le type est vraiment inconnu.
- Utilisez des **génériques** pour les fonctions traitant des types variables.
- `as unknown as T` (double cast) est un signal d'alarme — il masque souvent une mauvaise modélisation.

> **ESLint** : [`@typescript-eslint/no-explicit-any`](https://typescript-eslint.io/rules/no-explicit-any/), [`@typescript-eslint/no-unsafe-assignment`](https://typescript-eslint.io/rules/no-unsafe-assignment/)

```ts
// ❌ Bad
function parseConfig(data: any): any {
  return data.config;
}

// ✅ Good — unknown + type guard
function parseConfig(data: unknown): AppConfig {
  if (!isAppConfig(data)) throw new Error('Invalid config shape');
  return data;
}

function isAppConfig(data: unknown): data is AppConfig {
  return (
    typeof data === 'object' &&
    data !== null &&
    'apiUrl' in data &&
    typeof (data as Record<string, unknown>).apiUrl === 'string'
  );
}

// ✅ Good — générique
function first<T>(items: ReadonlyArray<T>): T {
  if (items.length === 0) throw new Error('Empty array');
  return items[0];
}
```

---

## Implementation Guidelines

- **Immutabilité** : Préférez `Object.freeze()`, `const`, champs `#field`, `readonly` TypeScript (→ Règle 10).
- **TypeScript strict** : Activez `"strict": true` dans `tsconfig.json`. Interdisez `any` explicitement (→ Règle 11).
- **Testing** : Testez les **comportements**, pas l'état interne. Évitez de tester des getters.
- **Code Reviews** : Vérifiez systématiquement ces règles lors des revues. Référencez ce document dans les commentaires PR.

### ESLint Configuration Recommandée

Chaque règle est applicable automatiquement via ESLint :

```json
{
  "rules": {
    "max-depth": ["error", { "max": 1 }],
    "no-else-return": "error",
    "prefer-const": "error",
    "no-param-reassign": "error",
    "no-var": "error",
    "max-lines-per-function": ["error", { "max": 20, "skipBlankLines": true, "skipComments": true }],
    "max-lines": ["error", { "max": 50, "skipBlankLines": true, "skipComments": true }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/prefer-readonly": "error"
  }
}
```
