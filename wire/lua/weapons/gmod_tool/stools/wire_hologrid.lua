TOOL.Category		= "Wire - Holography";
TOOL.Name		= "Grid";
TOOL.Command		= nil;
TOOL.ConfigName		= "";

// add language
if( CLIENT ) then
	language.Add( "Tool_wire_hologrid_name", "Holographic Grid Tool (Wire)" );
	language.Add( "Tool_wire_hologrid_desc", "The grid to aid in holographic projections" );
	language.Add( "Tool_wire_hologrid_0", "Primary: Create grid" );
	language.Add( "undone_hologrid", "Undone Wire hologrid" );
	language.Add( "sboxlimit_wire_hologrids", "You've hit the hologrids limit!" );
end


// max emitters
if( SERVER ) then CreateConVar( "sbox_maxwire_hologrids", 30 ); end


// tool data.
TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl";	// models/jaanus/wiretool/wiretool_siren.mdl
TOOL.Emitter = nil;

// create a cleanup.
cleanup.Register( "wire_hologrids" );


// primary fire.
function TOOL:LeftClick( tr )
	// some checks
	if( tr.HitNonWorld && tr.Entity:IsPlayer() ) then return false; end
	if( CLIENT ) then return true; end
	
	// create a holo emitter.
	if( !self:GetSWEP():CheckLimit( "wire_hologrids" ) ) then return false; end
	
	// get player
	local pl = self:GetOwner();
	
	// fix angle
	local ang = tr.HitNormal:Angle();
	ang.p = ang.p + 90;
	
	// create emitter
	local emitter = MakeWireHologrid( pl, tr.HitPos, ang );
	
	// pull it out of the spawn point
	local mins = emitter:OBBMins();
	emitter:SetPos( tr.HitPos + tr.HitNormal * -mins.z );
	
	// weld
	local constraintEntity = WireLib.Weld( emitter, tr.Entity, tr.PhysicsBone, true );
	
	// create undo
	undo.Create( "hologrid" );
		undo.AddEntity( emitter );
		undo.AddEntity( constraintEntity );
		undo.SetPlayer( pl );
	undo.Finish();
	
	// create cleanup
	pl:AddCleanup( "wire_hologrids", emitter );
	pl:AddCleanup( "wire_hologrids", constraintEntity );
	
	//
	return true;
end


// creation code
if( SERVER ) then
	// make emitter
	function MakeWireHologrid( pl, pos, ang )
		// check the players limit
		if( !pl:CheckLimit( "wire_hologrids" ) ) then return; end
		
		// create the emitter
		local emitter = ents.Create( "gmod_wire_hologrid" );
			emitter:SetPos( pos );
			emitter:SetPos( ang );
		emitter:Spawn();
		emitter:Activate();
		
		// setup the emitter.
		emitter:SetPlayer( pl );
		
		
		// add to the players count
		pl:AddCount( "wire_hologrids", emitter );
		
		//
		return emitter;
	end
	
	// register with duplicator
	duplicator.RegisterEntityClass(
		"gmod_wire_hologrid",
		MakeWireHologrid,
		"Pos",
		"Ang"
	);

end


// update ghost.
function TOOL:UpdateGhostWirehologrid( ent, pl )
	// invalid entity?
	if( !ent || !ent:IsValid() ) then return; end
	
	// figure out where it will end up.
	local trace = utilx.GetPlayerTrace( pl, pl:GetCursorAimVector() );
	local tr = util.TraceLine( trace );
	
	// should we show a preview?
	if( !tr.Hit || ( tr.HitNonWorld && ( tr.Entity:GetClass() == "gmod_wire_hologrid" || tr.Entity:GetClass() == "gmod_wire_hologrid" ) ) ) then
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
	self:UpdateGhostWirehologrid( self.GhostEntity, self:GetOwner() );
end


// build the control panel.
function TOOL.BuildCPanel( panel )
	// add header.
	panel:AddControl(
		"Header",
		{
			Text 		= "#Tool_wire_hologrid_name",
			Description 	= "#Tool_wire_hologrid_desc",
		}
	);
end
