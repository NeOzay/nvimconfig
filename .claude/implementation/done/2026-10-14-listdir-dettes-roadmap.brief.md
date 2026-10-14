+++
gabarit = "brief"
slug = "listdir-dettes-roadmap"
titre = "Remettre listdir au niveau de list-dir, et ajouter :Dettes et :Roadmap"
statut = "validé"
"créé" = 2026-10-14
+++

## Intention

**Symptôme** : « l'implémentation List-dir a subi des mises à jour ; il faut vérifier que
l'intégration de Nvim est encore entièrement compatible » ; `:Brief` « ne fonctionne pas si le
chantier n'est pas encore créé » ; l'indicateur de tri (« ↑ date ») reste à l'état initial quand le
picker est rouvert par `<leader>fr`.

**But** : que listdir et `lua/chantier.lua` suivent le list-dir actuel (Marqueurs typés, tri typé,
`deprecated`, registre de dette v3) ; un picker `:Dettes` qui met les dettes épinglées en tête, dans
une autre couleur, avec une touche pour basculer le pin ; un picker `:Roadmap` des entrées de
road-map ; `:Brief` utilisable avant la création du chantier.

## Critères de réussite

- **C1** — Registre local en v3 : `list-dir validate .claude/implementation/todo/technical-debt
  --filled` sort en 0 sans avertissement de péremption, de même pour `-solde` et `-ecarte`.
- **C2** — Marqueurs typés : `grep -n 'OPTIONNEL' lua/chantier.lua
  plugins/listdir/lua/listdir/picker/items.lua` montre que les deux reconnaissent la forme typée
  (`^<OPTIONNEL`, `^<À REMPLIR`) ; un `reviewed = <OPTIONNEL date>` s'affiche en retrait.
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

## Hors-périmètre

- L'écriture de la commande `set` de `list-dir` : elle relève d'un chantier préalable, dans
  `~/.claude`, ouvert par une entrée de road-map (dit).
- Toute écriture directe de Neovim dans une entrée de liste (dit).
- Une touche qui ouvrirait le suivi archivé du chantier d'origine d'une dette : proposée, non
  retenue (dit).

## Signaux de dérive

- **S1** — Un `io.open(…, "w")`, `vim.fn.writefile` ou `nvim_buf_set_lines` visant un `.md` de liste
  dans le diff : Neovim écrit dans une entrée (dit).
- **S2** — Le diff touche `~/.claude/skills/list-dir/` : c'est le travail de `set`, chantier
  préalable (dit).
- **S3** — Un appel `list` à plusieurs colonnes de `--sort` dont la sortie est découpée par position
  (dépôt: `docs/plugins/listdir.md`, Gotchas ; validé : dit).
- **S4** — Un appel `list-dir` par élément au lieu d'un par ouverture ou changement de tri (dépôt:
  `docs/plugins/listdir.md`, Key Behaviors ; validé : dit).
- **S5** — `:Dettes` ou `:Roadmap` réimplémentent un picker au lieu de réutiliser
  `picker/items.lua` (dit).

## Contraintes connues de l'utilisateur

- **Intouchable** : Neovim n'écrit jamais directement dans une entrée ; le pin se bascule par
  `list-dir set` (dit).
- **Existant** : `list-dir` n'a pas de commande `set` à ce jour — `list-dir help` en liste
  quatorze, `list-dir set` répond « commande inconnue » (dépôt: `~/.claude` `e597729`).
- **Décision** : `set` naît d'un chantier préalable dans `~/.claude`, démarré depuis une entrée de
  sa road-map ; le toggle du pin de ce chantier en dépend (dit).
- **Décision** : `:Dettes` lit le registre local de l'espace de travail,
  `.claude/implementation/todo/technical-debt` du dépôt courant (dit).
- **Décision** : la migration v2 → v3 du registre local fait partie du chantier (dit) ; il est en
  v2 et sans champ `pin`, ses sorties `-solde` et `-ecarte` en v1 (dépôt:
  `.claude/implementation/todo/technical-debt/.list/contract.toml`) ; procédure :
  `~/.claude/skills/implementation-tracker/list-dir/technical-debt/migrations/3.md` (dépôt).
- **Décision** : ordre de `:Dettes` — pin, puis le champ choisi au cycle du picker, puis `date`,
  puis `severite` ; `date` ou `severite` ne reviennent pas en clé secondaire quand c'est le champ
  choisi (dit).
- **Décision** : la commande s'appelle `:Roadmap` (dit) ; un nom à tiret n'est pas valide en
  Neovim.
- **Décision** : `:Brief` hors chantier — plusieurs briefs hors chantier ouvrent un picker pour
  choisir (dit). Un brief hors chantier est un `*.brief.md` qu'aucun suivi ne cite en `brief` ;
  sur une branche de chantier, rien ne change ; sinon un seul brief s'ouvre directement, aucun
  donne un message (dit).
- **Décision** : clés secondaires de `:Dettes` — `date` la plus récente d'abord, puis `severite`
  la plus grave d'abord (dit).
- **Décision** : `:Roadmap` est le picker d'éléments de listdir tel quel, ouvert directement sur
  la road-map locale (dit).
- **Décision** : `:Dettes` affiche aussi la sévérité en colonne, colorée par niveau ; une touche
  restreint le picker aux dettes épinglées ; le titre porte le nombre de dettes et de pins (dit).
- **Existant** : `EMPTY` (`plugins/listdir/lua/listdir/picker/items.lua`) et `PLACEHOLDERS`
  (`lua/chantier.lua`) ne reconnaissent que `<À REMPLIR>` et `<OPTIONNEL>`, pas
  `<OPTIONNEL date>` ; dette ouverte dans `~/.claude`,
  `consommateurs-des-marqueurs-generiques-hors-etat` (dépôt).
- **Existant** : `list --sort` trie selon le type et range les Marqueurs en fin dans les deux sens
  par `--sort=-champ` ; listdir inverse l'ordre en Lua, ce qui les remonte en tête (dépôt:
  `plugins/listdir/lua/listdir/cli.lua`, `~/.claude/skills/list-dir/references/operations.md`).
- **Existant** : `contract.lua` ne lit pas `deprecated` ; `source`, déprécié en v3, resterait dans
  le cycle de tri (dépôt: `plugins/listdir/lua/listdir/contract.lua`).
- **Existant** : le titre du picker d'éléments est passé une fois à `Snacks.picker.pick`, et
  `<leader>fr` est `Snacks.picker.resume()` (dépôt: `plugins/listdir/lua/listdir/picker/items.lua`,
  `lua/plugins/snacks/picker/init.lua`).
- **Existant** : `--sort` ne demande jamais plus d'une colonne, la sortie multi-colonnes de `list`
  étant ambiguë (dépôt: `docs/plugins/listdir.md`, Gotchas).

## Incertitudes à lever en plan

- Le toggle du pin dépend de `set`, absent aujourd'hui : l'étape qui le branche attend-elle la fin du
  chantier préalable, ou ce chantier livre-t-il tout le reste d'abord ?
- Le solde de la dette `consommateurs-des-marqueurs-generiques-hors-etat` vit dans le registre de
  `~/.claude`, avec un troisième point (`dette.md`) hors de ce dépôt : ce chantier la solde-t-il ?
