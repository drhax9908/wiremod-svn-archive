/*---------------------------------------------------------
   Duplicator module, 
   to add new constraints or entity classes use...
   
   duplicator.RegisterConstraint( "name", funct, ... )
   duplicator.RegisterEntityClass( "class", funct, ... )
   
---------------------------------------------------------*/

// I hate this code. The copy and paste functions should be broken into
// smaller subfunctions rather than having 6 nested for loops. The 2 main
// functions are just too hard to understand as it is now.. -garry

// I hate this code. The copy and paste functions should be broken into
// smaller subfunctions rather than having 6 nested for loops. The 2 main
// functions are just too hard to understand as it is now.. -garry

// I hate this code. The copy and paste functions should be broken into
// smaller subfunctions rather than having 6 nested for loops. The 2 main
// functions are just too hard to understand as it is now.. -garry

// PS this is gonna get re-written because JESUS CHRIST.

// Note: Modified by SatriAli
// Note: Modified by Erkle
// Note: Modified by TAD2020 because MFSF
duplicator = {}

local	ConstraintType,
	EntityModifiers,
	EntityBoneModifiers,
	EntType		= {},{},{},{}

// These functions are used to register new entity classes or constraint types
function duplicator.RegisterConstraint(	 Type,  func, ... )	ConstraintType[ Type ] 	= { Func = func, Args = {...} }	end
function duplicator.RegisterEntityClass(	 Class, func, ... )	EntType[ Class ] 	= { Func = func, Args = {...} }	end

// These functions are used to register entity or bone Modifiers (Like physprops or colour modify)
function duplicator.RegisterEntityModifier( Type,  func, ... )	EntityModifiers[ Type ] =	{ Func = func, Args = {...} }	end
function duplicator.RegisterEntityBoneModifier( Type,  func, ... )	EntityBoneModifiers[ Type ] =	{ Func = func, Args = {...} }	end


