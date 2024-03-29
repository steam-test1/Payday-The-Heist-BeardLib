core:import("CoreMenuItem")

MenuItemInput = MenuItemInput or class(CoreMenuItem.Item)
MenuItemInput.TYPE = "input"

function MenuItemInput:init(data_node, parameters)
	MenuItemInput.super.init(self, data_node, parameters)

	self._esc_released_callback = 0
	self._enter_callback = 0
	self._typing_callback = 0
	self._type = MenuItemInput.TYPE
	self._input_text = ""
	self._input_limit = self._parameters.input_limit or 30
	self._empty_gui_input_limit = self._parameters.empty_gui_input_limit or self._input_limit / 2
end

function MenuItemInput:input_text()
	return self._input_text
end

function MenuItemInput:set_input_text(input_text)
	self._input_text = input_text
end

function MenuItemInput:add_input_text(input_text)
	self._input_text = self._input_text .. input_text
end

function MenuItemInput:set_value(value)
	self:set_input_text(value)
end

function MenuItemInput:value()
	return self:input_text()
end

function MenuItemInput:setup_gui(node, row_item)
	local right_align = node:_right_align()
	row_item.gui_panel = node.item_panel:panel({
		alpha = 0.9,
		w = node.item_panel:w()
	})
	row_item.gui_text = node:_text_item_part(row_item, row_item.gui_panel, right_align, row_item.align)
	row_item.empty_gui_text = node:_text_item_part(row_item, row_item.gui_panel, right_align, row_item.align)
	row_item.input_bg = row_item.gui_panel:rect({
		alpha = 0,
		vertical = "scale",
		blend_mdoe = "add",
		halign = "scale",
		align = "scale",
		valign = "scale",
		color = Color(0.5, 0.5, 0.5),
		layer = node.layers.items - 1
	})

	row_item.empty_gui_text:set_alpha(1)
	row_item.gui_text:set_text("")

	row_item.caret = row_item.gui_panel:rect({
		rotation = 360,
		name = "caret",
		h = 0,
		w = 0,
		blend_mode = "add",
		y = 0,
		x = 0,
		color = Color(0.1, 1, 1, 1),
		layer = node.layers.items + 2
	})

	self:_layout_gui(node, row_item)

	return true
end

function MenuItemInput:_layout_gui(node, row_item)
	local safe_rect = managers.gui_data:scaled_size()
	local right_align = node:_right_align()
	local left_align = node:_left_align()

	row_item.gui_text:set_text(self._input_text or "")

	local n = utf8.len(row_item.gui_text:text())

	row_item.gui_text:set_selection(n, n)

	local _, _, w, h = row_item.empty_gui_text:text_rect()

	row_item.gui_panel:set_height(h)
	row_item.gui_panel:set_width(safe_rect.width - node:_mid_align())
	row_item.gui_panel:set_x(node:_mid_align())

	self._align_right = row_item.gui_panel:w()
	self._align_left = node:_right_align() - row_item.gui_panel:x()

	self:_layout(row_item)
end

function MenuItemInput:_layout(row_item)
	local _, _, w = row_item.gui_text:text_rect()

	row_item.gui_text:set_width(w + 5)

	local _, _, w, h = row_item.empty_gui_text:text_rect()

	row_item.gui_text:set_h(h)
	row_item.empty_gui_text:set_h(h)
	row_item.empty_gui_text:set_width(w + 5)

	if row_item.align == "right" then
		row_item.gui_text:set_left(self._align_left)
		row_item.empty_gui_text:set_right(self._align_right)
	else
		row_item.gui_text:set_right(self._align_right)
		row_item.empty_gui_text:set_left(self._align_left)
	end

	row_item.gui_text:set_color(row_item.color)
	row_item.empty_gui_text:set_color(row_item.color)
	row_item.empty_gui_text:set_visible(utf8.len(row_item.gui_text:text()) < (self._empty_gui_input_limit or 1))
	self:_update_caret(row_item)
	self:_update_input_bg(row_item)

	return true
end

function MenuItemInput:_update_input_bg(row_item)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	row_item.input_bg:set_alpha(self._input_text ~= row_item.gui_text:text() and 0.6 or 0)
end

function MenuItemInput:reload(row_item, node)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	self:_layout_gui(node, row_item)

	return true
end

