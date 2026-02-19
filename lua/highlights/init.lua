local M = {}

local dir = vim.fn.stdpath("config") .. "/lua/highlights"

--- Charge les highlights. Sans argument, charge tous les fichiers du dossier.
--- Avec un nom, charge uniquement ce fichier (ex: "neogit").
---@param name string
function M.load(name)
	local fn, err = loadfile(dir .. "/" .. name)
	if not fn then
		vim.notify("Erreur loadfile highlights/" .. name .. ": " .. err, vim.log.levels.ERROR)
		return
	end
	local apply = fn()
	if type(apply) == "function" then
		apply()
	end
end

function M.load_all()
	for file, _tp in vim.fs.dir(dir) do
		if not file:find("^init") then
			M.load(file)
		end
	end
end

vim.schedule(function()
	M.load_all()
end)

Userautocmd("BufWritePost", {
	pattern = "*/lua/highlights/*.lua",
	callback = function(ev)
		-- print(ev.match)
		local name = vim.fs.basename(ev.match)
		if name == "init.lua" then
			return
		end
		M.load(name)
		vim.notify("Highlights rechargés: " .. name, vim.log.levels.INFO)
	end,
})

return M
