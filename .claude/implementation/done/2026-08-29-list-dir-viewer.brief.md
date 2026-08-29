---
slug: list-dir-viewer
titre: Visualiser les répertoires-listes dans Neovim
statut: validé
execution: direct
créé: 2026-08-28
---

## Intention

**Symptôme** : les répertoires-listes du skill `list-dir` ne se consultent aujourd'hui qu'en CLI,
hors de Neovim.
**But** : « implémenter des façons de visualiser les répertoires-listes dans Neovim » (dit) —
un picker des répertoires-listes du workspace, d'où l'on ouvre un picker des éléments de la liste
sélectionnée, et un mapping ouvrant un buffer « nofile » pour cette liste.

## Critères de réussite

- une commande ouvre un picker listant les répertoires-listes trouvés sous les chemins configurés
  (cwd par défaut) ; `<CR>` sur l'une d'elles ouvre le picker de ses éléments
- dans le picker d'éléments : preview, `<CR>` ouvre le fichier de l'élément, et un mapping change
  le champ de tri à la volée (l'ordre affiché change en conséquence)
- un mapping du picker d'éléments ouvre un buffer `nofile` par liste, contenant tous les éléments
  concaténés en Markdown, chaque titre étant un lien vers le fichier de l'élément — `gf` (ou
  équivalent) sur ce lien ouvre le fichier
- aucun appel à `show`, `merge` ou à une commande écrivant dans la liste

## Hors-périmètre

- « Pour l'instant, seulement la visualisation » — aucune écriture dans les listes : pas de `new`,
  `move`, `derive`, `migrate`, `init` depuis le plugin (dit)
- Pas d'ordre manuel persistant des éléments (dit)

## Signaux de dérive

- si le plugin écrit dans une liste, c'est raté — la visualisation est en lecture seule (dit)
- si `show` est appelé, c'est raté : « nvim peut directement obtenir le contenu d'un élément » (dit)
- si le nombre d'appels Python croît avec le nombre d'éléments, c'est raté — `list` en rend
  beaucoup en une commande (dit)

## Contraintes connues de l'utilisateur

- **Navigation** : picker des listes du workspace → picker des éléments de la liste choisie →
  mapping vers le buffer nofile (dit)
- **Tri** : « tri à la volée depuis le picker, à partir des éléments contenus dans le
  frontmatter » — pas d'ordre manuel persistant (dit)
- **Buffer nofile** : « tous les éléments concaténés et formatés en un document Markdown lisible
  d'un trait » ; les titres sont des liens Markdown ciblant le fichier de l'élément, pour pouvoir
  y accéder (dit)
- **Performance** : « on ne peut pas faire un grand nombre d'appels rapidement, car chaque appel
  nécessite de recharger l'interpréteur en mémoire » — limiter le nombre d'invocations Python (dit)
- **Découverte** : « utiliser une liste de chemins. Par défaut, le cwd » — chemins de recherche
  configurables, un répertoire-liste se reconnaissant à son `.list/contract.toml` (dit)
- **Réutiliser** : pattern de picker Snacks custom déjà en place (dépôt:
  `lua/plugins/snacks/picker/sources/harpoon.lua`, `docs/plugins/snacks-picker-custom.md`)
- **Réutiliser** : structure de plugin local `plugins/<nom>/` + spec `dir =` (dépôt:
  `plugins/bookmarks/`, `lua/plugins/bookmarks.lua`)
- **Source de données** : « `list` est peu coûteux ; il permet d'obtenir beaucoup d'infos en une
  commande. Il faut éviter d'utiliser `show`, nvim peut directement obtenir le contenu d'un
  élément » (dit). `list` rend une ligne par élément : id + champs de `--sort` séparés par une
  espace (dépôt: `~/.claude/skills/list-dir/scripts/listdir/commands/list.py`)
- **Index et tri** : un appel `list <liste> --sort <champs>` par changement de tri ; pas de
  parseur de frontmatter côté Lua pour l'index (tranché)
- **Buffer concaténé** : « utiliser `list` pour obtenir les éléments et le tri, généré en Lua
  depuis les fichiers » — pas d'appel à `merge` (tranché)

## Incertitudes à lever en plan

- Quels champs proposer au tri : `list --sort` n'accepte que les champs déclarés au contrat, qui
  diffèrent d'une liste à l'autre — le plugin doit donc les découvrir, et `.list/contract.toml`
  est du TOML à lire côté Lua.
- Contenu de la preview du picker d'éléments : le fichier `.md` brut, ou une mise en forme.
