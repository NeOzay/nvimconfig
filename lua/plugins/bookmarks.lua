local function gen_keymaps()
	return {
		{ "<leader>bb", "<cmd>BookmarkToggle<CR>", mode = "n", desc = "Bookmarks: toggle" },
		{ "<leader>ba", "<cmd>BookmarkAnnotate<CR>", mode = "n", desc = "Bookmarks: annoter" },
		{ "<leader>bl", "<cmd>Bookmarks<CR>", mode = "n", desc = "Bookmarks: liste (Trouble)" },
		{ "<leader>bp", "<cmd>BookmarkPick<CR>", mode = "n", desc = "Bookmarks: picker Snacks" },
		{ "]b", "<cmd>BookmarkNext<CR>", mode = "n", desc = "Bookmark suivant" },
		{ "[b", "<cmd>BookmarkPrev<CR>", mode = "n", desc = "Bookmark précédent" },
		{ "<leader>bx", "<cmd>BookmarkClear<CR>", mode = "n", desc = "Bookmarks: vider le fichier" },
		{ "<leader>bK", "<cmd>BookmarkNote<CR>", mode = "n", desc = "Bookmarks: note (popup)" },
	}
end

---@type LazySpec
return {
	dir = vim.fn.stdpath("config") .. "/plugins/bookmarks",
	dependencies = {
		"neozay/trouble.nvim",
		"kkharji/sqlite.lua",
	},
	lazy = false,
	config = function()
		require("bookmarks").setup()
	end,
	cmd = {
		"Bookmarks",
		"BookmarkToggle",
		"BookmarkAdd",
		"BookmarkAnnotate",
		"BookmarkNext",
		"BookmarkPrev",
		"BookmarkClear",
		"BookmarkPick",
		"BookmarkNote",
	},
	keys = gen_keymaps(),
}
