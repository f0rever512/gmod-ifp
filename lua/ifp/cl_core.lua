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
local cv_maxLock = CreateClientConVar('cl_ifp_lock_max', '80')
local cv_selectedMod = CreateClientConVar('cl_ifp_mod', '0') -- set 0 for disable view mod
local cv_wepAimKey = CreateClientConVar('cl_ifp_key_weapon_aim', MOUSE_MIDDLE)

local blackList = {
	weapon_physgun = true,
	gmod_tool = true,
	gmod_camera = true
}

hook.Add('lrp-view.override', 'ifp-disableView', function()

	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()

	if (IsValid(wep) and blackList[wep:GetClass()] and not ply:InVehicle())
	or not cv_viewEnabled:GetBool() or ply:GetViewEntity() ~= ply then
		return true
	end

end)

hook.Add('lrp-view.chShouldDraw', 'ifp-disableCh', function()
	local ply = LocalPlayer()
	if ply:InVehicle() or not ply:Alive() or not cv_chEnabled:GetBool() then return false end
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
		fov = fov,
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

	return view

end

local usingSight = true

ifpTable.customWepView = {

	-- example:
	-- ['weapon_class'] = {
	-- 	offset = Vector(0, 0, 0),
	-- 	angles = Angle(0, 0, 0),
	-- 	znear = 1.5
	-- }

}

local function weaponCalcView(ply, pos, ang, fov)

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	local lrpWep = wep.Base == 'localrp_gun_base'
	local customWep = ifpTable.customWepView[wep:GetClass()]

	if not lrpWep and not customWep then return end

	local useRecoil, animIn, visualRecoil, smoothHandAng, aimPos, aimAng

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

	local handAtt = ply:GetAttachment(ply:LookupAttachment('anim_attachment_rh'))
	if not handAtt then return end

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
		aimPos = customWep.offset or Vector()
		aimAng = customWep.angles or Angle()
	end

	local view = mainCalcView(ply, pos, ang, fov)
	smoothHandAng = LerpAngle(0.5, smoothHandAng or handAtt.Ang, handAtt.Ang)
	local worldVector, worldAngle = LocalToWorld(aimPos, aimAng, handAtt.Pos, smoothHandAng)

	view.origin = LerpVector(easedProgress, view.origin, worldVector)
	view.angles = LerpAngle(easedProgress, view.angles, worldAngle)
	view.znear = 1.5

	return view

end

local function calcView(ply, pos, ang, fov)

	local wep = ply:GetActiveWeapon()

	if IsValid(wep) and (wep.Base == 'localrp_gun_base' or ifpTable.customWepView[wep:GetClass()]) then
		local view = weaponCalcView(ply, pos, ang, fov)
		if view then return view end
	end

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
		drawviewmodel	= false,
		dopostprocess	= true,
		drawmonitors	= true,
	})

	return true

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

local function lockViewAngle(cmd)

	local ply = LocalPlayer()

	if not cv_lockEnabled:GetBool() or not ply:Alive() then return end

	local down = math.Clamp(-cv_maxLock:GetInt() + 5, -90, -70)
	local up = math.Clamp(cv_maxLock:GetInt(), 75, 90)

	local viewAng = cmd:GetViewAngles()

	if ply:InVehicle() then
		cmd:SetViewAngles(Angle(math.min(math.max(viewAng.p, down+40), up-40), math.min(math.max(viewAng.y, 10), 170), viewAng.r))
	else
		cmd:SetViewAngles(Angle(math.min(math.max(viewAng.p, down), up), viewAng.y, viewAng.r))
	end

end

local function hideDefCrosshair(name)
	if name == 'CHudCrosshair' then return false end
end

local function blackScreen()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local eyeAtt = ply:GetAttachment(ply:LookupAttachment('eyes'))
	local handAtt = ply:GetAttachment(ply:LookupAttachment('anim_attachment_rh'))
	if not eyeAtt or not handAtt then return end

	if ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		local wep = ply:GetActiveWeapon()
		local inSight = IsValid(wep) and wep.Base == 'localrp_gun_base' and wep.aimProgress >= 0.5

		local hullTrace = util.TraceHull({
			maxs = Vector(5, 5, 3),
			mins = Vector(-5, -5, -3),
			start = inSight and handAtt.Pos or eyeAtt.Pos,
			endpos = inSight and handAtt.Pos or eyeAtt.Pos
		})

		if hullTrace.Hit and hullTrace.Entity:GetClass() ~= 'player' and hullTrace.Entity:GetClass() ~= 'gmod_sent_vehicle_fphysics_base' then
			draw.RoundedBox(0, -1, -1, ScrW() + 1, ScrH() + 1, Color(0, 0, 0, 255))
		end
	end

end

local function useSightKey(ply, key)

	if not IsFirstTimePredicted() then return end

	if key == cv_wepAimKey:GetInt() then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and ( (wep.Base == 'localrp_gun_base' and wep:GetReady()) or ifpTable.customWepView[wep:GetClass()] ) then
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

	if ply:InVehicle() then doHide = false end

	local head = ply:LookupBone('ValveBiped.Bip01_Head1')
	ply:ManipulateBoneScale(head, doHide and Vector(0.01, 0.01, 0.01) or Vector(1, 1, 1))

end

local function enableView()

	hook.Add('CalcView', 'ifp-hook', calcView)
	hook.Add('RenderScene', 'ifp-hook', renderWeaponView)
	hook.Add('PostDrawTranslucentRenderables', 'ifp-hook', drawCrosshair)
	hook.Add('RenderScreenspaceEffects', 'ifp-hook', applyShaders)
	hook.Add('CreateMove', 'ifp-hook', lockViewAngle)
	hook.Add('HUDShouldDraw', 'ifp-hook', hideDefCrosshair)
	hook.Add('PostDrawHUD', 'ifp-hook', blackScreen)
	hook.Add('PlayerButtonDown', 'ifp-hook', useSightKey)

	hideHead(true)

	ifpTable.active = true

end

local function disableView()

	hook.Remove('CalcView', 'ifp-hook')
	hook.Remove('RenderScene', 'ifp-hook')
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

	local override = hook.Run('lrp-view.override') == true

	if override and ifpTable.active then
		disableView()
	elseif not override and not ifpTable.active then
		enableView()
	end

end)
