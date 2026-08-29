---
slug: debt-registry-migration
---

## 2026-08-29 — clôture — `435c39e`

**Verdict** : RÉSERVES

### Vérifications exécutées

Toutes lancées depuis la racine du dépôt, sur `debt-registry-migration` à `435c39e`, avec
`L="$HOME/.claude/skills/list-dir/scripts/list-dir.py"` et `T=".claude/implementation/todo"`.

- `python3 "$L" validate "$T/technical-debt"` → `13 élément(s) conformes au contrat`, rc=0
- `python3 "$L" validate "$T/technical-debt-solde"` → `0 élément(s) conformes au contrat`, rc=0
- `python3 "$L" validate "$T/technical-debt-ecarte"` → `0 élément(s) conformes au contrat`, rc=0
- `python3 "$L" validate "$T/technical-debt" --filled` → `13 élément(s) remplis et conformes au
  contrat`, rc=0
- `python3 "$L" list "$T/technical-debt" | wc -l` → `13`
- `python3 "$L" list "$T/technical-debt-solde" | wc -l` → `0` ; idem `-ecarte` → `0`
- `python3 "$L" derive "$T/technical-debt" <tmp> --template review` → `13 fiche(s) à instruire`,
  rc=0 ; puis `validate <tmp>` → `13 élément(s) conformes`, rc=0 ; `list <tmp> | wc -l` → `13`
- `grep -rnE ':[0-9]+' "$T/technical-debt"` → aucune sortie, rc=1 (aucun repère)
- `grep -rniE 'lignes? [0-9]+' "$T/technical-debt"` → aucune sortie (contrôle ajouté : le motif du
  brief ne voit pas les repères en prose « ligne 44 », que la source portait)
- `git status --short` → vide ; `git status --short --untracked-files=all` → vide
- `git diff --stat master...debt-registry-migration` → 22 fichiers, tous sous `.claude/`

**Contrôles d'intégrité des vérifications elles-mêmes** — une commande qui passe toujours ne prouve
rien :

- `validate --filled` sur la liste dérivée (marqueurs `<À REMPLIR>` partout) → `65 manquements`,
  rc=1. Le `--filled` qui passe sur le registre est donc discriminant.
- `grep -rcE ':[0-9]+'` sur `git show master:…/technical-debt.md` → `5` lignes. Le contrôle
  anti-repère attrape bien ce qu'il vise, y compris `LICENSE:27` sans extension.
- `move` d'une entrée vers `technical-debt-solde`, rejoué dans un dépôt git jetable hors du
  dépôt → rc=0, avec le message attendu « Le contrat de technical-debt-solde demande encore :
  section « Soldé le » — manquante ». Voir R3.

### Conformité à l'intention

- Critère « `validate` passe sur les trois listes » : **atteint, vérifié**.
- Critère « `validate --filled` sur `technical-debt` » : **atteint, vérifié**, et établi comme
  discriminant.
- Critère « `list | wc -l` → 13 » : **atteint, vérifié**.
- Critère « `derive --template review` puis `validate` » : **atteint, vérifié**. Les gabarits
  `.list/templates/review.toml` et `review.md` existent, le `from = "title"` / `from = "date"`
  reporte bien, et les sections produites (`Vérifié par`, `Verdict`, `Action`, `Arbitrage`) sont
  exactement celles qu'attend l'Étape 1 de `debt-review`. Le symptôme d'origine — `/debt-review`
  inexécutable à son Étape 0 — a disparu : la boucle `validate` de son Étape 0 passe sur les trois
  noms qu'elle attend.
- Critère « aucun repère de ligne » : **atteint, vérifié**, et au-delà du motif du brief : les
  repères en prose (`ligne 44`, `lignes 17-20`, `lignes 64-67`) ont aussi été réécrits.
