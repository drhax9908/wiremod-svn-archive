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

	// vars
	self.Entity:SetNetworkedBool( "UseGPS", false );
	self.usesgps = 0

	// create inputs.
	self.Inputs = Wire_CreateInputs( self.Entity, { "UseGPS" } );
	
end

function ENT:Think()
	if self.usesgps == 0 then
		self:SetOverlayText( "Holo Grid\n(Local)" )
	else
		self:SetOverlayText( "Holo Grid\n(GPS)" )
	end
end


// trigger input
function ENT:TriggerInput( inputname, value, iter )
	// store values.
	if( inputname == "UseGPS" ) then
		if not (value == 0) then value = 1 end
		self.Entity:SetNetworkedBool( "UseGPS", value > 0 );
		self.usesgps = value
	end
end


function ENT:AcceptInput(name,activator,caller)
	if name == "Use" and caller:IsPlayer() and caller:KeyDownLast(IN_USE) == false then
		if ( self.usesgps == 0 ) then
			self.usesgps = 1
		else
			self.usesgps = 0
		end
		self.Entity:SetNetworkedBool( "UseGPS", self.usesgps > 0 );
	end
end
