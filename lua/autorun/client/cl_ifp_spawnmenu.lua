local language = language
local ifpMods = ifpTable.mods

local function createMenu(pnl)

	pnl:Clear()

	pnl:Help(language.GetPhrase('gmod_ifp.options.label'))

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.toggle'), 'cl_ifp_enable')

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.lock_toggle'), 'cl_ifp_lock_enabled')

	pnl:NumSlider(language.GetPhrase('gmod_ifp.options.lock_max'), 'cl_ifp_lock_max', 75, 90, 0)

	pnl:CheckBox(language.GetPhrase('gmod_ifp.options.crosshair'), 'cl_ifp_crosshair_enabled')

	pnl:AddControl('color', {
		label = language.GetPhrase('gmod_ifp.options.crosshair_color'),
		red = 'cl_ifp_crosshair_color_r',
		green = 'cl_ifp_crosshair_color_g',
		blue = 'cl_ifp_crosshair_color_b'
	})

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

end

hook.Add('PopulateToolMenu', 'ifp.createToolMenu', function()
	spawnmenu.AddToolMenuOption('Utilities', 'IFP', 'cl_ifp_options', 'IFP Options', nil, nil, createMenu)
end)
