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

local his
function M.get_availables()
	if his then
		return his
	end
	his = {}
	for file, _tp in vim.fs.dir(dir) do
		if not file:find("^init") then
			his[#his + 1] = file
		end
	end
	return his
end

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

local function escape_pattern(text)
	return text:gsub("[-%%^$*+?.()|%[%]{}]", "%%%1")
end

Userautocmd("User", {
	pattern = "LazyLoad",
	callback = function(opt)
		---@cast opt.data string
		local his = M.get_availables()
		for _, hi in ipairs(his) do
			-- remove .lua and escape pattern chars
			local clear_name = escape_pattern(hi:sub(1, -5))
			if opt.data:find(clear_name) then
				print("loading highlights: " .. opt.data)
				M.load(hi)
			end
		end
	end,
})

return M
