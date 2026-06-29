local cv_glideFix = CreateClientConVar('cl_ifp_glide_fix', '1')

local glideFunc

hook.Add('Initialize', 'ifp.glideFunc.init', function()
	glideFunc = hook.GetTable()['UpdateAnimation']['Glide.OverridePlayerAnim']
end)

local function applyGlideFix()

	local ply = LocalPlayer()
	local veh = ply:GetVehicle()

	if GetConVar('cl_ifp_enable'):GetBool() and cv_glideFix:GetBool() and IsValid(veh) then

		ifpTable.hideHead(true)

		if Glide and Glide.Camera then
			Glide.Camera:Shutdown()
			ply:SetEyeAngles(Angle(0, 90, 0))

			-- remove original hook
			hook.Remove('UpdateAnimation', 'Glide.OverridePlayerAnim')

			-- add original glide hook without head angle fix
			hook.Add( "UpdateAnimation", "Glide.OverridePlayerAnim", function( ply )
				local vehicle = ply:GlideGetVehicle()
				if not IsValid( vehicle ) then return end
				if not vehicle.UpdatePlayerPoseParameters then return end

				-- Workarond to fix head angles
				-- if CLIENT then
				-- 	local parent = ply:GetParent()

				-- 	if IsValid( parent ) then
				-- 		local ang = parent:WorldToLocalAngles( ply:EyeAngles() )

				-- 		-- For other clients, EyeAngles seems to have
				-- 		-- "local-to-world" applied twice somehow
				-- 		if ply ~= LocalPlayer() then
				-- 			ang = parent:WorldToLocalAngles( ang )
				-- 		end

				-- 		ang[2] = NormalizeAngle( ang[2] - 90 )

				-- 		ply:SetPoseParameter( "head_pitch", ang[1] )
				-- 		ply:SetPoseParameter( "head_yaw", ang[2] )
				-- 	end
				-- end

				local updated = vehicle:UpdatePlayerPoseParameters( ply )

				if updated then
					GAMEMODE:GrabEarAnimation( ply )

					if CLIENT then
						GAMEMODE:MouthMoveAnimation( ply )
					end
				end

				return false
			end )
		end

	else

		if glideFunc then
			hook.Remove('UpdateAnimation', 'Glide.OverridePlayerAnim')
			hook.Add('UpdateAnimation', 'Glide.OverridePlayerAnim', glideFunc)
		end

		if IsValid(veh) then
			ifpTable.hideHead(false)
			Glide.Camera:Initialize(ply, veh:GetParent(), ply:GlideGetSeatIndex())
		end

	end

end

hook.Add('Glide_OnLocalEnterVehicle', 'ifp.fix.glide-camera', function()
	applyGlideFix()
end)

cvars.AddChangeCallback('cl_ifp_glide_fix', function()
	applyGlideFix()
end)

cvars.AddChangeCallback('cl_ifp_enable', function()
	applyGlideFix()
end)
