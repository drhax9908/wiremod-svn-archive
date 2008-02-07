AddCSLuaFile( "manifest.lua" )

if ( VERSION < 34 ) then
	Msg("Your GMod is out of date! Wire will not work on version: ",VERSION,"\n")
	return
end

include( "helpers.lua" )

if (SERVER) then include( "sv_wirestools.lua" ) end

include("gates.lua")
include("display.lua")
include("io.lua")
include("physics.lua")

if (TOOL) then WireToolSetup.close() end
