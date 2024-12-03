local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks

if F == "tweakdata" then
	TweakDataHelper:Apply()

	tweak_data.achievement = {}
	tweak_data.narrative = {}
	tweak_data.narrative.jobs = {}
	tweak_data.narrative.contacts = {
		"hox"
	}

	if BLT:GetGame() == "pdth" then
		tweak_data.menu.pd2_large_font = "fonts/font_univers_530_bold"
		tweak_data.menu.pd2_medium_font = "fonts/font_univers_530_medium"
		tweak_data.menu.pd2_small_font = "fonts/font_univers_530_medium"
		tweak_data.menu.default_font = "fonts/font_univers_530_bold"
	end
	for _, framework in pairs(BeardLib.Frameworks) do framework:RegisterHooks() end
elseif F == "hudiconstweakdata" then
	--Makes sure that rect can be returned as a null if it's a custom icon
	local get_icon = HudIconsTweakData.get_icon_data
	function HudIconsTweakData:get_icon_data(id, rect, ...)
		local icon, texture_rect = get_icon(self, id, rect, ...)
		local data = self[id]
		if not rect and data and data.custom and not data.texture_rect then
			texture_rect = nil
		end
		return icon, texture_rect
	end
elseif F == "gamesetup" then
	Hooks:PreHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPrePausedUpdate", t, dt)
	end)
	Hooks:PostHook(GameSetup, "paused_update", "GameSetupPausedUpdateBase", function(self, t, dt)
        Hooks:Call("GameSetupPauseUpdate", t, dt)
	end)
elseif F == "setup" then
	Hooks:PreHook(Setup, "update", "BeardLibSetupPreUpdate", function(self, t, dt)
        Hooks:Call("SetupPreUpdate", t, dt)
	end)

	Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(self)
		Hooks:Call("SetupInitManagers", self)
	end)

	Hooks:PostHook(Setup, "init_finalize", "BeardLibInitFinalize", function(self)
		BeardLib.Managers.Sound:Open()
		Hooks:Call("BeardLibSetupInitFinalize", self)
	end)

	Hooks:PostHook(Setup, "unload_packages", "BeardLibUnloadPackages", function(self)
		BeardLib.Managers.Sound:Close()
		BeardLib.Managers.Package:Unload()
		Hooks:Call("BeardLibSetupUnloadPackages", self)
	end)
elseif F == "missionmanager" then
	for _, name in ipairs(BeardLib.config.mission_elements) do
		dofile(Path:Combine(BeardLib.config.classes_dir, "Elements", "Element"..name..".lua"))
	end

	local add_script = MissionManager._add_script
	function MissionManager:_add_script(data, ...)
		if self._scripts[data.name] then
			return
		end
		return add_script(self, data, ...)
	end
elseif F == "dlctweakdata" then
	Hooks:PostHook(DLCTweakData, "init", "BeardLibModDLCGlobalValue", function(self, tweak_data)
		tweak_data.lootdrop.global_values.mod = {
			name_id = "bm_global_value_mod",
			desc_id = "menu_l_global_value_mod",
			color = Color(255, 59, 174, 254) / 255,
			dlc = false,
			chance = 1,
			value_multiplier = 1,
			durability_multiplier = 1,
			track = false,
			sort_number = -10
		}

		table.insert(tweak_data.lootdrop.global_value_list_index, "mod")

		self.mod = {
			free = true,
			content = {loot_drops = {}, upgrades = {}}
		}
	end)
elseif F == "localizationmanager" then
	-- Don't you love when you crash just for asking if this shit exist?
	function LocalizationManager:modded_exists(str)
		return self._custom_localizations[str] ~= nil
	end
end
