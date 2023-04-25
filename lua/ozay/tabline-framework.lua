local colors = require "tokyonight.colors".setup()
local cutil = require "tokyonight.util"

local errors_fg = Highlights['DiagnosticError'].fg
local warnings_fg = Highlights['DiagnosticWarn'].fg
---@param f TablineFramework.renderTable
local function render(f)
  f.make_bufs(function(info)
    f.add_btn("x ", function(f)
      print("click")
    end)
    f.add("")
    local icon, iconhl = f.icon(info.filename), f.icon_color(info.filename)
    if icon then
      f.add { icon .. " ", fg = info.current and iconhl or nil }
    end
    f.add(info.buf_nr)
    local filename = vim.fn.fnamemodify(info.filename, ":r")
    local style = {}
    local errors = #vim.diagnostic.get(info.buf, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(info.buf, { severity = vim.diagnostic.severity.WARN })
    if info.modified then
      style["italic"] = true
    end
    if info.current then
      style["bold"] = true
    end
    local fg = ((errors ~= 0 and errors_fg) or (warnings ~= 0 and warnings_fg) or nil)
    --f.set_gui(table.concat(style, ","))
    f.add { filename or '[no name]', fg = fg, gui = style }
    f.add ' '
  end)
end
require('tabline_framework').setup {
  render = render,
  hl = { fg = Highlights["Comment"].fg, bg = colors.bg_dark },
  hl_sel = { fg = Highlights["Normal"].fg, bg = cutil.darken(colors.dark3, 0.5) },
  --hl_fill = { fg = '#ffffff', bg = '#000000'},
  buflist_size = 10,
  tablist_size = 10,
  min = 5,
  max = 10
}


