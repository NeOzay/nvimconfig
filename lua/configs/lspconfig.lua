local M = {}
local map = vim.keymap.set

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")
end

-- disable semanticTokens
M.on_init = function(client, _)
  if vim.fn.has "nvim-0.11" ~= 1 then
    if client.supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    if client:supports_method "textDocument/semanticTokens" then
      -- client.server_capabilities.semanticTokensProvider = nil
    end
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

M.defaults = function()
  dofile(vim.g.base46_cache .. "lsp")
  require("nvchad.lsp").diagnostic_config()

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)
    end,
  })

  local lua_lsp_settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }

  -- Use new vim.lsp.config API for Neovim 0.11+
  vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
  vim.lsp.config("emmylua_ls", { settings = lua_lsp_settings })
  vim.lsp.enable "emmylua_ls"
end

M.defaults()

-- Python: Détection automatique de l'environnement virtuel (Poetry, venv, etc.)
local function get_python_path()
  local cwd = vim.fn.getcwd()

  -- 1. Essayer Poetry
  local poetry_env = vim.fn.system("cd " .. cwd .. " && poetry env info --path 2>/dev/null")
  if vim.v.shell_error == 0 and poetry_env ~= "" then
    poetry_env = vim.trim(poetry_env)
    local poetry_python = poetry_env .. "/bin/python"
    if vim.fn.executable(poetry_python) == 1 then
      return poetry_python
    end
  end

  -- 2. Essayer .venv local
  local venv_python = cwd .. "/.venv/bin/python"
  if vim.fn.executable(venv_python) == 1 then
    return venv_python
  end

  -- 3. Essayer venv local
  local venv_alt = cwd .. "/venv/bin/python"
  if vim.fn.executable(venv_alt) == 1 then
    return venv_alt
  end

  -- 4. Utiliser python système
  return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

-- Python LSP configuration
local basedpyright_settings = {
  basedpyright = {
    analysis = {
      typeCheckingMode = "standard", -- "off", "basic", "standard", "strict"
      autoSearchPaths = true,
      useLibraryCodeForTypes = true,
      diagnosticMode = "openFilesOnly", -- "workspace" ou "openFilesOnly"
      autoImportCompletions = true,
      extraPaths = {},
    },
  },
  python = {
    pythonPath = get_python_path(),
  },
}

vim.lsp.config("basedpyright", { settings = basedpyright_settings })

local servers = { "basedpyright" }
vim.lsp.enable(servers)

-- Commande pour afficher le chemin Python détecté
vim.api.nvim_create_user_command("PyPath", function()
  local python_path = get_python_path()
  vim.notify("Python path: " .. python_path, vim.log.levels.INFO)
end, { desc = "Afficher le chemin Python utilisé par basedpyright" })

-- Commande pour recharger le LSP Python (utile si vous changez d'environnement)
vim.api.nvim_create_user_command("PyReload", function()
  vim.cmd("LspRestart basedpyright")
  vim.notify("Basedpyright redémarré avec: " .. get_python_path(), vim.log.levels.INFO)
end, { desc = "Redémarrer basedpyright avec le bon environnement" })

-- read :h vim.lsp.config for changing options of lsp servers 
