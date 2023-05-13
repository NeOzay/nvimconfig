local signs = {
    Error = "",
    Warning = "",
    Hint = "",
    Information = ""
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {text = icon.." ", texthl = hl, numhl = hl})
end
require "trouble".setup {
  signs = {
        -- icons / text used for a diagnostic
        error = signs.Error,
        warning = signs.Warning,
        hint = signs.Hint,
        information = signs.Information,
    }
}
