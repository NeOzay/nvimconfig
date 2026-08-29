---Lecture de `.list/contract.toml`.
---
---Pas de parseur TOML : seuls les noms de champs, leur type et leur caractère requis
---sont nécessaires, et ils se lisent au motif. La lecture des méta-données de la liste
---(`name`, `description`) s'arrête à la première ligne commençant par `[` — sans cette
---borne, les `description` internes aux blocs `[fields.X]` écraseraient celle de la liste.

---@class Ozay.ListDir.Field
---@field name string
---@field type string `slug` | `text` | `date` | `enum` | `list`
---@field required boolean

---@class Ozay.ListDir.Contract
---@field name string
---@field description string
---@field fields Ozay.ListDir.Field[] dans l'ordre du contrat, `id` inclus

---@class Ozay.ListDir.ContractReader
local M = {}

---Chemin du contrat d'un répertoire-liste.
---@param dir string
---@return string
---@nodiscard
function M.path(dir)
	return vim.fs.joinpath(dir, ".list", "contract.toml")
end

---@param dir string répertoire-liste (le parent de `.list`)
---@return Ozay.ListDir.Contract? contract
---@return string? err
---@nodiscard
function M.read(dir)
	local path = M.path(dir)
	local fd = io.open(path, "r")
	if not fd then
		return nil, ("contrat illisible : %s"):format(path)
	end

	---@type Ozay.ListDir.Contract
	local contract = { name = vim.fs.basename(dir), description = "", fields = {} }
	---@type Ozay.ListDir.Field?
	local current = nil
	local in_meta = true

	for line in fd:lines() do
		local section = line:match("^%s*%[(.-)%]%s*$")
		if section then
			in_meta = false
			local field = section:match("^fields%.([%w_]+)$")
			if field then
				current = { name = field, type = "text", required = false }
				contract.fields[#contract.fields + 1] = current
			else
				current = nil
			end
		elseif in_meta then
			local key, value = line:match('^(%w+)%s*=%s*"(.*)"%s*$')
			if key == "name" then
				contract.name = value
			elseif key == "description" then
				contract.description = value
			end
		elseif current then
			local ftype = line:match('^%s*type%s*=%s*"(.*)"%s*$')
			if ftype then
				current.type = ftype
			elseif line:match("^%s*required%s*=%s*true%s*$") then
				current.required = true
			end
		end
	end
	fd:close()

	if #contract.fields == 0 then
		return nil, ("contrat sans champ déclaré : %s"):format(path)
	end
	return contract
end

return M
