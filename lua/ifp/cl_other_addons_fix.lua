hook.Add('lrp-view.override', 'ifp.fix.arc9', function()

	local wep = LocalPlayer():GetActiveWeapon()

	-- disable view when arc9 customize menu opened
	if wep.ARC9 and wep.CustomizeHUD then
		return true
	end

end)
