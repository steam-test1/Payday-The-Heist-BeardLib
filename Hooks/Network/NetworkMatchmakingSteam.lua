-- API Calls --
local orig_NetworkMatchMakingSTEAM_set_attributes = NetworkMatchMakingSTEAM.set_attributes

local seta_hook = "BeardLibSteamLobbySetAttributes"

Hooks:Register(seta_hook)

function NetworkMatchMakingSTEAM:set_attributes(settings, ...)
	if not self.lobby_handler then
		return
	end
	orig_NetworkMatchMakingSTEAM_set_attributes(self, settings, ...)

	local new_data = {}

	Hooks:Call(seta_hook, self, new_data, settings, ...)
	if table.size(new_data) > 0 then
		table.merge(self._lobby_attributes, new_data)
	    self.lobby_handler:set_lobby_data(new_data)
	end
end

-- BEARDLIB API ADDITIONS --

Hooks:Add(seta_hook, "BeardLibCorrectCustomHeist", function(self, new_data, settings, ...)
	self.lobby_handler:delete_lobby_data("level_id")
	self.lobby_handler:delete_lobby_data("job_key")

	local level_index, job_index = self:_split_attribute_number(settings.numbers[1], 1000)
	local _level_id = tweak_data.levels._level_index[level_index]
	local _job_key = tweak_data.narrative._jobs_index[job_index]
	local level_id = (_level_id and tweak_data.levels[_level_id] and tweak_data.levels[_level_id].custom) and _level_id or nil
	local job_key = (_job_key and tweak_data.narrative.jobs[_job_key] and tweak_data.narrative.jobs[_job_key].custom) and _job_key or nil
	local mod = BeardLib.Utils:GetMapByJobId(_job_key)
	if mod and (level_id or job_key) then
		local mod_assets = mod:GetModule(ModAssetsModule.type_name)
		if mod_assets and mod_assets._data then
			local update = mod_assets._data
			--Localization might be an issue..
			table.merge(new_data, {
				custom_map = 1,
				custom_level_name = managers.localization:to_upper_text(tweak_data.levels[level_id].name_id),
				level_id = level_id,
				job_key = job_key,
				level_update_key = update.id,
				level_update_provider = update.provider,
				level_update_download_url = update.download_url,
			})
		else
			table.merge(new_data, {
				custom_level_name = managers.localization:to_upper_text(tweak_data.levels[level_id].name_id),
				custom_map = 1,
				level_id = level_id,
				job_key = job_key
			})
		end
	end
end)

-- Custom heists only filter
-- If they add any new interest keys, just make sure to update these.
-- If your mod adds any keys, you can extend this list.
NetworkMatchMakingSTEAM.DEFAULT_KEYS = {
	"owner_id",
	"owner_name",
	"level",
	"difficulty",
	"permission",
	"state",
	"num_players",
	"drop_in",
	"min_level",
	"kick_option",
	"job_class_min",
	"job_class_max",
	"allow_mods",
	"custom_map"
}
Hooks:PostHook(NetworkMatchMakingSTEAM, "search_lobby", "CustomMapFilter", function(self, friends_only, no_filters)
    if Global.game_settings.custom_maps_only and self.browser then
		self.browser:set_interest_keys(self.DEFAULT_KEYS)
		self.browser:set_lobby_filter("custom_map", 1, "equalto_or_greater_than")
    end
end)