function MenuItemInput:highlight_row_item(node, row_item, mouse_over)
	row_item.gui_text:set_color(row_item.color)
	row_item.empty_gui_text:set_color(row_item.color)
	self:_on_focus(row_item)

	return true
end

function MenuItemInput:fade_row_item(node, row_item, mouse_over)
	row_item.gui_text:set_color(row_item.color)
	row_item.empty_gui_text:set_color(row_item.color)
	self:_loose_focus(row_item)

	return true
end

function MenuItemInput:esc_key_callback(row_item)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	self:_set_enabled(false)
	self:_loose_focus(row_item)
end

function MenuItemInput:enter_key_callback(row_item)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	if not self._editing then
		self:_set_enabled(true)

		return
	end

	self:_set_enabled(false)

	local text = row_item.gui_text
	local message = text:text()

	self:set_input_text(message)
	self:_layout(row_item)
end

function MenuItemInput:_set_enabled(enabled)
	if not self:enabled() then
		return
	end

	if enabled then
		self._editing = true

		managers.menu:active_menu().input:set_back_enabled(false)
		managers.menu:active_menu().input:accept_input(false)
		managers.menu:active_menu().input:deactivate_mouse()
	else
		self._editing = false

		managers.menu:active_menu().input:activate_mouse()
		managers.menu:active_menu().input:accept_input(true)
		managers.menu:active_menu().input:set_back_enabled(true)
	end
end

function MenuItemInput:_animate_show_input(input_panel)
	local TOTAL_T = 0.2
	local start_alpha = input_panel:alpha()
	local end_alpha = 1

	over(TOTAL_T, function (p)
		input_panel:set_alpha(math.lerp(start_alpha, end_alpha, p))
	end)
end

function MenuItemInput:_animate_hide_input(input_panel)
	local TOTAL_T = 0.2
	local start_alpha = input_panel:alpha()
	local end_alpha = 0.95

	over(TOTAL_T, function (p)
		input_panel:set_alpha(math.lerp(start_alpha, end_alpha, p))
	end)
end

function MenuItemInput:_animate_input_bg(input_bg)
	local t = 0

	while true do
		local dt = coroutine.yield()
		t = t + dt
		local a = 0.75 + (1 + math.sin(t * 200)) / 8

		input_bg:set_alpha(a)
	end
end

function MenuItemInput:trigger()
	if type(self._enter_callback) ~= "number" then
		self._enter_callback()
	end

	for _, callback in pairs((self:enabled() or self:parameters().ignore_disabled) and self:parameters().callback or self:parameters().callback_disabled) do
		callback(self)
	end
end

function MenuItemInput:_on_focus(row_item)
	if self._focus or not self:enabled() then
		return
	end

	self._focus = true

	row_item.gui_panel:stop()
	row_item.gui_panel:animate(callback(self, self, "_animate_show_input"))
	row_item.node_gui.ws:connect_keyboard(Input:keyboard())
	row_item.gui_panel:key_press(callback(self, self, "key_press", row_item))
	row_item.gui_panel:enter_text(callback(self, self, "enter_text", row_item))
	row_item.gui_panel:key_release(callback(self, self, "key_release", row_item))

	self._esc_released_callback = callback(self, self, "esc_key_callback", row_item)
	self._enter_callback = callback(self, self, "enter_key_callback", row_item)
	self._typing_callback = 0
	self._enter_text_set = false

	self:_layout(row_item)
end

function MenuItemInput:focus()
	return self._focus
end

function MenuItemInput:_loose_focus(row_item)
	if not self._focus then
		return false
	end

	self._focus = false
	self._one_scroll_up_delay = nil
	self._one_scroll_dn_delay = nil
	local text = row_item.gui_text

	text:set_text(self._input_text or "")

	local n = utf8.len(text:text())

	text:set_selection(n, n)
	row_item.node_gui.ws:disconnect_keyboard()
	row_item.gui_panel:key_press(nil)
	row_item.gui_panel:enter_text(nil)
	row_item.gui_panel:key_release(nil)

	self._esc_released_callback = 0
	self._enter_callback = 0
	self._typing_callback = 0

	row_item.gui_panel:stop()
	row_item.gui_panel:animate(callback(self, self, "_animate_hide_input"))

	local text = row_item.gui_text

	text:stop()
	self:_layout(row_item)

	return true
end

