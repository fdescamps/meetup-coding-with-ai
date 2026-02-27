# Plan de démo — Meetup Coding with AI @ Sfeir

**Date** : 05 mars 2026  
**Lieu** : Sfeir  
**Public** : Développeurs

---

## Pitch

> **Coding with AI : Intégrer Copilot sans sacrifier la qualité**

GitHub Copilot est puissant, mais l'utilisez-vous à 100 % de ses capacités, notamment en TDD et BDD ? L'avez-vous dompté ?

Lors de cette session, nous irons au-delà de la simple autocomplétion. Au travers d'un savant mélange de slides et de démos, nous verrons comment l'IA peut assister la phase de développement post-Three Amigos et accélérer l'écriture de vos tests unitaires sans renier sur la qualité de vos tests.

Nous ferons également un focus technique sur les **"Copilot Instructions"**, une fonctionnalité clé pour contextualiser l'IA. L'objectif : vous fournir les clés pour contourner les limitations de l'outil et transformer votre IDE en un environnement de développement augmenté, plus fluide et plus fiable.

---

## Objectifs du talk

| Objectif | Description |
|----------|-------------|
| **Démystifier** | Montrer ce qu'est APM et les primitives Copilot |
| **Contextualiser** | Illustrer comment les Instructions ancrent l'IA dans vos standards |
| **Composer** | Montrer comment Skills et Agents augmentent Copilot |
| **Inspirer** | Donner aux participants les clés pour transposer ça dans leur équipe |

---

## Slides et Plan du talk

(voir pptx pour le détail des slides)

---

## Structure du repository pour la démo

```
meetup-coding-with-ai/
├── README.md                                         # Présentation du repo (FR)
├── LICENSE                                           # MIT
├── apm.yml                                           # Manifeste APM
├── PLAN.md                                           # Ce fichier (pitch + plan)
├── .github/
│   └── copilot-instructions.md                       # Instructions globales Copilot
├── .apm/
│   ├── instructions/
│   │   ├── object-calisthenics.js.instructions.md    # Règles de qualité JS/TS
│   │   └── contenu-markdown.instructions.md          # Règles de rédaction Markdown
│   ├── agents/
│   │   └── mentor-dev-senior.agent.fr.md             # Agent mentor (méthode Socratique)
│   ├── skills/
│   │   └── run-tests/
│   │       └── SKILL.md                              # Skill : lancer les tests
└── src/
    └── exemple/
        └── commande.js                               # Fichier de démo live (Object Calisthenics)
```

**Fichiers supprimés** (non pertinents pour la démo) :
- `CHANGELOG.md`
- `CONTRIBUTING.md`

---

## Déroulé détaillé de la démo

### Préparation (avant la démo)
- [ ] VS Code ouvert sur ce repository
- [ ] Extension GitHub Copilot activée et authentifiée
- [ ] APM installé (`npm install -g @danielmeppiel/apm` ou équivalent)
- [ ] Fichier `src/exemple/commande.js` ouvert mais vide (ou avec du code intentionnellement "mauvais")
- [ ] Panneau Chat Copilot ouvert sur le côté

---

### Étape 1 — Présenter le repository (2 min)

**Action** : Montrer la structure du repo dans VS Code Explorer

**Points clés à dire** :
- "Ce repository est un package APM : un ensemble de primitives Copilot versionnées et partageables"
- "Il contient 3 types d'éléments : des Instructions, des Skills, et un Agent"
- "APM me permet de distribuer ce package à toute mon équipe en une commande"

---

### Étape 2 — Démo Instructions — Object Calisthenics (8 min)

**Action 1** : Ouvrir `.apm/instructions/object-calisthenics.js.instructions.md`

**Points clés à dire** :
- "Le frontmatter `applyTo: '**/*.{js,ts,jsx,tsx}'` dit à Copilot d'appliquer ces règles sur tous les fichiers JS/TS"
- "Ces règles sont les Object Calisthenics : 9 règles pour un code propre et maintenable"
- "Copilot les lit automatiquement — sans prompt supplémentaire de ma part"

**Action 2** : Ouvrir `src/exemple/commande.js` et taper en live :

```javascript
// Contexte : on gère un système de commandes e-commerce
// Écrire une fonction qui traite une liste de commandes
```

- Laisser Copilot suggérer → montrer que les suggestions respectent les règles (pas d'else, une seule indentation, etc.)
- Si Copilot propose du code qui viole une règle → le corriger et montrer que Copilot s'adapte

**Points clés à dire** :
- "Sans ces instructions, Copilot aurait pu écrire une boucle for imbriquée avec des if/else"
- "Là, il génère directement du code conforme à mes standards"
- "C'est ça la puissance des Instructions : contextualiser l'IA sans effort supplémentaire à chaque prompt"

---

### Étape 3 — Démo Skill — Run Tests (5 min)

**Action** : Dans le Chat Copilot, taper : `@workspace /run-tests`  
(ou ouvrir `.apm/skills/run-tests/SKILL.md` pour montrer le contenu)

**Points clés à dire** :
- "Un Skill, c'est une capacité structurée : Copilot sait exactement quoi faire"
- "Ici, il va détecter mon runner de tests, lancer la suite, et me donner un résumé lisible"
- "Je peux créer des Skills métier : 'analyser les performances', 'générer un rapport de couverture', etc."

---

### Étape 4 — Démo Agent — Mentor Dev Senior (7 min)

**Action 1** : Dans VS Code, passer en mode Agent, sélectionner `.apm/agents/mentor-dev-senior`

**Action 2** : Poser cette question :

> "J'ai une fonction qui prend une liste d'utilisateurs et envoie un email à chacun. Ça marche mais c'est lent. Comment je l'optimise ?"

**Observer** : L'agent ne donne pas la réponse. Il pose des questions :
- "Qu'est-ce que tu as essayé ? Où penses-tu que le goulot se situe ?"
- "Est-ce que les envois sont séquentiels ou parallèles ?"

**Points clés à dire** :
- "Cet agent ne code pas à ma place — il m'apprend à raisonner"
- "C'est la méthode Socratique : on guide par les questions"
- "Je peux créer des agents adaptés à des personas métier : un expert sécurité, un reviewer de PR, un coach BDD..."
- "La clé : une description claire du comportement attendu dans le fichier `.agent.md`"

---

### Messages clés à retenir

1. **Les Instructions** = les règles que Copilot applique automatiquement (dans `.apm/instructions/`) → qualité sans friction
2. **Les Skills** = les capacités structurées que vous donnez à Copilot (dans `.apm/skills/`) → actions reproductibles
3. **Les Agents** = les personas que vous définissez pour Copilot (dans `.apm/agents/`) → comportements adaptés au contexte
4. **APM** = l'outil pour packager et partager tout ça dans votre équipe

---

## Ressources

- APM : https://github.com/danielmeppiel/apm
- Ce repository (template de démo) : à partager avec les participants
- Documentation GitHub Copilot Instructions : https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot
