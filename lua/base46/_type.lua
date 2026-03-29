---@meta

---@class Base46MixedColor.2
---@field [1] Base46ExtendedColors|Base46MixedColor
---@field [2] integer

---@class Base46MixedColor.4
---@field [1] Base46ExtendedColors|Base46MixedColor
---@field [2] Base46ExtendedColors|Base46MixedColor
---@field [3] integer
---@field [4] integer?

---@alias Base46MixedColor  Base46MixedColor.2|Base46MixedColor.4

---@class Base46HLGroups : vim.api.keyset.highlight
---@field fg? Base46MixedColor|Base46ExtendedColors|"NONE"
---@field bg? Base46MixedColor|Base46ExtendedColors|"NONE"
--- Color name or hex code that will be used for underline colors
--- - If sp is `NONE`, use transparent color for special
--- - If sp is `bg` or `background`, use normal background color
--- - If sp is `fg` or `foreground`, use normal foreground color
--- See :h guisp for more information
---@field sp? Base46MixedColor|Base46ExtendedColors|"NONE"|"bg"|"background"|"fg"|"foreground"

---@alias Base46HLTable table<string, Base46HLGroups>

---@alias Base46ExtendedColors
---| Base46Colors
---| Base46ExtendedPalette
---| string

---@alias Base46Colors
---| Base30Colors
---| Base16Colors

---@alias Base30Colors keyof Base30Table

---@alias Base16Colors keyof Base16Table

---@class Base46Theme
---@field base_16 Base16Table base00-base0F colors
---@field base_30 Base30Table extra colors to use
---@field base_16_terminal? Base16TerminalTable colors to be used in terminal
---@field type "dark"|"light" Denoting value to set for `vim.opt.bg`
---@field polish_hl? table<string, Base46HLTable> highlight groups to be changed from the default color

---@class Base16Table
---@field base00 string Neovim Default Background
---@field base01 string Lighter Background (Used for status bars, line number and folding marks)
---@field base02 string Selection Background (Visual Mode)
---@field base03 string Comments, Invisibles, Line Highlighting, Special Keys, Sings, Fold bg
---@field base04 string Dark Foreground, Dnf Underline (Used for status bars)
---@field base05 string Default Foreground (for text), Var, Refrences Caret, Delimiters, Operators
---@field base06 string Light Foreground (Not often used)
---@field base07 string Light Foreground, Cmp Icons (Not often used)
---@field base08 string Variables, Identifiers, Filed, Name Space, Error, Spell XML Tags, Markup Link Text, Markup Lists, Diff Deleted
---@field base09 string Integers, Boolean, Constants, XML Attributes, Markup Link Url, Inc Search
---@field base0A string Classes, Attribute, Type, Repeat, Tag, Todo, Markup Bold, Search Text Background
---@field base0B string Strings, Symbols, Inherited Class, Markup Code, Diff Inserted
---@field base0C string Constructor,Special, Fold Column, Support, Regular Expressions, Escape Characters, Markup Quotes
---@field base0D string Functions, Methods, Attribute IDs, Headings
---@field base0E string Keywords, Storage, Selector, Markup Italic, Diff Changed
---@field base0F string Delimiters, Special Char, Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>

---@class Base16TerminalTable
---@field [0] string
---@field [1] string
---@field [2] string
---@field [3] string
---@field [4] string
---@field [5] string
---@field [6] string
---@field [7] string
---@field [8] string
---@field [9] string
---@field [10] string
---@field [11] string
---@field [12] string
---@field [13] string
---@field [14] string
---@field [15] string

---@class Base30Table
---@field white string
---@field darker_black string LSP/CMP Pop-ups, Tree BG
---@field black string CMP BG, Icons/Headers FG
---@field black2 string Tabline BG, Cursor Lines, Selections
---@field one_bg string Pop-up Menu BG, Statusline Icon FG
---@field one_bg2 string Tabline Inactive BG, Indent Line Context Start
---@field one_bg3 string Tabline Toggle/New Btn, Borders
---@field grey string Line Nr, Scrollbar, Indent Line Hover
---@field grey_fg string Comment
---@field grey_fg2 string Unused
---@field light_grey string Diff Change, Tabline Inactive FG
---@field red string Diff Delete, Diag Error
---@field baby_pink string Some Dev Icons
---@field pink string Indicators
---@field line string Win Sep, Indent Line
---@field green string Diff Add, Diag Info, Indicators
---@field vibrant_green string Some Dev Icons
---@field blue string UI Elements, Dev/CMP Icons
---@field nord_blue string Indicators
---@field yellow string Diag Warn
---@field sun string Dev Icons
---@field purple string Diag Hint, Dev/CMP Icons
---@field dark_purple string Some Dev Icons
---@field teal string Dev/CMP Icons
---@field orange string Diff Mod
---@field cyan string Dev/CMP Icons
---@field statusline_bg string Statusline
---@field lightbg string Statusline Components
---@field pmenu_bg string Pop-up Menu Selection
---@field folder_bg string Nvimtree Items
