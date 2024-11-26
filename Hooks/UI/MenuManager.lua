dofile(Path:Combine(BeardLib.config.classes_dir, "UI/MenuItemColorButton.lua"))
local orig_MenuCallbackHandler_start_job = MenuCallbackHandler.start_job

local sync_game_settings_id = "BeardLib_sync_game_settings"
local SyncUtils = BeardLib.Utils.Sync
local MenuUIManager = BeardLib.Managers.MenuUI
local DialogManager = BeardLib.Managers.Dialog

local o_toggle_menu_state = MenuManager.toggle_menu_state
function MenuManager:toggle_menu_state(...)
    if DialogManager:DialogOpened() then
        DialogManager:CloseLastDialog()
        return
    end
    if not MenuUIManager:InputAllowed() then
        return
    end
    return o_toggle_menu_state(self, ...)
end

local o_refresh = MenuManager.refresh_level_select
function MenuManager.refresh_level_select(...)
    if Global.game_settings.level_id then
        return o_refresh(...)
    else
        BeardLib:log("[Warning] Refresh level select was called while level id was nil!")
    end
end

local o_resume_game = MenuCallbackHandler.resume_game
function MenuCallbackHandler:resume_game(...)
    if not DialogManager:DialogOpened() then
        return o_resume_game(self, ...)
    end
end

core:import("SystemMenuManager")
Hooks:PostHook(SystemMenuManager.GenericSystemMenuManager, "event_dialog_shown", "BeardLibEventDialogShown", function(self)
    if DialogManager:DialogOpened() then
        BeardLib.IgnoreDialogOnce = true
    end
end)
Hooks:PostHook(SystemMenuManager.GenericSystemMenuManager, "event_dialog_closed", "BeardLibEventDialogClosed", function(self)
    BeardLib.IgnoreDialogOnce = false
end)

Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobby_sync_game_settings", function(peer, peer_id)
    SyncUtils:SyncGameSettings(peer_id)
end)

Hooks:Add("NetworkManagerOnPeerAdded", "NetworkManagerOnPeerAdded_sync_game_settings", function(peer, peer_id)
    SyncUtils:SyncGameSettings(peer_id)
end)

QuickMenuPlus = QuickMenuPlus or class(QuickMenu)
QuickMenuPlus._menu_id_key = "quick_menu_p_id_"
QuickMenuPlus._menu_id_index = 0
function QuickMenuPlus:new( ... )
    return self:init( ... )
end

function QuickMenuPlus:init(title, text, options, dialog_merge)
    options = options or {}
    for _, opt in pairs(options) do
        if not opt.callback then
            opt.is_cancel_button = true
        end
    end
    QuickMenuPlus.super.init(self, title, text, options)
    if dialog_merge then
        table.merge(self.dialog_data, dialog_merge)
    end
    self.show = nil
    self.Show = nil
    self.visible = true
    managers.system_menu:show_custom(self.dialog_data)
    return self
end