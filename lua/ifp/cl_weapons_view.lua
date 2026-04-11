surface.CreateFont( 'ifpFont.medium', {
    font = 'Calibri',
    size = 25,
    weight = 300,
    antialias = true,
    extended = true
} )

ifpTable.weaponsView = {

	-- example:
	-- ['weapon_class'] = {
	-- 	offset = Vector(0, 0, 0),
	-- 	angles = Angle(0, 0, 0),
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
	offset = Vector(0, 0, 0),
	angles = Angle(0, 0, 0),
	znear = 1.5,
}

local function openWeaponsEditor(ply)

	if not IsValid(ply) then return end

	local scale = ScrW() >= 1600 and 1 or 0.7

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

	local leftPnl = vgui.Create('DPanel', f)
    leftPnl:Dock(LEFT)
    leftPnl:SetWide(320 * scale)
	function leftPnl:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, color_transparent)
	end

	local searchEntry = vgui.Create('DTextEntry', leftPnl)
	searchEntry:Dock(TOP)
	searchEntry:DockMargin(0, 0, 0, 4)
	searchEntry:SetTall(24)
	searchEntry:SetPlaceholderText(language.GetPhrase('gmod_ifp.ui.weapons_editor.search'))

	local scrollPnl = vgui.Create('DScrollPanel', leftPnl)
	scrollPnl:Dock(FILL)

	local weaponsList = weapons.GetList()
	table.sort(weaponsList, function(a, b)
		return (a.PrintName or a.ClassName) < (b.PrintName or b.ClassName)
	end)

	local selectedWeapon = nil
	local searchText = ''

	local function updateWeaponsList()
		searchText = string.lower(searchEntry:GetValue())
		scrollPnl:Clear()

		for _, wep in pairs(weaponsList) do
			if not wep.Spawnable then continue end

			local wepClass = wep.ClassName
			local wepName = wep.PrintName or wepClass

			if searchText ~= '' and not string.find(string.lower(wepName), searchText, 1, true) then
				continue
			end

			local btn = vgui.Create('DButton', scrollPnl)
			btn:Dock(TOP)
			btn:DockMargin(0, 1, 0, 1)
			btn:SetTall(56)
			btn:SetText(wep.PrintName or wepClass)

			local defButton = vgui.GetControlTable('DButton').Paint
			function btn:Paint(w, h)
				if selectedWeapon == wepClass then
					draw.RoundedBox(8, 0, 0, w, h, Color(10, 135, 80))
				else
					defButton(self, w, h)
				end
			end

			local icon = vgui.Create('DImage', btn)
			icon:Dock(LEFT)
			icon:DockMargin(4, 4, 4, 4)
			icon:SetWide(48)
			icon:SetImage(wep.IconOverride or 'entities/' .. wepClass .. '.png', 'icon64/tool.png')

			function btn:DoClick()
				selectedWeapon = wepClass
			end
		end
	end

	updateWeaponsList()

	function searchEntry:OnTextChanged()
		updateWeaponsList()
	end

	local rightPnl = vgui.Create('DPanel', f)
    rightPnl:Dock(FILL)
    rightPnl:DockMargin(4, 0, 0, 0)
    rightPnl:DockPadding(0, 8, 0, 0)

	local selectHint = vgui.Create('DLabel', rightPnl)
    selectHint:SetText(language.GetPhrase('gmod_ifp.ui.weapons_editor.choose'))
    selectHint:SetFont('ifpFont.medium')
    selectHint:Dock(FILL)
    selectHint:SetContentAlignment(5)

	local editPnl = vgui.Create('DScrollPanel', rightPnl)
    editPnl:Dock(FILL)

end

concommand.Add('ifp_weapons_editor', openWeaponsEditor)