function MenuItemInput:_shift()
	local k = Input:keyboard()

	return k:down(Idstring("left shift")) or k:down(Idstring("right shift")) or k:has_button(Idstring("shift")) and k:down(Idstring("shift"))
end

function MenuItemInput.blink(o)
	while true do
		o:set_color(Color(0.05, 1, 1, 1))
		wait(0.4)
		o:set_color(Color(0.9, 1, 1, 1))
		wait(0.4)
	end
end

function MenuItemInput:set_blinking(b, row_item)
	local caret = row_item.caret

	if b == self._blinking then
		return
	end

	if b then
		caret:animate(self.blink)
	else
		caret:stop()
	end

	self._blinking = b

	if not self._blinking then
		caret:set_color(Color(0.9, 1, 1, 1))
	end
end

function MenuItemInput:_update_caret(row_item)
	local text = row_item.gui_text
	local caret = row_item.caret
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()

	if s == 0 and e == 0 then
		if text:align() == "center" then
			x = text:world_x() + text:w() / 2
		elseif row_item.align == "right" then
			x = text:world_right()
		else
			x = text:world_left()
		end

		y = text:world_y()
	end

	h = text:h()

	if w < 3 then
		w = 3
	end

	if not self._editing then
		w = 0
		h = 0
	end

	caret:set_world_shape(x, y + 2, w, h - 4)

	if row_item.align == "right" then
		caret:set_world_right(x)
	end

	self:set_blinking(s == e and self._editing, row_item)
end

function MenuItemInput:enter_text(row_item, o, s)
	if not row_item or not alive(row_item.gui_text) or not self._editing then
		return
	end

	local text = row_item.gui_text
	local m = self._input_limit
	local n = utf8.len(text:text())
	s = utf8.sub(s, 1, m - n)

	if type(self._typing_callback) ~= "number" then
		self._typing_callback()
	end

	text:replace_text(s)
	self:_layout(row_item)
end

function MenuItemInput:update_key_down(row_item, o, k)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	wait(0.6)

	local text = row_item.gui_text

	while self._key_pressed == k do
		local s, e = text:selection()
		local n = utf8.len(text:text())
		local d = math.abs(e - s)

		if self._key_pressed == Idstring("backspace") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end

			text:replace_text("")

			if utf8.len(text:text()) < 1 and type(self._esc_released_callback) ~= "number" then
				-- Nothing
			end
		elseif self._key_pressed == Idstring("delete") then
			if s == e and s < n then
				text:set_selection(s, e + 1)
			end

			text:replace_text("")

			if utf8.len(text:text()) < 1 and type(self._esc_released_callback) ~= "number" then
				-- Nothing
			end
		elseif self._key_pressed == Idstring("insert") then
			local clipboard = Application:get_clipboard() or ""

			text:replace_text(clipboard)

			local lbs = text:line_breaks()

			if #lbs > 1 then
				local s = lbs[2]
				local e = utf8.len(text:text())

				text:set_selection(s, e)
				text:replace_text("")
			end
		elseif self._key_pressed == Idstring("left") then
			if s < e then
				text:set_selection(s, s)
			elseif s > 0 then
				text:set_selection(s - 1, s - 1)
			end
		elseif self._key_pressed == Idstring("right") then
			if s < e then
				text:set_selection(e, e)
			elseif s < n then
				text:set_selection(s + 1, s + 1)
			end
		else
			self._key_pressed = false
		end

		self:_layout(row_item)
		wait(0.03)
	end
end

function MenuItemInput:key_release(row_item, o, k)
	if not row_item or not alive(row_item.gui_text) then
		return
	end

	if self._key_pressed == k then
		self._key_pressed = false
	end

	if k == Idstring("esc") then
		if type(self._esc_released_callback) ~= "number" then
			self._esc_released_callback()
		end
	elseif k == Idstring("enter") and self._should_disable then
		self._should_disable = false

		self:trigger()
	end
end

