-- Termux compatibility patches for copilot native addons.
-- Applied via lazy.nvim build hooks after install/update.
--
-- Two issues on Termux:
--   1. node reports process.platform === "android" but .node addons only ship for "linux"
--      → symlink compiled/android/arm64 → compiled/linux/arm64
--   2. The linux/arm64 .node files require libstdc++.so.6 (glibc) — incompatible with
--      Android NDK node → patch main.js require() with a try/catch + no-op stub

local M = {}

local SENTINEL = "_watcher_stub_"
local STUB =
	"{writeSnapshot:()=>Promise.resolve(),getEventsSince:()=>Promise.resolve([]),subscribe:()=>Promise.resolve(),unsubscribe:()=>Promise.resolve()}"

local function patch_main_js(path)
	local f = io.open(path, "r")
	if not f then return end
	local content = f:read("*a")
	f:close()

	if content:find(SENTINEL, 1, true) then return end

	-- Pattern: var RV=require(BIND()),WV=WRAP(RV);
	-- →        var RV;try{RV=require(BIND())}catch(SENTINEL){RV=STUB};var WV=WRAP(RV);
	local patched = content:gsub(
		"var (%w+)=require%((%w+%(%))%),(%w+)=(%w+)%(%1%);",
		function(rv, bind, wv, wrap)
			return ("var %s;try{%s=require(%s)}catch(%s){%s=%s};var %s=%s(%s);")
				:format(rv, rv, bind, SENTINEL, rv, STUB, wv, wrap, rv)
		end
	)

	if patched ~= content then
		local w = io.open(path, "w")
		if w then w:write(patched); w:close() end
	end
end

local function ensure_android_symlink(dir)
	local linux = dir .. "/linux/arm64"
	local android = dir .. "/android"
	if vim.uv.fs_stat(linux) and not vim.uv.fs_stat(android) then
		vim.uv.fs_mkdir(android, 493)
		vim.uv.fs_symlink(linux, android .. "/arm64", { flags = 1 })
	end
end

function M.patch()
	if vim.uv.fs_stat("/usr/bin/env") then return end -- not Termux

	local js = vim.fn.stdpath("data") .. "/lazy/copilot.lua/copilot/js"
	ensure_android_symlink(js .. "/compiled")
	ensure_android_symlink(js .. "/bin")
	patch_main_js(js .. "/main.js")
end

return M
