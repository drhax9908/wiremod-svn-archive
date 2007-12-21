AddCSLuaFile( "manifest.lua" )

include( "helpers.lua" )

if (SERVER) then include( "sv_wirestools.lua" ) end


include( "gates.lua" )
include( "display.lua" )

--include( ".lua" )


if (TOOL) then WireToolSetup.close() end
