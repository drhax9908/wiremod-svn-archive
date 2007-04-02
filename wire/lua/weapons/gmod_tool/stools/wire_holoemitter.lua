TOOL.Category		= "Wire - Holography";
TOOL.Name		= "Emitter";
TOOL.Command		= nil;
TOOL.ConfigName		= "";

// add language
if( CLIENT ) then
	language.Add( "Tool_wire_holoemitter_name", "Holographic Emitter Tool (Wire)" );
	language.Add( "Tool_wire_holoemitter_desc", "The emitter required for holographic projections" );
	language.Add( "Tool_wire_holoemitter_0", "Primary: Create emitter      Secondary: Link emitter" );
	language.Add( "Tool_wire_holoemitter_1", "Select the emitter point to link to." );
	language.Add( "undone_holoemitter", "Undone Wire Holoemitter" );
	language.Add( "sboxlimit_wire_holoemitters", "You've hit the holoemitters limit!" );
end


// max emitters
if( SERVER ) then CreateConVar( "sbox_maxwire_holoemitters", 30 ); end


// client convars.
TOOL.ClientConVar["r"]	= "255";
TOOL.ClientConVar["g"]	= "255";
TOOL.ClientConVar["b"]	= "255";
TOOL.ClientConVar["a"]	= "255";

// tool data.
TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl";	// models/jaanus/wiretool/wiretool_siren.mdl
TOOL.Emitter = nil;

// create a cleanup.
cleanup.Register( "wire_holoemitters" );


// primary fire.
function TOOL:LeftClick( tr )
	// some checks
	if( tr.HitNonWorld && tr.Entity:IsPlayer() ) then return false; end
	if( CLIENT ) then return true; end
	
	// fetch vars
	local pl = self:GetOwner();
	local r = self:GetClientNumber( "r" );
	local g = self:GetClientNumber( "g" );
	local b = self:GetClientNumber( "b" );
	local a = self:GetClientNumber( "a" );
	
	// did we hit another holoemitter?
	if( tr.HitNonWorld && tr.Entity:GetClass() == "gmod_wire_holoemitter" ) then
		// update it.
		tr.Entity:SetColor( r, g, b, a );
		
		//
		return true;
	end

	// we linking?
	if( self.Emitter && self.Emitter:IsValid() ) then
		// link to this point.
		if( tr.HitNonWorld && tr.Entity:IsValid() && tr.Entity:GetClass() == "gmod_wire_hologrid" ) then
			// link.
			self.Emitter:LinkToGrid( tr.Entity );
			
			// reset selected emitter
			self.Emitter = nil;
			
			//
			return true;
		else
			// prevent effects
			return false;
		end
	end
	
	// create a holo emitter.
	if( !self:GetSWEP():CheckLimit( "wire_holoemitters" ) ) then return false; end
	
	// fix angle
	local ang = tr.HitNormal:Angle();
	ang.p = ang.p + 90;
	
	// create emitter
	local emitter = MakeWireHoloemitter( pl, tr.HitPos, ang, r, g, b, a );
	
	// pull it out of the spawn point
	local mins = emitter:OBBMins();
	emitter:SetPos( tr.HitPos + tr.HitNormal * -mins.z );
	
	// weld
	local constraintEntity = WireLib.Weld( emitter, tr.Entity, tr.PhysicsBone, true );
	
	// create undo
	undo.Create( "holoemitter" );
		undo.AddEntity( emitter );
		undo.AddEntity( constraintEntity );
		undo.SetPlayer( pl );
	undo.Finish();
	
	// create cleanup
	pl:AddCleanup( "wire_holoemitters", emitter );
	pl:AddCleanup( "wire_holoemitters", constraintEntity );
	
	//
	return true;
end


// secondary fire.
function TOOL:RightClick( tr )
	// some checks
	if( !tr.HitNonWorld || tr.Entity:GetClass() != "gmod_wire_holoemitter" ) then return false; end
	if( CLIENT ) then return true; end
	
	// select emitter.
	self.Emitter = tr.Entity;
	
	//
	return true;
end


// creation code
if( SERVER ) then
	// make emitter
	function MakeWireHoloemitter( pl, pos, ang, r, g, b, a )
		// check the players limit
		if( !pl:CheckLimit( "wire_holoemitters" ) ) then return; end
		
		// create the emitter
		local emitter = ents.Create( "gmod_wire_holoemitter" );
			emitter:SetPos( pos );
			emitter:SetPos( ang );
		emitter:Spawn();
		emitter:Activate();
		
		// setup the emitter.
		emitter:SetColor( r, g, b, a );
		emitter:SetPlayer( pl );
		
		// store the color on the table.
		local tbl = {
			r = r,
			g = g,
			b = b,
			a = a,
		};
		table.Merge( emitter:GetTable(), tbl );
		
		// add to the players count
		pl:AddCount( "wire_holoemitters", emitter );
		
		//
		return emitter;
	end
	
	// register with duplicator
	duplicator.RegisterEntityClass(
		"gmod_wire_holoemitter",
		MakeWireHoloemitter,
		"Pos",
		"Ang",
		"r", "g", "b", "a"
	);

end


// update ghost.
function TOOL:UpdateGhostWireHoloemitter( ent, pl )
	// invalid entity?
	if( !ent || !ent:IsValid() ) then return; end
	
	// figure out where it will end up.
	local trace = utilx.GetPlayerTrace( pl, pl:GetCursorAimVector() );
	local tr = util.TraceLine( trace );
	
	// should we show a preview?
	if( !tr.Hit || ( tr.HitNonWorld && ( tr.Entity:GetClass() == "gmod_wire_holoemitter" || tr.Entity:GetClass() == "gmod_wire_hologrid" ) ) ) then
		ent:SetNoDraw( true );
		return;
	end
	
	// fix angle
	local ang = tr.HitNormal:Angle();
	ang.p = ang.p + 90;
	ent:SetAngles( ang );
	
	// pull out of position.
	local mins = ent:OBBMins();
	ent:SetPos( tr.HitPos + tr.HitNormal * -mins.z );
	
	// render
	ent:SetNoDraw( false );
end


// tool think
function TOOL:Think( )
	// create a ghost if we dont' have one.
	if( !self.GhostEntity || !self.GhostEntity:IsValid() ) then
		self:MakeGhostEntity( self.Model, Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) );
	end
	
	// update it
	self:UpdateGhostWireHoloemitter( self.GhostEntity, self:GetOwner() );
end


// build the control panel.
function TOOL.BuildCPanel( panel )
	// add header.
	panel:AddControl(
		"Header",
		{
			Text 		= "#Tool_wire_holoemitter_name",
			Description 	= "#Tool_wire_holoemitter_desc",
		}
	);
	
	// add color picker.
	panel:AddControl(
		"Color",
		{
			Label 	= "Color",
			Red 	= "wire_holoemitter_r",
			Green 	= "wire_holoemitter_g",
			Blue 	= "wire_holoemitter_b",
			Alpha 	= "wire_holoemitter_a",
			ShowAlpha	= "1",
			ShowHSV		= "1",
			ShowRGB		= "1",
			Multiplier	= "255",
		}
	);
end