- Critère « `git status --short` ne liste que des chemins sous `.claude/implementation/` » :
  **atteint** — l'arbre est propre, les trois commits sont posés. Le diff contient bien un fichier
  hors de `.claude/implementation/`, `.claude/plans/spicy-shimmying-wand.md` ; l'écart est assumé
  et daté dans le plan (« Vérification d'ensemble », point 4) et dans le suivi, qui élargit le
  signal de dérive à `.claude/`. Vérifié par ailleurs que les six plans antérieurs sont eux aussi
  versionnés (`git ls-files .claude/plans/`) : c'est la pratique établie du dépôt, pas une entorse.

**Conservation du contenu** — contrôle indépendant, non demandé par le suivi mais central au but :
les 13 titres `## ` de `git show master:…/technical-debt.md` correspondent un pour un aux 13 champs
`title` des entrées, au caractère près une fois la date de préfixe retirée. Les `date` se
répartissent en 8 × `2026-08-18` et 5 × `2026-08-29`, conformément à la source. Aucune entrée
perdue, aucune ajoutée, aucun `id` ni aucune `date` altérés.

**Fidélité des citations** — les repères réécrits ont été confrontés au dépôt, pas seulement au
rapport d'audit d'origine. Tous vérifiés exacts :
`config.lua` `M.current_voice()` / `if M.voice then return M.voice end` (l. 63-66),
`client.lua` `if timer then` (l. 99) et `impossible d'ouvrir une socket` (l. 65),
`LICENSE` clause `edge_tts` (l. 27), `test_protocol.lua` cas « déduit la voix de la langue » et
`local expected = config.languages_to_voice[config.backend]["fr"]` (l. 68 et 73),
`tts-piperd.py` `Server.dispatch` et `self.player.stop()` (l. 232, 236),
`document.lua` `M.path` et `contract.name:gsub("[^%w%-_.]", "_")` (l. 96-97),
`discover.lua` `M.find(paths, depth)` (l. 42), `Makefile` cible `test` (l. 3-4).
La réécriture des repères a donc gagné en durabilité **sans** perdre en précision.

**Contrats** — les trois `contract.toml` reprennent exactement le tableau de champs et les sections
de `implementation-tracker/references/dette.md` (« Ce qu'une entrée porte »), y compris la variante
des listes sœurs (`Soldé le` / `Écartée le` requises, les deux du milieu facultatives). L'enum
`category` énumère les sept catégories de `debt-review/references/categories.md` avec les slugs
exacts : `a-solder`, `non-pertinent`, `doublon`, `pas-une-dette`, `aggravee`, `pertinent`,
`inverifiable`. L'incertitude n°1 du brief est donc levée et vérifiée contre sa source.

**Hors-périmètre** : respecté sur les quatre points.
- aucune ligne sous `plugins/` ni `lua/` dans le diff — le `--stat` ne contient que `.claude/` ;
- aucun `move`, aucun `category`, aucun `reviewed` renseigné : les 13 entrées portent
  `reviewed = "<OPTIONNEL>"` et `category = "<OPTIONNEL>"`, les deux listes sœurs sont vides (0/0) ;
- pas de `todo/README.md` (`ls .claude/implementation/todo/` → trois répertoires, rien d'autre) ;
- `source = "<OPTIONNEL>"` sur les 13, et la ligne « *Identifié par `implementation-auditor`,
  R<n>…* » est présente dans les 13 corps.

**Signaux de dérive** : aucun matérialisé.
- Aucune entrée soldée, écartée ni classée. Le seul cas de tension — `text-processor-defauts-upstream`,
  dont le point (a) est corrigé depuis `818270d` — a été **relevé sans être jugé**, et remonté au
  hand-off du suivi. C'est le comportement que le brief prescrivait.
- Aucun fichier hors de `.claude/`.
- Le compte de 13 tient à toutes les étapes.

### Qualité du travail produit

- **R1** — `technical-debt/text-processor-defauts-upstream.md`, section `## Constat` — la section
  porte un bloc de citation ajouté, « **Migration 2026-08-29** — le point (a) ne se vérifie plus
  … ». Il est correct, honnête, et le plan l'autorisait (« garder la description sans repère, et
  noter l'entrée pour la revue »). Mais `dette.md` réserve la réécriture d'un `## Constat` au cas
  `aggravee` — « son `## Constat` est mis à jour, daté de la mise à jour » — et le champ `date` de
  l'entrée reste au `2026-08-18` du constat, alors que le Constat contient désormais du texte daté
  du `2026-08-29`. Le coût est mince et la note est explicite, mais la revue doit lire ce Constat
  en sachant qu'il n'est plus intégralement daté de son champ `date`.

- **R2** — les 13 entrées — la ligne d'attribution « *Identifié par `implementation-auditor`,
  R<n> du rapport d'audit …* » se retrouve **à l'intérieur** de la section `## Pour solder`, alors
  qu'elle était un paragraphe libre en fin d'entrée dans la source. Conséquence directe du
  hors-périmètre « `source` reste au marqueur », donc conforme ; mais tout traitement qui projette
  ou cite `Pour solder` (un `derive`, une lecture de la section par la revue) récupérera
  l'attribution collée au plan de solde. Le rangement naturel de cette information est le champ
  `source`, que la revue pourra remplir.

- Le reste est bien fait : la conversion des étiquettes en gras (`**Constat**`) en titres `##`
  était nécessaire au contrat et le texte est repris fidèlement ; les sections `## Assumé` sont
  posées au marqueur `<OPTIONNEL>` partout sauf sur `speak-coupe-avant-synthese`, seule entrée qui
  en portait une dans la source, et son contenu y est repris mot pour mot. Le gabarit `review.md`
  porte bien ses marqueurs dans le corps, ce qu'imposait le fonctionnement de `derive` (copie
  verbatim) et que le plan avait établi au cadrage.

### Dette induite

- **R3** — contrats de `technical-debt-solde` et `technical-debt-ecarte` — ils exigent
  respectivement `## Soldé le` et `## Écartée le`, tandis que `debt-review` Étape 5 impose de
  déplacer l'entrée par `move` dans un **premier** commit et de n'écrire la section que dans un
  **second**. Entre les deux, la liste de destination est non conforme. Vérifié en le rejouant dans
  un dépôt git jetable : `move` rend rc=0 et prévient explicitement (« Le contrat de
  technical-debt-solde demande encore : section « Soldé le » — manquante … demande un SECOND
  commit »), puis `validate` sur la destination rend rc=1 tant que la section manque. Le dispositif
  est donc **cohérent et anticipé par l'outil**, pas cassé par ce chantier — mais l'opérateur de la
  première revue doit savoir que le contrôle final de l'Étape 6 (`validate` sur les trois listes)
  échouera s'il est lancé entre les deux commits. Rien à corriger ici ; c'est un point de passation.

- Aucune duplication introduite, aucune abstraction créée sans nécessité, aucun contournement laissé
  en place. Le préambule de l'ancien fichier (« N'y figurent pas : les idées d'amélioration … ») n'a
  pas été repris, et c'est correct : la règle vit dans `dette.md` (« les idées d'amélioration — le
  registre ne liste que du constaté »), sa recopie aurait été la dette.

### Réserve de procédure

- **R4** — trois commits sont posés sur la branche (`dae748f`, `dbf6e1a`, `435c39e`). La règle
  absolue de `CLAUDE.md` interdit tout `git commit` sans accord explicite de l'utilisateur, et rien
  dans le suivi, le plan ou le journal de décisions ne consigne cet accord. Je ne peux pas trancher
  depuis les artefacts : l'accord a pu être donné en séance sans être écrit. Point à confirmer par
  l'utilisateur, pas un manquement établi.

### Bloquants

Aucun.
