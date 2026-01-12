-- Credits to original https://github.com/sainnhe/sonokai
-- Sonokai color scheme for NvChad (Default variant)
local M = {}

M.base_30 = {
  white = "#e2e2e3",
  darker_black = "#181819", -- activityBar.background
  black = "#2c2e34",        -- editor.background
  black2 = "#30323a",       -- panel.background / hoverWidget
  one_bg = "#222327",       -- sideBar.background
  one_bg2 = "#363944",      -- selection/hover
  one_bg3 = "#3b3e48",      -- selection stronger
  grey = "#595f6f",
  grey_fg = "#7f8490",      -- editorLineNumber.foreground
  grey_fg2 = "#8a8f9a",
  light_grey = "#969ba5",
  red = "#fc5d7c",
  baby_pink = "#ff7a9a",
  pink = "#ff6077",
  line = "#414550",          -- editorIndentGuide.activeBackground
  green = "#9ed072",
  vibrant_green = "#a7df78", -- badge.background / progressBar
  nord_blue = "#85d3f2",     -- activityBarBadge.background
  blue = "#76cce0",
  yellow = "#e7c664",
  sun = "#edd691",
  purple = "#b39df3",
  dark_purple = "#a088d9",
  teal = "#69b5c7",
  orange = "#f39660",
  cyan = "#76cce0",
  statusline_bg = "#222327", -- statusBar.background
  lightbg = "#363944",
  pmenu_bg = "#9ed072",      -- editorSuggestWidget.highlightForeground
  folder_bg = "#76cce0",
}

local base_30 = M.base_30

M.base_16 = {
  base00 = "#2c2e34",
  base01 = "#33353f",
  base02 = "#363944",
  base03 = "#3b3e48",
  base04 = "#7f8490",
  base05 = "#e2e2e3",
  base06 = "#e8e8e9",
  base07 = "#eeeeef",
  base08 = "#fc5d7c",
  base09 = "#b39df3",
  base0A = "#e7c664",
  base0B = "#9ed072",
  base0C = "#76cce0",
  base0D = "#9ed072",
  base0E = "#fc5d7c",
  base0F = "#b39df3",
}

M.type = "dark"

M = require("base46").override_theme(M, "sonokai")

