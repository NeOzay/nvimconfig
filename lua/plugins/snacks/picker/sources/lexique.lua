---Picker des termes du lexique : chaque terme, son niveau et sa définition, global puis local.
---`<CR>` affiche la définition comme `:Lexique <terme>`.
return function()
	local lexique = require("lexique")
	local entries = lexique.entries()
	if not entries then
		return
	end

	local width = 0
	for _, e in ipairs(entries) do
		width = math.max(width, vim.api.nvim_strwidth(e.terme))
	end

	---@type snacks.picker.finder.Item[]
	local items = {}
	for i, e in ipairs(entries) do
		items[#items + 1] = {
			-- Terme ET définition : on retrouve un terme par ce qu'il veut dire.
			text = e.terme .. " " .. e.definition,
			idx = i,
			entry = e,
		}
	end

	Snacks.picker.pick({
		title = "Lexique",
		items = items,
		preview = "none",
		layout = { preset = "ivy", hidden = { "preview" } },
		format = function(item)
			---@type Ozay.Lexique.Entry
			local e = item.entry
			local pad = width - vim.api.nvim_strwidth(e.terme)
			return {
				{ e.terme .. (" "):rep(pad), "LexiqueTerme" },
				{ (" %-6s "):format(e.niveau), "LexiqueNiveau" },
				{ e.definition, "LexiqueDefinition" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				-- Après la fermeture : le redessin du picker effacerait le message.
				vim.schedule(function()
					lexique.echo({ item.entry })
				end)
			end
		end,
	})
end
