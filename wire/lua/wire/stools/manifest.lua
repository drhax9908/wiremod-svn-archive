AddCSLuaFile( "manifest.lua" )

if VERSION < 34 then
	MsgN("Your GMod is out of date! Wire will not work on version: ",VERSION)
	return
end
MsgN("Loading Wire Tools")
include( "helpers.lua" )

if SERVER then include( "sv_wirestools.lua" ) end

include("gates.lua")
include("detection.lua")
include("display.lua")
include("io.lua")
include("physics.lua")

if TOOL then WireToolSetup.close() end
