---@type LazySpec
return {
	"williamboman/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
	build = ":MasonUpdate",
	config = function(_, opts)
		require("mason").setup(opts)
		local registry = require("mason-registry")
		local ensure_installed = { "rust-analyzer" }
		for _, pkg_name in ipairs(ensure_installed) do
			local ok, pkg = pcall(registry.get_package, pkg_name)
			if ok and not pkg:is_installed() then
				pkg:install()
			end
		end
	end,
	opts = {
		ui = {
			border = "rounded",
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
	},
}
