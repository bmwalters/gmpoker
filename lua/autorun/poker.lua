poker = {}

color_red = color_red or COLOR_RED or Color(255, 0, 0)
color_green = color_green or COLOR_GREEN or Color(0, 255, 0)
color_blue = color_blue or COLOR_BLUE or Color(0, 0, 255)

if SERVER then
	AddCSLuaFile("poker/shared.lua")
	AddCSLuaFile("poker/znumslider.lua")
	AddCSLuaFile("poker/cl_poker.lua")

	include("poker/shared.lua")
	include("poker/sv_poker.lua")

	resource.AddWorkshop("194833894") -- map
	resource.AddWorkshop("109761816") -- pnati1 pack (used?)
	resource.AddWorkshop("406836173") -- custom stuff (TEMPORARY)
	resource.AddFile("resource/fonts/bello-script.ttf")
	resource.AddFile("resource/fonts/bello-smcp.ttf")
	resource.AddFile("resource/fonts/futura-lt-condensed-bold.ttf")
	resource.AddFile("resource/fonts/futura-lt-condensed-extra-bold.ttf")
	resource.AddFile("resource/fonts/fundamental-brigade-schwer.ttf")
else
	include("poker/shared.lua")
	include("poker/znumslider.lua")
	include("poker/cl_poker.lua")
end
