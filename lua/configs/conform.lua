local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format", "ruff_organize_imports" },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },

  -- Configuration pour ruff
  formatters = {
    ruff_format = {
      command = "ruff",
      args = { "format", "--stdin-filename", "$FILENAME", "-" },
    },
    ruff_organize_imports = {
      command = "ruff",
      args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
    },
  },
}

return options
