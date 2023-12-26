require'cokeline'

local get_hex = require('cokeline.hlgroups').get_hl_attr
local buffers = require('cokeline.buffers')
local state = require('cokeline.state')
local keymap = require("cokeline.mappings")
local util = require'ozay.util'

local green = vim.g.terminal_color_2
local yellow = vim.g.terminal_color_3
local red = vim.g.terminal_color_1

local api = vim.api

_G.cokeline.tab_group = _G.cokeline.tab_group or {}
local tab_group = _G.cokeline.tab_group

local empty_buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_option_value("modifiable", false, {buf = empty_buffer})
local old_get_valid_buffers = buffers.get_valid_buffers
---@return Buffer[]
---@diagnostic disable-next-line
buffers.get_valid_buffers = function ()
  local b = old_get_valid_buffers()
  if #b == 0 then
    local info = vim.fn.getbufinfo(empty_buffer)
    if  info then
      b[1] = buffers.Buffer.new(info[1])
    end
  end
  return b
end

api.nvim_create_autocmd('BufEnter', {
  callback = function()
    local bindex = api.nvim_get_current_buf()
    local current_tab = api.nvim_get_current_tabpage()
    local t = tab_group[current_tab] or {}
    t[bindex] = true
    tab_group[current_tab] = t
  end,
  group = api.nvim_create_augroup("cokevimOzay", {clear = true})
})

require('cokeline').setup({
  show_if_buffers_are_at_least = -1,
  buffers = {
    filter_valid = function(buffer)
      local t = api.nvim_get_current_tabpage()
      return tab_group[t] and tab_group[t][buffer.number]
    end,
    new_buffers_position = "directory"
  },
  default_hl = {
    fg = function(buffer)
      return
          buffer.is_focused
          and get_hex('Normal', 'fg')
          or get_hex('Comment', 'fg')
    end,
    bg = get_hex('ColorColumn', 'bg'),
  },

  components = {
    {
      text = '|',
      fg = function(buffer)
        if buffer.diagnostics and buffer.diagnostics.errors > 0 then
          return red
        end
        return buffer.is_modified and yellow or green
      end
    },
    {
      text = function(buffer) return buffer.unique_prefix end,
      fg = get_hex('Comment', 'fg'),
      italic = true,
    },
    {
      text = function(buffer) return vim.fn.fnamemodify(buffer.filename, ":r") .. ' ' end,
      bold = function(buffer) return buffer.is_focused end,
    },
    {
      text = function(buffer) return buffer.devicon.icon end,
      fg = function(buffer) return buffer.devicon.color end,
    },
  },
  tabs = {
    placement = "left",
    components = {
      {
        text = function(tab)
          return tab.number
        end,
        fg = function(tab)
          return tab.is_active and get_hex("Normal", "fg") or get_hex("Comment", "fg")
        end,
        on_click = function(idx, clicks, buttons, modifiers, buffer)
          vim.cmd.tabnext()
        end
      }
    }
  },
})


util.nnoremap("<leader>n", ":tabnext<cr>", "next tab")
util.nnoremap("<leader>p", ":tabNext<cr>", "previous tab")
util.nnoremap("<Tab>", "<Plug>(cokeline-focus-next)")
util.nnoremap('<S-Tab>', '<Plug>(cokeline-focus-prev)')

util.nnoremap("<leader>q", function ()
  local b = tab_group[api.nvim_get_current_tabpage()]
  if b then
    b[api.nvim_get_current_buf()] = nil
    if #state.visible_buffers == 1 then
      api.nvim_set_current_buf(empty_buffer)
    else
      keymap.by_step("focus", 1)
    end
  end
  vim.cmd.redrawtabline()
end)

util.nnoremap("<leader><Up>", function ()
  local current_tab = api.nvim_get_current_tabpage()
  local current_buf = api.nvim_get_current_buf()
  local t = tab_group[current_tab]
  local t2 = tab_group[current_tab + 1]
  if t and t[current_buf] and t2 then
    t[current_buf] = nil
    t2[current_buf] = true
    if #state.visible_buffers == 1 then
      api.nvim_set_current_buf(empty_buffer)
    else
      keymap.by_step("focus", 1)
    end
    api.nvim_set_current_tabpage(current_tab + 1)
    api.nvim_set_current_buf(current_buf)
  end
  vim.cmd.redrawtabline()
end)

util.nnoremap("<leader><Down>", function ()
  local current_tab = api.nvim_get_current_tabpage()
  local current_buf = api.nvim_get_current_buf()
  local t = tab_group[current_tab]
  local t2 = tab_group[current_tab - 1]
  if t and t[current_buf] and t2 then
    t[current_buf] = nil
    t2[current_buf] = true
    if #state.visible_buffers == 1 then
      api.nvim_set_current_buf(empty_buffer)
    else
      keymap.by_step("focus", 1)
    end
    api.nvim_set_current_tabpage(current_tab - 1)
    api.nvim_set_current_buf(current_buf)
  end
  vim.cmd.redrawtabline()
end)
