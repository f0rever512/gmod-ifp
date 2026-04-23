ifpTable = ifpTable or {}

local hook = hook
local util = util
local cam = cam
local surface = surface
local GetConVar = GetConVar
local math = math
local inOutQuad = math.ease.InOutQuad

-- immersive first person convars
local cv_viewEnabled = CreateClientConVar('cl_ifp_enable', '1')
local cv_chEnabled = CreateClientConVar('cl_ifp_crosshair_enabled', '1')
local cv_chClrR = CreateClientConVar('cl_ifp_crosshair_color_r', '255')
local cv_chClrG = CreateClientConVar('cl_ifp_crosshair_color_g', '255')
local cv_chClrB = CreateClientConVar('cl_ifp_crosshair_color_b', '255')
local cv_lockEnabled = CreateClientConVar('cl_ifp_lock_enabled', '1')
local cv_verticalLock = CreateClientConVar('cl_ifp_lock_vertical', '80', true, false, 'Vertical view angle lock', 75, 90)
local cv_selectedMod = CreateClientConVar('cl_ifp_mod', '0') -- set 0 for disable view mod
local cv_wepAimKey = CreateClientConVar('cl_ifp_key_weapon_aim', MOUSE_MIDDLE)
local cv_fovMultiplier = CreateClientConVar('cl_ifp_fov_multiplier', '1', true, false, 'Float multiplier view FOV', 0.75, 1.25)
local cv_disableWhenAiming = CreateClientConVar('cl_ifp_disable_when_aim', '0')

local blackList = {
	weapon_physgun = true,
	gmod_tool = true,
	gmod_camera = true
}

hook.Add('ifp.override', 'ifp-disableView', function()

	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()

	if (IsValid(wep) and blackList[wep:GetClass()] and not ply:InVehicle())
	or not cv_viewEnabled:GetBool() or ply:GetViewEntity() ~= ply then
		return true
	end

end)

concommand.Add('ifp_toggle', function()
	RunConsoleCommand(cv_viewEnabled:GetName(), cv_viewEnabled:GetBool() and '0' or '1')
end)

hook.Add('lrp-view.chShouldDraw', 'ifp-disableCh', function()
	local ply = LocalPlayer()
	if ply:InVehicle() or not ply:Alive() or not cv_chEnabled:GetBool()
		or ifpTable.aimingWithoutView then return false end
end)

local function mainCalcView(ply, pos, ang, fov)

	local modIndex = cv_selectedMod:GetInt()
	local attName = ifpTable.mods[modIndex] and ifpTable.mods[modIndex].att or 'eyes'

	local viewAtt

	if not ply:Alive() then
		local deathRag = ply:GetRagdollEntity()
		if not IsValid(deathRag) then return end

		viewAtt = deathRag:GetAttachment(deathRag:LookupAttachment(attName))
		if not viewAtt then return end

		pos, ang = viewAtt.Pos, viewAtt.Ang
	else
		viewAtt = ply:GetAttachment(ply:LookupAttachment(attName))
		if not viewAtt then return end

		pos = viewAtt.Pos
	end

	local view = {
		origin = pos,
		angles = ang,
		fov = fov * cv_fovMultiplier:GetFloat(),
		znear = 3,
		drawviewer = true,
	}

	-- apply view modifiers
	if ifpTable.mods[modIndex] and modIndex > 0 then
		local mod = ifpTable.mods[modIndex]

		if mod.offset then
			local worldPos = LocalToWorld(mod.offset, angle_zero, pos, viewAtt.Ang)
			view.origin = worldPos
		end

		if mod.angles then
			local _, worldAng = LocalToWorld(vector_origin, mod.angles,
				vector_origin, mod.useAttAngles and viewAtt.Ang or ang)

			if ply:Alive() then
				worldAng.r = 0
			end
			view.angles = worldAng
		end

		if mod.fov then view.fov = view.fov + mod.fov end
		if mod.znear then view.znear = mod.znear end
	end

	ifpTable.viewPos = view.origin

	return view

