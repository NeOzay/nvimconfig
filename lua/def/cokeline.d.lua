---@meta _

---@class Cokeline.Buffer
---@field  index  integer,
---@field  number  integer,
---@field  type  string,
---@field  is_focused  boolean,
---@field  is_modified  boolean,
---@field  is_readonly  boolean,
---@field  path string,
---@field  unique_prefix  string,
---@field  filename string,
---@field  filetype string,
---@field  pick_letter string, -- char
---@field  devicon { icon : string, color : string },
---@field  diagnostics { errors : integer, warnings : integer, infos : integer, hints : integer }
Buffer = {}

---@class Cokeline.Component
---@field text?  string|fun(cx: Buffer): string
---@field style?  string|fun(cx: Buffer): string
---@field fg?  string|fun(cx: Buffer): string
---@field bg?  string|fun(cx: Buffer): string
---@field highlight?  string|fun(cx: Buffer): string
---@field delete_buffer_on_left_click? boolean,
---@field on_click? fun(button_id: number, clicks: number, button: string, modifiers: string, cx: Buffer)
---@field on_mouse_enter? fun(cx: Buffer)
---@field on_mouse_leave? fun(cx: Buffer)
---@field truncation?  {priority: integer, direction:"left"|"middle"|"right" }
