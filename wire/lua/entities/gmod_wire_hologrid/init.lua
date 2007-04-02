AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

// wire debug and overlay crap.
ENT.WireDebugName	= "Holographic Grid";
ENT.OverlayDelay 	= 0;

// init.
function ENT:Initialize( )
	// set model
	util.PrecacheModel( "models/jaanus/wiretool/wiretool_siren.mdl" );
	self.Entity:SetModel( "models/jaanus/wiretool/wiretool_siren.mdl" );
	
	// setup physics
	self.Entity:PhysicsInit( SOLID_VPHYSICS );
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS );
	self.Entity:SetSolid( SOLID_VPHYSICS );
end
