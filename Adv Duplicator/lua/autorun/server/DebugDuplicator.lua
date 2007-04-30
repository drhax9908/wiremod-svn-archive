DebugDuplicator = {}
DebugDuplicator.Vesion = 24.41

/*---------------------------------------------------------
   Generic function for duplicating stuff
---------------------------------------------------------*/
function DebugDuplicator.GenericDuplicatorFunction( Player, data, ID )
	if (!data) or (!data.Class) then return false end
	
	Msg("Generic make function for Class: "..data.Class.." Ent: ".."\n")
	
	local Entity = ents.Create( data.Class )
	if (!Entity:IsValid()) then
		Msg("Error: Unknown class, making hallow prop instead for ent: "..ID.."\n")
		Entity = ents.Create( "prop_physics" )
		Entity:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
	//Entity:SetModel( data.Model )
	//Entity:Spawn()
	//duplicator.DoGeneric( Entity, data )
	//Entity:Activate()
	
	duplicator.DoGeneric( Entity, data )
	Entity:Spawn()
	Entity:Activate()
	duplicator.DoGenericPhysics( Entity, Player, data )
	
	table.Add( Entity:GetTable(), data )
	
	return Entity
	
end


/*---------------------------------------------------------
   Copy this entity, and all of its constraints and entities 
   and put them in a table.
---------------------------------------------------------*/
function DebugDuplicator.Copy( Ent )
	
	local Ents = {}
	local Constraints = {}
	
	DebugDuplicator.GetAllConstrainedEntitiesAndConstraints( Ent, Ents, Constraints )
	
	local EntTables = {}
	for k, v in pairs(Ents) do
		EntTables[ k ] = duplicator.CopyEntTable( v )
	end
	
	local ConstraintTables = {}
	for k, v in pairs(Constraints) do
		table.insert( ConstraintTables, v )
	end
	
	return EntTables, ConstraintTables
	
end


/*---------------------------------------------------------
   Create an entity from a table.
---------------------------------------------------------*/
function DebugDuplicator.CreateEntityFromTable( Player, EntTable, ID )
	
	local EntityClass = duplicator.FindEntityClass( EntTable.Class )
	
	// This class is unregistered. Instead of failing try using a generic
	// Duplication function to make a new copy..
	if (!EntityClass) then
		
		return DebugDuplicator.GenericDuplicatorFunction( Player, EntTable, ID )
		
	end
	
	// Build the argument list
	local ArgList = {}
	
	for iNumber, Key in pairs( EntityClass.Args ) do
		
		local Arg = nil
		
		// Translate keys from old system
		if ( Key == "pos" || Key == "position" ) then Key = "Pos" end
		if ( Key == "ang" || Key == "Ang" || Key == "angle" ) then Key = "Angle" end
		if ( Key == "model" ) then Key = "Model" end
		
		Arg = EntTable[ Key ]
		
		// Special keys
		if ( Key == "Data" ) then Arg = EntTable end
		
		// If there's a missing argument then unpack will stop sending at that argument
		if ( Arg == nil ) then Arg = false end
		
		ArgList[ iNumber ] = Arg
		
	end
	
	// Create and return the entity
	return EntityClass.Func( Player, unpack(ArgList) )
	
end



