# Snacks Picker — Créer un picker custom

## Role

Guide pour créer des pickers Snacks personnalisés : API complète, structure des items, format, actions et keymaps.

## Files

- Config globale : `lua/plugins/snacks/picker.lua`
- Exemples : `lua/pickers/harpoon_snacks.lua`, `lua/plugins/snacks/scratch.lua`
- Source : `~/projects/nvim-plugins/snacks.nvim/lua/snacks/picker/`

---

## Anatomie d'un picker

```lua
Snacks.picker.pick({
    title   = "Mon Picker",
    finder  = function(opts, ctx) ... end,   -- source des items
    format  = function(item, picker) ... end, -- affichage d'une ligne
    confirm = function(picker, item) ... end, -- action <CR>
    actions = { name = function(picker, item) ... end },
    win = {
        input = { keys = { ... } },
        list  = { keys = { ... } },
    },
})
```

---

## Finder

Fonction qui retourne les items. Deux formes possibles :

### Synchrone (tableau)

```lua
finder = function(opts, ctx)
    local items = {}
    for _, v in ipairs(source) do
        table.insert(items, {
            text = v.name,      -- obligatoire : utilisé pour le matching fuzzy
            file = v.path,      -- optionnel : active le preview fichier
            pos  = { 1, 0 },   -- optionnel : position dans le fichier [ligne, col]
            -- champs custom libres :
            my_id = v.id,
        })
    end
    return ctx.filter:filter(items)  -- toujours appeler pour le fuzzy
end
```

### Asynchrone (callback)

```lua
finder = function(opts, ctx)
    return function(cb)  ---@async
        for _, v in ipairs(big_source) do
            cb({ text = v.name, file = v.path })
        end
    end
end
```

### Items statiques (sans finder)

```lua
Snacks.picker.pick({
    items = {
        { text = "foo", file = "/path/foo.lua" },
        { text = "bar", file = "/path/bar.lua" },
    },
})
```

---

## Structure d'un item

```lua
---@class snacks.picker.finder.Item
{
    -- Obligatoire
    text         = string,    -- texte pour le matching fuzzy

    -- Preview fichier (activer avec `file`)
    file         = string,    -- chemin absolu → active le previewer fichier
    pos          = {row, col},-- position dans le fichier (numéros 1-based)
    end_pos      = {row, col},-- position de fin (optionnel)

    -- Score / tri
    score_add    = number,    -- bonus de score (+valeur)
    score_mul    = number,    -- multiplicateur de score

    -- Preview inline (sans `file`)
    preview = {
        text = string,        -- texte brut à afficher
        ft   = string,        -- filetype pour la coloration
    },

    -- Champs custom
    [string]     = any,       -- n'importe quel champ additionnel
}
```

---

## Format

Fonction qui retourne un tableau de `snacks.picker.Highlight` (segments texte colorés) :

```lua
format = function(item, picker)
    return {
        { "texte",       "HighlightGroup" },  -- segment normal
        { "virtuel",     "Comment", virtual = true },  -- ne compte pas dans la largeur
        { item.my_field, "Special" },
    }
end
```

### Formatters built-in réutilisables

```lua
-- Fichier avec icône (chemin tronqué, couleur git status)
Snacks.picker.format.filename(item, picker)

-- Fichier complet (= filename + col/ligne + flags de buffer)
Snacks.picker.format.file(item, picker)

-- Texte brut avec coloration syntaxique
Snacks.picker.format.text(item, picker)

-- Sévérité de diagnostic (icône + couleur)
Snacks.picker.format.severity(item, picker)

-- Buffer (flags %, #, h, a, +)
Snacks.picker.format.buffer(item, picker)
```

### Preset format (string)

```lua
format = "file",    -- équivalent à Snacks.picker.format.file
format = "text",    -- équivalent à Snacks.picker.format.text
```

### Composer des formatters

```lua
format = function(item, picker)
    local ret = {}
    -- préfixe custom
    ret[#ret + 1] = { string.format("[%d] ", item.harpoon_idx), "Comment" }
    -- + formatter built-in
    vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
    return ret
end
```

---

## Actions

### `confirm` — action par défaut (`<CR>`)

```lua
confirm = function(picker, item)
    if not item then return end
    picker:close()
    -- ... faire quelque chose avec item
end,
```

### Actions nommées

```lua
actions = {
    my_delete = function(picker, item)
        if not item then return end
        -- modifier la source...
        picker:refresh()   -- re-run le finder
    end,
    my_split = function(picker, item)
        picker:close()
        vim.cmd("split " .. item.file)
    end,
},
```

### Spec d'action (formats acceptés)

```lua
-- string → nom d'une action built-in ou custom
"confirm"

-- fonction directe
function(picker, item) ... end

-- table avec mode
{ "action_name", mode = { "i", "n" } }

-- séquence d'actions
{ { "pick_win", "jump" } }
```

---

## Keymaps (`win.input.keys` / `win.list.keys`)

```lua
win = {
    input = {  -- fenêtre de saisie (insert + normal)
        keys = {
            ["<A-d>"] = { "my_delete", mode = { "i", "n" } },
            ["<C-x>"] = "my_split",
            ["<C-k>"] = false,   -- désactiver un keymap global
        },
    },
    list = {   -- fenêtre de liste (normal uniquement)
        keys = {
            ["dd"] = "my_delete",
            ["s"]  = "my_split",
            -- fonction inline (closure ok) :
            ["x"]  = function(picker)
                local item = picker:current()
                -- ...
            end,
        },
    },
},
```

