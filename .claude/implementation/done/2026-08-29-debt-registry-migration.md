---
slug: debt-registry-migration
titre: Migrer le registre de dette vers le format répertoire-liste
branche: debt-registry-migration
base: master
statut: terminé
session: 1
execution: direct
plan: .claude/implementation/done/2026-08-29-debt-registry-migration.plan.md
brief: .claude/implementation/done/2026-08-29-debt-registry-migration.brief.md
audit: .claude/implementation/done/2026-08-29-debt-registry-migration.audit.md
créé: 2026-08-29
maj: 2026-08-29
---

## Objectif et périmètre

Repris du brief (`brief:`), pas réinventé.

**Symptôme** : `.claude/implementation/todo/technical-debt.md` est un fichier unique de 13 entrées,
alors que toute la documentation du pipeline décrit déjà trois répertoires-listes et n'en parle plus
qu'au passé — `dette.md` : « L'ancien registre portait **une** ligne "Dernière vérification" … Elle
a disparu avec le fichier unique ». La documentation est en avance sur le dépôt, au point que
`/debt-review` est inexécutable : son Étape 0 rend « répertoire introuvable » sur les trois listes.

**But** : migrer l'ancienne liste vers le nouveau format, sans perdre d'entrée, et rendre
`/debt-review` exécutable. La revue elle-même sera une passe séparée, après ce chantier.

**Critères de réussite** :
- `validate` passe sur les trois listes, et `validate --filled` sur le registre
- `list "$T/technical-debt" | wc -l` → 13
- `derive --template review` réussit, puis `validate` sur la liste dérivée
- `grep -rnE ':[0-9]+' "$T/technical-debt"` ne rend aucun repère de ligne
- `git status --short` ne liste que des chemins sous `.claude/implementation/`

**Hors-périmètre** :
- aucun code corrigé : pas une ligne dans `plugins/` ni `lua/`
- aucune entrée soldée, écartée ou classée : pas de `move`, pas de `category`, pas de `reviewed`.
  Les listes sœurs sont créées vides et le restent
- pas de `todo/README.md`
- le champ `source` reste au marqueur ; la ligne « *Identifié par `implementation-auditor`, R<n>…* »
  reste dans le corps de l'entrée

**Signaux de dérive** :
- si je commence à juger qu'une entrée est soldée ou sans objet, c'est raté : c'est la revue, pas la
  migration — le noter et continuer
- si un fichier hors de `.claude/` apparaît au `git status`, s'arrêter
- si le compte des entrées s'écarte de 13 à un moment quelconque, s'arrêter

## Étapes

- [x] 1. Créer les trois répertoires-listes et leurs contrats — `.claude/implementation/todo/` — vérif: `validate` ×3 + relecture des trois contrats par l'API `list-dir`
- [x] 2. Migrer les 8 entrées `tts-piper` — `todo/technical-debt/` — vérif: `list | wc -l` → 8, `validate --filled`
- [x] 3. Migrer les 5 entrées `list-dir-viewer` — `todo/technical-debt/` — vérif: `list | wc -l` → 13, `validate --filled`, aucun repère de ligne
- [x] 4. Écrire les gabarits `review.toml` / `review.md` — `todo/technical-debt/.list/templates/` — vérif: `derive --template review` vers un tmp + `validate` + 13 fiches
- [x] 5. Retirer `todo/technical-debt.md` et contrôler la conservation — vérif: 13/0/0, `validate --filled`, `git status` propre

## État courant

**Prochaine action** : aucune — chantier clos. La suite est `/debt-review`, qui a désormais un
registre à relire.
**Vérification** : `python3 "$L" validate "$T/technical-debt" --filled` et
`python3 "$L" list "$T/technical-debt" | wc -l` → 13
**Dernier audit** : `435c39e` — RÉSERVES — 2026-08-29
**Hand-off à la revue** : `text-processor-defauts-upstream` porte un point (a) corrigé depuis le
commit `818270d` — relevé dans l'entrée, non jugé. C'est le seul cas rencontré.
**Notes** : audit de clôture `RÉSERVES` — R1 corrigé, R2/R3 versés au registre de dette, R4 sans
objet (l'accord de commit avait été donné en conversation).

## Journal de décisions

- **2026-08-29** — La migration ne juge aucune dette : elle ne solde, n'écarte ni ne classe.
  *Pourquoi* : `/debt-review` porte la règle de preuve et l'arbitrage utilisateur ; les mêlerait à
  une migration produirait des sorties de registre que personne n'a validées. *Rejeté* : migrer et
  réviser d'un seul geste.
- **2026-08-29** — Les repères de ligne sont réécrits en citations de texte pendant la migration.
  *Pourquoi* : `dette.md` les interdit, et un repère périmé fait classer `non-pertinent` une dette
  vivante à la revue suivante. *Rejeté* : reprise strictement verbatim, qui aurait importé le défaut.
- **2026-08-29** — Le contrat des listes `-solde` et `-ecarte` rend facultatives « Pourquoi c'est
  gênant » et « Pour solder », et exige « Soldé le » / « Écartée le ». *Pourquoi* : `dette.md` —
  « ce qu'une entrée payée doit prouver est son solde, pas son plan de solde ».
- **2026-08-29** — Clos sur un audit `RÉSERVES` : R1 corrigé, R2 et R3 versés au registre de dette.
  *Pourquoi* : aucune réserve n'est un défaut du travail livré ; R2 découle d'un choix de périmètre
  et R3 d'une contradiction du dispositif, pas du chantier. *Rejeté* : traiter R2 ici, ce qui aurait
  élargi le périmètre après coup.
