
AddCSLuaFile( "autorun/client/cl_dupehelper.lua" )
AddCSLuaFile( "autorun/shared/dupeshare.lua" )

include( "autorun/shared/dupeshare.lua" )

/*---------------------------------------------------------
   Advanced Duplicator module, Saves and Loads files 
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
// Note: Very modified, rewriten, and added all sorts of stuff by TAD2020
--duplicator = {}

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
		duplicator[ply:UniqueID()] = { Ents = {}, Constraints = {}, HeadEntID = StartEnt:EntIndex(), DupeInfo = {}, DORInfo = {} }
		
		// Get info required to re-create each entity
		for EntID, Ent in pairs(EntTable) do
			local EntClass = Ent:GetClass()
			
			// Check the entity class is registered with the duplicator
			if EntType[EntClass] then
				
				duplicator[ply:UniqueID()].Ents[EntID] = duplicator.CopyGetEntArgs( ply, Ent, offset, EntClass)
				// yeah, just one line now
				
				if Ent:GetTable().BuildDupeInfo then
					duplicator[ply:UniqueID()].DupeInfo[EntID] = Ent:GetTable():BuildDupeInfo()
				end
				
				duplicator[ply:UniqueID()].DORInfo[EntID] = Ent:GetDeleteOnRemoveInfo()
				
			else
				Msg("Duplicator copy: Unknown class " .. (EntClass or "NIL") .. "\n")
			end
		end
		
		
		// Get info required to re-create each constraint
		for constID, Constraint in pairs(ConstraintTable) do
			
			
			// check the constraint has been registered with the duplicator
			if ConstraintType[Constraint:GetTable().Type] then
				
				local ctable, doconstraint = duplicator.CopyGetConstArgs( Constraint, function(id) return EntTable[id] end )
				
				if doconstraint then
					if (type(constID) == "number") then
						ctable.ConstID = constID
					end
					
					table.insert(duplicator[ply:UniqueID()].Constraints, ctable)
				end
				
			else
				Msg("Duplicator copy: Unknown constraint " .. (Constraint:GetTable().Type or "NIL") .. "\n")
			end
			
		end
		
		Msg("\n=======================--Copyed--=======================\n")
		
		return EntTable, ConstraintTable
	end


	// Paste duplicated ents
	function duplicator.Paste( ply, offset, filename )

		local Ents,Constraints = nil,nil
		local constIDtable, entIDtable, CreatedConstraints, CreatedEnts = {}, {}, {}, {}
		local HeadEntity = nil
		local pln = ply:UniqueID()
		
		Msg("\n=======================--PasteStart--=======================\n")
		
		if filename then 
			// TODO:
			// load file to ents/constraints tables
			// don't really need this any more
		elseif  duplicator[pln] then 
			
			Ents 			= 	duplicator[pln].Ents
			Constraints 	=	duplicator[pln].Constraints
			DupeInfo	 	=	duplicator[pln].DupeInfo
			DORInfo	 		=	duplicator[pln].DORInfo
			
		else
			return false
		end
		
		undo.Create("Duplicator")
			
		for entID, EntTable in pairs(Ents) do
			
			local EntClass = EntTable.Class
			
			// Check the antities class is registered with the duplicator
			if EntClass and EntType[EntClass] then
				
				local Args = duplicator.PasteGetEntArgs( ply, EntTable, offset )
				
				// make the Entity
				Ent = EntType[EntClass].Func(ply, unpack(Args))
				
				if (Ent && Ent:IsValid()) then
					undo.AddEntity( Ent )
					entIDtable[entID] = Ent
					table.insert(CreatedEnts,Ent)
					
					duplicator.PasteApplyEntMods( ply, Ent, EntTable )
				end
				
				if ( entID == duplicator[pln].HeadEntID ) then
					HeadEntity = Ent
				end
				
			else
			    Msg("Duplicator Paste: Unknown class " .. (EntClass or "NIL") .. "\n")
			end
			
		end
		
		for _, Constraint in pairs(Constraints) do
			
			// Check If the constraint type has been registered with the duplicator
			if Constraint.Type and ConstraintType[Constraint.Type] then
				
				local Args, DoConstraint = duplicator.PasteGetConstraintArgs( ply, Constraint, entIDtable, offset )
				
				// make the constraint
				if DoConstraint then
					local const = ConstraintType[Constraint.Type].Func(unpack(Args))
					table.insert(CreatedConstraints,const)
					undo.AddEntity( const )
					
					if (Constraint.ConstID) then
						constIDtable[Constraint.ConstID] = const
						Msg("Dupe add constraint ID: " .. Constraint.ConstID .. "\n")
					end
				end
				
			else
				Msg("Duplicator copy: Unknown constraint " .. (Constraint.Type or "NIL") .. "\n")
			end
		end
		undo.SetPlayer( ply )
		undo.Finish()
		
		duplicator.PasteApplyDupeInfo( ply, DupeInfo, entIDtable )
		
		duplicator.PasteApplyDORInfo( DORInfo, function(id) return entIDtable[id] end )
		
		//duplicator.PasteRotate( ply, HeadEntity, CreatedEnts ) //remember to turn ghost rotation back on too
		
		return CreatedEnts, CreatedConstraints
	end
	
	
	
	
	
	/*---------------------------------------------------------
   Name: duplicator.SaveToFile( table )
   Desc: 
	---------------------------------------------------------*/
	function duplicator.SaveToFile( pl, filename, desc )
		
		//save to a sub folder for each player
		local dir = "adv_duplicator/"..dupeshare.GetPlayerName(pl)
		
		//get and check the that filename contains no illegal characters
		local filename = dupeshare.ReplaceBadChar(tostring(pl:GetInfo( "adv_duplicator_save_filename" )))
		
		filename = dupeshare.FileNoOverWriteCheck( dir, filename )
		
		Msg("\nSaving to file: "..filename.."\n")
		
		//save to file
		local temp = {}
		
		//let's only save the junk we're acctually going to load
		local pln = pl:UniqueID()
		temp.Ents			= duplicator[pln].Ents
		temp.Constraints	= duplicator[pln].Constraints
		temp.DupeInfo		= duplicator[pln].DupeInfo
		temp.DORInfo		= duplicator[pln].DORInfo
		temp.HeadEntID		= duplicator[pln].HeadEntID
		temp.HoldAngle		= duplicator[pln].HoldAngle
		
		//add file versioning, it will come in handy later if save format changes
		temp["VersionInfo"] = {}
		temp["VersionInfo"]["FileVersion"]		= 0.4
		temp["VersionInfo"]["FileInfo"]			= "Advanced Duplicator Save File"
		temp["VersionInfo"]["Creator"]			= pl:GetName()	or "unknown"
		temp["VersionInfo"]["Desc"]				= desc 			or "none"
		temp["VersionInfo"]["NumOfEnts"]		= table.Count(temp.Ents)		or 0
		temp["VersionInfo"]["NumOfConst"]		= table.Count(temp.Constraints)	or 0
		temp["VersionInfo"]["NumOfDupeInfo"]	= table.Count(temp.DupeInfo)	or 0
		
		//prepare the table and save it to file 
		temp = dupeshare.PrepareTableToSave(temp)
		temp = util.TableToKeyValues(temp)
		file.Write(filename, temp)
		
		return filename //for sending to client after saving
	end
	
	
	function duplicator.LoadFromFile( pl, filename )
		
		local dir = "adv_duplicator"
		local ndir = dir.."/"..dupeshare.GetPlayerName(pl) //string.gsub(pl:GetName(), ":", "_") 
		
		if !file.Exists(dir.."/"..filename) && !file.Exists(ndir.."/"..filename) then
			print("File not found") return end
		
		// Clear Ghost entity if one exists
		local tool = pl:GetActiveWeapon()
		if (dupeshare.CurrentToolIsDuplicator(tool)) then
			tool:GetTable():GetToolObject():ReleaseGhostEntity()
			pl:SendLua("LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():ReleaseGhostEntity()")
		end
		
		local filepath
		if ( file.Exists(ndir.."/"..filename) ) then filepath = ndir.."/"..filename end
		if ( file.Exists(dir.."/"..filename) ) then filepath = dir.."/"..filename end
		
		//load from file
		local temp	= file.Read(filepath)
		temp		= util.KeyValuesToTable(temp)
		temp		= dupeshare.RebuildTableFromLoad(temp)
		
		
		//check the file was loaded and we understand it's version then load the data in to the tables
		local pln = pl:UniqueID()
		if (temp) and (temp["VersionInfo"]["FileVersion"] >= 0.4) then
			//current data file, an easy load
			duplicator[pln]					= {}
			duplicator[pln].Ents			= temp.Ents
			duplicator[pln].Constraints		= temp.Constraints
			duplicator[pln].DupeInfo		= temp.DupeInfo
			duplicator[pln].DORInfo			= temp.DORInfo
			duplicator[pln].HeadEntID		= temp.HeadEntID
			duplicator[pln].HoldAngle		= temp.HoldAngle
			
			Msg("Loaded new file "..filepath.."  version: "..temp["VersionInfo"]["FileVersion"].."\n")
			
		elseif (temp) and (temp["VersionInfo"]["FileVersion"] == 0.3) then
			//last data file, an easy load
			duplicator[pln]					= {}
			duplicator[pln].Ents			= temp.Ents
			duplicator[pln].Constraints		= temp.Constraints
			duplicator[pln].DupeInfo		= temp.DupeInfo
			duplicator[pln].DORInfo			= {} //this file verion doesn't have this info
			duplicator[pln].HeadEntID		= temp.HeadEntID
			duplicator[pln].HoldAngle		= temp.HoldAngle
			
			Msg("Loaded old file "..filepath.."  version: 0.3\n")
			
		elseif (temp) and (temp["VersionInfo"]["FileVersion"] <= 0.2) then
			//load the an old version data file, this is why file versioning is good
			duplicator[pln]					= {}
			duplicator[pln].Ents			= temp.Ents
			duplicator[pln].Constraints		= temp.Constraints
			duplicator[pln].DupeInfo 		= {}
			duplicator[pln].DORInfo			= {} //this file verion doesn't have this info
			duplicator[pln].HeadEntID		= temp.HeadEntID
			duplicator[pln].HoldAngle		= temp.HoldAngle
			
			//build the new type dupeinfo from the ents table
			for id, entTable in pairs(temp.Ents) do
				if (entTable.DupeInfo) then
					duplicator[pln].DupeInfo[id] = entTable.DupeInfo
				end
			end
			
			Msg("Loaded very old file "..filepath.."  version: "..temp["VersionInfo"]["FileVersion"].."\n")
			
		else
			Msg("\nFILE LOAD FAIL! something is wrong with this file:  "..filepath.."\n")
		end
		
	end
	
	
	
	
	
	
	function duplicator.RecieveFileContentStart( pl, cmd, args )
		
		Msg("DupeRecieveFileContentStart recieving file: "..args[1].."\n")
		
		if (!duplicator[pl:UniqueID()]) then duplicator[pl:UniqueID()] = {} end
		
		duplicator[pl:UniqueID()].templast		= tonumber(args[1])
		//duplicator[pl:UniqueID()].tempdir		= args[2]
		duplicator[pl:UniqueID()].tempfilename	= args[2]
		duplicator[pl:UniqueID()].tempnum		= 0
		duplicator[pl:UniqueID()].tempfile		= {}
		
	end
	concommand.Add("DupeRecieveFileContentStart", duplicator.RecieveFileContentStart)
	
	
	function duplicator.RecieveFileContent( pl, cmd, args )
		Msg("recieving piece ")
		if (args[1] == "") or (!args[1]) then return end
		duplicator[pl:UniqueID()].tempnum = duplicator[pl:UniqueID()].tempnum + 1
		
		Msg(args[1].." / "..duplicator[pl:UniqueID()].templast.." received: "..duplicator[pl:UniqueID()].tempnum.."\n")
		
		duplicator[pl:UniqueID()].tempfile[tonumber(args[1])] = args[2]
		
	end
	concommand.Add("_DFC", duplicator.RecieveFileContent)
	
	
	function duplicator.RecieveFileContentFinish( pl, cmd, args )
		local filepath = dupeshare.FileNoOverWriteCheck( "adv_duplicator/"..dupeshare.GetPlayerName(pl), duplicator[pl:UniqueID()].tempfilename )
		Msg("saving recieved file to "..filepath.."\n")
		duplicator.RecieveFileContentSave( pl, filepath )
	end
	concommand.Add("DupeRecieveFileContentFinish", duplicator.RecieveFileContentFinish)
	
	
	function duplicator.RecieveFileContentSave( pl, filepath )
		
		//reassemble the pieces
		local temp = ""
		for k, v in pairs(duplicator[pl:UniqueID()].tempfile) do
			temp = temp..v
		end
		
		//shitty string unprotect/decompression
		//temp = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(temp,"|mn","\t\t\"__name\"\t\t"),"|mt","\t\t\"__type\"\t\t"),"|mv|","\t\t\t\"V\"\t\t"),"|mD","\t\t\t\"DupeInfo\""),"|mN","\"Number\"\n"),"|mS","\"String\"\n"),"|mA","\"Angle\"\n"),"|mV","\"Vector\"\n"),"|mB","\"Bool\"\n"),"|mC","\"Class\""),"|mm","\"material\""),"|mp","\"prop_physics\""),"|VI","\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n"),"|wm","\"models"),"|NC","\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t"),"|nc","\"nocollide\"\n"),"|HE","\"HeadEntID\"\n"),"|ha","\n\t}\n\t\"holdangle\"\n\t{\n"),"|qY","\t\t\"Y\"\t\t\""),"|qz","\t\t\"z\"\t\t\""),"|qx","\t\t\"x\"\t\t\""),"|qA","\t\t\"A\"\t\t\""),"|qB","\t\t\"B\"\t\t\""),"|qg","\t\t\"g\"\t\t\""),"|qr","\t\t\"r\"\t\t\""),"|qp","\t\t\"p\"\t\t\""),"|HA","\"HoldAngle\"\n"),"|n","\n"),"|4t","\t\t\t\t"),"|3t","\t\t\t"),"|2t","\t\t"),"|t","\t"),"|N","name"),"|Q","\"")
		
		temp = dupeshare.DeCompress(temp, true)
		
		file.Write(filepath, temp)
		
		pl:PrintMessage(HUD_PRINTTALK, "Your file: \""..filepath.."\" was uploaded to the server")
		pl:PrintMessage(HUD_PRINTCONSOLE, "Your file: \""..filepath.."\" was uploaded to the server")
		
		Msg("player: \""..(pl:GetName() or "unknown").."\" uploaded file: \""..filepath.."\"")
		
		local tool = pl:GetActiveWeapon()
		if (dupeshare.CurrentToolIsDuplicator(tool, true)) then
			tool:GetTable():GetToolObject():UpdateList()
		end
		
		umsg.Start("ClientSendFinished", pl)
		umsg.End()
	end
	
	
	
	
	
	
	function duplicator.SaveAndSendSaveToClient( pl, filename, desc )
		local filepath = duplicator.SaveToFile( pl, filename, desc )
		duplicator.SendSaveToClient( pl, filepath )
	end
	
	function duplicator.SendSaveToClient( pl, filename )
		local pln = pl:UniqueID()
		if (!duplicator[pln]) then duplicator[pln] = {} end
		if (duplicator[pln].temp) then return end //then were sending already and give up
		
		local filepath = filename
		local dir = "adv_duplicator"
		local ndir = dir.."/"..dupeshare.GetPlayerName(pl)
		
		if !file.Exists(filepath) then //if filepath was just a file name then try to find the file, for sending from list
			if !file.Exists(dir.."/"..filename) && !file.Exists(ndir.."/"..filename) then
				Msg("File not found: \""..filepath.."\"\n") return end
			
			if ( file.Exists(ndir.."/"..filename) ) then filepath = ndir.."/"..filename end
			if ( file.Exists(dir.."/"..filename) ) then filepath = dir.."/"..filename end
		end
		
		filename = dupeshare.GetFileFromFilename(filepath)
		
		duplicator[pln].temp = file.Read(filepath)
		
		//duplicator[pln].temp = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(duplicator[pln].temp,"\t\t\"__name\"\t\t","|mn"),"\t\t\"__type\"\t\t","|mt"),"\t\t\t\"V\"\t\t","|mv|"),"\t\t\t\"DupeInfo\"","|mD"),"\"Number\"\n","|mN"),"\"String\"\n","|mS"),"\"Angle\"\n","|mA"),"\"Vector\"\n","|mV"),"\"Bool\"\n","|mB"),"\"Class\"","|mC"),"\"material\"","|mm"),"\"prop_physics\"","|mp"),"\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n","|VI"),"\"models","|wm"),"\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t","|NC"),"\"nocollide\"\n","|nc"),"\"HeadEntID\"\n","|HE"),"\n\t}\n\t\"holdangle\"\n\t{\n","|ha"),"\t\t\"Y\"\t\t\"","|qY"),"\t\t\"z\"\t\t\"","|qz"),"\t\t\"x\"\t\t\"","|qx"),"\t\t\"A\"\t\t\"","|qA"),"\t\t\"B\"\t\t\"","|qB"),"\t\t\"g\"\t\t\"","|qg"),"\t\t\"r\"\t\t\"","|qr"),"\t\t\"p\"\t\t\"","|qp"),"\"HoldAngle\"\n","|HA"),"\t\t\t\t","|4"),"\t\t\t","|3"),"name","|N")
		
		duplicator[pln].temp = dupeshare.Compress(duplicator[pln].temp, false)
		
		local len = string.len(duplicator[pln].temp)
		local last = math.ceil(len / 220) + 1 //+1 because the client counts the first piece recieved as 1 not 0
		
		umsg.Start("RecieveSaveStart", pl)
			umsg.Short(last)
			umsg.String(filename)
			umsg.String(ndir)
		umsg.End()
		Msg("sending file \""..filename..".txt\" in "..tostring(last).." pieces. len: "..tostring(len).."\n")
		
		duplicator.SendSaveToClientData(pl, pln, len, 0, last)
		
	end
	
	function duplicator.SendSaveToClientData(pl, pln, len, offset, last)
		
		for k=0,1 do //sends two pieces
			
			if ((offset + k + 1) <= last) then
				Msg("sending string: "..tostring((offset + k) * 220).." / "..len.." k: "..k.." piece: "..(offset + k + 1).." / "..last.."\n")
				umsg.Start("RecieveSaveData", pl)
					umsg.Short(offset + k + 1) //cause sometimes these are reccieved out of order
					
					if ((offset + k + 1) == last) then
						umsg.String(string.Right(duplicator[pln].temp, (len - ((last - 2) * 220))))
						//umsg.String(string.sub(duplicator[pln].temp, ((offset + k) * 220)))
						Msg("send last piece\n")
					else
						umsg.String(string.Right(string.Left(duplicator[pln].temp, ((offset + k) * 220)),220))
						//local pos = ((offset + k) * 220)
						//umsg.String(string.sub(duplicator[pln].temp, pos, (pos +220) ))
					end
					
				umsg.End()
			else
				break
			end
		end
		
		if (offset + 3) <= last then
			timer.Simple( 0.1, duplicator.SendSaveToClientData, pl, pln, len, (offset + 2), last )
		else
			duplicator[pln].temp = nil //clear this to send again
		end
		
	end
	
	
	
	
	
	/*---------------------------------------------------------
   Name: duplicator.PrepareTableToSave( table )
   Desc: Converts a table in to a lot tables to protect 
		vectors, angles, bools, numbers, and indexes
		from being horribly raped by TableToKeyValues
	---------------------------------------------------------*/
	/*function duplicator.PrepareTableToSave( t, done)
		
		local done = done or {}
		local tbl = {}
		
		for k, v in pairs ( t ) do
			if ( type( v ) == "table" and !done[ v ] ) then
				done[ v ] = true
				tbl[ k ] = duplicator.PrepareTableToSave ( v, done )
				tbl[k].__name = k
			else
				if ( type(v) == "Vector" ) then
					local x, y, z = v.x, v.y, v.z
					if y == 0 then y = nil end
					if z == 0 then z = nil end
					tbl[k] = { __type = "Vector", x = x, y = y, z = z, __name = k }
				elseif ( type(v) == "Angle" ) then
					local p,y,r = v.pitch, v.yaw, v.roll
					if p == 0 then p = nil end
					if y == 0 then y = nil end
					if r == 0 then r = nil end
					tbl[k] = { __type = "Angle", p = p, y = y, r = r, __name = k }
				elseif ( type(v) == "boolean" ) then
					tbl[k] = { __type = "Bool", v = tostring( v ), __name = k }
				elseif ( type(v) == "number" ) then
					tbl[k] = { __type = "Number", v = tostring( v ), __name = k }
				else
					tbl[k] = { __type = "String", v = tostring( v ), __name = k }
				end
			end
		end
		
		return tbl
	end*/
	

	/*---------------------------------------------------------
	   Name: duplicator.RebuildTableFromLoad( table )
	   Desc: Removes the protection added by PrepareTableToSave
			after table is loaded with KeyValuesToTable
	---------------------------------------------------------*/
	/*function duplicator.RebuildTableFromLoad( t, done )

		local done = done or {}
		local tbl = {}
		
		for k, v in pairs ( t ) do
			if ( type( v ) == "table" and !done[ v ] ) then
				done[ v ] = true
				if ( v.__type ) then
					if ( v.__type == "Vector" ) then
						tbl[ v.__name ] = Vector( v.x, v.y, v.z )
					elseif ( v.__type == "Angle" ) then
						tbl[ v.__name ] = Angle( v.p, v.y, v.r )
					elseif ( v.__type == "Bool" ) then
						tbl[ v.__name ] = util.tobool( v.v )
					elseif ( v.__type == "Number" ) then
						tbl[ v.__name ] = tonumber( v.v )
					elseif ( v.__type == "String" ) then
						tbl[ v.__name ] = tostring( v.v )
					end
				else
					tbl[ v.__name ] = duplicator.RebuildTableFromLoad ( v, done )
				end
			else
				if k != "__name" then //don't add the table names to output
					tbl[ k ] = v
				end
			end
		end
		
		return tbl
		
	end*/
	
	
	/*---------------------------------------------------------
	   Name: duplicator.FileNoOverWriteCheck( dir, filename )
	   Desc: Check if dir and filename exist and if so renames
	   returns filepath (dir.."/"..filename..".txt"), dir, filename
	---------------------------------------------------------*/
	/*function duplicator.FileNoOverWriteCheck( dir, filename )
		
		if !file.Exists(dir) then 
			file.CreateDir(dir)
		elseif !file.IsDir(dir) then
			local x = 0
			while x ~= nil do
				x = x + 1
				if not file.Exists(dir.."_"..tostring(x)) then
					dir = dir.."_"..tostring(x)
					file.CreateDir(dir)
					x = nil
				end
			end
		end
		
		if file.Exists(dir .. "/" .. filename .. ".txt") then
			local x = 0
			while x ~= nil do
				x = x + 1
				if not file.Exists(dir.."/"..filename.."_"..tostring(x)..".txt") then
					filename = filename.."_"..tostring(x)
					x = nil
				end
			end
		end
		
		local filepath = dir .. "/" .. filename .. ".txt"
		
		return filepath, filename, dir
	end*/
	
	
	/*---------------------------------------------------------
		cause garry's crashes the server
	and this one returns the filename without extention
	---------------------------------------------------------*/
	/*function duplicator.GetFileFromFilename(path)
		
		for i = string.len(path), 1, -1 do
			local str = string.sub(path, i, i)
			if str == "/" or str == "\\" then path = string.sub(path, (i + 1)) end
		end
		
		//removed .txt from the end if its there.
		if (string.sub(path, -4) == ".txt") then
			path = string.sub(path, 1, -5)
		end
		
		return path
	end*/
	
	
	
	
	/*---------------------------------------------------------
		Name: duplicator.Paste* sub functions
		Desc: functions used during duplicator.Paste
	---------------------------------------------------------*/
	function duplicator.CopyGetEntArgs( ply, Ent, offset, EntClass )
		
		local etable	= {Class = EntClass}
		local BoneArgs	= nil
		local EntityTable = Ent:GetTable()
		
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
			if	type(arg) == "table"	then BoneArgs = arg end
			etable[arg] = Arg
		end
		
		// Get bone args
		if EntityTable.Bones or BoneArgs then
			
			local Bones = {}
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

							if	barg == "ang"	or barg == "angle"		then bArg = Phys:GetAngle()
							elseif	barg == "pos"	or barg == "position"		then bArg = Phys:GetPos() - offset
							elseif	barg == "vel"	or barg == "velocity"		then bArg = Phys:GetVelocity()
							elseif	barg == "avel"	or barg == "angvelocity"	then bArg = Phys:GetAngleVelocity()
							elseif	barg == "mass"					then bArg = Phys:GetMass()
							elseif	barg == "inertia"				then bArg = Phys:GetInertia()
							elseif	barg == "damping"				then bArg = Phys:GetDamping()
							elseif	barg == "frozen" or barg == "motionenabled"	then bArg = !Phys:IsMoveable()
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
		end
		
		for ModifierType, _ in pairs(EntityModifiers) do
			if EntityTable[ModifierType] then
				etable[ModifierType] = EntityTable[ModifierType]
			end
		end
		
		// Hack to copy decals
		if EntityTable.decals then
			etable.decals = EntityTable.decals
		end
		
		return etable
		
	end
	
	function duplicator.CopyGetConstArgs( Constraint, GetEntByID )
		
		/*if (!Constraint:GetTable().Type) then
			return nil, nil
		end*/
		
		ctable = {Type = Constraint:GetTable().Type}
		local doconstraint = true
		
		for _,Key in pairs(ConstraintType[Constraint:GetTable().Type].Args) do
			
			local Arg = Constraint:GetTable()[Key]
			local len = string.len(Key)
			local key = string.lower(Key)
			
			if (Arg) then
				
				// Do special cases
				if		string.find(key, "lpos")  	and ( len == 4 or len == 5 )
				or		string.find(key, "ang" )  	and ( len == 3 or len == 4 )	then Arg = Arg
				elseif	string.find(key, "wpos")	and ( len == 4 or len == 5 )	then Arg = Arg - offset
				elseif	key == "pl" 				or key == "ply"					then Arg = Arg:SteamID()
				elseif	string.find(key, "ent" )  	and ( len == 3 or len == 4 )	then Arg = Arg:EntIndex() 
					if !GetEntByID(Arg) then doconstraint = nil end
				end
				
				// Nullify zero value args
				if tostring(Arg) == "0.000 0.000 0.000" or Arg == false then Arg = nil end
				
			end
			
			ctable[Key] = Arg
		end
		
		return ctable, doconstraint
		
	end
	
	
	
	function duplicator.GetEntClassArgs(entClass)
		if (EntType[entClass]) then
			return EntType[entClass].Args
		else
			return false
		end
	end
	
	
	/*---------------------------------------------------------
		Name: duplicator.Paste* sub functions
		Desc: functions used during duplicator.Paste
	---------------------------------------------------------*/
	function duplicator.PasteGetEntArgs( ply, EntTable, offset )
		
		local Args, BoneArgs, nBone = {}, nil, nil
		
		for n,Key in pairs(EntType[EntTable.Class].Args) do
			
			if type(Key) == "table" then
				BoneArgs = Key
				nBone	 = n
			else
				local Arg = EntTable[Key]
				
				key = string.lower(Key)
				
				if		key == "ang"	or key == "angle"			then Arg = Arg or Vector(0,0,0)
				elseif	key == "pos"	or key == "position"		then Arg = Arg + offset or Vector(0,0,0)
				elseif	key == "vel"	or key == "velocity"		then Arg = Arg or Vector(0,0,0)
				elseif	key == "avel"	or key == "anglevelocity"	then Arg = Arg or Vector(0,0,0)
				elseif	key == "pl" 	or key == "ply"				then Arg = ply 
				// TODO:  Arg = ply.GetBySteamID(Arg)
				end
				
				Args[n] = Arg
			end
		end
		
		if EntTable.Bones and BoneArgs then
			
			local Arg = {}
						
			// Get args for each bone
			for Bone,Args in pairs(EntTable.Bones) do
				Arg[Bone] = {}
				
				for n, bKey in pairs( BoneArgs ) do
					
					local bArg = EntTable.Bones[Bone][bKey] or tostring(0)
					
					// Do special cases
					local bkey = string.lower(bKey)
					
					if	bkey == "ang"	or bkey == "angle"				then bArg = bArg or Vector(0,0,0)
					elseif	bkey == "pos"	or bkey == "position"		then bArg = bArg + offset or Vector(0,0,0)
					elseif	bkey == "vel"	or bkey == "velocity"		then bArg = bArg or Vector(0,0,0)
					elseif	bkey == "avel"	or bkey == "angvelocity"	then bArg = bArg or Vector(0,0,0)
					end
					
					Arg[Bone][n] = bArg
				end
			end
			
			Args[nBone] = Arg
		end
		
		return Args
		
	end
	
	
	function duplicator.PasteApplyEntMods( ply, Ent, EntTable )
	
		for ModifierType, Modifier in pairs(EntityModifiers) do
			if EntTable[ModifierType] then
				local args = {}

				for n,arg in pairs(Modifier.Args) do
					args[n] = EntTable[ModifierType][arg]
				end

				Modifier.Func( ply, Ent, unpack(args))
			end
		end
		
		if EntTable.Bones then
			for ModifierType, Modifier in pairs(EntityBoneModifiers) do
				for Bone,Args in pairs(EntTable.Bones) do
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
		
		if EntTable.decals then
			// Hack to paste decals
			Ent:GetTable().decals = EntTable.decals
			timer.Simple( 0.001, 		// HORRID
			function( tbl,Ent ) 
				for n, DecalInfo in pairs(tbl) do

					local decal, Pos1, Pos2 = DecalInfo[1],
						Ent:LocalToWorld( DecalInfo[2]),
						Ent:LocalToWorld( DecalInfo[3])

					util.Decal( decal, Pos1, Pos2 )
				end
			end
			,EntTable.decals,Ent )
		end
	end
	
	
	// Get the args to make the constraints
	function duplicator.PasteGetConstraintArgs( ply, Constraint, entIDtable, offset )
		local Args = {}
		local DoConstraint = true
		
		// Get the args that we need from the ConstraintType table
		for n,key in pairs(ConstraintType[Constraint.Type].Args) do
			
			local Arg = Constraint[key]
			local len = string.len(key)
			
			// DO SPECIAL CASES
			// If key represents an entity, convert from an entID back to an ent
			if	string.find(key, "Ent")		and ( len == 3 or len == 4 ) then
				Arg = entIDtable[Arg]
				if !Arg or !Arg:IsValid() then DoConstraint = nil end
				
			// If key represents an Local angle or vector, convert from string, back to a vector
			elseif	(string.find(key, "LPos")	and ( len == 4 or len == 5 ))
			or	(string.find(key, "Ang")	and ( len == 3 or len == 4 )) then 
				Arg = Arg or Vector(0,0,0)
				
			// If key represents a World Vector or angle, convert from string, back to a vector
			elseif	(string.find(key, "WPos")	and ( len == 4 or len == 5 )) then
				Arg = Arg + offset or Vector(0,0,0)
				
			// If key represents a ply, convert from steamid back to a ply
			elseif	key == "pl" or key == "ply" or key == "ply" then
				--Arg = ply.GetBySteamID(Arg)
				Arg = ply
				if not Arg:IsValid() then DoConstraint = nil end
			end
			
			Args[n] = Arg
		end
		
		return Args, DoConstraint
	end
	
	
	// Apply DupeInfo for wire stuff
	function duplicator.PasteApplyDupeInfo( ply, DupeInfoTable, entIDtable )
		for id, infoTable in pairs(DupeInfoTable) do
			local ent = entIDtable[id]
			if (ent) and (ent:IsValid()) and (infoTable) and (ent.ApplyDupeInfo) then
			    ent:ApplyDupeInfo(
					ply, ent, infoTable,
					function(id) return entIDtable[id] end,
					function(id) return constIDtable[id] end
					)
			end
		end
	end
	
	// Apply DORInfo for DeleteOnRemove
	function duplicator.PasteApplyDORInfo( DORInfoTable, GetentID )
		
		for id, DORInfo in pairs(DORInfoTable) do
			local ent = GetentID(id)
			if (ent) and (ent:IsValid()) and (DORInfo) then
				ent:SetDeleteOnRemoveInfo(DORInfo, function(id) return GetentID(id) end)
				
				for _,entindex in pairs(DORInfo) do
					local ent2 = GetentID(entindex)
					if (ent2 && ent2:IsValid() && ent2:EntIndex() > 0) then
						// Add the entity
						
						ent:DeleteOnRemove(ent2)
					end
				end
				
			end
		end
		
	end
	
	
	// Rotate entities relative to the ply's hold angles
	function duplicator.PasteRotate( ply, HeadEntity, CreatedEnts )
		
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
			
			HeadEntity:SetAngles( angle - duplicator[ply:UniqueID()].HoldAngle )
			
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
	end
	
	
	
	function duplicator.GetEntType( EntClass )
		return EntType[EntClass]
	end
	
	
	function duplicator.KnownConstraintType( someConstraintType )
		if (ConstraintType[someConstraintType])	then 
			return true
		else
			return false
		end
	end

	function duplicator.ConstraintTypeFunc( someConstraintType, Args )
		return ConstraintType[someConstraintType].Func(unpack(Args))
	end
	
	
	
	
	/*---------------------------------------------------------
		Name: duplicator.Make* functions
		Desc: functions used to make stuff
	---------------------------------------------------------*/
	
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
		
		--if not gamemode.Call( "plySpawnRagdoll", ply, Model ) then return end
		local Ent = ents.Create( "prop_ragdoll" )
			Ent:SetModel( Model )
			Ent:SetAngles( Ang )
			Ent:SetPos( Pos )
		Ent:Spawn()
		
		for Bone, Args in pairs(Bones) do
			
			local Phys = Ent:GetPhysicsObjectNum(tonumber(Bone))
			
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

		--if not gamemode.Call( "plySpawnVehicle", ply, Model ) then return end
		local Ent = ents.Create( Class )
			Ent:SetModel( Model )
			Ent:SetAngles( Ang )
			Ent:SetPos( Pos )
			if (Class == "prop_vehicle_prisoner_pod") then
				Ent:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
			else
				Ent:SetKeyValue("vehiclescript", "scripts/vehicles/jeep_test.txt")
			end
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
	duplicator.RegisterEntityClass( "prop_vehicle_prisoner_pod", duplicator.MakeVehicle, "Pos", "Ang","Model", "Class", "Vel", "aVel", "frozen" )



	// Returns all ents & constraints in a system
	/*function duplicator.GetEnts(ent, EntTable, ConstraintTable)

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
	*/
	
	
	// Returns all ents & constraints in a system
	function duplicator.GetEnts(ent, EntTable, ConstraintTable)

		local EntTable			= EntTable	  or {}
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
			elseif ( !ConstraintTable[const:GetTable()] ) then
				
				// Add constraint to the constraints table
				ConstraintTable[const:GetTable()] = const
				
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
