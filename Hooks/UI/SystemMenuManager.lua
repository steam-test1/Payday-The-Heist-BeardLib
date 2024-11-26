core:module("SystemMenuManager")
GenericSystemMenuManager = GenericSystemMenuManager or SystemMenuManager.GenericSystemMenuManager

function GenericSystemMenuManager:show_custom(data)
	if _G.setup and _G.setup:has_queued_exec() then
		return
	end
	local success = self:_show_class(data, BeardLibGenericDialog, BeardLibGenericDialog, data.force)
	self:_show_result(success, data)
end

BeardLibGenericDialog = BeardLibGenericDialog or class(GenericDialog)
function BeardLibGenericDialog:init(manager, data)
    Dialog.init(self, manager, data)
	if not self._data.focus_button then
		if #self._button_text_list > 0 then
			self._data.focus_button = #self._button_text_list
		else
			self._data.focus_button = 1
		end
	end
	self._ws = self._data.ws or manager:_get_ws()
	self._panel = self._ws:panel():gui(Idstring("guis/dialog_manager"))
	self._panel:hide()
	self._panel_script = self._panel:script()
	self._panel_script:setup(self._data)
	self._panel_script:set_fade(0)
	self._controller = self._data.controller or manager:_get_controller()
	self._confirm_func = callback(self, self, "button_pressed_callback")
	self._cancel_func = callback(self, self, "dialog_cancel_callback")
	self._resolution_changed_callback = callback(self, self, "resolution_changed_callback")
	managers.viewport:add_resolution_changed_func(self._resolution_changed_callback)
	self._panel_script.indicator:set_visible(data.indicator or data.no_buttons)
	if data.counter then
		self._counter = data.counter
		self._counter_time = self._counter[1]
	end
end