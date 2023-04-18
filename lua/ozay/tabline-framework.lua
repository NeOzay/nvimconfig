local colors = require "tokyonight.colors".setup()
local highlights = require "ozay.tokyonight"
local cutil = require "tokyonight.util"

local errors_fg = highlights['DiagnosticError'].fg
local warnings_fg = highlights['DiagnosticWarn'].fg
local function render(f)
  f.make_tabs(function(info)
    f.add(" ")
    local icon, iconhl = f.icon(info.filename), f.icon_color(info.filename)
    if icon then
      f.add { icon .. " ", fg = info.current and iconhl or nil }
    end
    local filename = vim.fn.fnamemodify(info.filename, ":r")
    local style = {}
    local errors = #vim.diagnostic.get(info.buf, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(info.buf, { severity = vim.diagnostic.severity.WARN })
    if info.modified then
      table.insert(style, "italic")
    end
    if info.current then
      table.insert(style, "bold")
    end
    local fg = ((errors ~= 0 and errors_fg) or (warnings ~= 0 and warnings_fg) or nil)
    --f.set_gui(table.concat(style, ","))
    f.add { filename or '[no name]', fg = fg, gui = table.concat(style, ",") }
    f.add ' '
  end)
end
require('tabline_framework').setup {
  render = render,
  hl = { fg = highlights["Comment"].fg, bg = colors.bg_dark },
  hl_sel = { fg = highlights["Normal"].fg, bg = cutil.darken(colors.dark3, 0.5) },
  --hl_fill = { fg = '#ffffff', bg = '#000000'},
}