if (!SERVER) then return end

	// Copy ents & Constraints
	function duplicator.Copy( ply, StartEnt, offset )
		
		// Get all the ents & constraints in the system
		local EntTable, ConstraintTable  = duplicator.GetEnts(StartEnt)
		
		// Clear plys duplicator table
		ply:GetTable().Duplicator = { Ents = {}, Constraints = {}, HeadEntID = StartEnt:EntIndex() }
		
		local tempents = {}
		
		tempents["head"] = StartEnt:EntIndex()
		tempents["ents"] = {}
		tempents["const"] = {}
		
		// Get info required to re-create each entity
		for EntID, Ent in pairs(EntTable) do
			local EntClass = Ent:GetClass()
			
			tempents["ents"][EntID] = {}
			tempents["ents"][EntID]["class"] = EntClass
			tempents["ents"][EntID]["arg"] = {}
			// Check the entity class is registered with the duplicator
			if EntType[EntClass] then
				
				local etable	= {Class = EntClass}
				local BoneArgs	= nil
				local EntityTable = Ent:GetTable()
				
				if EntityTable.BuildDupeInfo then
					etable.DupeInfo = EntityTable:BuildDupeInfo()
					tempents["ents"][EntID]["dupeinfo"] = EntityTable:BuildDupeInfo()
				end
				
				// Get the args needed to recreate this ent
				for _, arg in pairs(EntType[EntClass].Args) do
					
					// Get args which are stored in the ent's table
					local Arg = EntityTable[arg]
					
					// Do special cases
					if !Arg and type(arg) == "string" then
						
						key = string.lower(arg)
						
						if	key == "ang"	or key == "angle"		then
							Arg = Ent:GetAngles()
						elseif	key == "pos"	or key == "position"		then
							Arg = Ent:GetPos() - offset
						elseif	key == "vel"	or key == "velocity"		then
							Arg = Ent:GetPhysicsObject():GetVelocity()
						elseif	key == "avel"	or key == "anglevelocity"	then
							Arg = Ent:GetPhysicsObject():GetAngleVelocity()
						elseif	key == "frozen"	or key == "motiondisabled"	then
							Arg = !Ent:GetPhysicsObject():IsMoveable()
						elseif	key == "mdl"	or key == "model"		then
							Arg = Ent:GetModel()
						elseif	key == "pl" 	or key == "ply"		then
							Arg = Arg:SteamID()
						elseif	key == "class"					then
							
							Arg = EntClass
						end
					end

					// get bone args
					if	type(arg) == "table"	then
						BoneArgs = arg
						tempents["ents"][EntID]["boneargs"] = arg
					end
					etable[arg] = Arg
					
					tempents["ents"][EntID]["arg"][arg] = Arg
				end

				// Get bone args
				if EntityTable.Bones or BoneArgs then
					
					local Bones = {}
					local tempBones = {}
					BoneArgs = BoneArgs or {}
					
					// Get args for each bone
					for Bone = 0,( Ent:GetPhysicsObjectCount() - 1 ) do
						if Ent:GetPhysicsObjectNum( Bone ):IsValid() then
							Bones[Bone] = {}
							
							for _, barg in pairs(BoneArgs) do
								
								local bArg = nil
								
								if  EntityTable.Bones 
								and EntityTable.Bones[Bone]
								and EntityTable.Bones[Bone][barg] then
									
									bArg = EntityTable.Bones[Bone][barg]
									
								else
									// Do special cases
									local Phys = Ent:GetPhysicsObjectNum(Bone)
									local barg = string.lower(barg)
									
									if	barg == "ang"	or barg == "angle"		then
										bArg = Phys:GetAngle()
									elseif	barg == "pos"	or barg == "position"		then
										bArg = Phys:GetPos() - offset
									elseif	barg == "vel"	or barg == "velocity"		then
										bArg = Phys:GetVelocity()
									elseif	barg == "avel"	or barg == "angvelocity"	then
										bArg = Phys:GetAngleVelocity()
									elseif	barg == "mass"					then
										bArg = Phys:GetMass()
									elseif	barg == "inertia"				then
										bArg = Phys:GetInertia()
									elseif	barg == "damping"				then
										bArg = Phys:GetDamping()
									elseif	barg == "frozen" or barg == "motionenabled"	then
										bArg = !Phys:IsMoveable()
									end
								end
								
								Bones[Bone][barg] = bArg
								
							end
							
							for ModifierType, _ in pairs(EntityBoneModifiers) do
								if  EntityTable.Bones 
								and EntityTable.Bones[Bone]
								and EntityTable.Bones[Bone][ModifierType] then
									Bones[Bone][ModifierType] = EntityTable.Bones[Bone][ModifierType]
								end
							end

						end
					end
					etable.Bones = Bones
					tempents["ents"][EntID]["bones"] = Bones
					
				end

				for ModifierType, _ in pairs(EntityModifiers) do
					tempents["ents"][EntID]["mods"] = {}
					if EntityTable[ModifierType] then
						etable[ModifierType] = EntityTable[ModifierType]
						tempents["ents"][EntID]["mods"][ModifierType] = EntityTable[ModifierType]
					end
				end

				// Hack to copy decals
				if EntityTable.decals then
					etable.decals = EntityTable.decals
					tempents["ents"][EntID]["decals"] = EntityTable.decals
				end

				ply:GetTable().Duplicator.Ents[EntID] = etable
			else
				Msg("Duplicator copy: Unknown class " .. EntClass .. "\n")
			end
		end
		
		
		// Get info required to re-create each constraint
		for constID, Constraint in pairs(ConstraintTable) do

			// check the constraint has been registered with the duplicator
			if ConstraintType[Constraint:GetTable().Type] then

				ctable = {Type = Constraint:GetTable().Type}
				
				local doconstraint = true
				for _,Key in pairs(ConstraintType[Constraint:GetTable().Type].Args) do

					local Arg = Constraint:GetTable()[Key]
					local len = string.len(Key)
					      key = string.lower(Key)
						  
					if (Arg) then

						// Do special cases
						if	string.find(key, "lpos")  and ( len == 4 or len == 5 )
						or	string.find(key, "ang" )  and ( len == 3 or len == 4 )	then
							Arg = Arg
						elseif	string.find(key, "wpos")  and ( len == 4 or len == 5 )	then
							Arg = Arg - offset
						elseif	key == "pl" or key == "ply"				then
							Arg = Arg:SteamID()
						elseif	string.find(key, "ent" )  and ( len == 3 or len == 4 )	then
							Arg = Arg:EntIndex() 
							if !EntTable[Arg] then doconstraint = nil end
						end

						// Nullify zero value args
						--if tostring(Arg) == "0.000 0.000 0.000" or Arg == false then Arg = nil end
					
					end

					ctable[Key] = Arg
				end
				if doconstraint then
				    if (type(constID) == "number") then
				        ctable.ConstID = constID
				    end
				
					table.insert(ply:GetTable().Duplicator.Constraints, ctable)
					table.insert(tempents["const"], ctable)
				end
			end
		end
		
		
		
		Msg("\n--tempents LocSanitise Start--\n")
		
		local temp = duplicator.LocSanitise(tempents)
		
		Msg("\n--tempents TableToKeyValues Start--\n")
		
		temp = util.TableToKeyValues(temp)
		Msg(temp)
		
		file.Write("test/1.txt", temp)
		Msg("\n--tempCopyEnts End--\n")
		
		Msg("\n--HeadID--\n")
		Msg( StartEnt:EntIndex() )
		Msg("\n--Copyed--\n")
		
		return EntTable, ConstraintTable
	end


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	// Paste duplicated ents
	function duplicator.Paste( ply, offset, filename )

		local Ents,Constraints = nil,nil
		local constIDtable, entIDtable, CreatedConstraints, CreatedEnts = {}, {}, {}, {}
		
		
		local HeadEntity = nil
		local tempents = {}
		local tHeadEntID = nil
		
		if filename then 
			// TODO:
			// load file to ents/constraints tables
			
		elseif  ply:GetTable().Duplicator then 

			--Ents 			= 	ply:GetTable().Duplicator.Ents
			--Constraints 	=	ply:GetTable().Duplicator.Constraints
			
			Msg("\n--Paste--\n--tempEnts--\n")
			
			local temp = file.Read("test/1.txt")
			Msg(temp)
			temp = util.KeyValuesToTable(temp)
			--Msg("\n--KeyValuesToTable--\n")
			--Msg(util.TableToKeyValues(temp))
			tempents = duplicator.LocDeSanitise(temp)
			
			Msg("\n--tempents TableToKeyValues Start--\n")
			Msg(util.TableToKeyValues(tempents))
			Msg(util.TableToKeyValues(duplicator.LocSanitise(tempents)))
			Msg("\n--tempents TableToKeyValues End--\n")
			
			Msg("\n--head--\n")
			tHeadEntID = (tempents["head"])
			Msg(tHeadEntID)
			
			Msg("\n--Pasting--\n")
		else
			return false
		end

		undo.Create("Duplicator")
			
		for entID, EntTable in pairs(tempents["ents"]) do
			
			local EntClass = EntTable["class"]
			
			// Check the antities class is registered with the duplicator
			if EntClass and EntType[EntClass] then
				
				local Args, BoneArgs, nBone = {}, nil, nil
				
				// Get the args that we need from the EntType table
				for n,Key in pairs(EntType[EntClass].Args) do
					
					if type(Key) == "string" then
						key = string.lower(Key)
						
						local Arg = EntTable["arg"][key]
						
						Msg("\nKey ")
						Msg(Key)
						Msg("\n Arg")
						Msg(Arg)
						
						if	key == "ang"	or key == "angle"		then
							Arg = Arg or Vector(0,0,0)
						elseif	key == "pos"	or key == "position"		then
							Arg = Arg + offset or Vector(0,0,0)
						elseif	key == "vel"	or key == "velocity"		then
							Arg = Arg or Vector(0,0,0)
						elseif	key == "avel"	or key == "anglevelocity"	then
							Arg = Arg or Vector(0,0,0)
						elseif	key == "pl" 	or key == "ply"		then
							Arg = ply // TODO:  Arg = ply.GetBySteamID(Arg)
						end
						
						Args[n] = Arg
						
					elseif type(Key) == "table" then
						
						BoneArgs = Key
						nBone	 = n
					end
				end
				
				if EntTable["bones"] and BoneArgs then
					
					Arg = {}
					
					// Get args for each bone
					for Bone,Args in pairs(EntTable["bones"]) do
						Arg[Bone] = {}

						for n, bKey in pairs( BoneArgs ) do

							local bArg = EntTable["bones"][Bone][bKey] or tostring(0)

							// Do special cases
							local bkey = string.lower(bKey)

							if	bkey == "ang"	or bkey == "angle"		then
								bArg = bArg or Vector(0,0,0)
							elseif	bkey == "pos"	or bkey == "position"		then
								bArg = bArg + offset or Vector(0,0,0)
							elseif	bkey == "vel"	or bkey == "velocity"		then
								bArg = bArg or Vector(0,0,0)
							elseif	bkey == "avel"	or bkey == "angvelocity"	then
								bArg = bArg or Vector(0,0,0)
							end

							Arg[Bone][n] = bArg
						end
					end
					Args[nBone] = Arg
				end

				// make the Entity
				Ent = EntType[EntClass].Func(ply, unpack(Args))

				if (Ent && Ent:IsValid()) then

					undo.AddEntity( Ent )
					entIDtable[tonumber(entID)] = Ent
					table.insert(CreatedEnts,Ent)
					
					if tempents["ents"][entID]["mods"] then
						for ModifierType, Modifier in pairs(EntityModifiers) do
							if EntTable["mods"][ModifierType] then
								local args = {}

								for n,arg in pairs(Modifier.Args) do
									args[n] = EntTable["mods"][ModifierType][arg]
								end

								Modifier.Func( ply, Ent, unpack(args))
							end
						end
					end

					if EntTable["bones"] then
						for ModifierType, Modifier in pairs(EntityBoneModifiers) do
							for Bone,Args in pairs(EntTable["bones"]) do
								if Args[ModifierType] then
									local args = {}

									for n,arg in pairs(Modifier.Args) do
									args[n] = Args[ModifierType][arg]
									end

									Modifier.Func( ply, Ent, Bone, unpack(args))
								end
							end
						end
					end
					
					// Hack to paste decals
					if EntTable.decals then

						Ent:GetTable().decals = EntTable["decals"]
						timer.Simple( 0.001, 		// HORRID
						function( tbl,Ent ) 
							for n, DecalInfo in pairs(tbl) do

								local decal, Pos1, Pos2 = DecalInfo[1],
									Ent:LocalToWorld( DecalInfo[2]),
									Ent:LocalToWorld( DecalInfo[3])

								util.Decal( decal, Pos1, Pos2 )
							end
						end
						,EntTable["decals"],Ent )
					end
				end
			elseif (EntClass) then
			    Msg("Duplicator Paste: Unknown class " .. EntClass .. "\n")
			end
			
			
			if ( tonumber(entID) == (tHeadEntID) ) then
				HeadEntity = Ent
			end
		end
		
		if !tempents["const"] then tempents["const"] = {} end
		
		for _, Constraint in pairs(tempents["const"]) do
			
			// Check If the constraint type has been registered with the duplicator
			if Constraint["type"] and ConstraintType[Constraint["type"]] then
				
				local Args = {}
				local DoConstraint = true
				
				// Get the args that we need from the ConstraintType table
				for n,key in pairs(ConstraintType[Constraint["type"]].Args) do
					
					
					local len = string.len(key)
					local Key = string.lower(key)
					local Arg = Constraint[Key]
					// DO SPECIAL CASES
					// If key represents an entity, convert from an entID back to an ent
					if	string.find(Key, "ent")		and ( len == 3 or len == 4 ) then
						Arg = entIDtable[(Arg)]
						if !Arg or !Arg:IsValid() then DoConstraint = nil end
						
					// If key represents an Local angle or vector, convert from string, back to a vector
					elseif	(string.find(Key, "lpos")	and ( len == 4 or len == 5 ))
					or	(string.find(key, "ang")	and ( len == 3 or len == 4 )) then 
						Arg = Arg or Vector(0,0,0)

					// If key represents a World Vector or angle, convert from string, back to a vector
					elseif	(string.find(Key, "wpos")	and ( len == 4 or len == 5 )) then
						Arg = Arg + offset or Vector(0,0,0)

					// If key represents a ply, convert from steamid back to a ply
					elseif	Key == "pl" or Key == "ply" or Key == "ply" then
						--Arg = ply.GetBySteamID(Arg)
						Arg = ply
						if not Arg:IsValid() then DoConstraint = nil end
					end
					
					Args[n] = Arg
				end

				// make the constraint
				if DoConstraint then
					local const = ConstraintType[Constraint["type"]].Func(unpack(Args))
					table.insert(CreatedConstraints,const)
					undo.AddEntity( const )

					if (Constraint["constid"]) then
						constIDtable[Constraint["constid"]] = const
						Msg("Dupe add constraint ID: " .. Constraint["constid"] .. "\n")
					end
				end
			end
		end
		undo.SetPlayer( ply )
		undo.Finish()

		for id, entTable in pairs(tempents["ents"]) do
			local ent = entIDtable[tonumber(id)]
			if (ent) and (ent:IsValid()) and (entTable["dupeinfo"]) and (ent.ApplyDupeInfo) then
			    Msg("\n------------------ApplyDupeInfo\n")
			    Msg(entTable["class"])
				ent:ApplyDupeInfo(
					ply, ent, entTable["dupeinfo"],
					function(id) return entIDtable[id] end,
					function(id) return constIDtable[id] end
					)
			end
		end
		
		// Rotate entities relative to the ply's hold angles
		local EntOffsets = {}
		
		if (HeadEntity) then
		
			for i, ent in pairs( CreatedEnts ) do
			
				EntOffsets[ ent ] = {}
				
				if ( ent != HeadEntity ) then 
				
					local Pos = ent:GetPos()
					local Ang = ent:GetAngles()
					
					EntOffsets[ ent ].Pos = HeadEntity:WorldToLocal( Pos )
					EntOffsets[ ent ].Ang = Ang - HeadEntity:GetAngles()
					
				end
				
				// And physics objects (for ragdolls)
				local Bones = {}
				for Bone=0, ent:GetPhysicsObjectCount()-1 do
				
					local PhysObject = ent:GetPhysicsObjectNum( Bone )
				
					if ( PhysObject:IsValid() ) then
					
						Bones[PhysObject] = {}
						Bones[PhysObject].Pos = HeadEntity:WorldToLocal( PhysObject:GetPos() )
						Bones[PhysObject].Ang = PhysObject:GetAngle() - HeadEntity:GetAngles()
						
					end
						
				end
				
				EntOffsets[ ent ].Bones = Bones

			end
			
			// Rotate main object
			local angle = ply:GetAngles()
			angle.pitch = 0
			angle.roll 	= 0
	
			HeadEntity:SetAngles( angle - duplicator.HoldAngle )
			
			for ent, tab in pairs( EntOffsets ) do
				
				if (HeadEntity != ent) then
					ent:SetPos( HeadEntity:LocalToWorld( tab.Pos ) )
					ent:SetAngles( HeadEntity:GetAngles() + tab.Ang )
				end
				
				// Ragdoll Bones
				for phys, ptab in pairs( tab.Bones ) do

					phys:SetPos( HeadEntity:LocalToWorld( ptab.Pos ) )
					phys:SetAngle( HeadEntity:GetAngles() + ptab.Ang )

				end
				
			end
		
		else
		
			Msg("Error! Head Duplicator entity not found!\n")
		
		end
		


		return CreatedEnts, CreatedConstraints
	end
	
	
	
	
	
	
	
	
	
	/*---------------------------------------------------------
   Name: table.Sanitise( table )
   Desc: Converts a table containing vectors, angles, bools so it can be converted to and from keyvalues
---------------------------------------------------------*/
function duplicator.LocSanitise( t, done)
	
	local done = done or {}
	local tbl = {}
	
	Msg("\n\nSanitising: ")
	
	for k, v in pairs ( t ) do
		
		Msg("\nk ")
		Msg(k)
		Msg("\nv ")
		Msg(tostring(v))
		Msg("\nv type: ")
		Msg(type(v))
			
		if ( type( v ) == "table" and !done[ v ] ) then
			Msg("\ntable found")
			done[ v ] = true
			tbl[ k ] = duplicator.LocSanitise ( v, done )
			
		else
			
			if ( type(v) == "Vector" ) then
				Msg("\nvector found")
				local x, y, z = v.x, v.y, v.z
				if y == 0 then y = nil end
				if z == 0 then z = nil end
				tbl[k] = { __type = "Vector", x = x, y = y, z = z }
				
			elseif ( type(v) == "Angle" ) then
				Msg("\nangle found")
				local p,y,r = v.pitch, v.yaw, v.roll
				if p == 0 then p = nil end
				if y == 0 then y = nil end
				if r == 0 then r = nil end
				tbl[k] = { __type = "Angle", p = p, y = y, r = r }
				
			elseif ( type(v) == "boolean" ) then
				Msg("\nbool found")
				tbl[k] = { __type = "Bool", tostring( v ) }
			
			elseif ( type(v) == "number" ) then
				Msg("\nnumber found")
				tbl[k] = { __type = "Number", tostring( v ) }
			
			else
				Msg("\nother found")
				tbl[k] = tostring(v)
				
			end
			
			
		end
		
		
	end
	
	return tbl
	