end

local usingSight = true
local smoothHandAng, visualRecoil

local function weaponCalcView(ply, pos, ang, fov)

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	local lrpWep = wep.Base == 'localrp_gun_base'
	local customWep = ifpTable.weaponsView[wep:GetClass()]

	if not lrpWep and not customWep then return end

	local useRecoil, animIn, aimPos, aimAng

	if lrpWep then
		if not wep.AimPos then return end
		useRecoil = true
		animIn = usingSight and wep:GetHoldType() == wep.Sight and wep:GetReady()
	else
		animIn = usingSight and ply:KeyDown(IN_ATTACK2)
	end

	local aimProgress = math.Approach(wep.aimProgress or 0, animIn and 1 or 0, FrameTime() * (animIn and 1 or 3))
	wep.aimProgress = aimProgress
	if aimProgress <= 0 then return end

	local viewAimingDisabled = cv_disableWhenAiming:GetBool() and not lrpWep
	ifpTable.aimingWithoutView = animIn and viewAimingDisabled

	local handAtt = ply:GetAttachment(ply:LookupAttachment('anim_attachment_rh'))
	if not handAtt and not viewAimingDisabled then return end

	if animIn then
		aimProgress = math.Clamp(aimProgress - 0.4, 0, 1) / 0.6
	end
	local easedProgress = inOutQuad(aimProgress)

	if useRecoil then
		local recoilCoef = ply:IsListenServerHost() and 10 or 5
		visualRecoil = Lerp(FrameTime() * recoilCoef, visualRecoil or 0, wep.visualRecoil or 0)
		aimPos = Vector(wep.AimPos.x, wep.AimPos.y, wep.AimPos.z + wep.AimPos.z * visualRecoil / 5)
		local muzzleAng = wep:GetMuzzleAng()
		aimAng = Angle(muzzleAng.p - (not wep.SightPos and (muzzleAng.p * visualRecoil * 2.5) or 0), muzzleAng.y, muzzleAng.r)
	else
		local wepOff = customWep.offset
		local wepAng = customWep.angles
		aimPos = wepOff and Vector(wepOff.x, wepOff.y, wepOff.z) or vector_origin
		aimAng = wepAng and Angle(wepAng.p, wepAng.y, wepAng.r) or angle_zero
	end

	local view = mainCalcView(ply, pos, ang, fov)
	if not view then return end

	local worldVector, worldAngle
	if not viewAimingDisabled then
		smoothHandAng = LerpAngle(0.5, smoothHandAng or handAtt.Ang, handAtt.Ang)
		worldVector, worldAngle = LocalToWorld(aimPos, aimAng, handAtt.Pos, smoothHandAng)
	else
		view.drawviewer = false
	end

	view.origin = LerpVector(easedProgress, view.origin, viewAimingDisabled and pos or worldVector)
	view.angles = LerpAngle(easedProgress, view.angles, viewAimingDisabled and ang or worldAngle)
	view.znear = customWep and customWep.znear or 1.5

	ifpTable.weaponViewActive = true
	ifpTable.viewPos = view.origin

	return view

end

local function calcView(ply, pos, ang, fov)

	local wep = ply:GetActiveWeapon()

	if IsValid(wep) and (wep.Base == 'localrp_gun_base' or ifpTable.weaponsView[wep:GetClass()]) then
		local view = weaponCalcView(ply, pos, ang, fov)
		if view then return view end
	end

	ifpTable.weaponViewActive = false

	return mainCalcView(ply, pos, ang, fov)

end

local function renderWeaponView(pos, ang, fov)

	local view = weaponCalcView(LocalPlayer(), pos, ang, fov)
	if not view then return end

	render.Clear(0, 0, 0, 255, true, true, true)
	render.RenderView({
		x				= 0,
		y				= 0,
		w				= ScrW(),
		h				= ScrH(),
		angles			= view.angles,
		origin			= view.origin,
		drawhud			= true,
		dopostprocess	= true,
		drawmonitors	= true,
	})

	return true

