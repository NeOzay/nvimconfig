+++
id = "todo-sans-readme"
title = "`todo/README.md`, annoncé par l'arborescence du pipeline, n'existe pas"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

L'arborescence de référence le déclare :

```
$ grep -n -A2 -B2 'README.md' ~/.claude/skills/implementation-tracker/references/contrat.md
42-  todo/
44:    README.md
45-    technical-debt/              # registre de dette, alimenté à la clôture
```

Il est absent du dépôt :

```
$ ls -a .claude/implementation/todo/
technical-debt/
technical-debt-ecarte/
technical-debt-solde/
$ test -f .claude/implementation/todo/README.md && echo présent || echo absent
absent
```

## Verdict

Le constat tient : le fichier est déclaré par l'arborescence qui fait autorité, et il n'existe pas.
Les trois répertoires sont là, lui seul manque.

Le classement est le moins évident des seize. `pas-une-dette` serait défendable — un README absent
ressemble à une idée d'amélioration plutôt qu'à un défaut constaté. Mais `categories.md` réserve
cette catégorie à ce qui « n'avait pas sa place au registre », et ici l'écart est vérifiable contre
un document normatif : l'arborescence promet un fichier que le dépôt ne fournit pas. Dans le doute,
la règle est explicite — c'est `pertinent`.

À noter que cette entrée décrit un manque du **pipeline**, pas de la configuration Neovim, comme
`registre-attribution-dans-pour-solder` et `registre-fenetre-non-conforme-pendant-un-solde`. Le
registre de ce dépôt héberge donc trois entrées dont le correctif s'écrirait dans `~/.claude/`.

## Action

Reste au registre avec ses deux champs de revue. Le **Pour solder** est actionnable et porte déjà le
piège à éviter — poser le fichier à la racine de `todo/`, jamais dans une liste, où tout `*.md` est
compté comme un élément.

## Arbitrage

<OPTIONNEL>
