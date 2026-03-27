local ifpTable = ifpTable

local shaderWarn = false

ifpTable.mods = {
	{
		name = 'BodyCam Mod',

		att = 'forward',
		offset = Vector(5, 0, -5),
		angles = Angle(0, 0, 0),
		fov = 30,
		znear = 1,

		shaderFunc = function()
			if not render.DrawMercFisheye then
				if not shaderWarn then
					local frame = vgui.Create('DFrame')
					frame:SetTitle(language.GetPhrase('gmod_ifp.ui.shader_warn.title'))
					frame:SetSize(400, 160)
					frame:Center()
					frame:MakePopup()

					local label = vgui.Create('DLabel', frame)
					label:SetText(language.GetPhrase('gmod_ifp.ui.shader_warn.text'))
					label:SizeToContents()
					label:Dock(FILL)
					label:DockMargin(8, 4, 8, 4)

					local linkBtn = vgui.Create('DButton', frame)
					linkBtn:SetText(language.GetPhrase('gmod_ifp.ui.shader_warn.link'))
					linkBtn:Dock(BOTTOM)
					linkBtn:DockMargin(4, 4, 4, 4)
					linkBtn:SetTall(32)
					linkBtn:SetIcon('icon16/link.png')
					function linkBtn:DoClick()
						gui.OpenURL('https://steamcommunity.com/sharedfiles/filedetails/?id=3440271589')
					end

					shaderWarn = true
				end

				return
			end

			-- shaders from https://steamcommunity.com/sharedfiles/filedetails/?id=3440271589
			render.DrawMercFisheye(0.2)
			render.DrawMercVignette(0.9, 0.5)
		end,
	},
}
