local M = {}

function M.check()
  vim.health.start("hover-translator")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim version >= 0.9")
  else
    vim.health.error("Neovim 0.9+ required")
  end

  -- Check plenary.nvim
  local has_plenary, _ = pcall(require, "plenary")
  if has_plenary then
    vim.health.ok("plenary.nvim is installed")
  else
    vim.health.error("plenary.nvim is not installed", {
      "Install plenary.nvim: https://github.com/nvim-lua/plenary.nvim",
    })
  end

  -- Check plenary.curl
  local has_curl, _ = pcall(require, "plenary.curl")
  if has_curl then
    vim.health.ok("plenary.curl is available")
  else
    vim.health.error("plenary.curl is not available", {
      "plenary.curl requires curl to be installed on your system",
    })
  end

  -- Check system curl
  local curl_installed = vim.fn.executable("curl") == 1
  if curl_installed then
    vim.health.ok("curl is installed")
  else
    vim.health.error("curl is not installed", {
      "Install curl using your package manager",
    })
  end

  -- Check LSP clients
  local clients = vim.lsp.get_clients()
  if #clients > 0 then
    local client_names = {}
    for _, client in ipairs(clients) do
      table.insert(client_names, client.name)
    end
    vim.health.ok("LSP clients active: " .. table.concat(client_names, ", "))
  else
    vim.health.warn("No LSP clients active", {
      "hover-translator requires an active LSP client to get hover information",
    })
  end

  -- Check configuration
  local config = require("hover-translator.config").get()
  vim.health.info("Current configuration:")
  vim.health.info("  translator: " .. config.translator)
  vim.health.info("  target_lang: " .. config.target_lang)
  vim.health.info("  cache.enabled: " .. tostring(config.cache.enabled))
  vim.health.info("  cache.ttl: " .. config.cache.ttl .. "s")

  -- Check registered translators
  local translators = require("hover-translator.translators")
  local translator_list = translators.list()
  if #translator_list > 0 then
    vim.health.ok("Registered translators: " .. table.concat(translator_list, ", "))
  else
    vim.health.error("No translators registered")
  end

  -- Check configured translator exists
  local configured_translator = translators.get(config.translator)
  if configured_translator then
    vim.health.ok("Configured translator '" .. config.translator .. "' is available")
  else
    vim.health.error("Configured translator '" .. config.translator .. "' is not registered")
  end

  -- Check registered parsers
  local parsers = require("hover-translator.parsers")
  local parser_list = parsers.list()
  if #parser_list > 0 then
    vim.health.ok("Registered parsers: " .. table.concat(parser_list, ", "))
  else
    vim.health.warn("No parsers registered")
  end

  -- Cache statistics
  local cache = require("hover-translator.cache")
  local stats = cache.stats()
  vim.health.info("Cache entries: " .. stats.entries .. " (expired: " .. stats.expired .. ")")
end

return M
