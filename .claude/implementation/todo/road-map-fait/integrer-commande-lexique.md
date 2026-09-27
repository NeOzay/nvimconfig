+++
id = "integrer-commande-lexique"
title = "Intégrer la commande `:Lexique` à la configuration Neovim"
date = 2026-09-27
source = "chantier `lexique-nvim` de `~/.claude`, clos le 2026-09-27 (`ba7203e`) ; son hors-périmètre renvoyait l'intégration à un chantier dans ce dépôt"
+++

## À faire

Faire entrer `:Lexique` dans cette configuration, pour obtenir le sens d'un terme du lexique sans
quitter Neovim en relisant un diff :

- `:Lexique` ouvre le lexique local du projet du cwd, `:Lexique!` le global,
  `:Lexique <terme>` affiche la définition (`vim.print()`), avec complétion des termes, composés
  compris (`Signal de dérive`).
- Reprendre le prototype `~/.claude/skills/lexique/nvim/lexique.lua` en module (`lua/lexique.lua`,
  sur le modèle de `lua/chantier.lua`), déclaré dans `lua/cmd.lua`.
- Neovim ne lit aucun `LEXIQUE.md` : tout vient de la commande `lexique` (`chemin [--global]`,
  `termes`, `definition -- <terme>`), lancée dans le cwd.
- Corriger au passage la complétion derrière un modificateur (`:silent Lexique Sig<Tab>` ne
  propose rien).
- Une fois intégrée, supprimer le prototype de `~/.claude` et réécrire les deux références qui le
  citent.
- Puis, si voulu, le mappage qui donne la définition du mot sous le curseur — `<cword>` ne rend
  qu'un mot : un terme composé demande une sélection visuelle, ou de chercher parmi les termes
  celui qui couvre le curseur.

## Fait le

**2026-09-27**, chantier `integrer-commande-lexique` — archive
`.claude/implementation/done/2026-09-27-integrer-commande-lexique.md`.

## Références

- prototype : `~/.claude/skills/lexique/nvim/lexique.lua` (se source à la main), et ses
  vérifications `nvim --headless` au plan archivé
  `~/.claude/.claude/implementation/done/2026-09-27-lexique-nvim.plan.md`, étape 3
- chantier archivé : `~/.claude/.claude/implementation/done/2026-09-27-lexique-nvim.md` (brief,
  audit et plan à côté) — décisions : projet = racine git du cwd, correspondance à la casse et aux
  espaces près, lexique malformé qui sert ses lignes valides
- interface de la commande : `~/.claude/skills/lexique/SKILL.md`, section « La commande »
- dettes dans `~/.claude/.claude/implementation/todo/technical-debt/` :
  `lexique-completion-sous-un-modificateur` (R8), `lexique-references-au-lua-temporaire` (R6)
- modèle dans ce dépôt : `lua/chantier.lua`, déclaré dans `lua/cmd.lua` ; tests mini.test sous
  `tests/`
