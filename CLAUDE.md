# Overview

Neovim 0.11+ · lazy.nvim · blink.cmp · sonokai (custom) · AZERTY

Personal Neovim configuration. No build/test/lint commands — changes are validated by opening Neovim.

# Critical Conventions

## AZERTY Support
- `init.lua` monkey-patches `vim.keymap.set`: any keymap with `[]{}` is auto-duplicated with AZERTY equivalents (`ç`, `à`, `é`, `è`) in n/v/o modes
- Explicit recursive mappings in `mappings.lua`: `ç→[`, `à→]`, `é→{`, `è→}`
- `lua/utils.lua` → `keys_nb_map`: digit-to-symbol table (`1→&, 2→é, 3→", ...`) used by harpoon picker
- Terminal toggle: `<C-ù>` (snacks)

## Plugin Locations — READ CAREFULLY
- **Installed (lazy.nvim)**: `~/.local/share/nvim/lazy/` — **READ-ONLY, never write here**
- **Dev plugins**: `~/projects/nvim-plugins/` (configured in `lua/lazy-conf.lua` → `dev.path`) — **write only with explicit user permission**
- Dev-flagged repos: `NeOzay/lualine.nvim`, `NeOzay/nvim-cokeline`, `NeOzay/harpoon` (branch harpoon2), `folke/snacks.nvim`, `OXY2DEV/markview.nvim`
- Local plugins (dir explicit): `hover-translator`, `docstring-highlight.nvim`

## LSP Architecture (Neovim 0.11+ native API)
- Uses `vim.lsp.config()` / `vim.lsp.enable()` — **NOT** nvim-lspconfig `setup()`
- Server configs in `lua/lsp/servers/` loaded via global `pRequire()`
- Capabilities from `blink.cmp.get_lsp_capabilities()`
- Servers: lua_ls, basedpyright, jsonls (+ schemastore), ts_ls

## Global Helpers (init.lua)
- `pRequire(mod)` — Protected require, returns nil on failure
- `Userautocmd(event, opts)` — Creates autocmd in group `UserAutocmds`

# Startup Sequence

`init.lua` controls the load order:
1. Global helpers (`pRequire`, `Userautocmd`)
2. AZERTY wrapper on `vim.keymap.set`
3. lazy.nvim bootstrap + `require("lazy").setup(...)` with all plugin imports
4. Theme highlights (`require("base46.load").apply()`)
5. `options`, `autocmds`, `cmd`
6. `vim.schedule`: `mappings`, `highlights` (deferred)

All plugin specs are explicitly imported in `init.lua` — not auto-discovered from the `plugins/` directory.

# Highlight System (3 layers)

> Full documentation: [`docs/plugins/theme-highlights.md`](docs/plugins/theme-highlights.md)

Applied in this order (last wins):
1. **Integration defaults** (`lua/base46/integrations/`) — base highlights for editor, syntax, treesitter, LSP, git.
2. **Theme polish** (`lua/themes/sonokai.lua` → `polish_hl`) — sonokai-specific overrides per category.
3. **Chadrc overrides** (`lua/chadrc.lua` → `hl_add` / `hl_override`) — base46 syntax: `{ "blue", -20 }` (lightness), `{ "red", "line", 80 }` (mix).
4. **Per-plugin highlights** (`lua/highlights/<plugin>.lua`) — each returns a **function**, loaded dynamically on `VeryLazy`/`LazyLoad`/`BufWritePost` (hot-reload).

Color mixing system (`lua/base46/init.lua` → `turn_str_to_color`): resolves palette names, lightness tuples, and mix tuples to hex values.

Color utilities: `lua/colors_bank.lua` (`hi_pathwork`, `mix_colors_group`, `bank`).

Palette: Red `#fc5d7c` · Green `#9ed072` · Yellow `#e7c664` · Cyan `#76cce0` · Purple `#b39df3` · Orange `#f39660` · Grey `#7f8490`

# Plugin Index

Detailed documentation for each plugin lives in `docs/plugins/<name>.md`.
When working on a plugin, **read its doc first** and **update it with any discoveries**.

| Plugin | Config file | Notes |
|---|---|---|
| blink.cmp | `plugins/blink-cmp.lua` | Completion + copilot + ghost text |
| cokeline | `plugins/cokeline.lua` | Fork NeOzay, harpoon-integrated bufferline |
| codediff | `plugins/codediff.lua` | Replaces diffview |
| dap | `plugins/dap.lua` | + dap-ui, OSV; shared state in shared_data.lua |
| gitsigns | `plugins/gitsigns.lua` | |
| harpoon | `plugins/harpoon.lua` | Fork NeOzay, branch harpoon2 |
| lualine | `plugins/lualine.lua` + `lualine-conf.lua` | Fork NeOzay, per-window statusline |
| snacks | `plugins/snacks/` | Terminal, scratch, picker, explorer, notifier |
| statuscol | `plugins/statuscol/` | Modular: segments, DAP handler, folds |
| telescope | `plugins/telescope.lua` + `pickers/` | Custom pickers: harpoon, jumplist |
| ufo | `plugins/ufo/` | Modular: handler, render, actions |
| claudecode | `plugins/claudecode.lua` | Claude Code integration |
| codecompanion | `plugins/codecompanion.lua` | AI chat (copilot adapter) |
| conform | `plugins/conform.lua` | Code formatting (ruff for Python) |
| treesitter | `plugins/treesitter.lua` | + context, textobjects (separate specs) |
| trouble | `plugins/trouble.lua` | Diagnostics list |
| neogit | `plugins/neogit.lua` | Magit-style git UI |
| markview | `plugins/markview.lua` | Markdown rendering |
| copilot | `plugins/copilot.lua` | GitHub Copilot |
| hover-translator | `plugins/hover-translator.lua` | Local dev plugin, FR translation |
| docstring-highlight | `plugins/docstring-highlight.lua` | Local dev plugin, Python docstrings |

Also loaded: aerial, auto-pairs, fidget, hover, illuminate, indent-blankline, lsp-endhints, navic, persistence, satellite, schemastore, which-key, wezterm-types, vim-suda.

Disabled: neo-tree (replaced by snacks explorer), avante, copilot-chat (replaced by codecompanion).

# Documentation Maintenance

Each `docs/plugins/<name>.md` follows this template:


```markdown
# <Plugin Name>

## Role
One-line description.

## Files
- Config: `lua/plugins/<file>.lua`
- Highlights: `lua/highlights/<file>.lua` (if any)
- Related: (other files)

## Key Behaviors
- Notable config choices, non-obvious defaults, interactions with other plugins.

## Keymaps
- Only custom/non-default keymaps.

## Gotchas
- Known quirks, workarounds, things that broke before.

## Changelog
- Date: brief note of what changed and why.
```

**Rule**: When Claude works on a plugin and discovers something non-obvious (a quirk, a workaround, an interaction), it updates the plugin's doc file. If the file doesn't exist yet, create it from the template.