function MenuItemInput:key_press(row_item, o, k)
	if not row_item or not alive(row_item.gui_text) or not self._editing then
		return
	end

	local text = row_item.gui_text
	local s, e = text:selection()
	local n = utf8.len(text:text())
	local d = math.abs(e - s)
	self._key_pressed = k

	text:stop()
	text:animate(callback(self, self, "update_key_down", row_item), k)

	if k == Idstring("backspace") then
		if s == e and s > 0 then
			text:set_selection(s - 1, e)
		end

		text:replace_text("")

		if utf8.len(text:text()) < 1 and type(self._esc_released_callback) ~= "number" then
			-- Nothing
		end
	elseif k == Idstring("delete") then
		if s == e and s < n then
			text:set_selection(s, e + 1)
		end

		text:replace_text("")

		if utf8.len(text:text()) < 1 and type(self._esc_released_callback) ~= "number" then
			-- Nothing
		end
	elseif k == Idstring("insert") then
		local clipboard = Application:get_clipboard() or ""

		text:replace_text(clipboard)

		local lbs = text:line_breaks()

		if #lbs > 1 then
			local s = lbs[2]
			local e = utf8.len(text:text())

			text:set_selection(s, e)
			text:replace_text("")
		end
	elseif k == Idstring("left") then
		if s < e then
			text:set_selection(s, s)
		elseif s > 0 then
			text:set_selection(s - 1, s - 1)
		end
	elseif k == Idstring("right") then
		if s < e then
			text:set_selection(e, e)
		elseif s < n then
			text:set_selection(s + 1, s + 1)
		end
	elseif self._key_pressed == Idstring("end") then
		text:set_selection(n, n)
	elseif self._key_pressed == Idstring("home") then
		text:set_selection(0, 0)
	elseif k == Idstring("enter") then
		self._should_disable = true
	end

	self:_layout(row_item)
end

MenuItemColorButton = MenuItemColorButton or class(MenuItemInput)
MenuItemColorButton.TYPE = "color_button"
MenuItemColorButton.trigger = CoreMenuItem.Item.trigger

function MenuItemColorButton:init(...)
    MenuItemColorButton.super.init(self, ...)
    self._type = "color_button"
    self._input_limit = 8 --AARRGGBB
end

function MenuItemColorButton:set_value(value)
    local t = type_name(value)
    if t == "Color" then
        value = value:to_hex()
    end
    t = type_name(value)
    if t == "string" then
        self:set_input_text(value)
    else
        self:set_input_text("ffffff")
    end
    self:update_color_preview()
    self:dirty()
end

function MenuItemColorButton:value(value)
    return Color:from_hex(self:input_text())
end

function MenuItemColorButton:setup_gui(node, row_item)
    MenuItemColorButton.super.setup_gui(self, node, row_item)
    self._color_preview = row_item.gui_panel:rect({name = "color_preview", layer = node.layers.items})
    self._panel = row_item.gui_panel
    self._text = row_item.gui_text
    self._caret = row_item.caret
    self._caret:set_blend_mode("normal")
    row_item.input_bg:hide()
    self:_update_caret()
    return true
end

function MenuItemColorButton:set_editing(set)
    self:_set_enabled(set)
end

function MenuItemColorButton:_set_enabled(enabled)
	if not self:enabled() then
		return
	end
    self._editing = enabled
    managers.menu:active_menu().input:set_back_enabled(not enabled)
    managers.menu:active_menu().input:accept_input(not enabled)
    if not enabled then
        managers.menu:active_menu().input._current_input_item = nil
    end
    if alive(self._text) then
        self._text:set_selection(self._text:text():len())
    end

    self:_update_caret()
end

function MenuItemColorButton:_layout(row_item)
    MenuItemColorButton.super._layout(self, row_item)
    if alive(self._color_preview) then
        local s = self._panel:h() - 4
        self._color_preview:set_size(s, s)
        self._color_preview:set_center_y(self._panel:h() / 2)
    end
    self:update_color_preview()
    return true
end

