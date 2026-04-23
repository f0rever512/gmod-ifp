surface.CreateFont( 'ifpFont.medium', {
	font = 'Calibri',
	size = 25,
	weight = 300,
	antialias = true,
	extended = true
} )

surface.CreateFont( 'ifpFont.small', {
	font = 'Calibri',
	size = 20,
	weight = 300,
	antialias = true,
	extended = true
} )

surface.CreateFont( 'ifpFont.tiny', {
	font = 'Calibri',
	size = 16,
	weight = 300,
	antialias = true,
	extended = true
} )

ifpTable.weaponsView = {

	-- example:
	-- ['weapon_class'] = {
	-- 	offset = { x = 0, y = 0, z = 0 },
	-- 	angles = { p = 0, y = 0, r = 0 },
	-- 	znear = 1.5
	-- },

}

local function saveData()
	local json = util.TableToJSON(ifpTable.weaponsView)
	file.Write('ifp/weapons_view_data.json', json)
end

local function loadData()
	if file.IsDir('ifp', 'DATA') then
		if file.Exists('ifp/weapons_view_data.json', 'DATA') then
			local json = file.Read('ifp/weapons_view_data.json', 'DATA')
			ifpTable.weaponsView = util.JSONToTable(json) or {}
		end
	else
		file.CreateDir('ifp')
		file.Write('ifp/weapons_view_data.json', '{}')
	end
end

hook.Add('Initialize', 'ifp.weapons-view.init', loadData)

local defWeaponData = {
	offset = { x = 0, y = 0, z = 0 },
	angles = { p = 0, y = 0, r = 0 },
	znear = 1.5,
}

local ifpWeaponsEditor

