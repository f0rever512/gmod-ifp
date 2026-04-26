local vgui = vgui
local pairs = pairs
local util = util
local language = language
local ifpMods = ifpTable.mods

surface.CreateFont( 'ifp-font.spawnMenu.label', {
	font = 'Calibri',
	size = 24,
	weight = 300,
	antialias = true,
	extended = true
} )

local function createMenu(pnl)

	pnl:Clear()

	local l = vgui.Create('DLabel')
	l:SetText(language.GetPhrase('gmod_ifp.options.label'))
	l:SetFont('ifp-font.spawnMenu.label')
	l:SetDark(true)
	l:SizeToContents()
	pnl:AddItem(l)

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.toggle'), 'cl_ifp_enable')

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.crosshair'), 'cl_ifp_crosshair_enabled')

	pnl:AddControl('color', {
		label = language.GetPhrase('gmod_ifp.options.crosshair_color'),
		red = 'cl_ifp_crosshair_color_r',
		green = 'cl_ifp_crosshair_color_g',
		blue = 'cl_ifp_crosshair_color_b'
	})

	pnl:NumSlider(language.GetPhrase('gmod_ifp.options.fov_multiplier'), 'cl_ifp_fov_multiplier', 0.75, 1.25, 2)

	local c = vgui.Create('DCheckBoxLabel')
	c:SetText(language.GetPhrase('gmod_ifp.options.lock_enable'))
	c:SetConVar('cl_ifp_lock_enabled')
	c:SetValue(GetConVar('cl_ifp_lock_enabled'):GetBool())
	c:SetDark(true)
	c:SizeToContents()
	pnl:AddItem(c)

	pnl:ControlHelp(language.GetPhrase('gmod_ifp.options.lock_enable_help'))

	local s = vgui.Create('DNumSlider')
	s:SetText(language.GetPhrase('gmod_ifp.options.lock_vertical'))
	s:SetConVar('cl_ifp_lock_vertical')
	s:SetDefaultValue(80)
	s:SetMin(75)
	s:SetMax(90)
	s:SetDecimals(0)
	s:SetDark(true)
	pnl:AddItem(s)

	pnl:ControlHelp(language.GetPhrase('gmod_ifp.options.lock_vertical_help'))

	function c:OnChange(val)
		s:SetEnabled(val)
	end

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.force_show_head'), 'cl_ifp_force_show_head')
	pnl:ControlHelp(language.GetPhrase('gmod_ifp.options.force_show_head_help'))

	local ifpModList = pnl:AddControl('listbox', {label = language.GetPhrase('gmod_ifp.options.mod_title')})
	ifpModList:SetSortItems(false)

	-- view mod disabled option
	ifpModList:AddOption(language.GetPhrase('gmod_ifp.options.mod_disabled'), {
		cl_ifp_mod = 0
	})

	-- other view mods from ifpTable.mods
	for id, data in pairs(ifpMods) do
		ifpModList:AddOption(data.name, {
			cl_ifp_mod = id
		})
	end

	local p = vgui.Create('DPanel')
	p:SetTall(16)
	function p:Paint() end
	pnl:AddItem(p)

	local l = vgui.Create('DLabel')
	l:SetText(language.GetPhrase('gmod_ifp.options.weapons_view.label'))
	l:SetFont('ifp-font.spawnMenu.label')
	l:SetDark(true)
	l:SizeToContents()
	pnl:AddItem(l)

	pnl:Help(language.GetPhrase('gmod_ifp.options.weapons_view.hint'))

	pnl:KeyBinder(language.GetPhrase('gmod_ifp.options.weapons_view.switch_aim_key'), 'cl_ifp_key_weapon_aim')
	pnl:ControlHelp(language.GetPhrase('gmod_ifp.options.weapons_view.switch_aim_key_help'))

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.weapons_view.disable_when_aim'), 'cl_ifp_disable_when_aim')
	pnl:ControlHelp(language.GetPhrase('gmod_ifp.options.weapons_view.disable_when_aim_help'))

	pnl:Button(language.GetPhrase('gmod_ifp.options.weapons_view.open_editor'), 'ifp_weapons_editor')

	local p = vgui.Create('DPanel')
	p:SetTall(16)
	function p:Paint() end
	pnl:AddItem(p)

	local l = vgui.Create('DLabel')
	l:SetText(language.GetPhrase('gmod_ifp.options.reset_title'))
	l:SetFont('ifp-font.spawnMenu.label')
	l:SetDark(true)
	l:SizeToContents()
	pnl:AddItem(l)

	pnl:Button(language.GetPhrase('gmod_ifp.options.reset_button'), 'ifp_reset_settings')

	local b = vgui.Create('DButton')
	b:SetText(language.GetPhrase('gmod_ifp.options.reset_button_table'))
	function b:DoClick()
		ifpTable.weaponsView = {}
		file.Write('ifp/weapons_view_data.json', util.TableToJSON(ifpTable.weaponsView))
	end
	pnl:AddItem(b)

end

hook.Add('PopulateToolMenu', 'ifp.createToolMenu', function()
	spawnmenu.AddToolMenuOption('Utilities', 'IFP', 'cl_ifp_settings', 'IFP Settings', nil, nil, createMenu)
end)

local defCVars = {
	['cl_ifp_crosshair_enabled'] = '1',
	['cl_ifp_crosshair_color_r'] = '255',
	['cl_ifp_crosshair_color_g'] = '255',
	['cl_ifp_crosshair_color_b'] = '255',
	['cl_ifp_fov_multiplier'] = '1.00',
	['cl_ifp_lock_enabled'] = '1',
	['cl_ifp_lock_vertical'] = '80',
	['cl_ifp_mod'] = '0',
	['cl_ifp_key_weapon_aim'] = MOUSE_MIDDLE,
	['cl_ifp_disable_when_aim'] = '1',
}

concommand.Add('ifp_reset_settings', function()
	for cvar, val in pairs(defCVars) do RunConsoleCommand(cvar, val) end
end)
