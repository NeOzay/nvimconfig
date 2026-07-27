# docstring-highlight.nvim

Plugin Neovim qui met en évidence le contenu des docstrings Python (style Google).

Inspiré de [python-docstring-highlighter](https://github.com/rodolphebarbanneau/python-docstring-highlighter) pour VSCode, qui utilise des injections TextMate grammar pour colorer les sections, directives, types, paramètres et code inline dans les docstrings. Cette extension ne supporte que le matching single-line. Notre implémentation utilise treesitter + extmarks au lieu de TextMate.

## Objectif

Reproduire dans Neovim les fonctionnalités de [python-docstring-highlighter](https://github.com/rodolphebarbanneau/python-docstring-highlighter) (VSCode). Ce plugin met en évidence :

- **Section headings** — `Args`, `Returns`, `Raises`, `See Also`, etc.
- **Directives RST** — `.. note::`, `.. warning::`, etc.
- **Identifiants / cross-references** — `:meth:`, `:attr:`, `:class:`, `:func:`, etc.
- **Inline literals** — contenu entre backticks `` `code` ``
- **Code snippets** — texte interprété avec catégorisation (fonctions, types, variables)
- **Paramètres / variables** — déclarations dans les 3 formats (Google, NumPy, Sphinx)
- **Type annotations** — types avec détection adaptée au format

Formats supportés par le plugin VSCode : **Google**, **NumPy**, **Sphinx** + support partiel d'autres formats.

### État actuel vs cible

| Fonctionnalité | VSCode plugin | Notre plugin |
|---|---|---|
| Section headings (Google) | oui | **oui** |
| Params + types (Google) | oui | **oui** |
| Inline code | oui | **oui** |
| Params + types (NumPy) | oui | non |
| Params + types (Sphinx) | oui | non |
| Directives RST (`.. note::`) | oui | non |
| Cross-references (`:meth:`, `:class:`) | oui | non |
| NumPy underlines (`------`) | oui | non |
| Code snippets catégorisés | oui | non |

## Architecture

Un seul fichier source : `lua/docstring-highlight/init.lua`

Le plugin fonctionne en 3 étapes :
1. **Détection** — Treesitter localise les docstrings (premier `string_content` dans le body d'une function/class/module)
2. **Analyse** — Regex (Lua patterns + `vim.regex`) identifient les éléments dans chaque ligne de docstring
3. **Rendu** — Extmarks avec highlight groups appliqués via `nvim_buf_set_extmark`

### Flux de données

```
FileType python → attach(buf) → nvim_buf_attach (on_lines)
                                      ↓
                              schedule(buf) [debounce 150ms]
                                      ↓
                              refresh(buf)
                                ├── treesitter parse → iter docstring nodes
                                └── pour chaque ligne → highlight_line()
                                      ├── section_re     → DocstringSection
                                      ├── param + type   → DocstringParam + DocstringType
                                      ├── param sans type → DocstringParam
                                      └── inline code    → DocstringInlineCode
```

### Namespace & augroup

- Namespace extmarks : `docstring_highlight`
- Augroup : `DocstringHighlight`

## Éléments détectés (Google style)

| Élément | Pattern | Highlight group | Exemple |
|---|---|---|---|
| Section header | `vim.regex` very magic, mots-clés en début de ligne | `DocstringSection` | `Args:`, `Returns:`, `Raises:` |
| Param + type | `^%s%s+%w+%s*%b()%s*:` (Lua pattern) | `DocstringParam` + `DocstringType` | `name (str):` |
| Param sans type | `^%s%s%s%s+%w+%s*:` (indent ≥ 4) | `DocstringParam` | `name:` |
| Inline code | `` `text` `` | `DocstringInlineCode` | `` `value` `` |

### Mots-clés de section reconnus

Args, Arguments, Attributes, Deprecated, Example(s), Keyword Args/Arguments,
Methods, Note(s), Other Parameters, Parameters, Params, Raise(s), Reference(s),
Return(s), See Also, Todo, Warn(s), Warning(s), Yield(s)

## API publique

```lua
require("docstring-highlight").setup(opts?)
```

### Config (`DocstringHighlightConfig`)

| Champ | Type | Défaut | Description |
|---|---|---|---|
| `hl` | `table<string, vim.api.keyset.highlight>` | `{}` | Override des highlight groups par nom |
| `debounce` | `number` | `150` | Délai debounce en ms |
| `priority` | `number` | `200` | Priorité des extmarks (treesitter = 100) |

### Highlight groups

| Groupe | Lié à | Rôle |
|---|---|---|
| `DocstringSection` | `@markup.heading` | En-têtes de section |
| `DocstringParam` | `@variable.parameter` | Noms de paramètres |
| `DocstringType` | `@type` | Types entre parenthèses |
| `DocstringInlineCode` | `@markup.raw` | Code inline entre backticks |

Les groupes sont liés par défaut aux groupes treesitter standards (via `default = true`). L'utilisateur peut les overrider via l'option `hl` ou en définissant les groupes dans son colorscheme.

## Intégration

Chargé via lazy.nvim depuis la config Neovim (`~/.config/nvim/lua/plugins/docstring-highlight.lua`) :

```lua
return {
    dir = vim.fn.stdpath("config") .. "/plugins/docstring-highlight.nvim",
    ft = "python",
    opts = {},
}
```

## Dépendances

- Neovim ≥ 0.10 (pour `vim.treesitter.query.parse`, `vim.api.nvim_get_hl`)
- Treesitter parser `python` installé (`:TSInstall python`)
- Aucune dépendance plugin externe

## Treesitter query

La query cible uniquement les vrais docstrings (pas les strings arbitraires) :
- Premier `expression_statement > string > string_content` dans `function_definition.body`
- Premier `expression_statement > string > string_content` dans `class_definition.body`
- Premier `expression_statement > string > string_content` au niveau `module`

L'ancre `.` (dot) dans la query garantit que seul le PREMIER statement du block est capturé.

## Documentation de référence

- `doc/vscode-reference.md` — Analyse complète du plugin VSCode [python-docstring-highlighter](https://github.com/rodolphebarbanneau/python-docstring-highlighter) : tous les éléments détectés, regex exactes, scopes TextMate, exemples, et mapping vers nos highlight groups.

## Pistes d'évolution

- Support NumPy style (`name : type` avec underlines `------`)
- Support Sphinx/RST (`:param name:`, `:type:`, `.. directive::`)
- Injection RST via treesitter (parseur `rst` déjà disponible, mais problèmes d'indentation connus)
- `tree-sitter-python-docstring` (parseur Google style dédié, mais v0.0.1 immature en mars 2025)
- Rendu des cross-references (`:class:`, `:func:`, `:meth:`)
- Commande toggle pour activer/désactiver par buffer
- Support d'autres langages (Lua docstrings `---`, JSDoc `/** */`)

## Test manuel

```bash
nvim --headless /tmp/test.py -c "lua vim.defer_fn(function()
  local ns = vim.api.nvim_get_namespaces()['docstring_highlight']
  local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
  print('Extmarks: ' .. #marks)
  for _, m in ipairs(marks) do
    local line = vim.api.nvim_buf_get_lines(0, m[2], m[2]+1, false)[1]
    print(('  L%d [%s] = \"%s\"'):format(m[2]+1, m[4].hl_group, line:sub(m[3]+1, m[4].end_col)))
  end
  vim.cmd('qa')
end, 500)"
```