end


/*---------------------------------------------------------
   Name: table.DeSanitise( table )
   Desc: Converts a Sanitised table back
---------------------------------------------------------*/
function duplicator.LocDeSanitise( t, done )

	local done = done or {}
	local tbl = {}
	
	Msg("\n\nSanitising: ")
	
	for k, v in pairs ( t ) do
		
		Msg("\nk ")
		Msg(k)
		
		if ( type( v ) == "table" and !done[ v ] ) then
			
			done[ v ] = true
			
			if ( v.__type ) then
				Msg("\nc.__type ")
				Msg(v.__type)
				
				if ( v.__type == "Vector" ) then
					Msg("\nvector found")
					tbl[ k ] = Vector( v.x, v.y, v.z )
					
				elseif ( v.__type == "Angle" ) then
					Msg("\nangle found")
					tbl[ k ] = Angle( v.p, v.y, v.r )
					
				elseif ( v.__type == "Bool" ) then
					Msg("\nbool found------ ")
					Msg( v["1"] )
					--tbl[ k ] = ( v[1] == "true" )
					tbl[ k ] = util.tobool( v["1"] )
				elseif ( v.__type == "Number" ) then
					Msg("\nnumber found------num ")
					Msg( v["1"] )
					tbl[ k ] = tonumber( v["1"] )
				end
				
				Msg("\ntbl[ k ] ")
				Msg(tostring(tbl[ k ]))
				
			else
				Msg("\ntable found")
				tbl[ k ] = duplicator.LocDeSanitise ( v, done )
				
			end
			
		else
			Msg("\nother found")
			if k == "Src" or k == "src" then
				tbl[ k ] = tonumber(v)
			else
				tbl[ k ] = v
			end
			
			Msg("\ntbl[ k ] = v ")
			Msg(tostring(v))
			
		end
		
		Msg("\ntbl[ k ] ")
		Msg(tostring(tbl[ k ]))
		
	end
	
	return tbl
	
