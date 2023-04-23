-- luasnip setup
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'
-- 
lspkind.init(
  {
    symbol_map = {
      Interface = "",
      TypeParameter = "",
      Snippet = "",
      Unit = "",
      Class = "󰠱",
      Field = "󰜢",
      Property = "󰜢"
    }
  }
)

-- nvim-cmp setup
local cmp = require 'cmp'
---@type cmp.ConfigSchema
local config = {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping(function ()
      if not cmp.visible()  then
        cmp.complete()
      else
        cmp.close()
      end
    end
    ),
    ['<CR>'] = cmp.mapping(function (fallback)
      if cmp.get_selected_entry() then
        cmp.confirm {}
      else
        cmp.close()
        fallback()
      end
    end, {"i", "s"}),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),

  sources = {
    { name = 'nvim_lsp', keyword_length = 1, trigger_characters = {".", "@", ":"}},
    { name = 'luasnip', keyword_length = 1 },
    {
      name = 'buffer', keyword_length = 3, max_item_count = 10,
      option = {
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end
      }
    },
    { name = 'async_path', keyword_length = 1, trigger_characters = {"/", "~"} }
  },
  view = {
    entries = { name = 'custom', selection_order = 'near_cursor' }
  },
  window = {
    completion = {
      winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
      col_offset = -3,
      side_padding = 0,
    },
  },
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format =
      function(entry, vim_item)
      local kind = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
      local strings = vim.split(kind.kind, "%s", { trimempty = true })
      kind.kind = " " .. strings[1] .. " "
      kind.menu = "(" .. strings[2] .. ")"

      return kind
    end,
  }
}

cmp.setup(config)
return cmp
