-- Bootstrap mini.nvim for testing
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"

if not vim.uv.fs_stat(mini_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/echasnovski/mini.nvim",
		mini_path,
	})
	vim.cmd("packadd mini.nvim")
end

-- Add plugin under test to runtimepath
vim.opt.rtp:prepend(vim.fn.getcwd())

require("mini.test").setup()
