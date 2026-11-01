---@namespace Ozay.MarkdownRenderer

--- Abstraction du moteur de rendu markdown (markview ou render-markdown).
--- Le moteur actif est celui que le fichier d'état désignait au démarrage : il ne change plus de
--- la session, la bascule ne prend effet qu'au redémarrage suivant.
---@class Module
local M = {}

local state = require("markdown_renderer.state")

---@type Engine[]
M.ENGINES = state.ENGINES

--- Filetypes rendus par les moteurs (source unique pour les specs et le picker).
---@type string[]
M.FILETYPES = { "markdown", "Avante", "codecompanion", "snacks_notif" }

---@type string? chemin du fichier d'état (nil : le fichier réel)
local state_path = nil
---@type Engine?
local active_engine = nil

--- Moteur du démarrage, lu une fois puis figé.
---@return Engine
function M.active()
	if not active_engine then
		active_engine = state.read(state_path)
	end
	return active_engine
end

---@param engine string
---@return boolean
function M.is_active(engine)
	return M.active() == engine
end

--- Moteur du prochain démarrage (relit le fichier d'état).
---@return Engine
function M.next()
	return state.read(state_path)
end

--- Choisit le moteur du prochain démarrage ; valeur inconnue → erreur, fichier intact.
---@param engine string
function M.set_next(engine)
	state.write(engine, state_path)
end

--- Nom du module adaptateur du moteur actif.
---@return string
local function adapter()
	local name = M.active():gsub("%-", "_")
	return "markdown_renderer." .. name
end

---@param buf integer
---@param win integer
function M.render_notification(buf, win)
	require(adapter()).render_notification(buf, win)
end

---@param buf integer
---@param win integer
function M.render_preview(buf, win)
	require(adapter()).render_preview(buf, win)
end

---@param buf integer
---@param win integer
function M.render_hover(buf, win)
	require(adapter()).render_hover(buf, win)
end

--- Attache le moteur actif à un buffer qui ne s'attache pas de lui-même.
---@param buf integer
function M.attach(buf)
	require(adapter()).attach(buf)
end

--- Vide le cache et fixe le fichier d'état utilisé par `active`, `next` et `set_next`.
---@private
---@param path? string nil : le fichier réel
function M._reset(path)
	state_path = path
	active_engine = nil
end

return M
