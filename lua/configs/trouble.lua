-- Configuration pour trouble.nvim
-- Liste améliorée des diagnostics, quickfix, etc.

return {
  modes = {
    -- Mode diagnostics personnalisé
    diagnostics = {
      mode = "diagnostics",
      preview = {
        type = "split",
        relative = "win",
        position = "right",
        size = 0.4,
      },
    },
  },

  -- Icônes personnalisées
  icons = {
    indent = {
      top = "│ ",
      middle = "├╴",
      last = "└╴",
      fold_open = " ",
      fold_closed = " ",
      ws = "  ",
    },
    folder_closed = " ",
    folder_open = " ",
    kinds = {
      Array = " ",
      Boolean = "󰨙 ",
      Class = " ",
      Constant = "󰏿 ",
      Constructor = " ",
      Enum = " ",
      EnumMember = " ",
      Event = " ",
      Field = " ",
      File = " ",
      Function = "󰊕 ",
      Interface = " ",
      Key = " ",
      Method = "󰊕 ",
      Module = " ",
      Namespace = "󰦮 ",
      Null = " ",
      Number = "󰎠 ",
      Object = " ",
      Operator = " ",
      Package = " ",
      Property = " ",
      String = " ",
      Struct = "󰆼 ",
      TypeParameter = " ",
      Variable = "󰀫 ",
    },
  },

  -- Couleurs intégrées avec thème Sonokai
  -- Les highlights seront définis dans le thème via polish_hl

  -- Options d'affichage
  auto_close = false, -- Ne pas fermer automatiquement
  auto_open = false, -- Ne pas ouvrir automatiquement
  auto_preview = true, -- Aperçu automatique
  auto_refresh = true, -- Rafraîchir automatiquement
  auto_jump = false, -- Ne pas sauter automatiquement
  focus = true, -- Focus sur la fenêtre trouble au toggle
  restore = true, -- Restaurer la dernière position
  follow = true, -- Suivre le curseur
  indent_guides = true, -- Guides d'indentation
  max_items = 200, -- Nombre max d'items
  multiline = true, -- Support multiligne
  pinned = false, -- Ne pas épingler par défaut

  -- Configuration de la fenêtre
  win = {
    position = "bottom",
    size = {
      height = 10,
    },
  },

  -- Preview window
  preview = {
    type = "main",
    scratch = true,
  },

  -- Filtres par défaut
  filter = {
    -- Exclure certains messages
    ["not"] = {
      severity = vim.diagnostic.severity.HINT,
    },
  },
}
