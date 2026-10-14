+++
gabarit = "suivi"
slug = "listdir-dettes-roadmap"
titre = "Remettre listdir au niveau de list-dir, et ajouter :Dettes et :Roadmap"
branche = "listdir-dettes-roadmap"
base = "master"
statut = "terminé"
session = 2
lettre = "A"
"modèle" = "opus"
plan = ".claude/implementation/done/2026-10-14-listdir-dettes-roadmap.plan.md"
brief = ".claude/implementation/done/2026-10-14-listdir-dettes-roadmap.brief.md"
audit = ".claude/implementation/done/2026-10-14-listdir-dettes-roadmap.audit"
skills = ["nvim-mini-test"]
"créé" = 2026-10-14
maj = 2026-10-14
+++

## Objectif et périmètre

**Symptôme** : « l'implémentation List-dir a subi des mises à jour ; il faut vérifier que
l'intégration de Nvim est encore entièrement compatible » ; `:Brief` « ne fonctionne pas si le
chantier n'est pas encore créé » ; l'indicateur de tri (« ↑ date ») reste à l'état initial quand le
picker est rouvert par `<leader>fr`.

**But** : que listdir et `lua/chantier.lua` suivent le list-dir actuel (Marqueurs typés, tri typé,
`deprecated`, registre de dette v3) ; un picker `:Dettes` qui met les dettes épinglées en tête, dans
une autre couleur, avec une touche pour basculer le pin ; un picker `:Roadmap` des entrées de
road-map ; `:Brief` utilisable avant la création du chantier.

**Critères de réussite** :

- **C1** — Registre local en v3 : `list-dir validate .claude/implementation/todo/technical-debt
  --filled` sort en 0 sans avertissement de péremption, de même pour `-solde` et `-ecarte`.
- **C2** — Marqueurs typés : `grep -n 'OPTIONNEL' lua/chantier.lua
  plugins/listdir/lua/listdir/picker/items.lua` montre que les deux reconnaissent la forme typée
  (`^<OPTIONNEL`, `^<À REMPLIR`) ; un `reviewed = <OPTIONNEL date>` s'affiche en retrait.
  *Preuve déplacée sur `lua/frontmatter.lua`, plus un test d'affichage — arbitrage Q1 du Plan.*
- **C3** — Tri : avec le sens inversé (`<A-v>`), les éléments au Marqueur ou sans valeur restent en
  fin ; les champs `deprecated` sortent du cycle de tri.
- **C4** — `:Dettes` : pins en tête, dans une couleur propre ; dans chaque groupe, ordre du champ du
  cycle, puis `date` décroissante, puis `severite` décroissante, sans clé répétée ; sévérité
  colorée par niveau ; une touche restreint aux pins ; le titre donne le nombre de dettes et de
  pins.
- **C5** — Toggle du pin : la touche appelle `list-dir set` ; le diff de l'entrée ne touche que la
  ligne `pin` ; le picker se rafraîchit en place.
- **C6** — `:Roadmap` ouvre le picker d'éléments de listdir directement sur
  `.claude/implementation/todo/road-map`.
- **C7** — `:Brief` sur `master` : un brief hors chantier → ouvert ; plusieurs → picker ; aucun →
  message. Sur une branche de chantier, inchangé.
- **C8** — Après un changement de tri, `<leader>fr` rouvre le picker avec un indicateur
  (« ↑ date ») conforme au tri en cours.
- **C9** — Tests mini.test du listdir et de `chantier.lua` verts ; `docs/plugins/listdir.md` décrit
  les nouvelles commandes et touches.

**Hors-périmètre** :

- L'écriture de la commande `set` de `list-dir` : elle relève d'un chantier préalable, dans
  `~/.claude`, ouvert par une entrée de road-map.
- Toute écriture directe de Neovim dans une entrée de liste.
- Une touche qui ouvrirait le suivi archivé du chantier d'origine d'une dette.

**Signaux de dérive** :

- **S1** — Un `io.open(…, "w")`, `vim.fn.writefile` ou `nvim_buf_set_lines` visant un `.md` de liste
  dans le diff : Neovim écrit dans une entrée.
- **S2** — Le diff touche `~/.claude/skills/list-dir/` : c'est le travail de `set`, chantier
  préalable.
- **S3** — Un appel `list` à plusieurs colonnes de `--sort` dont la sortie est découpée par position.
  *Un `--sort` à plusieurs clés dont seul l'id est lu n'en est pas un — arbitrage Q7 du Plan.*
- **S4** — Un appel `list-dir` par élément au lieu d'un par ouverture ou changement de tri.
- **S5** — `:Dettes` ou `:Roadmap` réimplémentent un picker au lieu de réutiliser
  `picker/items.lua`.

## Étapes