end

local function preDrawViewModel(_, _, wep)
	if ifpTable.weaponViewActive and wep.aimProgress <= 0.8 then return true end
end

local hl2weps = {
	weapon_357 = true,
	weapon_pistol = true,
	weapon_bugbait = true,
	weapon_crossbow = true,
	weapon_crowbar = true,
	weapon_frag = true,
	weapon_physcannon = true,
	weapon_ar2 = true,
	weapon_rpg = true,
	weapon_slam = true,
	weapon_shotgun = true,
	weapon_smg1 = true,
	weapon_stunstick = true
}

local chIcon = Material('materials/forever512/ifp_crosshair.png')
local chPosOff, chAngOff = Vector(0, 0, 0), Angle(0, -90, 90)

local function drawCrosshair()

	if hook.Run('octolib.delay.chShouldDraw') then return end

	local ply = LocalPlayer()

	local override = hook.Run('lrp-view.chShouldDraw', ply)
	if override == nil then
		local wep, veh = ply:GetActiveWeapon(), ply:GetVehicle()
		if IsValid(wep) and not blackList[wep:GetClass()] and ( wep.DrawCrosshair or hl2weps[wep:GetClass()] ) then
			override = not IsValid(veh) or ply:GetAllowWeaponsInVehicle()
		end
	end

	if not override then return end

	local aim = ply:EyeAngles():Forward()
	local tr = hook.Run('lrp-view.chTraceOverride')
	if not tr then
		local pos = ply:GetShootPos()
		local endpos = pos + aim * 1600
		tr = util.TraceLine({
			start = pos,
			endpos = endpos,
			filter = function(ent)
				return ent ~= ply and ent:GetRenderMode() ~= RENDERMODE_TRANSALPHA
			end
		})
	end

	local _icon, _alpha, _scale = hook.Run('lrp-view.chOverride', tr)
	local chPos, chAng = LocalToWorld(chPosOff, chAngOff, tr.HitPos or endpos, ply:EyeAngles())

	cam.Start3D2D(chPos, chAng, math.pow(tr.Fraction, 0.8) * (_scale or 0.25))
	cam.IgnoreZ(true)
	if not hook.Run('lrp-view.chPaint', tr, _icon) then
		if _icon then
			surface.SetDrawColor(255, 255, 255, _alpha or 150)
		else
			local clrR, clrG, clrB = cv_chClrR:GetInt(), cv_chClrG:GetInt(), cv_chClrB:GetInt()
			surface.SetDrawColor(clrR, clrG, clrB, _alpha or 200)
		end
		surface.SetMaterial(_icon or chIcon)
		surface.DrawTexturedRect(-32, -32, 64, 64)
	end
	cam.IgnoreZ(false)
	cam.End3D2D()

end

local function applyShaders()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local modIndex = cv_selectedMod:GetInt()
	if modIndex == 0 then return end

	local mod = ifpTable.mods[modIndex]
	if mod and mod.shaderFunc then mod.shaderFunc() end

end

local realAng, prevAng
local function lockViewAngle(cmd)

	local ply = LocalPlayer()
	if not cv_lockEnabled:GetBool() or not ply:Alive() then return end

	realAng = ply:EyeAngles()
	prevAng = realAng

	local vLock = cv_verticalLock:GetInt()

	realAng = realAng + cmd:GetViewAngles() - prevAng
	if ply:InVehicle() then
		realAng.y = realAng.y - 90
		realAng:Normalize()
		realAng.y = math.Clamp(realAng.y, -135, 135)
		realAng.p = math.Clamp(realAng.p, -50, 50*(1-(math.abs(realAng.y)/125)^2))
		local negate = realAng.y < 0
		realAng.y = realAng.y + 90
		realAng.r = (negate and -1 or 1) * (math.pow(realAng.y - 90, 2)) * (realAng.p - 0) / 28000
	else
		realAng.p = math.Clamp(realAng.p, -vLock, vLock)
		realAng.r = 0
	end
	realAng:Normalize()

	cmd:SetViewAngles(realAng)
	prevAng = cmd:GetViewAngles()

