local function checkConfigDir()
  if vim.fn.getcwd() == "/home/ozay/.config/nvim" then
    return vim.api.nvim_get_runtime_file("", true)
  end
end

local sumneko = {
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                --version = 'LuaJIT',
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                --globals = {'vim'},
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                --library = checkConfigDir(),
                checkThirdParty = false
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },

            completion = {
                autoRequire = false
            },
        },
        format = {
            enable = false,
            indent_size = "2",
            -- Put format options here
            -- NOTE: the value should be STRING!!
            defaultConfig = {
                indent_style = "space",
                indent_size = "2",
            } }
    },
    cmd = { vim.fn.expand("$HOME/lua-language-server/bin/lua-language-server") }
}

return sumneko
