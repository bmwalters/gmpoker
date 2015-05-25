// Made originally by http://steamcommunity.com/profiles/76561198014909945 on http://steamcommunity.com/sharedfiles/filedetails/?id=109761816
// Edited/Recompiled by Zerf (http://steamcommunity.com/profiles/76561198052589582)

$modelname "gmpoker\chair.mdl"

$staticprop

$body "Body" "tychochair_reference.smd"

$cdmaterials "models\pnati\maxchair\"

$surfaceprop "Wood_Furniture"

$contents "solid"

$attachment "vehicle_feet_passenger0" "static_prop" 2.50 -9.00 25.50 rotate 0 -90 0
$attachment "enter1" "static_prop" 2.50 -25.00 30.00 rotate 0 -90 0
$attachment "vehicle_driver_eyes" "static_prop" 2.50 -9.00 50.00 rotate 0 -90 0
$attachment "exit1" "static_prop" 2.50 -25.00 30.00 rotate 0 -90 0

// $hboxset "default"

// NOTE: The following commented-out $definebone lines might be needed, as is often the case for view models. When needed, simply remove the two slashes '//' from the start of each line.
// $definebone "SMDImport" "" 0 0 0 0 0 0 0 0 0 0 0 0

$sequence "idle" "tychochair_reference.smd"

$collisionmodel "tychochair_physics.smd"
{
	$mass 10
	$inertia 1
	$damping 0
	$rotdamping 0
	$concave
}


$keyvalues
{
	prop_data
	{
		"base" "Wooden.Medium"
	}
}