end

local function hideDefCrosshair(name)
	if name == 'CHudCrosshair' then return false end
end

local function blackScreen()

	local ply = LocalPlayer()
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP and not ply:InVehicle() then
		local trHit = util.TraceHull({
			maxs = Vector(5, 5, 3),
			mins = Vector(-5, -5, -3),
			start = ifpTable.viewPos,
			endpos = ifpTable.viewPos,
			filter = ply
		}).Hit

		if trHit then
			draw.RoundedBox(0, -1, -1, ScrW() + 1, ScrH() + 1, Color(0, 0, 0, 255))
		end
	end

end

local function useSightKey(ply, key)

	if not IsFirstTimePredicted() then return end

	if key == cv_wepAimKey:GetInt() then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and ( (wep.Base == 'localrp_gun_base' and wep:GetReady()) or ifpTable.weaponsView[wep:GetClass()] ) then
			usingSight = not usingSight
		end
	end

	if key == MOUSE_RIGHT and usingSight then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep.Base == 'localrp_gun_base' then
			usingSight = false
			timer.Simple(0.2, function()
				usingSight = true
			end)
		end
	end

end

local function hideHead(doHide)

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local head = ply:LookupBone('ValveBiped.Bip01_Head1')
	ply:ManipulateBoneScale(head, doHide and Vector(0.01, 0.01, 0.01) or Vector(1, 1, 1))

end

local function enableView()

	hook.Add('CalcView', 'ifp-hook', calcView)
	hook.Add('RenderScene', 'ifp-hook', renderWeaponView)
	hook.Add('PreDrawViewModel', 'ifp-hook', preDrawViewModel)
	hook.Add('PostDrawTranslucentRenderables', 'ifp-hook', drawCrosshair)
	hook.Add('RenderScreenspaceEffects', 'ifp-hook', applyShaders)
	hook.Add('CreateMove', 'ifp-hook', lockViewAngle)
	hook.Add('HUDShouldDraw', 'ifp-hook', hideDefCrosshair)
	hook.Add('PostDrawHUD', 'ifp-hook', blackScreen)
	hook.Add('PlayerButtonDown', 'ifp-hook', useSightKey)

	if ConVarExists('lrp_view') then
		hook.Remove('CalcView', 'lrp-view')
		hook.Remove('PostDrawTranslucentRenderables', 'lrp-view')
		hook.Remove('CreateMove', 'lrp-view')
		hook.Remove('HUDShouldDraw', 'lrp-view')
		hook.Remove('PostDrawHUD', 'lrp-view')
		hook.Remove('PlayerButtonDown', 'lrp-view')
	end

	hideHead(true)

	ifpTable.active = true
	ifpTable.aimingWithoutView = false

end

local function disableView()

	hook.Remove('CalcView', 'ifp-hook')
	hook.Remove('RenderScene', 'ifp-hook')
	hook.Remove('PreDrawViewModel', 'ifp-hook')
	hook.Remove('PostDrawTranslucentRenderables', 'ifp-hook')
	hook.Remove('RenderScreenspaceEffects', 'ifp-hook')
	hook.Remove('CreateMove', 'ifp-hook')
	hook.Remove('HUDShouldDraw', 'ifp-hook')
	hook.Remove('PostDrawHUD', 'ifp-hook')
	hook.Remove('PlayerButtonDown', 'ifp-hook')

	hideHead(false)

	ifpTable.active = false

end

hook.Add('Think', 'ifp-override', function()

	local override = hook.Run('ifp.override') == true

	if override and ifpTable.active then
		disableView()
	elseif not override and not ifpTable.active then
		enableView()
	end

end)