end
	
	
	
	
	
	
	
	
	
	
	// Function used to create prop physics classes
	function duplicator.MakeProp( ply, Pos, Ang, Model, Vel, aVel, frozen )

		// check we're allowed to spawn
		--if ( !gamemode.Call( "plySpawnProp", ply, Model ) ) then return end
		local Ent = ents.Create( "prop_physics" )
			Ent:SetModel( Model )
			Ent:SetAngles( Ang )
			Ent:SetPos( Pos )
		Ent:Spawn()

		// apply velocity If required
		if ( Ent:GetPhysicsObject():IsValid() ) then
			Phys = Ent:GetPhysicsObject()
			Phys:SetVelocity(Vel)
			Phys:AddAngleVelocity(aVel)
			Phys:EnableMotion(frozen != true)
		end
		Ent:Activate()

		// tell the gamemode we just spawned something
		--gamemode.Call( "plySpawnedProp", ply, Model, Ent )
		return Ent	
	end

	// Register the "prop_physics" class with the duplicator, so it knows which args to retrive when copying, 
	//	and what to send back to the MakeProp Function when pasting
	duplicator.RegisterEntityClass( "prop_physics", duplicator.MakeProp, "Pos", "Ang", "Model", "Vel", "aVel", "frozen" )


	function duplicator.MakeRagdoll( ply, Pos, Ang, Model, Bones )

		if not gamemode.Call( "plySpawnRagdoll", ply, Model ) then return end
		local Ent = ents.Create( "prop_ragdoll" )
			Ent:SetModel( Model )
			Ent:SetAngles( Ang )
			Ent:SetPos( Pos )
		Ent:Spawn()
		
		for Bone, Args in pairs(Bones) do
		
			local Phys = Ent:GetPhysicsObjectNum(Bone)
			
			if (Phys:IsValid()) then	

				
				Phys:SetPos(Args[1])
				Phys:SetAngle(Args[2])
				Phys:SetVelocity(Args[3])
				Phys:AddAngleVelocity(Args[4])
				if (Args[5] == true) then Phys:EnableMotion(false) end
								
			end
			
		end
		Ent:Activate()

		gamemode.Call( "plySpawnedRagdoll", ply, Model, Ent )
		return Ent	
	end
	// Register the "prop_ragdoll" class with the duplicator, (Args in brackets will be retreived for every bone)
	duplicator.RegisterEntityClass( "prop_ragdoll", duplicator.MakeRagdoll, "Pos", "Ang", "Model", {"Pos", "Ang", "Vel", "aVel", "frozen"} )


	function duplicator.MakeVehicle( ply, Pos, Ang, Model, Class, Vel, aVel, frozen )

		if not gamemode.Call( "plySpawnVehicle", ply, Model ) then return end
		local Ent = ents.Create( Class )
			Ent:SetModel( Model )
			Ent:SetAngles( Ang )
			Ent:SetPos( Pos )
			Ent:SetKeyValue("vehiclescript", "scripts/vehicles/jeep_test.txt")
			Ent:SetKeyValue("actionScale",	 1)
			Ent:SetKeyValue("VehicleLocked", 0)
			Ent:SetKeyValue("solid",	 6)
		Ent:Spawn()

		if Ent:GetPhysicsObject():IsValid() then
			Phys = Ent:GetPhysicsObject()
			Phys:SetVelocity(Vel)
			Phys:AddAngleVelocity(aVel)
			Phys:EnableMotion(frozen != true)
		end

		Ent:Activate()

		gamemode.Call( "plySpawnedVehicle", ply, Ent )
		return Ent	
	end
	duplicator.RegisterEntityClass( "prop_vehicle_jeep",    duplicator.MakeVehicle, "Pos", "Ang","Model", "Class", "Vel", "aVel", "frozen" )
	duplicator.RegisterEntityClass( "prop_vehicle_airboat", duplicator.MakeVehicle, "Pos", "Ang","Model", "Class", "Vel", "aVel", "frozen" )



	// Returns all ents & constraints in a system
	function duplicator.GetEnts(ent, EntTable, ConstraintTable)

		local EntTable		= EntTable	  or {}
		local ConstraintTable	= ConstraintTable or {}

		// Ignore the world
		if not ent:IsValid() then return EntTable, ConstraintTable end

		// Add ent to the list of found ents
		EntTable[ent:EntIndex()] = ent

		// If there are no Constraints attached then return
		if not ent:GetTable().Constraints then return EntTable, ConstraintTable end

		for key, const in pairs( ent:GetTable().Constraints ) do

			// If the constraint doesn't exist, delete it from the list
			if ( !const:IsValid() ) then

				ent:GetTable().Constraints[key] = nil

			// Check that the constraint has not already been added to the constraints table
			else
			    local id = const:EntIndex()
			    if (id == 0) then id = const:GetTable() end
			
				if ( !ConstraintTable[id] ) then
					// Add constraint to the constraints table
					ConstraintTable[id] = const

					// Run the Function for any ents attached to this constraint
					for key,Ent in pairs(const:GetTable()) do
						local len = string.len(key)
						if	string.find(key, "Ent")
						and	( len == 3 or len == 4 )
						and	Ent:IsValid()
						and	!EntTable[Ent:EntIndex()] then

							EntTable, ConstraintTable  = duplicator.GetEnts(Ent, EntTable, ConstraintTable)
						end
					end
				end

			end
		end

		return EntTable, ConstraintTable
	end

	
