# Minuet AI

## Role
Complétion de code par LLM (DeepSeek `deepseek-v4-flash`), affichée en ghost text inline. Remplace copilot.lua.

## Files
- Config : `lua/plugins/minuet.lua`
- Recalage frappe/suggestion : `lua/utils/minuet_typing.lua`
- Highlights : `lua/highlights/minuet.lua`
- Intégration blink : `lua/plugins/blink-cmp.lua` (source `minuet`, keymap `<A-y>`)
- Clé d'API : `lua/utils/env.lua` → lit `.env` à la racine de la config (gitignoré)

## Key Behaviors
- Provider `openai_compatible` (endpoint `https://api.deepseek.com/v1/chat/completions`), pas `openai_fim_compatible` :
  l'endpoint FIM beta de DeepSeek ne sert que `deepseek-chat`, alors que `deepseek-v4-flash` n'est exposé
  que par l'API chat.
- Clé lue via `require("utils.env").get("DEEPSEEK_API_KEY")` : `.env` d'abord, variable d'environnement en repli.
  `.env` est parsé une fois puis mis en cache ; `require("utils.env").reload()` invalide le cache.
- Mode d'affichage : **ghost text** (`virtualtext`, clé au singulier sans underscore), `auto_trigger_ft = { "*" }`
  avec une liste d'exclusions (`codecompanion`, `markdown`, prompts de picker, etc.).
- `virtualtext.show_on_completion_menu = true` : le ghost text reste visible **même quand le menu blink est
  ouvert** (par défaut minuet l'efface dès que le menu apparaît).
- La source blink `minuet` existe toujours mais **n'est pas** dans `sources.default` : elle ne part qu'en
  manuel via `<A-y>`. La mettre en auto ferait payer deux fois chaque frappe (ghost text + menu).
- `blink.completion.ghost_text.enabled = false` : évite un second ghost text concurrent.
- `throttle = 1500` / `debounce = 600` limitent le coût des appels API.
- **Recalage des suggestions « en vol »** (`lua/utils/minuet_typing.lua`) : minuet ne recale sur le texte tapé
  que les suggestions *déjà affichées* (`update_suggestion_on_typing`). Celles qui arrivent après coup étaient
  affichées telles quelles, décalées. Le module enveloppe `complete()` du backend actif : à la réception,
  la suggestion est amputée du texte tapé depuis l'envoi si celui-ci la préfixe, sinon elle est jetée.
  Jette aussi tout si on a changé de buffer, quitté l'insertion ou reculé le curseur.
  Tolère une indentation en tête de suggestion (les modèles FIM répètent souvent l'indentation du buffer).
  Ne s'applique **qu'aux** requêtes du ghost text : la détection se fait sur la pile d'appel
  (`minuet/virtualtext.lua`), la source blink garde son comportement natif.

## Keymaps
Tous en mode insertion, choisis hors du champ de blink (`<Tab>`, `<S-Tab>`, `<CR>`, `<C-y>`, `<C-e>`, `<C-space>`) :
- `<A-a>` — accepter la suggestion complète
- `<A-l>` — accepter une ligne
- `<A-z>` — accepter N lignes (demande le nombre)
- `<A-n>` / `<A-p>` — suggestion suivante / précédente (ou invocation manuelle)
- `<A-e>` — rejeter
- `<A-y>` (blink) — déclencher la source minuet dans le menu de complétion

## Gotchas
- **`thinking = { type = "disabled" }` est obligatoire** dans `optional`. `deepseek-v4-flash` raisonne par
  défaut : en streaming il n'envoie que `delta.reasoning_content` pendant plusieurs secondes et `delta.content`
  reste `nil`. minuet coupe la requête à `request_timeout` (3 s) et n'affiche donc jamais rien — alors que la
  console DeepSeek montre bien des requêtes facturées. Symptôme typique : « requêtes OK, zéro suggestion ».
- Ne pas mettre `stop = { "\n\n" }` : ça tronque les complétions multi-lignes.
- La clé de config est `virtualtext`, **pas** `virtual_text` : une faute de frappe ici est silencieuse
  (minuet garde ses défauts, donc aucun ghost text).
- `MinuetVirtualText` : minuet le lie à `Comment` **uniquement s'il n'est pas déjà défini**. Il est surchargé
  dans `lua/highlights/minuet.lua` (`grey_fg` + italique), appliqué automatiquement à `LazyLoad` — le loader
  base46 matche le nom de fichier `minuet` contre le nom de plugin `minuet-ai.nvim`. Un `link` ne permettant
  pas d'ajouter l'italique, la couleur est posée en dur plutôt que liée à `Comment`.
- `require("minuet").make_blink_map()` renvoie une **liste** de fonctions, pas une fonction : l'appeler comme
  une fonction plante. Dans `blink-cmp.lua` la table est écrite en dur (`cmp.show { providers = { "minuet" } }`)
  pour éviter en plus de charger minuet au démarrage.
- Sans clé, minuet notifie une erreur à chaque déclenchement (`notify = "warn"`). Renseigner `.env`.
- Copilot est désactivé (`enabled = false` dans `lua/plugins/copilot.lua`), y compris `copilot-lsp` et
  `blink-cmp-copilot`. `lsp/copilot_ls.lua` reste présent mais n'est plus activé (l'appel `vim.lsp.enable`
  vivait dans l'`init` de `copilot-lsp`).
- codecompanion est passé sur l'adapter `deepseek` (`adapters.http.deepseek`, modèle `deepseek-v4-flash`),
  puisqu'il dépendait de copilot.lua pour l'auth.

## Changelog
- 2026-08-02 : ajout de minuet-ai en remplacement de copilot.lua ; création de `lua/utils/env.lua` et du `.env`
  gitignoré ; bascule de codecompanion sur DeepSeek.
- 2026-08-02 : passage de la source blink auto au ghost text (`virtualtext`), visible même menu blink ouvert,
  mappings `<A-…>` sans conflit ; source blink conservée en manuel (`<A-y>`).
- 2026-08-02 : correctif « requêtes API mais aucune suggestion » → `thinking.type = "disabled"` ajouté et
  `stop` retiré. Vérifié de bout en bout : le backend renvoie bien des items.
- 2026-08-02 : ajout de `lua/utils/minuet_typing.lua` — les suggestions arrivant pendant la frappe sont
  recalées (préfixe tapé retiré) ou jetées si elles ne correspondent plus.
