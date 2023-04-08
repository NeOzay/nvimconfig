require("bufferline").setup {
  options = {
    mode = 'tabs',
    tab_size = 5,
    max_name_length = 15,
    max_prefix_length = 5,
    --diagnostics_indicator = nil,
    diagnostics = 'nvim_lsp',
    show_buffer_close_icons = false,
    show_buffer_icons = false, -- disable filetype icons for buffers
    show_close_icon = false
  }
}