/*---------------------------------------------------------
  Make a constraint from a constraint table
---------------------------------------------------------*/
function DebugDuplicator.CreateConstraintFromTable( Constraint, EntityList )
	if ( !Constraint ) then return end
	
	local Factory = duplicator.ConstraintType[ Constraint.Type ]
	if ( !Factory ) then return end
	
	local Args = {}
	for k, Key in pairs( Factory.Args ) do
		
		local Val = Constraint[ Key ]
		
		for i=1, 6 do 
			if ( Constraint.Entity[ i ] ) then
				if ( Key == "Ent"..i ) or ( Key == "Ent" ) then	
					Val = EntityList[ Constraint.Entity[ i ].Index ] 
					if ( Constraint.Entity[ i ].World ) then
						Val = GetWorldEntity()
					else
						if (!Val) or (!Val:IsValid()) then
							Msg("Problem with = "..(Constraint.Type or "NIL").." Constraint. Could not find Ent: "..Constraint.Entity[ i ].Index.."\n")
						end
					end
				end
				if ( Key == "Bone"..i ) or ( Key == "Bone" ) then Val = Constraint.Entity[ i ].Bone end
				if ( Key == "LPos"..i ) then Val = Constraint.Entity[ i ].LPos end
				if ( Key == "WPos"..i ) then Val = Constraint.Entity[ i ].WPos end
				if ( Key == "Length"..i ) then Val = Constraint.Entity[ i ].Length end
			end
		end
		
		// If there's a missing argument then unpack will stop sending at that argument
		if ( Val == nil ) then Val = false end
		
		table.insert( Args, Val )
		
	end
	
	local Entity = Factory.Func( unpack(Args) )
	
	return Entity
	
end


/*---------------------------------------------------------
   Given entity list and constranit list, create all entities
   and return their tables
---------------------------------------------------------*/
function DebugDuplicator.Paste( Player, EntityList, ConstraintList )
	
	local CreatedEntities = {}
	
	//
	// Create the Entities
	//
	for k, v in pairs( EntityList ) do
		
		CreatedEntities[ k ] = DebugDuplicator.CreateEntityFromTable( Player, v, k )
		
		if ( CreatedEntities[ k ] and CreatedEntities[ k ]:IsValid() )
			and not (!CreatedEntities[ k ].Spawnable and CreatedEntities[ k ].AdminSpawnable) then
			
			//safe guard
			Player:AddCleanup( "duplicates", CreatedEntities[ k ] )
			
			CreatedEntities[ k ].BoneMods = table.Copy( v.BoneMods )
			CreatedEntities[ k ].EntityMods = table.Copy( v.EntityMods )
			CreatedEntities[ k ].PhysicsObjects = table.Copy( v.PhysicsObjects )
			
		else
			Msg("Error:Created Entity Bad! Class: "..(v.Class or "NIL").." Ent: "..k.."\n")
			
			CreatedEntities[ k ] = nil
			
		end
		
	end
	
	//
	// Apply modifiers to the created entities
	//
	for EntID, Ent in pairs( CreatedEntities ) do	
		
		duplicator.ApplyEntityModifiers ( Player, Ent )
		duplicator.ApplyBoneModifiers ( Player, Ent )
		
		if ( Ent.PostEntityPaste ) then
			Ent:PostEntityPaste( Player, Ent, CreatedEntities )
		end
		
	end
	
	
	local CreatedConstraints = {}
	
	//
	// Create constraints
	//
	if ConstraintList then
		for k, Constraint in pairs( ConstraintList ) do
			
			local Entity = DebugDuplicator.CreateConstraintFromTable( Constraint, CreatedEntities )
			
			if ( Entity && Entity:IsValid() ) then
				table.insert( CreatedConstraints, Entity )
			else
				Msg("Error:Created Constraint Bad! Type= "..(Constraint.Type or "NIL").."\n")
			end
			
		end
	end
	
	return CreatedEntities, CreatedConstraints
	
end



