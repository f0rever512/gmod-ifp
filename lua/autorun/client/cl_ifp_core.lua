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

local blackList = {
	weapon_physgun = true,
	gmod_tool = true,
	gmod_camera = true
}

hook.Add('lrp-view.override', 'ifp-disableView', function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()

	if (IsValid(wep) and blackList[wep:GetClass()] and not ply:InVehicle()) or not cv_viewEnabled:GetBool() then
		return true
	end
end)

local function hideHead(doHide)

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	if ply:InVehicle() or ply:GetViewEntity() ~= ply then
		doHide = false
	end

	local head = ply:LookupBone('ValveBiped.Bip01_Head1')
	ply:ManipulateBoneScale(head, doHide and Vector(0.01, 0.01, 0.01) or Vector(1, 1, 1))

end

local visualRecoil
local usingSight = true

local function calcView(ply, pos, ang, fov)

	local modIndex = cv_selectedMod:GetInt()
	local attName = ifpTable.mods[modIndex] and ifpTable.mods[modIndex].att or 'eyes'
	local viewAtt = ply:GetAttachment(ply:LookupAttachment(attName))

	if not IsValid(ply) or ply:GetViewEntity() ~= ply or not viewAtt then return end

	local wep = ply:GetActiveWeapon()

	if ply:Alive() then
		pos, ang = viewAtt.Pos, ang

		-- for lrp guns
		if IsValid(wep) and wep.Base == 'localrp_gun_base' and modIndex == 0 then

			local animIn = usingSight and wep:GetHoldType() == wep.Sight and wep:GetReady()
			local aimProgress = math.Approach(wep.aimProgress or 0, animIn and 1 or 0, FrameTime() * (animIn and 1.5 or 2.5))
			wep.aimProgress = aimProgress

			local recoilCoef = ply:IsListenServerHost() and 10 or 5
			visualRecoil = Lerp(FrameTime() * recoilCoef, visualRecoil or 0, wep.visualRecoil or 0)

			local handAtt = ply:GetAttachment(ply:LookupAttachment('anim_attachment_rh'))
			if not handAtt then return end

			local easedProgress = inOutQuad(aimProgress)

			local aimPos = Vector(wep.AimPos.x, wep.AimPos.y, wep.AimPos.z + wep.AimPos.z * visualRecoil / 5)

			local muzzleAng = wep:GetMuzzleAng()
			local aimAng = Angle(muzzleAng.p - (not wep.SightPos and (muzzleAng.p * visualRecoil * 2.5) or 0), muzzleAng.y, muzzleAng.r)

			wep.smoothHandAng = LerpAngle(0.5, wep.smoothHandAng or handAtt.Ang, handAtt.Ang)
			local worldVector, worldAngle = LocalToWorld(aimPos, aimAng, handAtt.Pos, wep.smoothHandAng)

			pos = LerpVector(easedProgress, pos, worldVector)
			ang = LerpAngle(easedProgress, ang, worldAngle)

		end
	else
		local ragdoll = ply:GetRagdollEntity()
		if not ragdoll or not IsValid(ragdoll) then return end

		local ragEyeAtt = ragdoll:GetAttachment(ragdoll:LookupAttachment('eyes'))
		pos, ang = ragEyeAtt.Pos, ragEyeAtt.Ang
	end

	local view = {
		origin = pos,
		angles = ang,
		fov = fov,
		znear = (wep.Base == 'localrp_gun_base' and wep.aimProgress >= 0.5) and 1.5 or 3,
		drawviewer = true,
	}

	if ifpTable.mods[modIndex] and modIndex > 0 and view and ply:Alive() then
		local mod = ifpTable.mods[modIndex]

		if mod.offset then
			local worldPos = LocalToWorld(mod.offset, Angle(), viewAtt.Pos, viewAtt.Ang)
			view.origin = worldPos
		end

		if mod.angles then
			local _, worldAng = LocalToWorld(Vector(), mod.angles, viewAtt.Pos, viewAtt.Ang)
			worldAng.r = 0
			view.angles = worldAng
		end

		if mod.fov then view.fov = view.fov + mod.fov end
		if mod.znear then view.znear = mod.znear end
	end

	return view

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

