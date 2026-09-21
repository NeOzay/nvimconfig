# Plan — chantier-docs-commands

Brief : `.claude/implementation/chantier-docs-commands.brief.md` (validé).

## Context

Ouvrir le suivi, le brief, le plan ou l'audit du chantier en cours demande aujourd'hui de naviguer
à la main dans `.claude/implementation/` et `.claude/plans/` (noms de plan générés). But : `:Suivi`,
`:Brief`, `:Plan`, `:Audit` ouvrent directement le document du chantier dont `branche` = branche git
courante, dans n'importe quel dépôt utilisant implementation-tracker.

Rappel du brief :
- **Critères** : ouverture du bon document ; document absent / champ vide → erreur, rien d'ouvert ;
  `master` ou branche sans suivi → message, rien d'ouvert ; dépôt résolu depuis le cwd de Neovim.
- **Hors-périmètre** : `done/` ignoré ; aucun sélecteur ; aucune création de document.
- **Signal de dérive** : un sélecteur (picker snacks, `vim.ui.select`) apparaît dans le diff.
- **Incertitude à lever** : emplacement et nom du module commun de front matter → tranchée ci-dessous.

## Décisions

- **Module commun : `lua/frontmatter.lua`**, au même niveau que `lua/utils.lua`. `listdir` n'est
  utilisé que dans cette config ; un plugin local dédié serait disproportionné pour ~60 lignes.
  Types renommés `Ozay.Frontmatter.*`.
- **Extraction à comportement identique** : `parse`, `unquote`, cache sur `mtime` et messages
  d'erreur déplacés tels quels. `listdir.item` garde `read`/`title`/`clear` comme façade
  (délégation), pour ne toucher aucun appelant (`document.lua`, `picker/items.lua`).
- **Logique chantier : `lua/chantier.lua`**, enregistrement des commandes dans `lua/cmd.lua`.
- Détection du suivi : fichiers `<root>/.claude/implementation/*.md` hors `*.brief.md`,
  `*.audit.md`, `*.plan.md` (le glob n'entre pas dans `done/`), dont le champ `branche` égale la
  branche courante. Les valeurs `<À REMPLIR>` / `<OPTIONNEL>` comptent comme vides.
- HEAD détachée (`branch --show-current` vide) → message « pas de branche », jamais de
  correspondance avec un suivi dont `branche` serait vide.
- Racine : `vim.fs.root(vim.uv.cwd(), ".git")` ; branche : `git -C <root> branch --show-current`
  via `vim.system(...):wait()`. Chemins du suivi résolus relativement à la racine.

## Étapes

1. **Extraire le parseur de front matter dans `lua/frontmatter.lua`** — `plugins/listdir/lua/listdir/item.lua`
   délègue `read` et `clear` au module commun ; aucun changement de comportement.
   Vérif : `nvim --headless -c 'lua local i=require("listdir.item"); local d=assert(i.read(".claude/implementation/chantier-docs-commands.brief.md")); assert(d.fields.slug=="chantier-docs-commands"); assert(i.title(".claude/implementation/chantier-docs-commands.brief.md","x")=="x"); print("OK")' -c q` affiche `OK`.
2. **Écrire `lua/chantier.lua` et enregistrer `:Suivi`, `:Brief`, `:Plan`, `:Audit` dans `lua/cmd.lua`** —
   `chantier.open(field)` : racine → branche → suivi correspondant → champ (`nil` pour `:Suivi`,
   qui ouvre le suivi lui-même) → `vim.cmd.edit`. Chaque échec : `vim.notify(..., WARN|ERROR)` et retour.
   Vérif : script `scratchpad/chantier-check.sh` qui monte un dépôt temporaire (`git init`, branche
   `demo`, suivi `branche = "demo"`, `brief` pointant un fichier existant, `plan = "<À REMPLIR>"`,
   `audit` pointant un fichier absent) et lance pour chaque cas
   `nvim --headless -c <Cmd> -c 'lua print(vim.api.nvim_buf_get_name(0))' -c q` :
   `:Suivi` et `:Brief` → chemin attendu ; `:Plan` (champ vide), `:Audit` (fichier absent), `:Suivi`
   sur `master`, sur une branche `autre` et en HEAD détachée → nom de buffer vide (aucun fichier
   ouvert). Le script sort en erreur au premier écart.
3. **Documenter** — `docs/plugins/listdir.md` (fichier `item.lua` → délégation à `lua/frontmatter.lua`,
   changelog) et une ligne sur les commandes et `lua/frontmatter.lua` dans `CLAUDE.md`, section
   « Global Helpers (init.lua) ».
   Vérif : `git status --short` ne liste que les fichiers de la section Fichiers (nouveaux compris),
   et `grep -n 'frontmatter' docs/plugins/listdir.md CLAUDE.md` trouve les deux mentions.

## Fichiers

- `lua/frontmatter.lua` (nouveau), `plugins/listdir/lua/listdir/item.lua`
- `lua/chantier.lua` (nouveau), `lua/cmd.lua`
- `docs/plugins/listdir.md`, `CLAUDE.md`

## Vérification de bout en bout

Prérequis : branche `chantier-docs-commands` et son suivi, créés par implementation-tracker avant
l'étape 1. Dans ce dépôt, sur cette branche : `:Suivi`, `:Brief`, `:Plan` ouvrent les
fichiers du chantier ; `:Audit` notifie l'absence d'audit. `:ListDir` fonctionne comme avant
(titres des éléments affichés dans le picker).
