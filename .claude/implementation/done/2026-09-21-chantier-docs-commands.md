+++
gabarit = "suivi"
slug = "chantier-docs-commands"
titre = "Commandes nvim :Suivi, :Brief, :Plan, :Audit pour ouvrir les documents du chantier en cours"
branche = "chantier-docs-commands"
base = "master"
statut = "terminé"
session = 2
lettre = "A"
execution = "direct"
plan = ".claude/implementation/done/2026-09-21-chantier-docs-commands.plan.md"
brief = ".claude/implementation/done/2026-09-21-chantier-docs-commands.brief.md"
audit = ".claude/implementation/done/2026-09-21-chantier-docs-commands.audit.md"
"créé" = 2026-09-21
maj = 2026-09-21
+++

## Objectif et périmètre

**Symptôme** : pour ouvrir le suivi, le brief, le plan ou l'audit du chantier en cours, il faut naviguer à la main dans `.claude/implementation/` et `.claude/plans/` (noms de plan générés par le harness).

**But** : une commande par document, qui ouvre directement celui du chantier en cours, dans n'importe quel dépôt qui utilise implementation-tracker.

**Critères de réussite** :
- Sur une branche de chantier, `:Suivi`, `:Brief`, `:Plan`, `:Audit` ouvrent chacun le document désigné par le suivi dont `branche` égale la branche courante
- Document absent ou champ vide → message d'erreur, aucun buffer ouvert
- Sur `master`, ou sur une branche sans suivi correspondant → message l'indiquant, rien d'ouvert
- Fonctionne depuis un autre dépôt que la config nvim, résolu depuis le cwd de Neovim

**Hors-périmètre** :
- Les chantiers archivés dans `done/` : ignorés
- Aucun sélecteur quand aucun suivi ne correspond à la branche courante — message, puis rien
- Aucune création du document manquant

**Signaux de dérive** :
- Un sélecteur (picker snacks, `vim.ui.select`) apparaît dans le diff

## Étapes

- [x] 1. Extraire le parseur de front matter dans `lua/frontmatter.lua` — `lua/frontmatter.lua`, `plugins/listdir/lua/listdir/item.lua` — vérif: headless `require("listdir.item").read(<brief>)` → `OK` (cf. plan)
- [x] 2. Écrire `lua/chantier.lua` et enregistrer `:Suivi`, `:Brief`, `:Plan`, `:Audit` — `lua/chantier.lua`, `lua/cmd.lua` — vérif: script `chantier-check.sh` sur dépôt temporaire (cf. plan)
- [x] 3. Documenter — `docs/plugins/listdir.md`, `CLAUDE.md` — vérif: `git status --short` + `grep -n frontmatter docs/plugins/listdir.md CLAUDE.md`
- [x] 4. Corriger R2 de l'audit : un suivi illisible est signalé au lieu d'être sauté — `lua/chantier.lua` — vérif: headless sur dépôt temporaire, suivi en `chmod 000` → message ERROR nommant le fichier

## État courant

**Prochaine action** : aucune — chantier clos avec les réserves R3–R6, versées au registre de dette.
**Vérification** : sur la branche `chantier-docs-commands`, `:Suivi`, `:Brief`, `:Plan`, `:Audit` ouvrent les fichiers du chantier, `:ListDir` affiche toujours les titres.
**Dernier audit** : 2190004 — RÉSERVES — 2026-09-21
**Notes** : relecture du plan par plan-reviewer : RÉSERVES, uniquement sur la qualité des vérifications (Q1–Q5), corrigées dans le plan avant validation.

## Journal de décisions

- **2026-09-21** — Module commun de front matter en `lua/frontmatter.lua`, `listdir.item` en façade. *Pourquoi* : listdir n'est utilisé que dans cette config, aucun appelant à toucher. *Rejeté* : plugin local dédié, disproportionné.
- **2026-09-21** — `listdir` dépend désormais de `lua/frontmatter.lua` de la config. *Pourquoi* : module commun voulu par l'utilisateur. *Rejeté* : garder deux parseurs identiques.
- **2026-09-21** — Audit RÉSERVES : R2 corrigé ; R1 (deux suivis sur une même branche) non traité. *Pourquoi* : un seul suivi par branche d'implémentation, par construction du pipeline. *Rejeté* : détecter et signaler les doublons.
