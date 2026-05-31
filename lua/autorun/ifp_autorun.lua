local AddCSLuaFile = AddCSLuaFile
local resource = resource
local include = include

if SERVER then

	-- client files
	AddCSLuaFile('ifp/cl_core.lua')
	AddCSLuaFile('ifp/cl_glide_camera_fix.lua')
	AddCSLuaFile('ifp/cl_modifiers.lua')
	AddCSLuaFile('ifp/cl_options_menu.lua')
	AddCSLuaFile('ifp/cl_other_addons_fix.lua')
	AddCSLuaFile('ifp/cl_weapons_view.lua')

	-- load localization files
	resource.AddSingleFile('resource/localization/en/gmod_ifp.properties')
	resource.AddSingleFile('resource/localization/ru/gmod_ifp.properties')

else

	-- client files
	include('ifp/cl_core.lua')
	include('ifp/cl_glide_camera_fix.lua')
	include('ifp/cl_modifiers.lua')
	include('ifp/cl_options_menu.lua')
	include('ifp/cl_other_addons_fix.lua')
	include('ifp/cl_weapons_view.lua')

end
