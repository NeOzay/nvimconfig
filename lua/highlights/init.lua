-- Load custom highlights
vim.schedule(function()
	local modules = {
		"highlights.neo-tree",
		"highlights.diffview",
		"highlights.neogit",
	}

	for _, module in ipairs(modules) do
		local apply_highlights, ok = pRequire(module)
		if ok and type(apply_highlights) == "function" then
			apply_highlights()
		end
	end
end)
