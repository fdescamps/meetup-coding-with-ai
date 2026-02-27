# Coding with AI — Démo Meetup Sfeir (05/03/2026)

> **Package APM de démo : Instructions, Skills et Agent pour GitHub Copilot**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![APM](https://img.shields.io/badge/APM-compatible-blue.svg)](https://github.com/danielmeppiel/apm)

---

## Contexte

Ce repository est le support de démo du talk **"Coding with AI : intégrer Copilot sans sacrifier la qualité"** présenté le 5 mars 2026 chez [Sfeir](https://www.sfeir.com/).

Il illustre les **primitives GitHub Copilot** — Instructions, Skills et Agents — packagées avec [APM](https://github.com/danielmeppiel/apm).

---


## Structure du repository

```
meetup-coding-with-ai/
├── README.md                                         # Ce fichier
├── LICENSE                                           # MIT
├── apm.yml                                           # Manifeste APM
├── PLAN.md                                           # Pitch + plan de démo
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
        └── commande.js                               # Fichier de démo live
```

---

## Les 3 primitives Copilot


### Instructions

Les fichiers `.apm/instructions/*.instructions.md` définissent des règles que Copilot applique **automatiquement** sur les fichiers ciblés via le frontmatter `applyTo`.

**Exemple** : les règles [Object Calisthenics](.apm/instructions/object-calisthenics.js.instructions.md) s'appliquent à tous les fichiers `*.js`, `*.ts`, `*.jsx` et `*.tsx`.

```yaml
---
applyTo: '**/*.{js,ts,jsx,tsx}'
---
```

Copilot génère du code conforme à ces règles sans que le développeur n'ait besoin de les rappeler à chaque prompt.

### Skills

Les fichiers `.apm/skills/**/SKILL.md` définissent des **capacités structurées** que Copilot peut invoquer. Un Skill décrit une tâche de façon reproductible.

**Exemple** : [run-tests](.apm/skills/run-tests/SKILL.md) — détecte automatiquement Jest, Vitest ou pytest et résume les résultats.

### Agent

Les fichiers `.apm/agents/*.agent.md` définissent des **personas** pour le mode Agent de Copilot. Ils permettent de donner à Copilot un comportement précis, adapté à un contexte métier ou pédagogique.

**Exemple** : [mentor-dev-senior](.apm/agents/mentor-dev-senior.agent.fr.md) — un mentor qui guide par les questions (méthode Socratique).

---

## Installation avec APM

```bash
# Installer APM
npm install -g @danielmeppiel/apm

# Installer ce package dans votre projet
apm install
```

---


## Utilisation directe (sans APM)

1. Copier `.apm/instructions/` dans `.github/instructions/` de votre projet
2. Copier `.apm/agents/` dans `.github/agents/` de votre projet
3. Copier `.apm/skills/` dans `.github/skills/` de votre projet
4. VS Code + GitHub Copilot détectera automatiquement les fichiers

---

## Ressources

- [APM — Agent Prompt Manager](https://github.com/danielmeppiel/apm)
- [Documentation : Copilot Instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
- [Object Calisthenics](https://www.cs.helsinki.fi/u/luontola/tdd-2009/ext/ObjectCalisthenics.pdf)
- [Plan de démo complet](PLAN.md)

---

## Licence

[MIT](LICENSE) — Libre de réutilisation et d'adaptation.
















