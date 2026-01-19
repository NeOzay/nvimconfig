-- Configuration nvim-cmp désactivée - migration vers blink.cmp
local function map_down(fallback)
  local cmp = require("cmp")
  if cmp.visible() then
    cmp.select_next_item()
  elseif require("luasnip").expand_or_jumpable() then
    require("luasnip").expand_or_jump()
  else
    fallback()
  end
end

local function map_up(fallback)
  local cmp = require("cmp")
  if cmp.visible() then
    cmp.select_prev_item()
  elseif require("luasnip").jumpable(-1) then
    require("luasnip").jump(-1)
  else
    fallback()
  end
end

local function opts(_, opts)
  opts.sources = opts.sources or {}
  table.insert(opts.sources, {
    name = "lazydev",
    group_index = 0,
  })
  table.insert(opts.sources, {
    name = "copilot",
    group_index = 2,
  })

  local cmp = require("cmp")
  opts.mapping = opts.mapping or {}
  opts.mapping["<Down>"] = cmp.mapping(map_down, { "i", "s" })
  opts.mapping["<Up>"] = cmp.mapping(map_up, { "i", "s" })
end
---@type LazySpec
return {
  "hrsh7th/nvim-cmp",
  enabled = false,
  opts = opts,
}