local KB = BeardLib.Utils.Input
function MenuItemColorButton:update_key_down(row_item, o, k)
    if not row_item or not alive(row_item.gui_text) then
		return
    end

    local first
    local text = row_item.gui_text
  	while self._key_pressed == k do
		local s, e = text:selection()
		local t = text:text()
		local n = utf8.len(t)
		if ctrl() then
	    	if KB:Down("a") then
	    		text:set_selection(0, text:text():len())
	    	elseif Input:keyboard():down(Idstring("c")) then
	    		Application:set_clipboard(tostring(text:selected_text()))
	    	elseif KB:Down("v") then
	    		if (self.filter == "number" and tonumber(Application:get_clipboard()) == nil) then
	    			return
				end
				self._before_text = t
                text:replace_text(tostring(Application:get_clipboard()))
                text:set_text(text:text():sub(1, self._input_limit))
                self:check_changed()
			elseif shift() then
                if KB:Down(Idstring("left")) then text:set_selection(s - 1, e)
                elseif KB:Down(Idstring("right")) then text:set_selection(s, e + 1) end
			elseif KB:Down("z") and self._before_text then
				local before_text = self._before_text
				self._before_text = t
                text:set_text(before_text)
                self:check_changed()
	    	end
	    elseif shift() then
	  	    if KB:Down("left") then
				text:set_selection(s - 1, e)
			elseif KB:Down("right") then
				text:set_selection(s, e + 1)
			end
	    elseif self._key_pressed == Idstring("backspace") or self._key_pressed == Idstring("delete") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end

			if not (utf8.len(t) < 1) or type(self._esc_callback) ~= "number" then
                text:replace_text("")
                self:check_changed()
			end
		elseif k == Idstring("left") then
			if s < e then
				text:set_selection(s, s)
			elseif s > 0 then
				text:set_selection(s - 1, s - 1)
			end
		elseif k == Idstring("right") then
			if s < e then
				text:set_selection(e, e)
			elseif s < n then
				text:set_selection(s + 1, s + 1)
			end
		else
			self._key_pressed = nil
	    end
		self:_update_caret()
        if not first then
            first = true
            wait(0.5)
        end
	    wait(0.01)
  	end
end

function MenuItemColorButton:update_color_preview(row_item)
    if alive(self._color_preview) then
        self._color_preview:set_color(Color:from_hex(self._text:text()))
        self._text:set_x(self._color_preview:right() + 4)
    end
end

function MenuItemColorButton:_update_caret()
    if not alive(self._text) then
        return
    end
	local text = self._text
    local caret = self._caret
    self:update_color_preview()

    text:set_align("left")
    caret:set_size(2, text:font_size())

    local s, e = text:selection()
	local x, y = text:character_rect(self._select_neg and s or e)

    if s == 0 and e == 0 then
		caret:set_world_position(text:world_position())
	else
		caret:set_world_position(x, y)
	end
    caret:set_alpha(1)
    caret:set_visible(self._editing)
    caret:set_color(text:color():with_alpha(1))
end

function MenuItemColorButton:check_changed()
    if alive(self._text) and self._text:text() ~= self:input_text() then
        self:set_value(self._text:text())
        self:trigger()
    end
end

function MenuItemColorButton:enter_text(row_item, ...)
	if ctrl() then
		return
	end
    MenuItemColorButton.super.enter_text(self, row_item, ...)
    self:check_changed()
end

function MenuItemColorButton:key_press(row_item, o, k)
	if not row_item or not alive(row_item.gui_text) or not self._editing then
		return
	end

    local text = row_item.gui_text
	self._key_pressed = k

	text:stop()
	text:animate(ClassClbk(self, "update_key_down", row_item), k)

	if k == Idstring("insert") then
		local clipboard = Application:get_clipboard() or ""
		text:replace_text(clipboard)
		local lbs = text:line_breaks()
		if #lbs > 1 then
			local s = lbs[2]
			local e = utf8.len(text:text())
			text:set_selection(s, e)
			text:replace_text("")
		end
	elseif self._key_pressed == Idstring("end") then
		text:set_selection(n, n)
	elseif self._key_pressed == Idstring("home") then
		text:set_selection(0, 0)
	end

	self:_layout(row_item)
end

function MenuItemColorButton:mouse_moved(x,y)
    local text = self._text
    local ret = false
    if self._start_select and self._old_x then
        local i = text:point_to_index(x, y)
        local s, e = text:selection()
        local old = self._select_neg
        if self._select_neg == nil or (s == e) then
            self._select_neg = (x - self._old_x) < 0
        end
        if self._select_neg then
            text:set_selection(i - 1, self._start_select)
        else
            text:set_selection(self._start_select, i + 1)
        end
        self:_update_caret()
        ret = true
    elseif not self._panel:inside(x,y) then
        self:set_editing(false)
    end
    self._old_x = x
    return ret
end

function MenuItemColorButton:mouse_pressed(button, x, y)
    local text = self._text
    if self._editing then
        local i = text:point_to_index(x, y)
        self._start_select = i
        self._select_neg = nil
        text:set_selection(i, i)
        self:_update_caret()
        return true
    end
    return false
end

function MenuItemColorButton:mouse_released(button, x, y)
    self._start_select = nil
end