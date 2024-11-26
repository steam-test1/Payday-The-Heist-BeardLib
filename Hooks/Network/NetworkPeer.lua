local peer_send_hook = "NetworkPeerSend"

local NetworkPeerSend = NetworkPeer.send
local SyncUtils = BeardLib.Utils.Sync
local SyncConsts = BeardLib.Constants.Sync

Hooks:Register(peer_send_hook)

Hooks:Add(peer_send_hook, "BeardLibCustomHeistFix", function(self, func_name, params)
    if self ~= managers.network:session():local_peer() and SyncUtils:IsCurrentJobCustom() then
        if func_name == "sync_game_settings" or func_name == "sync_lobby_data" then
            SyncUtils:Send(self, SyncConsts.GameSettings, SyncUtils:GetJobString())
        elseif func_name == "lobby_sync_update_level_id" then
            SyncUtils:Send(self, SyncConsts.LobbyLevelId, Global.game_settings.level_id)
        elseif func_name == "sync_stage_settings" then
            local glbl = managers.job._global
            local msg = string.format("%s|%s|%s|%s", Global.game_settings.level_id, tostring(glbl.current_job.current_stage), tostring(glbl.alternative_stage or 0), tostring(glbl.interupt_stage))
            SyncUtils:Send(self, SyncConsts.StageSettings, msg)
        elseif string.ends(func_name,"join_request_reply") then
            if params[1] == 1 then
                params[15] = SyncUtils:GetJobString()
            end
        end
    end
end)

function NetworkPeer:send(func_name, ...)
    if not self._ip_verified then
        return
    end
    local params = table.pack(...)
    Hooks:Call(peer_send_hook, self, func_name, params)
    NetworkPeerSend(self, func_name, unpack(params, 1, params.n))
end

Hooks:Add("NetworkReceivedData", SyncConsts.LobbyLevelId, function(sender, id, data)
    if id == SyncConsts.LobbyLevelId then
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:lobby_sync_update_level_id_ignore_once(data)
        end
    end
end)

Hooks:Add("NetworkReceivedData", SyncConsts.GameSettings, function(sender, id, data)
    if id == SyncConsts.GameSettings then
        local split_data = string.split(data, "|")
        local level_name = split_data[4]
        local update_data = BeardLib.Utils.Sync:GetUpdateData(split_data)
        local session = managers.network:session()
        local function disconnect()
            if managers.network:session() then
                managers.network:queue_stop_network()
                managers.platform:set_presence("Idle")
                managers.network.matchmake:leave_game()
                managers.network.voice_chat:destroy_voice(true)
                managers.menu:exit_online_menues()
            end
        end
        if update_data then
            session._ignore_load = true
            BeardLib.Utils.Sync:DownloadMap(level_name, update_data, function(success)
                if success then
                    session._ignore_load = nil
                    if session._ignored_load then
                        session:ok_to_load_level(unpack(session._ignored_load))
                    end
                else
                    disconnect()
                end
            end)
        else
            disconnect()
            BeardLib.Managers.Dialog:Simple():Show({title = managers.localization:text("mod_assets_error"), message = managers.localization:text("custom_map_cant_download"), force = true})
            return
        end
    end
end)

Hooks:Add("NetworkReceivedData", SyncConsts.StageSettings, function(sender, id, data)
    if id == SyncConsts.StageSettings then
        local split_data = string.split(data, "|")
        local peer = managers.network:session():peer(sender)
        local rpc = peer and peer:rpc()
        if rpc then
            managers.network._handlers.connection:sync_stage_settings_ignore_once(tweak_data.levels:get_index_from_level_id(split_data[1]),
            tonumber(split_data[2]),
            tonumber(split_data[3]),
            tweak_data.levels:get_index_from_level_id(split_data[4]) or 0,
            rpc)
        else
            log("[ERROR] RPC is nil!")
        end
    end
end)