/*----------------------------------------------------------------------
Returns this entities constraints table
This is for the future, because ideally the constraints table will eventually look like this - and we won't have to build it every time.
----------------------------------------------------------------------*/
function DebugDuplicator.GetConstTable( ent )
	
	if ( !constraint.HasConstraints( ent ) ) then return {} end
	
	local RetTable = {}
	
	for key, ConstraintEntity in pairs( ent.Constraints ) do
		
		local con = {}
		
		table.Merge( con, ConstraintEntity:GetTable() )
		
		con.Constraint = ConstraintEntity
		con.Entity = {}
		
		if ( con[ "Ent" ] && ( con[ "Ent" ]:IsWorld() || con[ "Ent" ]:IsValid() ) ) then
			
			con.Entity[ 1 ] = {}
			con.Entity[ 1 ].Index	 	= con[ "Ent" ]:EntIndex()
			con.Entity[ 1 ].Entity		= con[ "Ent" ]
			con.Entity[ 1 ].World		= con[ "Ent" ]:IsWorld()
			con.Entity[ 1 ].Bone 		= con[ "Bone" ]
			
		else
			
			for i=1, 6 do
				
				if ( con[ "Ent"..i ] && ( con[ "Ent"..i ]:IsWorld() || con[ "Ent"..i ]:IsValid() ) ) then
					
					con.Entity[ i ] = {}
					con.Entity[ i ].Index	 	= con[ "Ent"..i ]:EntIndex()
					con.Entity[ i ].Entity	 	= con[ "Ent"..i ]
					con.Entity[ i ].Bone 		= con[ "Bone"..i ]
					con.Entity[ i ].LPos 		= con[ "LPos"..i ]
					con.Entity[ i ].WPos 		= con[ "WPos"..i ]
					con.Entity[ i ].Length 		= con[ "Length"..i ]
					con.Entity[ i ].World		= con[ "Ent"..i ]:IsWorld()
					
				end
				
			end
			
		end
		
		table.insert( RetTable, con )
		
	end
	
	return RetTable
	
end


/*---------------------------------------------------------
  Returns all constrained Entities and constraints
  This is kind of in the wrong place. No not call this 
  from outside of this code. It will probably get moved to
  constraint.lua soon.
---------------------------------------------------------*/
function DebugDuplicator.GetAllConstrainedEntitiesAndConstraints( ent, EntTable, ConstraintTable )

	if ( !ent:IsValid() ) then return end

	EntTable[ ent:EntIndex() ] = ent
	
	if ( !constraint.HasConstraints( ent ) ) then return end
	
	local ConTable = DebugDuplicator.GetConstTable( ent )
	
	for key, constraint in pairs( ConTable ) do

		local index = constraint.Constraint
		
		if ( !ConstraintTable[ index ] ) then

			// Add constraint to the constraints table
			ConstraintTable[ index ] = constraint

			// Run the Function for any ents attached to this constraint
			for key, ConstrainedEnt in pairs( constraint.Entity ) do

				DebugDuplicator.GetAllConstrainedEntitiesAndConstraints( ConstrainedEnt.Entity, EntTable, ConstraintTable )
					
			end
			
		end
	end

	return EntTable, ConstraintTable
	
end






function DebugDuplicator.GetAllConstrainedEntities( ent, EntTable, ConstraintTable)
	
	if ( !ent:IsValid() ) then return end

	EntTable[ ent:EntIndex() ] = ent
	
	if ( !constraint.HasConstraints( ent ) ) then return end
	
	for key, ConstraintEntity in pairs( ent.Constraints ) do
		if ( !ConstraintTable[ ConstraintEntity ] ) then
			ConstraintTable[ ConstraintEntity ] = true
			if ( ConstraintEntity[ "Ent" ] && ConstraintEntity[ "Ent" ]:IsValid() ) then
				DebugDuplicator.GetAllConstrainedEntities( ConstraintEntity[ "Ent" ].Entity, EntTable, ConstraintTable)
			else
				for i=1, 6 do
					if ( ConstraintEntity[ "Ent"..i ] && ConstraintEntity[ "Ent"..i ]:IsValid() ) then
						DebugDuplicator.GetAllConstrainedEntities( ConstraintEntity[ "Ent"..i ].Entity, EntTable, ConstraintTable)
					end
				end
			end
		end
	end
	
	return EntTable, ConstraintTable
	
end


Msg("==== Advanced Duplicator v.1.62.2 debug duplicator module installed! ====\n")
