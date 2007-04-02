AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

// wire debug and overlay crap.
ENT.WireDebugName	= "Holographic Emitter"
ENT.OverlayDelay 	= 0;

// init.
function ENT:Initialize( )
	// set model
	util.PrecacheModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	self.Entity:SetModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	
	// setup physics
	self.Entity:PhysicsInit( SOLID_VPHYSICS );
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS );
	self.Entity:SetSolid( SOLID_VPHYSICS );
	
	// vars
	self.Entity:SetNetworkedFloat( "X", 0 );
	self.Entity:SetNetworkedFloat( "Y", 0 );
	self.Entity:SetNetworkedFloat( "Z", 0 );
	self.Entity:SetNetworkedFloat( "Lifetime", 0.2 );
	self.Entity:SetNetworkedBool( "Display", false );
	self.Entity:SetNetworkedEntity( "grid", self.Entity );

	// create inputs.
	self.Inputs = Wire_CreateInputs( self.Entity, { "X", "Y", "Z", "Display", "Lifetime" } );
end

// link to grid
function ENT:LinkToGrid( ent )
	self.Entity:SetNetworkedEntity( "grid", ent );
end

// trigger input
function ENT:TriggerInput( inputname, value, iter )
	// store values.
	if( inputname == "Display" ) then
		self.Entity:SetNetworkedBool( "Display", value > 0 );
		
	// store float values.
	else
		self.Entity:SetNetworkedFloat( inputname, value );
	end
end
