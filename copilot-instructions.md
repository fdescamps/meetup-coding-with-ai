# Instructions Copilot — Meetup Coding with AI

Ce repository est un package APM de démonstration présentant les primitives GitHub Copilot : Instructions, Skills et Agents.


## Structure du repository

```
.apm/
├── instructions/   # Directives système appliquées automatiquement par Copilot
├── agents/         # Configurations d'agents pour le mode Agent
├── skills/         # Capacités modulaires invocables par les assistants
src/                # Code source d'exemple pour les démos live
```


## Fichiers d'instructions

Les fichiers d'instructions suivants sont disponibles dans le répertoire `.apm/instructions/` :

- [`object-calisthenics.js.instructions.md`](.apm/instructions/object-calisthenics.js.instructions.md) - Règles Object Calisthenics pour JS/TS (`**/*.{js,ts,jsx,tsx}`)
- [`contenu-markdown.instructions.md`](.apm/instructions/contenu-markdown.instructions.md) - Directives de rédaction et de mise en forme Markdown (`**/*.md`)

## Agent

- [`mentor-dev-senior.agent.fr.md`](.apm/agents/mentor-dev-senior.agent.fr.md) - Mentor bienveillant pour développeurs — méthode Socratique

## Skills

- [`run-tests`](.apm/skills/run-tests/SKILL.md) - Exécute la suite de tests et résume les résultats

## Utilisation

Les fichiers d'instructions sont appliqués automatiquement par GitHub Copilot selon les patterns `applyTo` de leur frontmatter.
L'agent est disponible en mode Agent via le répertoire `agents/`.
