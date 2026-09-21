+++
gabarit = "brief"
slug = "chantier-docs-commands"
titre = "Commandes nvim :Suivi, :Brief, :Plan, :Audit pour ouvrir les documents du chantier en cours"
statut = "validé"
execution = "direct"
"créé" = 2026-09-21
+++

## Intention

**Symptôme** : pour ouvrir le suivi, le brief, le plan ou l'audit du chantier en cours, il faut naviguer à la main dans `.claude/implementation/` et `.claude/plans/` (noms de plan générés par le harness).
**But** : une commande par document, qui ouvre directement celui du chantier en cours, dans n'importe quel dépôt qui utilise implementation-tracker.

## Critères de réussite

- Sur une branche de chantier, `:Suivi`, `:Brief`, `:Plan`, `:Audit` ouvrent chacun le document désigné par le suivi dont `branche` égale la branche courante
- Document absent ou champ vide → message d'erreur, aucun buffer ouvert
- Sur `master`, ou sur une branche sans suivi correspondant → message l'indiquant, rien d'ouvert
- Fonctionne depuis un autre dépôt que la config nvim, résolu depuis le cwd de Neovim

## Hors-périmètre

- Les chantiers archivés dans `done/` : ignorés (dit)
- Aucun sélecteur quand aucun suivi ne correspond à la branche courante — ni sur `master`, ni ailleurs : message, puis rien (dit)
- Aucune création du document manquant (dit)

## Signaux de dérive

- Un sélecteur (picker snacks, `vim.ui.select`) apparaît dans le diff (dit)

## Contraintes connues de l'utilisateur

- **Décision** : commandes nommées avec une majuscule — `:Suivi`, `:Brief`, `:Plan`, `:Audit` (dit)
- **Décision** : le chantier en cours est le suivi dont le champ `branche` correspond à la branche git courante (dit)
- **Décision** : document absent (ex. audit pas encore produit) → message d'erreur, pas de buffer vide (dit)
- **Décision** : fonctionne dans n'importe quel dépôt qui utilise le tracker, pas seulement la config nvim (dit)
- **Existant** : le suivi porte déjà les chemins `plan`, `brief`, `audit` et `branche` dans son frontmatter (dépôt: .claude/implementation/done/2026-08-29-list-dir-viewer.md)
- **Décision** : le dépôt de référence est celui du cwd de Neovim, pas celui du buffer courant (dit)
- **Existant** : le suivi actuel porte un front matter TOML délimité par `+++` (dépôt: semence `gabarit new suivi`)
- **Réutiliser** : le parseur de front matter de `listdir.item` (`item.read`) est extrait dans un module commun, que listdir et les nouvelles commandes utilisent tous deux (dit)
- **Existant** : les commandes utilisateur sont déclarées dans `lua/cmd.lua` (dépôt: lua/cmd.lua)

## Incertitudes à lever en plan

- Emplacement et nom du module commun de lecture du front matter