local function openWeaponsEditor()

	if IsValid(ifpWeaponsEditor) then ifpWeaponsEditor:Remove() end

	local f = vgui.Create('DFrame')
	f:SetTitle(language.GetPhrase('gmod_ifp.ui.weapons_editor.title'))
	f:SetSize(ScrW() * 0.5, ScrH() * 0.7)
	f:SetSizable(true)
	f:SetMinWidth(f:GetWide())
	f:SetMinHeight(f:GetTall())
	f:Center()
	f:MakePopup()
	ifpWeaponsEditor = f

	local screenScale = ScrW() >= 1600 and 1 or 0.7

	local leftPnl = vgui.Create('DPanel', f)
	leftPnl:Dock(LEFT)
	leftPnl:SetWide(320 * screenScale)
	function leftPnl:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, color_transparent)
	end

	local searchEntry = vgui.Create('DTextEntry', leftPnl)
	searchEntry:Dock(TOP)
	searchEntry:DockMargin(0, 0, 0, 4)
	searchEntry:SetTall(24)
	searchEntry:SetPlaceholderText(language.GetPhrase('spawnmenu.search'))

	local scrollPnl = vgui.Create('DScrollPanel', leftPnl)
	scrollPnl:Dock(FILL)

	local rightPnl = vgui.Create('DPanel', f)
	rightPnl:Dock(FILL)
	rightPnl:DockMargin(4, 0, 0, 0)
	rightPnl:DockPadding(0, 8, 0, 0)

	local hintL = vgui.Create('DLabel', rightPnl)
	hintL:SetText(language.GetPhrase('gmod_ifp.ui.weapons_editor.hint'))
	hintL:SetFont('ifpFont.medium')
	hintL:Dock(FILL)
	hintL:SetContentAlignment(5)
	hintL:SetDark(true)

	local editPnl = vgui.Create('DPanel', rightPnl)
	editPnl:Dock(FILL)
	editPnl.Paint = nil

	local function createNumSlider(parent, text, dock, margin, defValue, minValue, maxValue, callback)
		local s = vgui.Create('DNumSlider', parent)
		s:SetText(text and text or '')
		s:SetMin(minValue)
		s:SetMax(maxValue)
		if defValue then
			s:SetDefaultValue(defValue)
			s:SetValue(defValue)
		end
		s:SetDecimals(2)
		s:SetDark(true)

		if dock then s:Dock(dock) end
		if margin then s:DockMargin(unpack(margin)) end

		function s:OnValueChanged(val) callback(val) end

		return s
	end

	local selectedWeapon = nil

	local function populateEditPanel(wepClass)

		editPnl:Clear()
		hintL:Hide()

		local rScrollP = vgui.Create('DScrollPanel', editPnl)
		rScrollP:Dock(FILL)
		rScrollP:DockMargin(8, 8, 8, 8)

		local editL = vgui.Create('DLabel', rScrollP)
		editL:Dock(TOP)
		editL:SetTall(25)
		editL:SetText( string.format(language.GetPhrase('gmod_ifp.ui.weapons_editor.edit_panel.title'), wepClass) )
		editL:SetFont('ifpFont.medium')
		editL:DockMargin(0, 0, 0, 8)
		editL:SetDark(true)

		local offL = vgui.Create('DLabel', rScrollP)
		offL:Dock(TOP)
		offL:SetTall(20)
		offL:SetText('Offset:')
		offL:DockMargin(0, 8, 0, 4)
		offL:SetDark(true)

		local weaponData = table.Copy(ifpTable.weaponsView[wepClass] and ifpTable.weaponsView[wepClass] or defWeaponData)

		createNumSlider(rScrollP, 'X:', TOP, nil, weaponData.offset.x, -64, 64, function(val)
			weaponData.offset.x = val
		end)

		createNumSlider(rScrollP, 'Y:', TOP, nil, weaponData.offset.y, -64, 64, function(val)
			weaponData.offset.y = val
		end)

		createNumSlider(rScrollP, 'Z:', TOP, nil, weaponData.offset.z, -64, 64, function(val)
			weaponData.offset.z = val
		end)

		local angL = vgui.Create('DLabel', rScrollP)
		angL:Dock(TOP)
		angL:SetTall(20)
		angL:SetText('Angles:')
		angL:DockMargin(0, 12, 0, 4)
		angL:SetDark(true)

		createNumSlider(rScrollP, 'Pitch:', TOP, nil, weaponData.angles.p, -360, 360, function(val)
			weaponData.angles.p = val
		end)

		createNumSlider(rScrollP, 'Yaw:', TOP, nil, weaponData.angles.y, -360, 360, function(val)
			weaponData.angles.y = val
		end)

		createNumSlider(rScrollP, 'Roll:', TOP, nil, weaponData.angles.r, -360, 360, function(val)
			weaponData.angles.r = val
		end)

		local otherL = vgui.Create('DLabel', rScrollP)
		otherL:Dock(TOP)
		otherL:SetTall(20)
		otherL:SetText('Other:')
		otherL:DockMargin(0, 12, 0, 4)
		otherL:SetDark(true)

		createNumSlider(rScrollP, 'zNear:', TOP, nil, weaponData.znear, 0, 10, function(val)
			weaponData.znear = val
		end)

		local removeB = vgui.Create('DButton', editPnl)
		removeB:SetText(language.GetPhrase('gmod_ifp.ui.weapons_editor.edit_panel.remove'))
		removeB:Dock(BOTTOM)
		removeB:DockMargin(8, 8, 8, 8)
		removeB:SetTall(32)
		removeB:SetIcon('icon16/delete.png')
		function removeB:DoClick()
			ifpTable.weaponsView[wepClass] = nil
			saveData()

			editPnl:Clear()
			hintL:Show()
			selectedWeapon = nil
		end

		local saveB = vgui.Create('DButton', editPnl)
		saveB:SetText(language.GetPhrase('gmod_ifp.ui.weapons_editor.edit_panel.add'))
		saveB:Dock(BOTTOM)
		saveB:DockMargin(8, 0, 8, 0)
		saveB:SetTall(32)
		saveB:SetIcon('icon16/add.png')
		function saveB:DoClick()
			ifpTable.weaponsView[wepClass] = weaponData or defWeaponData
			saveData()
		end

	end

	local weaponsList = weapons.GetList()
	table.sort(weaponsList, function(a, b)
		return (a.PrintName or a.ClassName) < (b.PrintName or b.ClassName)
	end)

	local searchText = ''

	local function updateWeaponsList()
		searchText = string.lower(searchEntry:GetValue())
		scrollPnl:Clear()

		for _, wep in pairs(weaponsList) do

			if not wep.Spawnable or wep.Base == 'localrp_gun_base' then continue end

			local wepClass = wep.ClassName
			local wepName = wep.PrintName or wepClass

			if searchText ~= '' and not string.find(string.lower(wepClass), searchText, 1, true)
				and not string.find(string.lower(wepName), searchText, 1, true) then
				continue
			end

			local wepB = vgui.Create('DButton', scrollPnl)
			wepB:Dock(TOP)
			wepB:DockMargin(0, 1, 0, 1)
			wepB:SetTall(56)
			wepB:SetText('')

			function wepB:Paint(w, h)
				if ifpTable.weaponsView[wepClass] then
					draw.RoundedBox(4, 0, 0, w, h, Color(140, 220, 145))
				else
					draw.RoundedBox(4, 0, 0, w, h, Color(230, 160, 160))
				end

				if selectedWeapon == wepClass then
					draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 90))
				end
			end

			local icon = vgui.Create('DImage', wepB)
			icon:Dock(LEFT)
			icon:DockMargin(4, 4, 4, 4)
			icon:SetWide(48)
			icon:SetImage(wep.IconOverride or 'entities/' .. wepClass .. '.png', 'icon64/tool.png')

			local nameL = vgui.Create('DLabel', wepB)
			nameL:Dock(TOP)
			nameL:DockMargin(8, 8, 0, 0)
			nameL:SetText(wep.PrintName or wepClass)
			nameL:SetFont('ifpFont.small')
			nameL:SetTextColor(Color(0, 0, 0, 240))
			nameL:SizeToContents()

			local classL = vgui.Create('DLabel', wepB)
			classL:Dock(BOTTOM)
			classL:DockMargin(8, 0, 0, 8)
			classL:SetText(wepClass)
			classL:SetFont('ifpFont.tiny')
			classL:SetTextColor(Color(0, 0, 0, 220))
			classL:SizeToContents()

			function wepB:DoClick()
				selectedWeapon = wepClass
				populateEditPanel(wepClass)
			end

			function wepB:DoRightClick()
				if ifpTable.weaponsView[wepClass] then
					ifpTable.weaponsView[wepClass] = nil
					saveData()
				else
					ifpTable.weaponsView[wepClass] = defWeaponData
					saveData()
				end
			end

		end
	end

	updateWeaponsList()

	function searchEntry:OnTextChanged()
		updateWeaponsList()
	end

end

concommand.Add('ifp_weapons_editor', openWeaponsEditor)
