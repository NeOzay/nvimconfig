---@type LazySpec
return {
	"nvim-java/nvim-java",
	ft = "java",
	dependencies = {
		-- "nvim-java/lua-async-await",
		-- "nvim-java/nvim-java-core",
		-- "nvim-java/nvim-java-test",
		-- "nvim-java/nvim-java-dap",
		"MunifTanjim/nui.nvim",
		"mfussenegger/nvim-dap",
	},
	config = function()
		require("java").setup({
			jdtls = {
				-- version = "1.43.0",
			},
			lombok = {
				enable = true,
			},
			java_test = {
				enable = true,
			},
			java_debug_adapter = {
				enable = true,
			},
			jdk = {
				auto_install = true,
				-- version = "21",
			},
		})

		vim.lsp.enable("jdtls")

		-- Keymaps Java (buffer-local, ft=java)
		Userautocmd("FileType", {
			pattern = "java",
			callback = function(args)
				local bufnr = args.buf
				local map = vim.keymap.set
				local function opts(desc)
					return { buffer = bufnr, desc = "Java " .. desc }
				end

				-- Build
				map("n", "<leader>jb", "<cmd>JavaBuildBuildWorkspace<CR>", opts("build workspace"))
				map("n", "<leader>jB", "<cmd>JavaBuildCleanWorkspace<CR>", opts("clean workspace"))

				-- Run
				map("n", "<leader>jr", "<cmd>JavaRunnerRunMain<CR>", opts("run main"))
				map("n", "<leader>jR", "<cmd>JavaRunnerStopMain<CR>", opts("stop main"))
				map("n", "<leader>jl", "<cmd>JavaRunnerToggleLogs<CR>", opts("toggle logs"))

				-- Test
				map("n", "<leader>jtc", "<cmd>JavaTestRunCurrentClass<CR>", opts("test current class"))
				map("n", "<leader>jtC", "<cmd>JavaTestDebugCurrentClass<CR>", opts("debug current class"))
				map("n", "<leader>jtm", "<cmd>JavaTestRunCurrentMethod<CR>", opts("test current method"))
				map("n", "<leader>jtM", "<cmd>JavaTestDebugCurrentMethod<CR>", opts("debug current method"))
				map("n", "<leader>jta", "<cmd>JavaTestRunAllTests<CR>", opts("run all tests"))
				map("n", "<leader>jtv", "<cmd>JavaTestViewLastReport<CR>", opts("view last report"))

				-- Refactor
				map({ "n", "v" }, "<leader>jev", "<cmd>JavaRefactorExtractVariable<CR>", opts("extract variable"))
				map({ "n", "v" }, "<leader>jec", "<cmd>JavaRefactorExtractConstant<CR>", opts("extract constant"))
				map({ "n", "v" }, "<leader>jem", "<cmd>JavaRefactorExtractMethod<CR>", opts("extract method"))
				map({ "n", "v" }, "<leader>jef", "<cmd>JavaRefactorExtractField<CR>", opts("extract field"))

				-- Misc
				map("n", "<leader>jp", "<cmd>JavaProfile<CR>", opts("profile"))
				map("n", "<leader>js", "<cmd>JavaSettingsChangeRuntime<CR>", opts("change runtime"))
			end,
		})
	end,
}