- [x] 1. Migrer la structure du registre local de dette en v3 — `.claude/implementation/todo/technical-debt{,-solde,-ecarte}/` — vérif: `list-dir validate` des trois listes sans « périmé », comptes `severite=inconnue` égaux (plan, étape 1)
- [x] 2. Reporter `source` dans `chantier` et `reference` — `.claude/implementation/todo/technical-debt/*.md` — vérif: garde de `migrations/3.md` en 0, `list-dir validate --filled` des trois listes (plan, étape 2)
- [x] 3. Reconnaître les Marqueurs typés — `lua/frontmatter.lua`, `lua/chantier.lua`, `plugins/listdir/lua/listdir/picker/items.lua`, `tests/minimal_init.lua`, `tests/listdir/test_frontmatter.lua` — vérif: `make test-file FILE=tests/listdir/test_frontmatter.lua` et les grep du plan (étape 3)
- [x] 4. Tri typé et champs dépréciés — `plugins/listdir/lua/listdir/{cli,contract}.lua`, `picker/{items,lists}.lua`, `tests/listdir/test_cli.lua` — vérif: `make test-file FILE=tests/listdir/test_cli.lua`
- [x] 5. Indicateur de tri juste au resume — `plugins/listdir/lua/listdir/picker/items.lua`, `tests/minimal_init.lua`, `tests/listdir/test_items.lua` — vérif: `make test-file FILE=tests/listdir/test_items.lua`
- [x] 6. Points d'extension du picker d'éléments, et `:Roadmap` — `picker/items.lua`, `lua/registres.lua`, `lua/cmd.lua`, `tests/listdir/test_items.lua` — vérif: `make test-file FILE=tests/listdir/test_items.lua` et le titre headless de `:Roadmap` (plan, étape 6)
- [x] 7. `:Dettes` — `lua/registres.lua`, `lua/cmd.lua`, `lua/highlights/listdir.lua`, `tests/listdir/test_registres.lua` — vérif: `make test-file FILE=tests/listdir/test_registres.lua` et le décompte headless de `:Dettes`
- [x] 8. `:Brief` hors chantier — `lua/chantier.lua`, `tests/chantier/test_chantier.lua` — vérif: `make test-file FILE=tests/chantier/test_chantier.lua`
- [x] 9. Documentation — `docs/plugins/listdir.md`, `CLAUDE.md` — vérif: `make test`, grep des nouvelles entrées (plan, étape 9)
- [x] 10. Toggle du pin par `list-dir toggle` — `plugins/listdir/lua/listdir/cli.lua`, `lua/frontmatter.lua`, `lua/registres.lua`, `tests/listdir/test_registres.lua`, `docs/plugins/listdir.md` — vérif: `make test-file FILE=tests/listdir/test_registres.lua`, `make test`

## État courant

**Prochaine action** : Clôture — aplatissement sur `master`.
**Vérification** : `make test` ; `list-dir validate --filled` des trois listes de dette ; ouverture
manuelle de `:Dettes`, `:Roadmap`, `:Brief` sur `master`, `<leader>fr` après un `<A-s>`.
**Dernier audit** : d100e50 — DÉFAVORABLE — 2026-10-14
**Notes** : `list-dir set` n'existe pas : `list-dir toggle <liste> pin --id <id>` sert le pin
(`fill --id <id> --override` réécrit tout autre champ) ; l'Étape 10 n'attend plus rien. À la Clôture, signaler que la dette
`consommateurs-des-marqueurs-generiques-hors-etat` de `~/.claude` ne garde que son point `dette.md`.

## Passation

**Écrite** : session 1, après AE0.

**En cours** : rien.

**À savoir** :

- `list-dir validate` rend 0 sur un contrat périmé : l'avertissement ne passe que sur stderr, d'où
  le `grep -c 'périmé'` des vérifications des Étapes 1 et 2.
- `list-dir new` pose une date au Marqueur typé entre guillemets (`date = "<À REMPLIR date>"`) :
  dans les tests, remplir par `list-dir fill`, qui écrit la date sans guillemets.
- `list --sort=-id` répète l'id en colonne (`<id> <id>`) : sans effet, seul le premier token est lu.
- `list … | head` laisse une trace `BrokenPipeError` sur stderr : bruit, pas une erreur.
- L'entrée `list-dir-set` de la road-map de `~/.claude` n'y est pas commitée : à faire dans ce
  dépôt-là, hors de ce Chantier.

## Dettes écartées

<OPTIONNEL>

## Journal de décisions

- **2026-10-14** — `list` est appelé avec plusieurs clés de tri, seul l'id est lu ; toutes les
  valeurs affichées viennent du front matter. *Pourquoi* : tri typé par la CLI (Marqueurs en fin
  dans les deux sens) sans découpage positionnel. *Rejeté* : tri secondaire en Lua (arbitrage Q7).
- **2026-10-14** — Une valeur fausse de `migrateur-de-liste` se corrige à la main par l'agent
  Claude, jamais par Neovim. *Pourquoi* : geste 6 de `migrations/3.md`, `fill` ne réécrit que les
  Marqueurs. *Rejeté* : attendre `set` (arbitrage Q2).
- **2026-10-14** — Le toggle du pin appelle `list-dir toggle <liste> pin --id <id>` ; C5, S2 et le
  Hors-périmètre lisent `set` comme cette commande. *Pourquoi* : `set` n'a pas été livré, `toggle`
  inverse le booléen sans lecture préalable. *Rejeté* : `fill --override`, qui demande la valeur.
- **2026-10-14** — Hors périmètre, pour le registre de `~/.claude` à la Clôture : la consigne de
  `migrations/3.md` ne lit que `source`, or 16 entrées l'avaient au Marqueur et citaient leur origine
  dans le corps (« Identifié par … R<n> du rapport d'audit `<slug>` ») ; les 22 valeurs ont été
  tranchées par l'utilisateur au geste 8.
- **2026-10-14** — Le picker d'éléments s'ouvre même vide (`show_empty`). *Pourquoi* : la
  road-map locale est vide, et un filtre des pins sans résultat fermerait `:Dettes` sans pouvoir se
  défaire. *Rejeté* : un message à la place du picker.
- **2026-10-14** — Audit de Clôture `d100e50` DÉFAVORABLE (R1 : touche du pin `<A-N>` au code,
  `<A-t>` à la doc ; R2 : type de `ItemsOpts.keys`), corrigés en `AE10.1` ; Clôture sans nouvel
  audit, sur décision de l'utilisateur. *Rejeté* : un second audit complet.