local function renderCrosshair()

	local ply = LocalPlayer()

	if ply:InVehicle() or not ply:Alive() or not cv_chEnabled:GetBool() or ply:GetViewEntity() ~= ply then return end

	if hook.Run('octolib.delay.chShouldDraw') then return end

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
	-- local n = tr.Hit and tr.HitNormal or -aim
	-- if math.abs(n.z) > 0.98 then
	-- 	n:Add(-aim * 0.01)
	-- end
	local chPos, chAng = LocalToWorld(chPosOff, chAngOff, tr.HitPos or endpos, ply:EyeAngles())
	cam.Start3D2D(chPos, chAng, math.pow(tr.Fraction, 0.6) * (_scale or 0.25))
	cam.IgnoreZ(true)
	if not hook.Run('lrp-view.chPaint', tr, _icon) then
		if _icon then
			surface.SetDrawColor(255,255,255, _alpha or 150)
		else
			local clrR, clrG, clrB = cv_chClrR:GetInt(), cv_chClrG:GetInt(), cv_chClrB:GetInt()
			surface.SetDrawColor(clrR, clrG, clrB, _alpha or 200)
		end
		surface.SetMaterial(chIcon)
		surface.DrawTexturedRect(-32, -32, 64, 64)
	end
	cam.IgnoreZ(false)
	cam.End3D2D()

end

local function applyShaders()

	local ply = LocalPlayer()
	if not IsValid(ply) or ply:GetViewEntity() ~= ply then return end

	local modIndex = cv_selectedMod:GetInt()
	if modIndex == 0 then return end

	local mod = ifpTable.mods[modIndex]
	if mod and mod.shaderFunc then mod.shaderFunc() end

end

local function lockViewAngle(cmd)

	local ply = LocalPlayer()

	if not cv_lockEnabled:GetBool() or not ply:Alive() or ply:GetViewEntity() ~= ply then return end

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

	if name ~= 'CHudCrosshair' then return end

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and blackList[wep:GetClass()] then
		return true
	end

	return false

end

local function blackScreen()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local eyeAtt = ply:GetAttachment(ply:LookupAttachment('eyes'))
	local handAtt = ply:GetAttachment(ply:LookupAttachment('anim_attachment_rh'))
	if not eyeAtt or not handAtt then return end

	if ply:GetViewEntity() == ply and ply:Alive() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
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
	if ply:InVehicle() or cv_selectedMod:GetInt() ~= 0 then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep.Base ~= 'localrp_gun_base' then return end

	if key == MOUSE_MIDDLE and wep:GetReady() then
		timer.Simple(0.2, function()
			usingSight = not usingSight
		end)
	end

	if key == MOUSE_RIGHT and usingSight then
		usingSight = false
		timer.Simple(0.25, function()
			usingSight = true
		end)
	end

end

local function enableView()

	hook.Add('CalcView', 'ifp-hook', calcView)
	hook.Add('PostDrawTranslucentRenderables', 'ifp-hook', renderCrosshair)
	hook.Add('RenderScreenspaceEffects', 'ifp-hook', applyShaders)
	hook.Add('CreateMove', 'ifp-hook', lockViewAngle)
	hook.Add('HUDShouldDraw', 'ifp-hook', hideDefCrosshair)
	hook.Add('PostDrawHUD', 'ifp-hook', blackScreen)
	hook.Add('PlayerButtonDown', 'ifp-hook', useSightKey)

	hideHead(true)

end

local function disableView()

	hook.Remove('CalcView', 'ifp-hook')
	hook.Remove('PostDrawTranslucentRenderables', 'ifp-hook')
	hook.Remove('RenderScreenspaceEffects', 'ifp-hook')
	hook.Remove('CreateMove', 'ifp-hook')
	hook.Remove('HUDShouldDraw', 'ifp-hook')
	hook.Remove('PostDrawHUD', 'ifp-hook')
	hook.Remove('PlayerButtonDown', 'ifp-hook')

	hideHead(false)

end

hook.Add('Think', 'ifp-override', function()

	local override = hook.Run('lrp-view.override') == true

	if override then
		disableView()
	elseif not override then
		enableView()
	end

end)
