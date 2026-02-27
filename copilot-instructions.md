# Instructions Copilot — Meetup Coding with AI

Ce repository est un package APM de démonstration présentant les primitives GitHub Copilot : Instructions, Skills et Agents.

## Structure du repository

```
instructions/   # Directives système appliquées automatiquement par Copilot
agents/         # Configurations d'agents pour le mode Agent
skills/         # Capacités modulaires invocables par les assistants
src/            # Code source d'exemple pour les démos live
```

## Fichiers d'instructions

Les fichiers d'instructions suivants sont disponibles dans le répertoire `instructions/` :

- [`object-calisthenics.js.instructions.md`](instructions/object-calisthenics.js.instructions.md) - Règles Object Calisthenics pour JS/TS (`**/*.{js,ts,jsx,tsx}`)
- [`contenu-markdown.instructions.md`](instructions/contenu-markdown.instructions.md) - Directives de rédaction et de mise en forme Markdown (`**/*.md`)

## Agent

- [`mentor-dev-senior.agent.fr.md`](agents/mentor-dev-senior.agent.fr.md) - Mentor bienveillant pour développeurs — méthode Socratique

## Skills

- [`run-tests`](skills/run-tests/SKILL.md) - Exécute la suite de tests et résume les résultats

## Utilisation

Les fichiers d'instructions sont appliqués automatiquement par GitHub Copilot selon les patterns `applyTo` de leur frontmatter.
L'agent est disponible en mode Agent via le répertoire `agents/`.
