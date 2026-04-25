local Vector = Vector
local Angle = Angle
local vgui = vgui
local language = language
local render = render

local cv_shaderWarn = CreateClientConVar('cl_ifp_shader_warn', '1')

local shaderWarn = false

local function shaderWarnMenu()

	local f = vgui.Create('DFrame')
	f:SetTitle(language.GetPhrase('gmod_ifp.ui.shader_warn.title'))
	f:SetSize(460, 180)
	f:Center()
	f:MakePopup()

	local l = vgui.Create('DLabel', f)
	l:SetText(language.GetPhrase('gmod_ifp.ui.shader_warn.text'))
	l:SizeToContents()
	l:Dock(FILL)
	l:DockMargin(8, 4, 8, 4)

	local c = vgui.Create('DCheckBoxLabel', f)
	c:SetText(language.GetPhrase('gmod_ifp.ui.shader_warn.donotshow'))
	c:SizeToContents()
	c:Dock(BOTTOM)
	c:DockMargin(8, 8, 0, 8)
	c:SetChecked(not cv_shaderWarn:GetBool())
	function c:OnChange(val)
		RunConsoleCommand(cv_shaderWarn:GetName(), val and '0' or '1')
	end

	local b = vgui.Create('DButton', f)
	b:SetText(language.GetPhrase('gmod_ifp.ui.shader_warn.link'))
	b:Dock(BOTTOM)
	b:DockMargin(4, 0, 4, 0)
	b:SetTall(28)
	b:SetIcon('icon16/link.png')
	function b:DoClick()
		gui.OpenURL('https://steamcommunity.com/sharedfiles/filedetails/?id=3440271589')
	end

end

ifpTable.mods = {

	-- example
	-- {
	-- 	name = 'example mod',
	-- 	att = 'eyes',
	-- 	useAttAngles = false,
	-- 	offset = Vector(0, 0, 0),
	-- 	angles = Angle(0, 0, 0),
	-- 	fov = 0,
	-- 	znear = 1.5,
	-- 	shaderFunc = function()
	-- 		-- custom shader func called by RenderScreenspaceEffects hook
	-- 	end,
	-- }

	{
		name = 'Full Immersion',
		useAttAngles = true,
	},

	{
		name = 'BodyCam Mod',
		att = 'forward',
		useAttAngles = true,
		offset = Vector(5, 0, -5),
		angles = Angle(0, 0, 0),
		fov = 30,
		znear = 1,
		shaderFunc = function()

			-- "simple custom shaders" addon check
			if not render.DrawMercFisheye then
				if not shaderWarn then
					if cv_shaderWarn:GetBool() then
						shaderWarnMenu()
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