M.polish_hl = {
  treesitter = {
    -- Variables
    ["@variable"] = { fg = M.base_30.white },
    ["@variable.member"] = { fg = M.base_30.white },
    ["@variable.builtin"] = { fg = M.base_30.orange, italic = true },
    ["@variable.parameter"] = { fg = M.base_30.white },

    -- Functions
    ["@function"] = { fg = M.base_30.green },
    ["@function.call"] = { fg = M.base_30.green },
    ["@function.builtin"] = { fg = M.base_30.green },
    ["@function.method"] = { fg = M.base_30.green },
    ["@function.method.call"] = { fg = M.base_30.green },

    -- Operators & Punctuation
    ["@operator"] = { fg = M.base_30.red },
    ["@punctuation.bracket"] = { fg = M.base_30.grey_fg },
    ["@punctuation.delimiter"] = { fg = M.base_30.grey_fg2 },
    ["@punctuation.special"] = { fg = M.base_30.red },

    -- Keywords
    ["@keyword"] = { fg = M.base_30.red, italic = true },
    ["@keyword.function"] = { fg = M.base_30.red },
    ["@keyword.return"] = { fg = M.base_30.red, italic = true },
    ["@keyword.operator"] = { fg = M.base_30.red },
    ["@keyword.conditional"] = { fg = M.base_30.red },
    ["@keyword.repeat"] = { fg = M.base_30.red },

    -- Types & Constants
    ["@type"] = { fg = M.base_30.cyan },
    ["@type.builtin"] = { fg = M.base_30.cyan, italic = true },
    ["@type.qualifier"] = { fg = M.base_30.red },
    ["@constant"] = { fg = M.base_30.purple },
    ["@constant.builtin"] = { fg = M.base_30.purple },
    ["@constant.macro"] = { fg = M.base_30.purple },

    -- Strings & Numbers
    ["@string"] = { fg = M.base_30.yellow },
    ["@string.escape"] = { fg = M.base_30.purple },
    ["@string.regex"] = { fg = M.base_30.yellow },
    ["@number"] = { fg = M.base_30.purple },
    ["@boolean"] = { fg = M.base_30.purple },

    -- Tags (HTML/JSX)
    ["@tag"] = { fg = M.base_30.red },
    ["@tag.attribute"] = { fg = M.base_30.cyan, italic = true },
    ["@tag.delimiter"] = { fg = M.base_30.grey_fg },

    -- Properties & Attributes
    ["@property"] = { fg = M.base_30.white },
    ["@attribute"] = { fg = M.base_30.cyan, italic = true },

    -- Comments
    ["@comment"] = { fg = M.base_30.grey, italic = true },
    ["@comment.todo"] = { fg = M.base_30.black, bg = M.base_30.yellow, bold = true },
    ["@comment.warning"] = { fg = M.base_30.black, bg = M.base_30.orange, bold = true },
    ["@comment.note"] = { fg = M.base_30.black, bg = M.base_30.blue, bold = true },
    ["@comment.danger"] = { fg = M.base_30.black, bg = M.base_30.red, bold = true },
    ["@comment.error"] = { fg = M.base_30.black, bg = M.base_30.red, bold = true },

    -- Markup (Markdown)
    ["@markup.heading"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.1"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.2"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.3"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.4"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.5"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.heading.6"] = { fg = M.base_30.yellow, bold = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.link"] = { fg = M.base_30.green, underline = true },
    ["@markup.link.url"] = { fg = M.base_30.green, underline = true },
    ["@markup.raw"] = { fg = M.base_30.yellow },
    ["@markup.list"] = { fg = M.base_30.red },
    ["@markup.list.checked"] = { fg = M.base_30.green },
    ["@markup.list.unchecked"] = { fg = M.base_30.grey_fg },

    -- Diff
    ["@diff.plus"] = { fg = M.base_30.green },
    ["@diff.minus"] = { fg = M.base_30.red },
    ["@diff.delta"] = { fg = M.base_30.blue },
  },

  lsp = {
    -- Semantic tokens
    ["@lsp.type.namespace"] = { fg = M.base_30.cyan },
    ["@lsp.type.class"] = { fg = M.base_30.cyan },
    ["@lsp.type.enum"] = { fg = M.base_30.cyan },
    ["@lsp.type.interface"] = { fg = M.base_30.cyan },
    ["@lsp.type.struct"] = { fg = M.base_30.cyan },
    ["@lsp.type.typeParameter"] = { fg = M.base_30.cyan },
    ["@lsp.type.parameter"] = { fg = M.base_30.white },
    ["@lsp.type.variable"] = { fg = M.base_30.white },
    ["@lsp.type.property"] = { fg = M.base_30.white },
    ["@lsp.type.enumMember"] = { fg = M.base_30.purple },
    ["@lsp.type.function"] = { fg = M.base_30.green },
    ["@lsp.type.method"] = { fg = M.base_30.green },
    ["@lsp.type.macro"] = { fg = M.base_30.purple },
    ["@lsp.type.decorator"] = { fg = M.base_30.cyan },
    ["@lsp.type.comment"] = { fg = M.base_30.grey_fg, italic = true },
  },

  syntax = {
    -- Basic syntax
    Comment = { fg = M.base_30.grey_fg, italic = true },
    Operator = { fg = M.base_30.red },
    String = { fg = M.base_30.yellow },
    Function = { fg = M.base_30.green },
    Keyword = { fg = M.base_30.red, italic = true },
    Type = { fg = M.base_30.cyan, italic = true },
    Constant = { fg = M.base_30.purple },
    Identifier = { fg = M.base_30.white },
    Special = { fg = M.base_30.purple },
    PreProc = { fg = M.base_30.red },
    Statement = { fg = M.base_30.red },

    -- Conditional & Repeat
    Conditional = { fg = M.base_30.red, italic = true },
    Repeat = { fg = M.base_30.red, italic = true },

    -- Special characters
    SpecialChar = { fg = M.base_30.purple },
    Delimiter = { fg = M.base_30.grey_fg },

    -- Errors & Warnings
    Error = { fg = M.base_30.red },
    Todo = { fg = M.base_30.black, bg = M.base_30.yellow, bold = true },
  },

  -- UI Highlights (based on VSCode Sonokai)
  defaults = {
    -- Editor
    CursorLine = { bg = "#30323a" },                            -- editor.lineHighlightBackground
    CursorLineNr = { fg = M.base_30.white },                    -- editorLineNumber.activeForeground
    LineNr = { fg = M.base_30.grey_fg, bg = M.base_30.one_bg }, -- editorLineNumber.foreground + darker gutterno
    SignColumn = { bg = M.base_30.one_bg },                     -- Gutter (Git signs, etc.)
    Visual = { bg = "#3b3e48" },                                -- editor.selectionBackground
    MatchParen = { bg = "#414550" },                            -- editorBracketMatch.background
    Search = { bg = "#fc5d7c", fg = "#2c2e34" },                -- editor.findMatchBackground
    IncSearch = { bg = "#b39df3", fg = "#2c2e34" },
    EndOfBuffer = { bg = M.base_30.one_bg },

    -- Diagnostics
    DiagnosticError = { fg = M.base_30.red },
    DiagnosticWarn = { fg = M.base_30.yellow },
    DiagnosticInfo = { fg = M.base_30.cyan },
    DiagnosticHint = { fg = M.base_30.green },

    -- Diagnostic signs in gutter
    DiagnosticSignError = { fg = M.base_30.red, bg = M.base_30.one_bg },
    DiagnosticSignWarn = { fg = M.base_30.yellow, bg = M.base_30.one_bg },
    DiagnosticSignInfo = { fg = M.base_30.cyan, bg = M.base_30.one_bg },
    DiagnosticSignHint = { fg = M.base_30.green, bg = M.base_30.one_bg },

    -- Diff
    DiffAdd = { bg = "#394634" },    -- diff_green
    DiffChange = { bg = "#354157" }, -- diff_blue
    DiffDelete = { bg = "#55393d" }, -- diff_red
    DiffText = { bg = "#354157" },

    -- Pmenu (popup menu)
    Pmenu = { bg = "#33363f", fg = M.base_30.white }, -- editorSuggestWidget
    PmenuSel = { bg = "#3b3e48", fg = M.base_30.white },
    PmenuSbar = { bg = "#33363f" },
    PmenuThumb = { bg = M.base_30.grey_fg },

    -- Statusline colors handled by base46 integrations
    -- Tabs colors handled by base46 integrations

    -- Folds
    Folded = { bg = "#30323a", fg = M.base_30.grey_fg },
    FoldColumn = { fg = M.base_30.grey_fg, bg = M.base_30.one_bg },

    -- Borders
    FloatBorder = { fg = "#414550" }, -- editorWidget.border
    NormalFloat = { bg = "#30323a" }, -- editorHoverWidget.background

    -- Links
    Underlined = { fg = M.base_30.green, underline = true },
  },

  telescope = {
    TelescopeSelection = { bg = "#3b3e48", fg = "None" },
    TelescopeMatching = { fg = base_30.green, bg = "None" }, -- highlightForeground
    TelescopeBorder = { fg = "#414550", bg = base_30.black },
    TelescopePromptBorder = { fg = "#414550", bg = base_30.black },
    TelescopeResultsBorder = { fg = "#414550", bg = base_30.black },
    TelescopePreviewBorder = { fg = "#414550", bg = base_30.black },
    TelescopePromptPrefix = { fg = base_30.green },
    TelescopeResultsTitle = { fg = base_30.blue, bg = base_30.black },
    TelescopeNormal = { fg = base_30.white, bg = base_30.black },
    TelescopePromptCounter = { fg = base_30.green },
  },

  cmp = {
    CmpItemAbbrMatch = { fg = M.base_30.green, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = M.base_30.green, bold = true },
    CmpItemKindFunction = { fg = M.base_30.green },
    CmpItemKindMethod = { fg = M.base_30.green },
    CmpItemKindClass = { fg = M.base_30.cyan },
    CmpItemKindStruct = { fg = M.base_30.cyan },
    CmpItemKindInterface = { fg = M.base_30.cyan },
    CmpItemKindVariable = { fg = M.base_30.white },
    CmpItemKindConstant = { fg = M.base_30.purple },
    CmpItemKindKeyword = { fg = M.base_30.red },
    CmpItemKindOperator = { fg = M.base_30.red },
    CmpItemKindSnippet = { fg = M.base_30.yellow },
    CmpItemKindText = { fg = M.base_30.white },
  },

  git = {
    -- Git signs in gutter
    GitSignsAdd = { fg = M.base_30.green, bg = M.base_30.one_bg },
    GitSignsChange = { fg = M.base_30.cyan, bg = M.base_30.one_bg },
    GitSignsDelete = { fg = M.base_30.red, bg = M.base_30.one_bg },

    -- Git diff colors (in buffer)
    DiffAdd = { fg = M.base_30.green },
    DiffChange = { fg = M.base_30.cyan },
    DiffDelete = { fg = M.base_30.red },
    DiffModified = { fg = M.base_30.cyan },
  },

  trouble = {
    -- Trouble.nvim colors
    TroubleNormal = { bg = M.base_30.black, fg = M.base_30.white },
    TroubleNormalNC = { bg = M.base_30.black, fg = M.base_30.white },

    -- Text styling
    TroubleText = { fg = M.base_30.white },
    TroubleTextError = { fg = M.base_30.red },
    TroubleTextWarning = { fg = M.base_30.yellow },
    TroubleTextInformation = { fg = M.base_30.cyan },
    TroubleTextHint = { fg = M.base_30.green },

    -- Icons
    TroubleIconError = { fg = M.base_30.red },
    TroubleIconWarning = { fg = M.base_30.yellow },
    TroubleIconInformation = { fg = M.base_30.cyan },
    TroubleIconHint = { fg = M.base_30.green },

    -- Source
    TroubleSource = { fg = M.base_30.grey_fg },
    TroubleCode = { fg = M.base_30.grey_fg },

    -- Location
    TroubleLocation = { fg = M.base_30.grey_fg },
    TroubleFile = { fg = M.base_30.cyan },
    TroubleDirectory = { fg = M.base_30.blue },

    -- Counts
    TroubleCount = { fg = M.base_30.purple, bg = M.base_30.one_bg2 },

    -- Indents
    TroubleIndent = { fg = M.base_30.line },
    TroubleIndentFoldClosed = { fg = M.base_30.grey_fg },
    TroubleIndentFoldOpen = { fg = M.base_30.grey_fg },

    -- Fold icons
    TroubleFoldIcon = { fg = M.base_30.grey_fg },
  },
}

-- Terminal colors (ANSI)
M.base46_terminal = {
  [0] = "#414550",  -- black
  [1] = "#fc5d7c",  -- red
  [2] = "#9ed072",  -- green
  [3] = "#e7c664",  -- yellow
  [4] = "#76cce0",  -- blue
  [5] = "#b39df3",  -- magenta
  [6] = "#f39660",  -- cyan (orange in Sonokai)
  [7] = "#e2e2e3",  -- white
  [8] = "#414550",  -- bright black
  [9] = "#fc5d7c",  -- bright red
  [10] = "#9ed072", -- bright green
  [11] = "#e7c664", -- bright yellow
  [12] = "#76cce0", -- bright blue
  [13] = "#b39df3", -- bright magenta
  [14] = "#f39660", -- bright cyan (orange)
  [15] = "#e2e2e3", -- bright white
}

return M
