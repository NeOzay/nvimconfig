---
slug: debt-registry-migration
titre: Migrer le registre de dette vers le format répertoire-liste
statut: validé
execution: direct
créé: 2026-08-29
---

## Intention

**Symptôme** : `.claude/implementation/todo/technical-debt.md` est un fichier unique de 13 entrées,
alors que toute la documentation du pipeline décrit déjà trois répertoires-listes et n'en parle plus
qu'au passé — `dette.md` : « L'ancien registre portait **une** ligne "Dernière vérification" … Elle
a disparu avec le fichier unique ». La documentation est en avance sur le dépôt, au point que
`/debt-review` est inexécutable : son Étape 0 rend « répertoire introuvable » sur les trois listes.

**But** : migrer l'ancienne liste vers le nouveau format, sans perdre d'entrée, et rendre
`/debt-review` exécutable. La revue elle-même sera une passe séparée, après ce chantier (dit).

## Critères de réussite

- `python3 "$L" validate "$T/<liste>"` passe sur les trois listes
- `python3 "$L" validate "$T/technical-debt" --filled` passe
- `python3 "$L" list "$T/technical-debt" | wc -l` → 13
- `python3 "$L" derive "$T/technical-debt" <tmp> --template review` réussit, puis `validate` sur la
  liste dérivée — c'est le contrôle qui établit que `/debt-review` peut tourner
- `grep -rnE ':[0-9]+' "$T/technical-debt"` ne rend aucun repère de ligne
- `git status --short` ne liste que des chemins sous `.claude/implementation/`

## Hors-périmètre

- **aucun code corrigé** : pas une ligne touchée dans `plugins/` ni `lua/` (dit — première règle de
  `debt-review`, et le chantier hérite de la même borne)
- **aucune entrée soldée, écartée ou classée** : pas de `move`, pas de `category`, pas de
  `reviewed`. Les trois listes sœurs sont créées vides et le restent (dit)
- `todo/README.md`, pourtant annoncé par l'arborescence de `contrat.md`, n'est pas écrit (dit)
- le champ `source` reste au marqueur `<OPTIONNEL>` ; la ligne « *Identifié par
  `implementation-auditor`, R<n>…* » reste dans le corps de l'entrée (dit)

## Signaux de dérive

- si je commence à juger qu'une entrée est soldée ou sans objet, c'est raté : c'est la revue, pas
  la migration — le noter et continuer (dit)
- si un fichier hors de `.claude/implementation/` apparaît au `git status`, s'arrêter (dit)
- si le compte des entrées s'écarte de 13 à un moment quelconque, s'arrêter (dépôt: dette.md,
  « contrôle de conservation »)

## Contraintes connues de l'utilisateur

- **Réutiliser** : toute manipulation de liste passe par `list-dir` ; aucun `mv`, `cp` ni fichier
  créé à la main (dépôt: skills/debt-review/SKILL.md, « Aucun fichier n'est créé, déplacé ni
  renommé à la main »)
- **Intouchable** : le champ `date` de chaque entrée et son `id` ne changent jamais — l'`id` est la
  clé de dédoublonnage (dépôt: skills/implementation-tracker/references/dette.md, « Corriger une
  entrée »)
- **À écrire** : les gabarits `.list/templates/review.toml` et `review.md` de `technical-debt/`
  n'existent nulle part, et `/debt-review` Étape 1 en dépend (dit + dépôt: debt-review/SKILL.md)
- **Repères** : les 13 entrées citent des numéros de ligne, que `dette.md` interdit désormais. Ils
  sont réécrits en citations de texte, en s'appuyant sur les deux rapports d'audit d'origine
  (`done/2026-08-18-tts-piper.audit.md`, `done/2026-08-29-list-dir-viewer.audit.md`) et sur une
  lecture du fichier cité (dit)
- **Ancien fichier** : `todo/technical-debt.md` est supprimé par `git rm` une fois les 13 entrées
  éclatées (dit)

## Incertitudes à lever en plan

- l'enum `category` du contrat doit énumérer les sept catégories de `debt-review` : reste à établir
  leurs slugs exacts, tous les sept, contre `references/categories.md`
- le contrat des deux listes sœurs diffère de celui du registre actif (`## Soldé le` / `## Écartée
  le` requis, les deux sections du milieu facultatives) : trois contrats distincts à écrire, dont
  la forme exacte reste à arrêter
- une entrée dont le repère ne retrouve plus sa cible dans le dépôt : la citation ne peut alors
  s'appuyer que sur le rapport d'audit — à borner avant d'écrire
