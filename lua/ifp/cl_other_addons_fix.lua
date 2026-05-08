local hook = hook
local LocalPlayer = LocalPlayer

hook.Add('ifp.override', 'ifp.fix.arc9', function()

	local wep = LocalPlayer():GetActiveWeapon()

	-- disable view when arc9 customize menu opened
	if wep.ARC9 and wep.CustomizeHUD then
		return true
	end

end)

-- RagMod Reworked
hook.Add('ifp.override', 'ifp.fix.ragMod', function()
	if ragmod and ragmod:IsRagdoll(LocalPlayer()) then return true end
end)

hook.Add('Initialize', 'ifp.fix.remove-lrp-hooks', function()
	-- remove localrp guns RenderScene hook
	hook.Remove('RenderScene', 'lrp-guns')
end)

hook.Add('InitPostEntity', 'ifp.warning.lrp-view', function()
	if not ConVarExists('lrp_view') then return end
	LocalPlayer():PrintMessage(HUD_PRINTTALK, language.GetPhrase('gmod_ifp.warning.lrp_view_conflict'))
end)