duplicator.RegisterConstraint( "Weld", constraint.Weld, "Ent1", "Ent2", "Bone1", "Bone2", "forcelimit", "nocollide" )
duplicator.RegisterConstraint( "Rope", constraint.Rope, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "length", "addlength", "forcelimit", "width", "material", "rigid" )
duplicator.RegisterConstraint( "Elastic", constraint.Elastic, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "constant", "damping", "rdamping", "material", "width", "stretchonly")
duplicator.RegisterConstraint( "Keepupright", constraint.Keepupright, "Ent", "Ang", "Bone", "angularlimit" )
duplicator.RegisterConstraint( "Slider", constraint.Slider, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width" )
duplicator.RegisterConstraint( "Axis", constraint.Axis, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "forcelimit", "torquelimit", "friction", "nocollide" )
duplicator.RegisterConstraint( "AdvBallsocket", constraint.AdvBallsocket, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "forcelimit", "torquelimit", "xmin", "ymin", "zmin", "xmax", "ymax", "zmax", "xfric", "yfric", "zfric", "onlyrotation", "nocollide")
duplicator.RegisterConstraint( "NoCollide", constraint.NoCollide, "Ent1", "Ent2", "Bone1", "Bone2" )
duplicator.RegisterConstraint( "Motor", constraint.Motor, "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "friction", "torque", "forcetime", "nocollide", "toggle", "pl", "forcelimit", "numpadkey_fwd", "numpadkey_bwd" )
duplicator.RegisterConstraint( "Pulley", constraint.Pulley, "Ent1", "Ent4", "Bone1", "Bone4", "LPos1", "LPos4", "WPos2", "WPos3", "forcelimit", "rigid", "width", "material" )
duplicator.RegisterConstraint( "Ballsocket", constraint.Ballsocket, "Ent1", "Ent2", "Bone1", "Bone2", "LPos", "forcelimit", "torquelimit", "nocollide" )
duplicator.RegisterConstraint( "Winch", constraint.Winch, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width", "fwd_bind", "bwd_bind", "fwd_speed", "bwd_speed", "material", "toggle" )
duplicator.RegisterConstraint( "Hydraulic", constraint.Hydraulic, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "Length1", "Length2", "width", "key", "fixed", "fwd_speed" )
duplicator.RegisterConstraint( "Muscle", constraint.Muscle, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "Length1", "Length2", "width", "key", "fixed", "period", "amplitude" )


Msg("--- Wire duplicator module installed! ---\n")
