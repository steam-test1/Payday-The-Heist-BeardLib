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

local orig_NetworkMatchMakingSTEAM_lobby_to_numbers = NetworkMatchMakingSTEAM._lobby_to_numbers
function NetworkMatchMakingSTEAM:_lobby_to_numbers(lobby, ...)
	BeardLib:DevLog("Received level: " .. tostring(lobby:key_value("level_id")))
	local data = orig_NetworkMatchMakingSTEAM_lobby_to_numbers(self, lobby, ...)
	local is_key_valid = function(key) return key ~= "value_missing" and key ~= "value_pending" end
	if is_key_valid(lobby:key_value("level_id")) then
		local _level_index = table.index_of(tweak_data.levels._level_index, lobby:key_value("level_id"))
		if _level_index ~= -1 or _job_index ~= -1 then
			local level_index = _level_index == -1 and tonumber(lobby:key_value("level")) or _level_index
			--log("level_index: " .. tostring(level_index))
			--log("job_index: " .. tostring(job_index))
			data[1] = level_index + 1000
			return data
		end
	end
	local level_name = lobby:key_value("custom_level_name")
	local uid = lobby:key_value("level_update_key")
	local provider = lobby:key_value("level_update_provider")
	local url = lobby:key_value("level_update_download_url")
	if is_key_valid(level_name) then
		BeardLib:DevLog("Received level real name: " .. tostring(level_name))
		data["level_id"] = lobby:key_value("level_id")
		data["custom_level_name"] = level_name
		data["custom_map"] = 1
		data[1] = 1001
		if is_key_valid(uid) or is_key_valid(provider) or is_key_valid(url) then
			BeardLib:DevLog("Received custom map data, id: " .. tostring(uid))
			BeardLib:DevLog("provider: " .. tostring(provider))
			BeardLib:DevLog("download url: " .. tostring(url))
			data["level_update_key"] = uid
			data["level_update_provider"] = provider
			data["level_update_download_url"] = url
		end
	end
	return data
end

-- BEARDLIB API ADDITIONS --

Hooks:Add(seta_hook, "BeardLibCorrectCustomHeist", function(self, new_data, settings, ...)
	self.lobby_handler:delete_lobby_data("level_id")

	local level_index = self:_split_attribute_number(settings.numbers[1], 1000)
	local _level_id = tweak_data.levels._level_index[level_index]
	local level_id = (_level_id and tweak_data.levels[_level_id] and tweak_data.levels[_level_id].custom) and _level_id or nil
	local mod = BeardLib.Utils:GetMapByLevelId(_level_id) --BeardLib.Utils:GetMapByJobId(_job_key)
	if mod and (level_id) then
		local mod_assets = mod:GetModule(ModAssetsModule.type_name)
		if mod_assets and mod_assets._data then
			local update = mod_assets._data
			--Localization might be an issue..
			table.merge(new_data, {
				custom_map = 1,
				custom_level_name = managers.localization:to_upper_text(tweak_data.levels[level_id].name_id),
				level_id = level_id,
				level_update_key = update.id,
				level_update_provider = update.provider,
				level_update_download_url = update.download_url
			})
		else
			table.merge(new_data, {
				custom_level_name = managers.localization:to_upper_text(tweak_data.levels[level_id].name_id),
				custom_map = 1,
				level_id = level_id
			})
		end
	end
end)