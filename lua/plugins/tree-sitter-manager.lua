Userautocmd("FileType", {
	pattern = require("utils").get_installed_parsers(),
	callback = function()
		vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo[0][0].foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})

---@type LazyPluginSpec
return {
	"romus204/tree-sitter-manager.nvim",
	lazy = false,
	cmd = "TSManager",
	build = function(plugin)
		vim.fn.system({ "ln", "-sf", plugin.dir .. "/runtime/queries", plugin.dir .. "/queries" })
	end,
	config = function()
		require("tree-sitter-manager").setup({
			ensure_installed = {},
			auto_install = true,
			highlight = true,
			languages = {
				luadoc = {
					install_info = {
						url = "https://github.com/NeOzay/tree-sitter-luadoc.git",
						-- Use the query files that ship with the forked repo instead of
						-- the bundled queries. The parser's queries/ directory is copied
						-- automatically during installation.
						use_repo_queries = true,
					},
				},
			},
		})
	end,
}