### Touches globales par défaut (à connaître pour éviter les conflits)

| Touche | Action |
|--------|--------|
| `<CR>` | `confirm` |
| `<Esc>` | `cancel` |
| `<a-d>` | `inspect` ← **conflit fréquent** avec delete |
| `<a-p>` | `toggle_preview` |
| `<a-m>` | `toggle_maximize` |
| `<c-q>` | `qflist` |
| `<c-s>` | `edit_split` |
| `<c-v>` | `edit_vsplit` |
| `<c-t>` | `tab` |
| `<Tab>` | `select_and_next` |
| `<c-j/k>` | `list_down/up` |

---

## Méthodes du picker (`snacks.Picker`)

```lua
picker:close()            -- fermer le picker
picker:refresh()          -- re-run le finder (utile après mutation de source)
picker:current()          -- item sous le curseur (snacks.picker.Item)
picker:selected()         -- items sélectionnés (multi-select)
picker:items()            -- tous les items matchés
picker:count()            -- nombre d'items
picker:cwd()              -- répertoire courant du picker
picker:find(opts?)        -- re-run finder + matcher (opts: {refresh?, on_done?})
```

---

## Options `snacks.picker.Config` (sélection)

```lua
{
    title        = string,          -- titre de la fenêtre input
    prompt       = string,          -- icône/texte avant la saisie
    focus        = "input"|"list",  -- focus initial (défaut: "input")
    live         = boolean,         -- recherche en temps réel
    limit        = number,          -- stop finder après N items
    auto_confirm = boolean,         -- confirm auto si 1 seul item
    show_empty   = boolean,         -- ouvrir même si 0 items
    layout       = "telescope"|"default"|"vertical"|...,
    matcher = {
        fuzzy          = true,
        smartcase      = true,
        sort_empty     = false,     -- trier quand recherche vide
        filename_bonus = true,
    },
    sort = {
        fields = { "score:desc", "#text", "idx" },
    },
    on_change = function(picker, item) ... end,
    on_show   = function(picker) ... end,
    on_close  = function(picker) ... end,
}
```

---

## Exemple complet : `lua/pickers/harpoon_snacks.lua`

Picker pour lister les buffers harpoon avec :
- affichage `[n] icon fichier`
- suppression en place (`<A-d>` / `dd`) + refresh
- sélection directe par touches AZERTY 1-9

```lua
return function()
    local harpoon = require("harpoon")
    local utils   = require("utils")

    -- Construction dynamique des keymaps AZERTY
    local input_keys = { ["<A-d>"] = { "harpoon_delete", mode = { "i", "n" } } }
    local list_keys  = { ["dd"]    = "harpoon_delete" }
    for i = 1, 9 do
        local key = utils.key_nb_mapping(i)
        local idx = i  -- closure locale nécessaire
        list_keys[key]              = function(p) p:close(); harpoon:list():select(idx) end
        input_keys["<C-" .. key .. ">"] = function(p) p:close(); harpoon:list():select(idx) end
    end

    Snacks.picker.pick({
        title  = "Harpoon",
        finder = function(opts, ctx)
            local items = {}
            for idx, item in pairs(harpoon:list().items) do
                table.insert(items, {
                    text        = item.value,
                    file        = vim.fn.fnamemodify(item.value, ":p"),
                    pos         = { item.context and item.context.row or 1,
                                    item.context and item.context.col or 0 },
                    harpoon_idx = idx,
                })
            end
            table.sort(items, function(a, b) return a.harpoon_idx < b.harpoon_idx end)
            return ctx.filter:filter(items)
        end,
        format = function(item, picker)
            local ret = { { string.format("[%d] ", item.harpoon_idx), "Comment" } }
            vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
            return ret
        end,
        confirm = function(picker, item)
            if not item then return end
            picker:close()
            harpoon:list():select(item.harpoon_idx)
        end,
        actions = {
            harpoon_delete = function(picker, item)
                if not item then return end
                harpoon:list():remove_at(item.harpoon_idx)
                picker:refresh()
            end,
        },
        win = {
            input = { keys = input_keys },
            list  = { keys = list_keys },
        },
    })
end
```

## Gotchas

- **`<a-d>` est mappé à `inspect` par défaut** — utiliser `<A-d>` dans les opts suffit à le surcharger (normalisation de casse automatique).
- **`ctx.filter:filter(items)` est obligatoire** dans le finder synchrone pour que le fuzzy matching fonctionne.
- **`picker:refresh()`** re-run le finder complet — adapté aux sources mutables (harpoon, buffers). Ne pas utiliser `picker:find()` directement sans `{refresh=true}`.
- **Closures dans les keymaps** : en Lua, les boucles `for i` créent une nouvelle variable `i` à chaque itération — les closures capturent bien la bonne valeur. Inutile de faire `local idx = i` dans un `for` numérique, mais c'est une bonne habitude explicite.
- **Chemin absolu pour `file`** : utiliser `vim.fn.fnamemodify(path, ":p")` si le chemin est relatif, sinon le preview ne trouve pas le fichier.

## Changelog

- 2026-03-27 : création du guide, basé sur l'implémentation du picker harpoon snacks.
