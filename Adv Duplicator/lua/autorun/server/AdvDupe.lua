
AddCSLuaFile( "autorun/client/cl_advdupe.lua" )
AddCSLuaFile( "autorun/shared/dupeshare.lua" )

include( "autorun/shared/dupeshare.lua" )
if (!dupeshare) then Msg("===AdvDupe: Error! dupeshare module not loaded\n") end
/*---------------------------------------------------------
   Advanced Duplicator module
   Author: TAD2020
   Thanks to: TheApathetic, SatriAli, Erkle
---------------------------------------------------------*/

AdvDupe = {}


if (CLIENT) then return end

AdvDupe.Version = 1.83
AdvDupe.ToolVersion = 1.81
AdvDupe.FileVersion = 0.83
local MAXDOWNLOADLENGTH = 200

/*---------------------------------------------------------
  Process and save given dupe tables to file
---------------------------------------------------------*/
function AdvDupe.SaveDupeTablesToFile( pl, EntTables, ConstraintTables, HeadEntityIdx, HoldAngle, HoldPos, filename, desc, StartPos, debugsave )
	
	//save to a sub folder for each player
	//local dir = "adv_duplicator/"..dupeshare.GetPlayerName(pl)
	if (!AdvDupe[pl]) then AdvDupe[pl] = {} end
	local dir = AdvDupe[pl].cdir or AdvDupe.GetPlayersFolder(pl)
	
	//get and check the that filename contains no illegal characters
	local filename = dupeshare.ReplaceBadChar(filename)
	//tostring(pl:GetInfo( "adv_duplicator_save_filename" )))
	
	filename = dupeshare.FileNoOverWriteCheck( dir, filename )
	
	//save to file
	local temp = {}
	temp.HeadEntityIdx		= HeadEntityIdx
	temp.HoldAngle			= HoldAngle
	temp.HoldPos			= HoldPos
	temp.Entities			= EntTables
	ConstsTable				= {}
	for k, v in pairs(ConstraintTables) do
		table.insert( ConstsTable, v )
	end
	temp.Constraints		= ConstsTable
	
	local Creator			= pl:GetName()	or "unknown"
	local NumOfEnts			= table.Count(EntTables) or 0
	local NumOfConst		= table.Count(ConstraintTables) or 0
	
	local Header = {}
	Header[1] = "Type:"			.."AdvDupe File"
	Header[2] =	"Creator:"		..string.format('%q', Creator)
	Header[3] =	"Date:"			..os.date("%m/%d/%y")
	if (!desc) or (desc == "") then desc = "none" end
	Header[4] =	"Description:"	..string.format('%q', desc)
	Header[5] =	"Entities:"		..NumOfEnts
	Header[6] =	"Constraints:"	..NumOfConst
	
	local ExtraHeader = {}
	ExtraHeader[1] = "FileVersion:"				..AdvDupe.FileVersion
	ExtraHeader[2] = "AdvDupeVersion:"			..AdvDupe.Version
	ExtraHeader[3] = "AdvDupeToolVersion:"		..AdvDupe.ToolVersion
	ExtraHeader[4] = "AdvDupeSharedVersion:"	..dupeshare.Version
	ExtraHeader[5] = "SerialiserVersion:"		..Serialiser.Version
	ExtraHeader[6] = "WireVersion:"				..(WireVersion or "Not Installed")
	ExtraHeader[7] = "Time:"					..os.date("%I:%M %p")
	ExtraHeader[8] = "Head:"					..HeadEntityIdx
	ExtraHeader[9] = "HoldAngle:"				..string.format( "%g,%g,%g", HoldAngle.pitch, HoldAngle.yaw, HoldAngle.roll )
	ExtraHeader[10] = "HoldPos:"				..string.format( "%g,%g,%g", HoldPos.x, HoldPos.y, HoldPos.z )
	ExtraHeader[11] = "StartPos:"				..string.format( "%g,%g,%g", StartPos.x, StartPos.y, StartPos.z )
	
	Serialiser.SaveTablesToFile( pl, filename, Header, ExtraHeader, NumOfEnts, EntTables, NumOfConst, ConstsTable, debugsave )
	
	//prepare the table and save it to file
	/*local StrTbl = {}
	temp, StrTbl = dupeshare.PrepareTableToSave(temp)
	temp["strtbl"] = StrTbl
	
	temp = util.TableToKeyValues(temp)
	file.Write(filename, temp)*/
	
	return filename, Creator, desc , NumOfEnts, NumOfConst, AdvDupe.FileVersion //for sending to client after saving
end

/*---------------------------------------------------------
  Load and return dupe tables from given file
---------------------------------------------------------*/
function AdvDupe.LoadDupeTableFromFile( pl, filepath )
	
	if ( !file.Exists(filepath) ) then return end
	
	//load from file
	//local temp = file.Read(filepath)
	
	local tool = AdvDupe.GetAdvDupeToolObj(pl)
	if ( !tool ) then return end
	
	local function Load1(pl, filepath, tool, temp)
		
		//
		//	new file format
		//
		if ( string.Left(temp, 5) != "\"Out\"") then
			
			//local HeaderTbl, ExtraHeaderTbl, Data = Serialiser.DeserialiseWithHeaders( temp )
			
			local function Load2NewFile(pl, filepath, tool, HeaderTbl, ExtraHeaderTbl, Data)
				if ( HeaderTbl.Type ) and ( HeaderTbl.Type == "AdvDupe File" ) then
					
					Msg("AdvDupe:Loaded new file "..filepath.."  version: "..ExtraHeaderTbl.FileVersion.."\n")
					
					ExtraHeaderTbl.FileVersion = tonumber(ExtraHeaderTbl.FileVersion)
					
					if (ExtraHeaderTbl.FileVersion > AdvDupe.FileVersion) then
						Msg("AdvDupeINFO:File is newer than installed version, failure may occure, you should update.")
					end
					
					if ( ExtraHeaderTbl.FileVersion >= 0.82 ) and ( ExtraHeaderTbl.FileVersion < 0.9 )then
						
						local a,b,c = ExtraHeaderTbl.HoldAngle:match("(.-),(.-),(.+)")
						local HoldAngle = Angle( tonumber(a), tonumber(b), tonumber(c) )
						
						local a,b,c = ExtraHeaderTbl.HoldPos:match("(.-),(.-),(.+)")
						local HoldPos = Vector( tonumber(a), tonumber(b), tonumber(c) )
						
						local StartPos
						if ( ExtraHeaderTbl.FileVersion >= 0.83 ) then
							local a,b,c = ExtraHeaderTbl.StartPos:match("(.-),(.-),(.+)")
							StartPos = Vector( tonumber(a), tonumber(b), tonumber(c) )
						end
						
						tool:LoadFileCallBack( filepath,
							Data.Entities, Data.Constraints,
							{},{}, tonumber(ExtraHeaderTbl.Head),
							HoldAngle,
							HoldPos, false,
							HeaderTbl.Creator:sub(2, -2),
							HeaderTbl.Description:sub(2, -2),
							tonumber(HeaderTbl.Entities),
							tonumber(HeaderTbl.Constraints),
							ExtraHeaderTbl.FileVersion,
							HeaderTbl.Date,
							ExtraHeaderTbl.Time, StartPos
						)
					elseif ( ExtraHeaderTbl.FileVersion <= 0.81 ) then
						tool:LoadFileCallBack( filepath,
							Data.Entities, Data.Constraints,
							{},{}, Data.HeadEntityIdx,
							Data.HoldAngle,
							Data.HoldPos, false,
							HeaderTbl.Creator:sub(2, -2),
							HeaderTbl.Description:sub(2, -2),
							tonumber(HeaderTbl.Entities),
							tonumber(HeaderTbl.Constraints),
							ExtraHeaderTbl.FileVersion,
							HeaderTbl.Date,
							ExtraHeaderTbl.Time
						)
					end
					
					/*return Data.Entities, Data.Constraints,
					{},{}, Data.HeadEntityIdx,
					Data.HoldAngle,
					Data.HoldPos, false, 
					HeaderTbl.Creator:sub(2, -2),
					HeaderTbl.Description:sub(2, -2), 
					HeaderTbl.Entities,
					HeaderTbl.Constraints,
					ExtraHeaderTbl.FileVersion,
					HeaderTbl.Date,
					ExtraHeaderTbl.Time*/
					
				elseif ( HeaderTbl.Type ) and ( HeaderTbl.Type == "Contraption Saver File" ) then
					
					Msg("AdvDupe:Loaded Contraption Saver file "..filepath.."  version: "..ExtraHeaderTbl.Version.."\n")
					
					/*for k,v in pairs(Data.Entities) do
						v.LocalPos.z = v.LocalPos.z + Data.Height + 8
					end*/
					
					/*for k,v in pairs(Data.Constraints) do
						if (v.Entity) then
							for b, j in pairs(v.Entity) do
								if ( j.World and j.LPos ) then
									v.Entity[b].LPos.z = j.LPos.z + Data.Height + 8
								end
							end
						end
					end*/
					
					pl:ConCommand( "adv_duplicator_height "..(Data.Height + 8) )
					
					tool:LoadFileCallBack( filepath,
						Data.Entities, Data.Constraints,
						{},{}, Data.Head, Angle(0,0,0), 
						Vector(0,0, -(Data.Height + 8)), //Data.Entities[Data.Head].LocalPos.z + 
						false, HeaderTbl.Creator:sub(2, -2),
						"Contraption Saver file v"..ExtraHeaderTbl.Version, 
						tonumber(HeaderTbl.Entities),
						tonumber(HeaderTbl.Constraints),
						tonumber(ExtraHeaderTbl.Version),
						HeaderTbl.Date,
						"n/a"
					)
					
				elseif (Data.Information) then
					Msg("AdvDupe:Loaded old Contraption Saver file version "..Data.Information.Version.."\n")
					
					//find the lowest and use that as the head
					local head,low
					for k,v in pairs(Data.Entities) do
						if (!head) or (v.Pos.z < low) then
							head = k
							low = v.Pos.z
						end
					end
					
					//Convert the Pos and Angle keys to a system AdvDupe understands
					AdvDupe.ConvertPositionsToLocal( Data.Entities, Data.Constraints, Data.Entities[head].Pos + Vector(0,0,-15), Angle(0,0,0) )
					
					tool:LoadFileCallBack( filepath,
						Data.Entities, Data.Constraints,
						{},{}, head, Angle(0,0,0), Vector(0,0,0), false, 
						Data.Information.Creator,
						"Old Contraption Saver file v"..Data.Information.Version, 
						Data.Information.Entities,
						Data.Information.Constraints,
						Data.Information.Version,
						Data.Information.Date,
						"n/a"
					)
					
					/*return Data.Entities, Data.Constraints,
					{},{}, head,
					Angle(0,0,0),
					Vector(0,0,0), false, 
					Data.Information.Creator,
					"Old Contraption Saver file v"..Data.Information.Version, 
					Data.Information.Entities,
					Data.Information.Constraints,
					Data.Information.Version,
					Data.Information.Date,
					"n/a"*/
					
				else
					AdvDupe.SendClientError(pl, "Unknown File Type or Bad File")
					Msg("AdvDupeERROR: Unknown File Type or Bad File\n")
					return
				end
			end
			
			//timer.Simple(.1, Load2NewFile, pl, filepath, tool, HeaderTbl, ExtraHeaderTbl, Data)
			
			Serialiser.DeserialiseWithHeaders( temp, Load2NewFile, pl, filepath, tool )
			
			return //or it will try to load as an old file
		//
		//	old file formats
		//
		else
			temp = util.KeyValuesToTable(temp)
			if ( temp["VersionInfo"] or temp["versioninfo"] ) then //pre-0.6x file, it ueses a different meathod os stroing FullCase
				Msg("AdvDipe: Loading old legacy file type\n")
				temp = dupeshare.RebuildTableFromLoad_Old(temp)
			elseif ( temp["strtbl"] ) then // v0.7x
				Msg("AdvDipe: Loading v0.7x file type\n")
				local StrTbl = temp["strtbl"]
				temp["strtbl"] = nil
				temp = dupeshare.RebuildTableFromLoad(temp, {}, StrTbl)
			else //0.6x
				Msg("AdvDipe: Loading v0.6x file type\n")
				temp = dupeshare.RebuildTableFromLoad(temp)
			end
		end
		
		if (temp) and (temp["VersionInfo"]) and (temp["VersionInfo"]["FileVersion"] > AdvDupe.FileVersion) then
			Msg("AdvDupeINFO:File is newer than installed version, failure may occure, you should update.")
		end
		
		
		local function Load3(pl, filepath, tool, temp)
			//check the file was loaded and we understand it's version then load the data in to the tables
			if (temp) and (temp["VersionInfo"]) and (temp["VersionInfo"]["FileVersion"] >= 0.6) then
				Msg("AdvDupe:Loaded old file "..filepath.."  version: "..temp.VersionInfo.FileVersion.."\n")
				
				tool:LoadFileCallBack( filepath,
					temp.EntTables, temp.ConstraintTables, {},{}, 
					temp.HeadEntityIdx, temp.HoldAngle, temp.HoldPos, 
					false, temp.VersionInfo.Creator, temp.VersionInfo.Desc, 
					temp.VersionInfo.NumOfEnts, temp.VersionInfo.NumOfConst, 
					temp.VersionInfo.FileVersion
				)
				
				/*return temp.EntTables, temp.ConstraintTables, {},{}, 
				temp.HeadEntityIdx, temp.HoldAngle, temp.HoldPos, false, 
				temp.VersionInfo.Creator, temp.VersionInfo.Desc, temp.VersionInfo.NumOfEnts, 
				temp.VersionInfo.NumOfConst, temp.VersionInfo.FileVersion*/
				
			//Legacy versions, there are no version 0.5 files
			elseif (temp) and (temp["VersionInfo"]) and (temp["VersionInfo"]["FileVersion"] <= 0.4) then
				Msg("AdvDupe:Loaded old legacy file "..filepath.."  version: "..temp.VersionInfo.FileVersion.."\n")
				
				if (temp["VersionInfo"]["FileVersion"] <= 0.2) then
					temp.DupeInfo = {}
					for id, entTable in pairs(temp.Ents) do
						if (entTable.DupeInfo) then
							temp.DupeInfo[id] = entTable.DupeInfo
						end
					end
				end
				
				tool:LoadFileCallBack( filepath,
					temp.Ents, temp.Constraints, temp.DupeInfo, 
					(temp.DORInfo or {}), temp.HeadEntID, temp.HoldAngle, Vector(0,0,0), 
					true, temp.VersionInfo.Creator, temp.VersionInfo.Desc, 
					temp.VersionInfo.NumOfEnts, temp.VersionInfo.NumOfConst, 
					temp.VersionInfo.FileVersion
				)
				
				/*return temp.Ents, temp.Constraints, temp.DupeInfo, 
				(temp.DORInfo or {}), temp.HeadEntID, temp.HoldAngle, Vector(0,0,0), 
				true, temp.VersionInfo.Creator, temp.VersionInfo.Desc, 
				temp.VersionInfo.NumOfEnts, temp.VersionInfo.NumOfConst, 
				temp.VersionInfo.FileVersion*/
				
			elseif (temp) and (temp["Information"]) then //Old Contrpation Saver File
				Msg("AdvDupe:Loading old Contraption Saver file.\n")
				
				//find the lowest and use that as the head
				local head,low
				for k,v in pairs(temp.Entities) do
					if (!head) or (v.Pos.z < low) then
						head = k
						low = v.Pos.z
					end
				end
				
				//Convert the Pos and Angle keys to a system AdvDupe understands
				AdvDupe.ConvertPositionsToLocal( temp.Entities, temp.Constraints, temp.Entities[head].Pos, Angle(0,0,0) )
				
				tool:LoadFileCallBack( filepath,
					temp.Entities, temp.Constraints,
					{},{}, head, Angle(0,0,0), Vector(0,0,0),
					false, temp.Information.Creator, "Old Contrpaption Saver File",
					temp.Information.Entities, temp.Information.Constraints, 
					"Old Contrpaption Saver File", temp.Date
				)
				
				/*return temp.Entities, temp.Constraints,
				{},{}, head, Angle(0,0,0), Vector(0,0,0),
				false, temp.Information.Creator, "Old Contrpaption Saver File",
				temp.Information.Entities, temp.Information.Constraints, "Old Contrpaption Saver File", temp.Date*/
				
				
			else
				Msg("AdvDupeERROR:FILE FAILED TO LOAD! something is wrong with this file:  "..filepath.."\n")
			end
			AdvDupe.SetPercent(pl, 50)
		end
		
		AdvDupe.SetPercent(pl, 30)
		timer.Simple(.1, Load3, pl, filepath, tool, temp)
	end
	
	AdvDupe.SetPercent(pl, 10)
	timer.Simple(.1, Load1, pl, filepath, tool, file.Read(filepath))
	
end


/*---------------------------------------------------------
  Prepreares Tables For Save
   Compacts the size of the table by
   returning what will be needed
---------------------------------------------------------*/
/*function AdvDupe.CompactTables( EntityList, ConstraintList )

	local SaveableEntities = {}
	for k, v in pairs( EntityList ) do
		
		if AdvDupe.NewSave then
			SaveableEntities[ k ] = AdvDupe.EntityArgsFromTable( v )
		else
			SaveableEntities[ k ] = AdvDupe.SaveableEntityFromTable( v )
		end
		
		SaveableEntities[ k ].BoneMods = ( v.BoneMods ) //table.Copy
		SaveableEntities[ k ].EntityMods = ( v.EntityMods )
		SaveableEntities[ k ].PhysicsObjects = ( v.PhysicsObjects )
		
	end
	
	local SaveableConstraints = {}
	for k, Constraint in pairs( ConstraintList ) do
		
		local SaveableConst = AdvDupe.SaveableConstraintFromTable( Constraint )
		
		if ( SaveableConst ) then
			table.insert( SaveableConstraints, SaveableConst )
		end
		
	end
	
	return SaveableEntities, SaveableConstraints
	
end

function AdvDupe.StoreBasicsFromEntityTable( EntTable )
	
	local SaveableEntity = {}
	SaveableEntity.Class = EntTable.Class
	
	if ( EntTable.Model ) then SaveableEntity.Model = EntTable.Model end
	if ( EntTable.Angle ) then SaveableEntity.Angle = EntTable.Angle end
	if ( EntTable.Pos ) then SaveableEntity.Pos = EntTable.Pos end
	if ( EntTable.LocalPos ) then SaveableEntity.LocalPos = EntTable.LocalPos end
	if ( EntTable.LocalAngle ) then SaveableEntity.LocalAngle = EntTable.LocalAngle end
	
	if ( EntTable.CollisionGroup ) then
		if ( !EntTable.EntityMods ) then EntTable.EntityMods = {} end
		EntTable.EntityMods.CollisionGroupMod = EntTable.CollisionGroup
	end
	
	return SaveableEntity
	
end

function AdvDupe.SaveableEntityFromTable( EntTable )

	local EntityClass = duplicator.FindEntityClass( EntTable.Class )
	local SaveableEntity = AdvDupe.StoreBasicsFromEntityTable( EntTable )
	
	if (!EntityClass) then
		return SaveableEntity
	end
	
	for iNumber, Key in pairs( EntityClass.Args ) do
		
		SaveableEntity[ Key ] = EntTable[ Key ]
		
	end
	
	return SaveableEntity
	
end

function AdvDupe.SaveableConstraintFromTable( Constraint )

	local Factory = duplicator.ConstraintType[ Constraint.Type ]
	if ( !Factory ) then return end
	
	local SaveableConst = {}
	SaveableConst.Type = Constraint.Type
	SaveableConst.Entity = table.Copy( Constraint.Entity )
	if (Constraint.Entity1) then SaveableConst.Entity1 = table.Copy( Constraint.Entity1 ) end
	
	for k, Key in pairs( Factory.Args ) do
		if (!string.find(Key, "Ent") or string.len(Key) != 4)
		and (!string.find(Key, "Bone") or string.len(Key) != 5)
		and (Key != "Ent") and (Key != "Bone")
		and (Constraint[ Key ]) and (Constraint[ Key ] != false) then //don't include faluse values
			SaveableConst[ Key ] = Constraint[ Key ]
		end
	end
	
	return SaveableConst

end*/

/*function AdvDupe.EntityArgsFromTable( EntTable )
	
	local EntityClass = duplicator.FindEntityClass( EntTable.Class )
	local SaveableEntity = AdvDupe.StoreBasicsFromEntityTable( EntTable )
	
	// This class is unregistered. Just save the basics instead
	if (!EntityClass) then
		return SaveableEntity
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
		// Doesn't save space to prebuild the arglist when there is a data key, we'd end up with a self-nested table
		if ( Key == "Data" ) then return SaveableEntity end
		// If there's a missing argument then unpack will stop sending at that argument
		if ( Arg == nil ) then Arg = false end
		if ( Key != "Pos" ) and ( Key != "Angle" ) then
			ArgList[ iNumber ] = Arg
		end
	end
	
	SaveableEntity.arglist = ArgList
	
	return SaveableEntity
	
end*/


//
//	Gets savable info from an entity
//
function AdvDupe.GetSaveableEntity( Ent, Offset )
	
	if ( Ent.PreEntityCopy ) then Ent:PreEntityCopy() end
	
	//we're going to be a little distructive to this table, let's not use the orginal
	local Tab = table.Copy( Ent:GetTable() )
	
	if ( Ent.PostEntityCopy ) then Ent:PostEntityCopy() end
	
	//let's junk up the table a little
	Tab.Angle = Ent:GetAngles()
	Tab.Pos = Ent:GetPos()
	
	// Physics Objects
	Tab.PhysicsObjects =  Tab.PhysicsObjects or {}
	local iNumPhysObjects = Ent:GetPhysicsObjectCount()
	for Bone = 0, iNumPhysObjects-1 do 
		local PhysObj = Ent:GetPhysicsObjectNum( Bone )
		if ( PhysObj:IsValid() ) then
			Tab.PhysicsObjects[ Bone ] = Tab.PhysicsObjects[ Bone ] or {}
			Tab.PhysicsObjects[ Bone ].Pos = PhysObj:GetPos()
			Tab.PhysicsObjects[ Bone ].Angle = PhysObj:GetAngle()
			Tab.PhysicsObjects[ Bone ].Frozen = !PhysObj:IsMoveable()
		end
	end
	
	// Flexes (WTF are these?)
	local FlexNum = Ent:GetFlexNum()
	for i = 0, FlexNum do
		Tab.Flex = Tab.Flex or {}
		Tab.Flex[ i ] = Ent:GetFlexWeight( i )
	end
	Tab.FlexScale = Ent:GetFlexScale()
	
	// Let the ent fuckup our nice new table if it wants too
	if ( Ent.OnEntityCopyTableFinish ) then Ent:OnEntityCopyTableFinish( Tab ) end
	
	//moved from ConvertPositionsToLocal
	Tab.Pos = Tab.Pos - Offset
	Tab.LocalPos = Tab.Pos * 1
	Tab.LocalAngle = Tab.Angle * 1
	if ( Tab.PhysicsObjects ) then
		for Num, Object in pairs(Tab.PhysicsObjects) do
			Object.Pos = Object.Pos - Offset
			Object.LocalPos = Object.Pos * 1
			Object.LocalAngle = Object.Angle * 1
			Object.Pos = nil
			Object.Angle = nil
		end
	end
	
	//Save CollisionGroupMod
	if ( Tab.CollisionGroup ) then
		if ( !Tab.EntityMods ) then Tab.EntityMods = {} end
		Tab.EntityMods.CollisionGroupMod = Tab.CollisionGroup
	end
	
	//fix for saving key on camera (Conna)
	if (Ent:GetClass() == "gmod_cameraprop") then
		Tab.key = Ent:GetNetworkedInt(0)
	end
	
	//Saveablity
	local SaveableEntity = {}
	SaveableEntity.Class		 = Ent:GetClass()
	SaveableEntity.Model 		 = Ent:GetModel()
	SaveableEntity.LocalPos		 = Tab.LocalPos
	SaveableEntity.LocalAngle	 = Tab.LocalAngle
	SaveableEntity.BoneMods		 = table.Copy( Tab.BoneMods )
	SaveableEntity.EntityMods	 = table.Copy( Tab.EntityMods )
	SaveableEntity.PhysicsObjects = table.Copy( Tab.PhysicsObjects )
	
	if ( Ent:GetParent() ) and ( Ent:GetParent():IsValid() ) then
		SaveableEntity.SavedParentIdx = Ent:GetParent():EntIndex()
	end
	
	local EntityClass = duplicator.FindEntityClass( SaveableEntity.Class )
	if (!EntityClass) then return SaveableEntity end // This class is unregistered. Just save what we have so far
	
	//filter functions, we only want to save what will be used
	for iNumber, key in pairs( EntityClass.Args ) do
		//we dont need this crap, it's already added
		if (key != "pos") and (key != "position") and (key != "Pos") and ( key != "model" ) and (key != "Model")
		and (key != "ang") and (key != "Ang") and (key != "angle") and (key != "Angle") and (key != "Class") then
			SaveableEntity[ key ] = Tab[ key ]
		end
	end
	
	/*local ArgList = {}
	for iNumber, Key in pairs( EntityClass.Args ) do
		
		// Doesn't save space to prebuild the arglist when there is a data key, we'd end up with a self-nested table
		if ( Key == "Data" ) then
			for iNumber, key in pairs( EntityClass.Args ) do
				//we dont need this crap, it's already added
				if (key != "pos") and (key != "position") and (key != "Pos") and ( key != "model" ) and (key != "Model")
				and (key != "ang") and (key != "Ang") and (key != "angle") and (key != "Angle") then
					SaveableEntity[ key ] = Tab[ key ]
				end
			end
			ArgList = nil
			break
		end
		
		if (key != "pos") and (key != "position") and (key != "Pos")
		and (key != "ang") and (key != "Ang") and (key != "angle") and (key != "Angle") then
			local Arg
			if ( Key == "model" ) or ( Key == "Model" ) then
				Arg = Ent:GetModel()
			elseif Tab[ Key ] then
				Arg = Tab[ Key ]
			else
				Arg = false
			end
			ArgList[ iNumber ] = Arg
		end
		
	end
	SaveableEntity.arglist = ArgList*/
	
	return SaveableEntity	
end

//
//	Gets savable info from an constraint
//
function AdvDupe.GetSaveableConst( ConstraintEntity, Offset )
	if (!ConstraintEntity) then return {} end
	
	local SaveableConst = {}
	local ConstTable = ConstraintEntity:GetTable()
	
	local Factory = duplicator.ConstraintType[ ConstTable.Type ]
	if ( Factory ) then
		SaveableConst.Type = ConstTable.Type
		
		for k, Key in pairs( Factory.Args ) do
			if (!string.find(Key, "Ent") or string.len(Key) != 4)
			and (!string.find(Key, "Bone") or string.len(Key) != 5)
			and (Key != "Ent") and (Key != "Bone")
			and (ConstTable[ Key ]) and (ConstTable[ Key ] != false) then
				SaveableConst[ Key ] = ConstTable[ Key ]
			end
		end
		
	else
		table.Merge( SaveableConst, ConstraintEntity:GetTable() )
	end
	
	SaveableConst.Entity = {}
	
	if ( ConstTable[ "Ent" ] && ( ConstTable[ "Ent" ]:IsWorld() || ConstTable[ "Ent" ]:IsValid() ) ) then
		
		SaveableConst.Entity[ 1 ] = {}
		SaveableConst.Entity[ 1 ].Index	 	= ConstTable[ "Ent" ]:EntIndex()
		if ConstTable[ "Ent" ]:IsWorld() then SaveableConst.Entity[ 1 ].World = true end
		SaveableConst.Entity[ 1 ].Bone 		= ConstTable[ "Bone" ]
		
	else
		for i=1, 6 do
			if ( ConstTable[ "Ent"..i ] && ( ConstTable[ "Ent"..i ]:IsWorld() || ConstTable[ "Ent"..i ]:IsValid() ) ) then
				SaveableConst.Entity[ i ] = {}
				SaveableConst.Entity[ i ].Index	 	= ConstTable[ "Ent"..i ]:EntIndex()
				SaveableConst.Entity[ i ].Bone 		= ConstTable[ "Bone"..i ]
				SaveableConst.Entity[ i ].WPos 		= ConstTable[ "WPos"..i ]
				SaveableConst.Entity[ i ].Length 	= ConstTable[ "Length"..i ]
				if ConstTable[ "Ent"..i ]:IsWorld() then
					SaveableConst.Entity[ i ].World = true
					SaveableConst.Entity[ i ].LPos = ConstTable[ "LPos"..i ] - Offset
				else
					SaveableConst.Entity[ i ].LPos = ConstTable[ "LPos"..i ]
				end
			end
		end
	end
	
	return SaveableConst
end


//
//	Custom GetAllConstrainedEntitiesAndConstraints
//	Built for speed and saveablity
//	Compatable in place of duplicator.GetAllConstrainedEntitiesAndConstraints
//	Do not steal
//GetAllConstrainedEntitiesAndConstraints
function AdvDupe.Copy( Ent, EntTable, ConstraintTable, Offset )
	
	if ( !Ent or !Ent:IsValid() ) or ( EntTable[ Ent:EntIndex() ] ) 
	or ( ( Ent:GetClass() == "prop_physics" ) and ( Ent:GetVar("IsPlug",nil) == 1 ) ) then
		return EntTable, ConstraintTable
	end
	
	EntTable[ Ent:EntIndex() ] = AdvDupe.GetSaveableEntity( Ent, Offset )
	if ( !constraint.HasConstraints( Ent ) ) then return EntTable, ConstraintTable end
	
	for key, ConstraintEntity in pairs( Ent.Constraints ) do
		if ( !ConstraintTable[ ConstraintEntity ] ) then
			ConstraintTable[ ConstraintEntity ] = AdvDupe.GetSaveableConst( ConstraintEntity, Offset )
			local ConstTable = ConstraintEntity:GetTable()
			for i=1, 6 do
				local e = ConstTable[ "Ent"..i ]
				if ( e and ( e:IsWorld() or e:IsValid() ) ) and ( !EntTable[ e:EntIndex() ] ) then
					AdvDupe.Copy( e, EntTable, ConstraintTable, Offset )
				end
			end
		end
	end
	
	return EntTable, ConstraintTable
	
end



//
//	Gets the entity's constraints and connected entities
//	Like GetAll, but only returns a table of fisrt level connects
//	Might be usefull for for something later
//
function AdvDupe.GetEntitysConstrainedEntitiesAndConstraints( ent )
	if ( !Ent ) then return {},{} end
	local Consts, Ents = {},{}
	Ents[ Ent:EntIndex()] = Ent
	if ( constraint.HasConstraints( Ent ) ) then
		for key, ConstraintEntity in pairs( Ent.Constraints ) do
			local ConstTable = ConstraintEntity:GetTable()
			table.insert( Consts, ConstraintEntity )
			for i=1, 6 do
				if ( ConstTable[ "Ent"..i ] && ( ConstTable[ "Ent"..i ]:IsWorld() || ConstTable[ "Ent"..i ]:IsValid() ) ) then
					local ent = ConstTable[ "Ent"..i ]
					Ents[ ent:EntIndex() ] = ent
				end
			end
		end
	end
	return Ents, Consts
end


/*AdvDupe.NewSave = true
local function NewSaveSet(pl, cmd, args)
	if args[1] and args[1] == "1" or args[1] == 1 then
		AdvDupe.NewSave = true
	elseif args[1] and args[1] == "0" or args[1] == 0 then
		AdvDupe.NewSave = false
	end
	Msg("\AdvDupe_NewSave = "..tostring(AdvDupe.NewSave).."\n")
end
concommand.Add( "AdvDupe_NewSave", NewSaveSet )*/





local function CollisionGroupModifier(ply, Ent, group )
	
	if ( group == COLLISION_GROUP_WORLD ) then
		Ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
		Ent.CollisionGroup = COLLISION_GROUP_WORLD
	else
		Ent:SetCollisionGroup( COLLISION_GROUP_NONE )
		Ent.CollisionGroup = COLLISION_GROUP_NONE
	end
	
end
duplicator.RegisterEntityModifier( "CollisionGroupMod", CollisionGroupModifier )


local function SetMass( Player, Entity, Data )

	if ( Data and Data.Mass ) then
		if (Data.Mass > 0) then
			Entity:GetPhysicsObject():SetMass(Data.Mass)
			duplicator.StoreEntityModifier( Entity, "MassMod", Data )
		else 
			self:GetOwner():ConCommand("weight_set 1");
			self:GetOwner():SendLua("ZMass()");
		end
		
		return true
	end
	
end
duplicator.RegisterEntityModifier( "MassMod", SetMass )




if (dupeshare and dupeshare.PublicDirs) then
	AdvDupe.PublicDirs = {}
	for k, v in pairs(dupeshare.PublicDirs) do
		local dir = dupeshare.BaseDir.."/"..v
		AdvDupe.PublicDirs[v] = dir
		if ( !file.Exists(dir) ) or ( file.Exists(dir) and !file.IsDir(dir) ) then 
			file.CreateDir( dir )
		end
	end
end


function AdvDupe.GetPlayersFolder(pl)
	local dir = dupeshare.BaseDir
	
	if (!SinglePlayer()) then
		local name = dupeshare.ReplaceBadChar(tostring(pl:SteamID()))
		
		if (name == "STEAM_ID_LAN") or (name == "UNKNOWN") or (name == "STEAM_ID_PENDING") then
			name = dupeshare.GetPlayerName(pl) or "unknown"
		end
		
		dir = dir.."/"..name
	end
	
	return dir
end



function AdvDupe.MakeDir(pl, cmd, args)
	if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
	
	local dir = AdvDupe[pl].cdir
	local foldername = dupeshare.ReplaceBadChar(string.Implode(" ", args))
	
	AdvDupe.FileOpts(pl, "makedir", foldername, dir)
	
	/*local dir = AdvDupe[pl].cdir.."/"..dupeshare.ReplaceBadChar(args[1])
	
	if file.Exists(dir) and file.IsDir(dir) then 
		AdvDupe.SendClientError(pl, "Folder Already Exists!")
		return
	end
	
	file.CreateDir(dir)*/
	
	if (dupeshare.UsePWSys) and (!SinglePlayer()) then
		//todo
	end
	
	//AdvDupe.UpdateList(pl)
	
end
concommand.Add("adv_duplicator_makedir", AdvDupe.MakeDir)

local function FileOptsCommand(pl, cmd, args)
	if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
	
	local action = args[1]
	//local filename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename" ))..".txt"
	local filename = pl:GetInfo( "adv_duplicator_load_filename" )
	//local filename2 = pl:GetInfo( "adv_duplicator_load_filename2" )
	local dir	= AdvDupe[pl].cdir
	local dir2	= AdvDupe[pl].cdir2
	
	AdvDupe.FileOpts(pl, action, filename, dir, dir2)
	
end
concommand.Add("adv_duplicator_fileopts", FileOptsCommand)

local function FileOptsRenameCommand(pl, cmd, args)
	Msg("rename cmd\n")
	if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
	
	//local filename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename" ))..".txt"
	local filename = pl:GetInfo( "adv_duplicator_load_filename" )
	local dir	= AdvDupe[pl].cdir
	local newname = string.Implode(" ", args)
	newname = dupeshare.ReplaceBadChar(dupeshare.GetFileFromFilename(newname))..".txt"
	Msg("s-newname= "..newname.."\n")
	AdvDupe.FileOpts(pl, "rename", filename, dir, newname)
	
end
concommand.Add("adv_duplicator_fileoptsrename", FileOptsRenameCommand)

function AdvDupe.FileOpts(pl, action, filename, dir, dir2)
	if not filename or not dir then return end
	
	local file1 = dir.."/"..filename
	Msg("action= "..action.."  filename= "..filename.."  dir= "..dir.."  dir2= "..(dir2 or "none").."\n")
	
	if (!AdvDupe.CheckPerms(pl, "", dir, "access")) then return end
	
	if (action == "delete") and AdvDupe.CheckPerms(pl, "", dir, "delete") then
		
		file.Delete(file1)
		AdvDupe.HideGhost(pl, false)
		AdvDupe.UpdateList(pl)
		
	elseif (action == "copy") and AdvDupe.CheckPerms(pl, "", dir2, "write") then
		
		local file2 = dir2.."/"..filename
		if file.Exists(file2) then
			local filename2 = ""
			file2, filename2 = dupeshare.FileNoOverWriteCheck(dir2, filename)
			if dir == dir2 then
				AdvDupe.SendClientError(pl, "Destination Same as Source, Saved File as: "..filename2)
			else
				AdvDupe.SendClientError(pl, "File Exists at Destination, Saved File as: "..filename2)
			end
		end
		file.Write(file2, file.Read(file1))
		AdvDupe.UpdateList(pl)
		
	elseif (action == "move") and AdvDupe.CheckPerms(pl, "", dir, "delete")
							and AdvDupe.CheckPerms(pl, "", dir2, "write") then
		
		if dir == dir2 then
			AdvDupe.SendClientError(pl, "Cannot move file to same directory")
			return
		end
		
		AdvDupe.FileOpts(pl, "copy", filename, dir, dir2)
		AdvDupe.FileOpts(pl, "delete", filename, dir)
		
	elseif (action == "makedir") and AdvDupe.CheckPerms(pl, "", dir, "makedir") then
		
		if !SinglePlayer() and dupeshare.NamedLikeAPublicDir(filename) then
			AdvDupe.SendClientError(pl, "You Cannot Name a Folder Like a Public Folder")
			return
		end
		
		if file.Exists(file1) and file.IsDir(file1) then 
			AdvDupe.SendClientError(pl, "Folder Already Exists!")
			return
		end
		
		file.CreateDir(file1)
		AdvDupe.HideGhost(pl, false)
		AdvDupe.UpdateList(pl)
		
	elseif (action == "rename") and AdvDupe.CheckPerms(pl, "", dir, "delete")
							and AdvDupe.CheckPerms(pl, "", dir, "write") then
		
		AdvDupe.FileOpts(pl, "duplicate", filename, dir, dir2)
		AdvDupe.FileOpts(pl, "delete", filename, dir)
		
	elseif (action == "duplicate") and AdvDupe.CheckPerms(pl, "", dir, "write") then
		
		local file2 = dir.."/"..dir2 //using dir2 to hold the new filename
		if file.Exists(file2) then
			local filename2 = ""
			file2, filename2 = dupeshare.FileNoOverWriteCheck(dir, dir2)
			AdvDupe.SendClientError(pl, "File Exists With That Name Already, Renamed as: "..filename2)
		end
		file.Write(file2, file.Read(file1))
		AdvDupe.UpdateList(pl)
		
	else
		AdvDupe.SendClientError(pl, "FileOpts: Bad Action Command!")
	end
	
end

//TODO
function AdvDupe.CheckPerms(pl, dir, password, action)
	
	if (dupeshare.UsePWSys) and (!SinglePlayer()) then
		//todo
		return true
	else
		return true
	end
	
	AdvDupe.SendClientError(pl, "Permission error!")
end




//makes the player see an error
//todo: make enum error codes
function AdvDupe.SendClientError(pl, errormsg, NoSound)
	if !pl:IsValid() or !pl:IsPlayer() or !errormsg then return end
	//pl:SendLua( "dvdupeclient.Error( \""..errormsg.."\" )" )
	Msg("AdvDupe: Sending this ErrorMsg to "..tostring(pl).."\nAdvDupe-ERROR: \""..tostring(errormsg).."\"\n")
	umsg.Start("AdvDupeCLError", pl)
		umsg.String(errormsg)
		umsg.Bool(NoSound)
	umsg.End()
end
function AdvDupe.SendClientInfoMsg(pl, msg, NoSound)
	if !pl:IsValid() or !pl:IsPlayer() or !msg then return end
	//pl:SendLua( "dvdupeclient.Error( \""..errormsg.."\" )" )
	Msg("AdvDupe, Sending This InfoMsg to "..tostring(pl).."\nAdvDupe: \""..tostring(msg).."\"\n")
	umsg.Start("AdvDupeCLInfo", pl)
		umsg.String(msg)
		umsg.Bool(NoSound)
	umsg.End()
end

function AdvDupe.UpdateList(pl)
	local tool = AdvDupe.GetAdvDupeToolObj(pl)
	if (tool) then
		tool:UpdateList()
	end
end

function AdvDupe.HideGhost(pl, Hide)
	local tool = AdvDupe.GetAdvDupeToolObj(pl)
	if (tool) then
		tool:HideGhost(Hide)
	end
end
local function AdvDupe_HideGhost( pl, command, args )
	if ( args[1] ) and  ( args[1] == "0" ) then
		AdvDupe.HideGhost(pl, false)
	elseif ( args[1] ) and  ( args[1] == "1" ) then
		AdvDupe.HideGhost(pl, true)
	end
end
concommand.Add( "adv_duplicator_hideghost", AdvDupe_HideGhost )

function AdvDupe.SetPasting(pl, Pasting)
	AdvDupe[pl] = AdvDupe[pl] or {}
	AdvDupe[pl].Pasting = Pasting
	
	umsg.Start("AdvDupeSetPasting", pl)
		umsg.Bool(Pasting)
	umsg.End()
end

function AdvDupe.SetPercentText( pl, Txt )
	AdvDupe[pl].PercentText = Txt
	umsg.Start("AdvDupe_Start_Percent", pl)
		umsg.String(Txt)
	umsg.End()
end

function AdvDupe.SetPercent(pl, Percent)
	/*local tool = AdvDupe.GetAdvDupeToolObj(pl)
	if (tool) then*/
		umsg.Start("AdvDupe_Update_Percent", pl)
			umsg.Short(Percent)
		umsg.End()
	//end
end

function AdvDupe.GetAdvDupeToolObj(pl)
	//local tool = pl:GetActiveWeapon()
	if ( !pl:GetActiveWeapon():GetTable().Tool ) then return end
	local tool = pl:GetActiveWeapon():GetTable().Tool.adv_duplicator.Weapon
	if ( dupeshare.CurrentToolIsDuplicator(tool) ) then
		return tool:GetTable():GetToolObject()
	end
	return 
end



//
//Recieves file from client
//
function AdvDupe.RecieveFileContentStart( pl, cmd, args )
	if !pl:IsValid() or !pl:IsPlayer() then return end
	
	Msg("AdvDupe: Ready to recieve file: \""..args[1].."\" from player: "..(pl:GetName() or "unknown").."\n")
	
	if (!AdvDupe[pl]) then AdvDupe[pl] = {} end
	
	AdvDupe[pl].templast		= tonumber(args[1])
	AdvDupe[pl].tempdir			= AdvDupe[pl].cdir //upload into curent open dir
	AdvDupe[pl].tempfilename	= args[2]
	AdvDupe[pl].tempnum		= 0
	AdvDupe[pl].tempfile		= {}
	
end
concommand.Add("DupeRecieveFileContentStart", AdvDupe.RecieveFileContentStart)

function AdvDupe.RecieveFileContent( pl, cmd, args )
	if !pl:IsValid() or !pl:IsPlayer() then return end
	
	Msg("AdvDupe: Recieving piece ")
	if (!args[1]) or (args[1] == "") then return end
	AdvDupe[pl].tempnum = AdvDupe[pl].tempnum + 1
	
	Msg(args[1].." / "..AdvDupe[pl].templast.." received: "..AdvDupe[pl].tempnum.."\n")
	
	AdvDupe[pl].tempfile[tonumber(args[1])] = args[2]
	
	if (AdvDupe[pl].templast == AdvDupe[pl].tempnum) then
		AdvDupe.RecieveFileContentFinish( pl )
	end
	
end
concommand.Add("_DFC", AdvDupe.RecieveFileContent)

function AdvDupe.RecieveFileContentFinish( pl, cmd, args )
	if (!pl:IsValid() or !pl:IsPlayer()) then return end
	
	//local filepath = dupeshare.FileNoOverWriteCheck( AdvDupe.GetPlayersFolder(pl), AdvDupe[pl].tempfilename )
	local filepath = dupeshare.FileNoOverWriteCheck( AdvDupe[pl].tempdir, AdvDupe[pl].tempfilename )
	Msg("AdvDupe: Saving "..(pl:GetName() or "unknown").."'s recieved file to "..filepath.."\n")
	AdvDupe.RecieveFileContentSave( pl, filepath )
end
concommand.Add("DupeRecieveFileContentFinish", AdvDupe.RecieveFileContentFinish)

function AdvDupe.RecieveFileContentSave( pl, filepath )
	if (!pl:IsValid() or !pl:IsPlayer()) then return end
	if (!AdvDupe[pl].tempfile) then return end
	
	local expected = AdvDupe[pl].templast
	local got = AdvDupe[pl].tempnum
	local FileName = dupeshare.GetFileFromFilename( filepath )
	
	if (expected != got) then
		//reassemble the pieces
		local txt = "AdvDupe: Missing piece(s): " 
		for i = 1,expected do
			if (!AdvDupe[pl].tempfile[i]) then
				txt = txt .. i .. ", "
			end
		end
		Msg(txt.."\n")
		
		//pl:PrintMessage(HUD_PRINTTALK, "ERROR: Your file, \""..filepath.."\", was not recieved properly: server expected "..expected.." pieces but got "..got)
		//pl:PrintMessage(HUD_PRINTTALK, "Try resending it.")
		AdvDupe.SendClientError(pl, "ERROR: \""..FileName.."\", failed uploading", true)
		AdvDupe.SendClientError(pl, "Server expected "..expected.." pieces but got "..got)
		AdvDupe.SendClientInfoMsg(pl, "Try resending it.", true)
		
		pl:PrintMessage(HUD_PRINTCONSOLE, "AdvDupeERROR: Your file, \""..FileName.."\", was not recieved properly\nAdvDupe: server expected "..expected.." pieces but got "..got)
		Msg("AdvDupe: This file, \""..filepath.."\", was not recieved properly\nAdvDupe: expected: "..expected.." pieces but got: "..got.."\n")
		
		umsg.Start("AdvDupeClientSendFinishedFailed", pl)
		umsg.End()
		
		return
	end
	
	//reassemble the pieces
	//local temp = string.Implode("", AdvDupe[pl].tempfile)
	local temp = table.concat(AdvDupe[pl].tempfile)
	temp = dupeshare.DeCompress(temp, true)
	file.Write(filepath, temp)
	AdvDupe[pl].tempfile	 = nil
	
	//pl:PrintMessage(HUD_PRINTTALK, "Your file: \""..filepath.."\" was uploaded to the server")
	AdvDupe.SendClientInfoMsg(pl, "Your file: \""..FileName.."\" was uploaded to the server")
	pl:PrintMessage(HUD_PRINTCONSOLE, "Your file: \""..FileName.."\" was uploaded to the server")
	
	Msg("player: \""..(pl:GetName() or "unknown").."\" uploaded file: \""..filepath.."\"\n")
	
	AdvDupe.UpdateList(pl)
	
	umsg.Start("AdvDupeClientSendFinished", pl)
	umsg.End()
end




//
//Sends a file to the client
//
/*function AdvDupe.SaveAndSendSaveToClient( pl, filename, desc )
	local filepath = AdvDupe.SaveToFile( pl, filename, desc )
	AdvDupe.SendSaveToClient( pl, filepath )
end*/

function AdvDupe.SendSaveToClient( pl, filename )
	if (!AdvDupe[pl]) then AdvDupe[pl] = {} end
	if (AdvDupe[pl].temp) then return end //then were sending already and give up
	
	local filepath = filename
	local dir = "adv_duplicator"
	local ndir = dir.."/"..dupeshare.GetPlayerName(pl)
	
	if !file.Exists(filepath) then //if filepath was just a file name then try to find the file, for sending from list
		if !file.Exists(dir.."/"..filename) && !file.Exists(ndir.."/"..filename) then
			Msg("AdvDupe: File not found: \""..filepath.."\"\n") return end
		
		if ( file.Exists(ndir.."/"..filename) ) then filepath = ndir.."/"..filename end
		if ( file.Exists(dir.."/"..filename) ) then filepath = dir.."/"..filename end
	end
	
	filename = dupeshare.GetFileFromFilename(filepath)
	
	AdvDupe[pl].temp = file.Read(filepath)
	
	AdvDupe[pl].temp = dupeshare.Compress(AdvDupe[pl].temp, false)
	
	local len = string.len(AdvDupe[pl].temp)
	local last = math.ceil(len / MAXDOWNLOADLENGTH) + 1 //+1 because the client counts the first piece recieved as 1 not 0
	
	umsg.Start("AdvDupeRecieveSaveStart", pl)
		umsg.Short(last)
		umsg.String(filename)
		//umsg.String(ndir)
	umsg.End()
	Msg("AdvDupe: sending file \""..filename..".txt\" in "..tostring(last).." pieces. len: "..tostring(len).."\n")
	AdvDupe.SetPercentText( pl, "Downloading" )
	
	AdvDupe.SendSaveToClientData(pl, len, 0, last)
	
end

function AdvDupe.SendSaveToClientData(pl, len, offset, last)
	
	for k=0,2 do //sends three pieces
		
		if ((offset + k + 1) <= last) then
			Msg("AdvDupe: sending string: "..tostring((offset + k) * MAXDOWNLOADLENGTH).." / "..len.." k: "..k.." piece: "..(offset + k + 1).." / "..last.."\n")
			if ( AdvDupe[pl].PercentText == "Downloading" ) 
			and ( 0 == math.fmod( (((offset + k + 1) / last) * 100), 5 ) ) then
				AdvDupe.SetPercent(pl, ((offset + k + 1) / last) * 100 )
			end
			
			umsg.Start("AdvDupeRecieveSaveData", pl)
				umsg.Short(offset + k + 1) //cause sometimes these are reccieved out of order
				
				if ((offset + k + 1) == last) then
					umsg.String(string.Right(AdvDupe[pl].temp, (len - ((last - 2) * MAXDOWNLOADLENGTH))))
					//umsg.String(string.sub(AdvDupe[pln].temp, ((offset + k) * 220)))
					Msg("AdvDupe: send last piece\n")
					AdvDupe.SetPercent(pl, 100)
					timer.Simple(.1, AdvDupe.SetPercent, pl, -1)
				else
					umsg.String(string.Right(string.Left(AdvDupe[pl].temp, ((offset + k) * MAXDOWNLOADLENGTH)),MAXDOWNLOADLENGTH))
					//local pos = ((offset + k) * 220)
					//umsg.String(string.sub(AdvDupe[pln].temp, pos, (pos +220) ))
				end
				
			umsg.End()
		else
			break
		end
	end
	
	if (offset + 4) <= last then
		timer.Simple( 0.02, AdvDupe.SendSaveToClientData, pl, len, (offset + 3), last )
	else
		AdvDupe[pl].temp = nil //clear this to send again
		//inform the client they finished downloading in case they didn't notice
		umsg.Start("AdvDupeClientDownloadFinished", pl)
		umsg.End()
	end
	
end




//	=============
//	AdvDupeThink
//	=============
//
//	Paste Duplication Managment
//	Special Timer Control
//
local UseTimedPasteThreshold = 100
if ( SinglePlayer() ) then UseTimedPasteThreshold = 500 end
local PasteEntsPerTick = 2
local PostEntityPastePerTick = 20
local PasteConstsPerTick = 10
local DoPasteFX = false
local UseTaskSwitchingPaste = false
local DebugWeldsByDrawingThem = false

local TimedPasteDataNum = 0
local TimedPasteDataCurrent = 1
local TimedPasteData = {}
local NextPasteTime = 0
//local NumPastePartCallInRun = 0
local LastDelay = 0
local Timers = {}
local function AdvDupeThink()
	
	if (CurTime() >= NextPasteTime) then
		if TimedPasteData[TimedPasteDataCurrent] then
			if ( !TimedPasteData[TimedPasteDataCurrent].Shooting_Ent )
			or ( !TimedPasteData[TimedPasteDataCurrent].Shooting_Ent.Entity )
			or ( !TimedPasteData[TimedPasteDataCurrent].Shooting_Ent.Entity:IsValid() ) then
				AdvDupe.FinishPasting( TimedPasteData,TimedPasteDataCurrent )
				//table.remove(TimedPasteData,TimedPasteDataCurrent)
				NextPasteTime = CurTime() +  .08
			else
				if ( TimedPasteData[TimedPasteDataCurrent].NormPaste ) and ( TimedPasteData[TimedPasteDataCurrent].Delay < CurTime() ) then
					local NoFail, Result = pcall( AdvDupe.NormPaste,
						TimedPasteData[TimedPasteDataCurrent].Player, 
						TimedPasteData[TimedPasteDataCurrent].EntityList, 
						TimedPasteData[TimedPasteDataCurrent].ConstraintList, 
						TimedPasteData[TimedPasteDataCurrent].HeadEntityIdx, 
						TimedPasteData[TimedPasteDataCurrent].HitPos, 
						TimedPasteData[TimedPasteDataCurrent].HoldAngle, 
						TimedPasteData[TimedPasteDataCurrent].Shooting_Ent,
						TimedPasteData[TimedPasteDataCurrent].PasteFrozen,
						TimedPasteData[TimedPasteDataCurrent].PastewoConst
					)
					if ( !NoFail ) then
						Msg("AdvDupeERROR: NormPaste Failed, Error: "..tostring(Result).."\n")
					end
					AdvDupe.FinishPasting( TimedPasteData,TimedPasteDataCurrent )
					//table.remove(TimedPasteData,TimedPasteDataCurrent)
					NextPasteTime = CurTime() + 2
				elseif ( TimedPasteData[TimedPasteDataCurrent].Delay < CurTime() ) then
					local NoFail, Result = pcall( AdvDupe.OverTimePasteProcess,
						TimedPasteData[TimedPasteDataCurrent].Player, 
						TimedPasteData[TimedPasteDataCurrent].EntityList, 
						TimedPasteData[TimedPasteDataCurrent].ConstraintList, 
						TimedPasteData[TimedPasteDataCurrent].HeadEntityIdx, 
						TimedPasteData[TimedPasteDataCurrent].Stage, 
						TimedPasteData[TimedPasteDataCurrent].LastID, 
						TimedPasteData[TimedPasteDataCurrent].EntIDList, 
						TimedPasteData[TimedPasteDataCurrent].CreatedEntities, 
						TimedPasteData[TimedPasteDataCurrent].CreatedConstraints, 
						TimedPasteData[TimedPasteDataCurrent].Shooting_Ent,
						TimedPasteDataCurrent,
						TimedPasteData[TimedPasteDataCurrent].HitPos,
						TimedPasteData[TimedPasteDataCurrent].HoldAngle,
						TimedPasteData[TimedPasteDataCurrent].PasteFrozen,
						TimedPasteData[TimedPasteDataCurrent].PastewoConst
					)
					if ( !NoFail ) then
						Msg("AdvDupeERROR: OverTimePaste Failed in stage "..(TimedPasteData[TimedPasteDataCurrent].Stage or "BadStage")..", Error: "..tostring(Result).."\n")
						TimedPasteData[TimedPasteDataCurrent].Stage = 5
					end
					TimedPasteData[TimedPasteDataCurrent].CallsInRun = TimedPasteData[TimedPasteDataCurrent].CallsInRun + 1
					if ( TimedPasteData[TimedPasteDataCurrent].Stage ) and ( TimedPasteData[TimedPasteDataCurrent].Stage == 5 ) then
						
						Msg("==TotalTicks= "..TimedPasteData[TimedPasteDataCurrent].TotalTicks.."\n")
						
						Msg("==CallsInRun = "..TimedPasteData[TimedPasteDataCurrent].CallsInRun.."\n")
						Msg("==LastDelay = "..LastDelay.."\n")
						
						AdvDupe.FinishPasting( TimedPasteData,TimedPasteDataCurrent )
						
						NextPasteTime = CurTime() +  2
						
					else
						
						AdvDupe.SetPercent(TimedPasteData[TimedPasteDataCurrent].Player, 
							(TimedPasteData[TimedPasteDataCurrent].CallsInRun / TimedPasteData[TimedPasteDataCurrent].TotalTicks) * 100)
						
						LastDelay = .1 + .25 * TimedPasteData[TimedPasteDataCurrent].CallsInRun / 4
						
						NextPasteTime = CurTime() + LastDelay
						
					end
				end
				
				//task switching mode
				if ( UseTaskSwitchingPaste) and ( TimedPasteData[TimedPasteDataCurrent + 1] ) then
					TimedPasteDataCurrent = TimedPasteDataCurrent + 1
				elseif ( UseTaskSwitchingPaste ) then
					TimedPasteDataCurrent = 1
				end
				
			end
		elseif TimedPasteDataCurrent != 1 then
			TimedPasteDataCurrent = 1
		end
		NextPasteTime = CurTime() +  .08
	end
	
	// Run Special Timers
	for key, value in pairs( Timers ) do
		if ( value.Finish <= CurTime() ) then
			local b, e = pcall( value.Func, unpack( value.FuncArgs ) )
			if ( !b ) then
				Msg("AdvDupe Timer Error: "..tostring(e).."\n")
				if ( value.OnFailFunc ) then
					local b, e = pcall( value.OnFailFunc, unpack( value.OnFailArgs ) )
					if ( !b ) then
						Msg("AdvDupe Timer Error: OnFailFunc Error: "..tostring(e).."\n")
					end
				end
			end
			Timers[ key ] = nil
		end
	end
	
end
hook.Add("Think", "AdvDupe_Think", AdvDupeThink)

function AdvDupe.MakeTimer( Delay, Func, FuncArgs, OnFailFunc, OnFailArgs )
	if ( !Delay or !Func ) then Msg("AdvDupe.MakeTimer: Missings arg\n"); return end
	
	FuncArgs = FuncArgs or {}
	OnFailArgs = OnFailArgs or {}
	
	local timer			= {}
	timer.Finish		= CurTime() + Delay //UnPredictedCurTime()
	timer.Func			= Func
	timer.FuncArgs		= FuncArgs
	timer.OnFailFunc	= OnFailFunc
	timer.OnFailArgs	= OnFailArgs
	
	table.insert( Timers, timer )
	
	hook.Add("Think", "AdvDupe_Think", AdvDupeThink)
	
	return true;
	
end



//
//	Admin functions
//
local function SetTimedPasteVars(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] then 
			UseTimedPasteThreshold = tonumber( args[1] )
		end
		if args[2] then
			PasteEntsPerTick = tonumber( args[2] )
		end
		if args[3] then
			PostEntityPastePerTick = tonumber( args[3] )
		end
		if args[4] then
			PasteConstsPerTick = tonumber( args[4] )
		end
		pl:PrintMessage(HUD_PRINTCONSOLE, "/nAdvDupe_SetTimedPasteVars:\n\tUseTimedPasteThreshold = "..UseTimedPasteThreshold.."\n\tPasteEntsPerTick = "..PasteEntsPerTick.."\n\tPostEntityPastePerTick = "..PostEntityPastePerTick.."\n\tPasteConstsPerTick = "..PasteConstsPerTick.."\nDefault: 100, 2, 20, 10\n")
	else
		pl:PrintMessage(HUD_PRINTCONSOLE, "Usage: \n  AdvDupe_SetTimedPasteVars <UseTimedPasteThreshold> [PasteEntsPerTick] [PostEntityPastePerTick] [PasteConstsPerTick]\nDefault: 100, 2, 20, 10\n")
	end
end
concommand.Add( "AdvDupe_SetTimedPasteVars", SetTimedPasteVars )

local function SetUseTaskSwitchingPaste(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			UseTaskSwitchingPaste = true
		elseif args[1] == "0" or args[1] == 0 then
			UseTaskSwitchingPaste = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\n  AdvDupe_UseTaskSwitchingPaste = "..tostring(UseTaskSwitchingPaste).."  ( norm: False(0) )\n")
end
concommand.Add( "AdvDupe_UseTaskSwitchingPaste", SetUseTaskSwitchingPaste )

local function SetDoPasteFX(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			DoPasteFX = true
		elseif args[1] == "0" or args[1] == 0 then
			DoPasteFX = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\n  AdvDupe_DoPasteFX = "..tostring(DoPasteFX).."  ( norm: False(0) )\n")
end
concommand.Add( "AdvDupe_DoPasteFX", SetDoPasteFX )

local function SetDebugWeldsByDrawingThem(pl, cmd, args)
	if ( args[1] ) and ( ( pl:IsAdmin() ) or ( pl:IsSuperAdmin( )() ) ) then
		if args[1] == "1" or args[1] == 1 then 
			DebugWeldsByDrawingThem = true
		elseif args[1] == "0" or args[1] == 0 then
			DebugWeldsByDrawingThem = false
		else
			pl:PrintMessage(HUD_PRINTCONSOLE, "Only takes 0 or 1")
		end
	end
	pl:PrintMessage(HUD_PRINTCONSOLE, "\n  AdvDupe_DebugWeldsByDrawingThem = "..tostring(DebugWeldsByDrawingThem).."  ( norm: False(0) )\n")
end
concommand.Add( "AdvDupe_DebugWeldsByDrawingThem", SetDebugWeldsByDrawingThem )

local function ReAddAdvDupeThink( ply, cmd, args )
	hook.Add("Think", "AdvDupe_Think", AdvDupeThink)
	pl:PrintMessage(HUD_PRINTCONSOLE, "ReAdded AdvDupe_Think Hook\n")
end 
concommand.Add( "AdvDupe_ReAdd_Think", ReAddAdvDupeThink ) 

local function RestartAdvDupeThink( ply, cmd, args )
	if ( !pl:IsAdmin() ) or ( !pl:IsSuperAdmin( )() ) then return end
	hook.Remove("Think", "AdvDupe_Think", AdvDupeThink)
	TimedPasteDataNum = 0
	TimedPasteDataCurrent = 1
	NextPasteTime = 0
	
	for n,d in pairs(TimedPasteData) do
		if ( d.Shooting_Ent ) and ( d.Shooting_Ent.Entity ) and ( d.Shooting_Ent.Entity:IsValid() ) then
			d.Shooting_Ent.Entity:Remove()
		end
		d = nil
	end
	TimedPasteData = {}
	
	hook.Add("Think", "AdvDupe_Think", AdvDupeThink)
	
	pl:PrintMessage(HUD_PRINTCONSOLE, "Restarted AdvDupe_Think Hook\n")
end 
concommand.Add( "AdvDupe_Restart_Think", RestartAdvDupeThink ) 




local function MakeThinger(Player, Hide)
	
	local Shooting_Ent = ents.Create( "base_gmodentity" )
		Shooting_Ent:SetModel( "models/props_lab/labpart.mdl" )
		Shooting_Ent:SetAngles( Player:GetAimVector():Angle() )
		Shooting_Ent:SetPos( Player:GetShootPos() + (Player:GetAimVector( ) * 24) - Vector(0,0,20) )
		Shooting_Ent:SetNotSolid(true)
	Shooting_Ent:Spawn()
	if ( Shooting_Ent:GetPhysicsObject():IsValid() ) then
		Shooting_Ent:GetPhysicsObject():EnableMotion(false)
	end
	Shooting_Ent:Activate()
	Shooting_Ent:SetNoDraw(Hide)
	Shooting_Ent:SetOverlayText("AdvDupe Paster")
	//DoPropSpawnedEffect( Shooting_Ent )
	Player:AddCleanup( "duplicates", Shooting_Ent )
	undo.Create( "Duplicator" )
		undo.AddEntity( Shooting_Ent )
		undo.SetPlayer( Player )
	undo.Finish()
	
	return Shooting_Ent
end

local function TingerFX( Shooting_Ent, HitPos )
	local effectdata = EffectData()
		effectdata:SetOrigin( HitPos )
		effectdata:SetStart( Shooting_Ent.Entity:GetPos() )
	util.Effect( "PasteBeam", effectdata )
end


function AdvDupe.StartPaste( Player, inEntityList, inConstraintList, HeadEntityIdx, HitPos, HoldAngle, NumOfEnts, NumOfConst, PasteFrozen, PastewoConst )
	hook.Add("Think", "AdvDupe_Think", AdvDupeThink)
	
	if ( NumOfEnts + NumOfConst > UseTimedPasteThreshold) then
		Msg("===adding new timed paste===\n")
		AdvDupe.OverTimePasteStart( Player, inEntityList, inConstraintList, HeadEntityIdx, HitPos, HoldAngle, NumOfEnts, NumOfConst, PasteFrozen, PastewoConst )
	else
		Msg("===adding new delayed paste===\n")
		AdvDupe.AddDelayedPaste( Player, inEntityList, inConstraintList, HeadEntityIdx, HitPos, HoldAngle, false, PasteFrozen, PastewoConst )
	end
end


function AdvDupe.AddDelayedPaste( Player, EntityList, ConstraintList, HeadEntityIdx, HitPos, HoldAngle, HideThinger, PasteFrozen, PastewoConst )
	
	T					= {}
	T.Player			= Player
	T.EntityList		= EntityList
	T.ConstraintList	= ConstraintList
	T.HeadEntityIdx		= HeadEntityIdx
	T.HitPos			= HitPos
	T.HoldAngle			= HoldAngle
	T.Shooting_Ent		= MakeThinger(Player, HideThinger)
	T.NormPaste			= true
	T.Delay				= CurTime() + .2
	T.PasteFrozen		= PasteFrozen
	T.PastewoConst		= PastewoConst
	
	table.insert(TimedPasteData, T)
	
end


//
//	Paste
//
function AdvDupe.NormPaste( Player, EntityList, ConstraintList, HeadEntityIdx, Offset, HoldAngle, Shooting_Ent, PasteFrozen, PastewoConst )
	
	//do the effect
	if (DoPasteFX) then
		Shooting_Ent:EmitSound( "Airboat.FireGunRevDown" )
		TingerFX( Shooting_Ent, HitPos )
	end
	
	--Msg("===doing delayed paste===\n")
	Ents, Constraints = AdvDupe.Paste( Player, EntityList, ConstraintList, HeadEntityIdx, Offset, HoldAngle, Shooting_Ent, PastewoConst )
	
	AdvDupe.ResetPositions( EntityList, ConstraintList )
	
	undo.Create( "Duplicator" )
		
		for k, ent in pairs( Ents ) do
			undo.AddEntity( ent )
			
			if ( PasteFrozen ) and (ent:GetPhysicsObject():IsValid()) then
				local Phys = ent:GetPhysicsObject()
				Phys:Sleep()
				Phys:EnableMotion(true)
				Player:AddFrozenPhysicsObject( ent, Phys )
			end
			
			AdvDupe.ApplyParenting( ent, k, EntityList, Ents )
			
		end
		
		undo.SetPlayer( Player )
		
	undo.Finish()
	
end

function AdvDupe.Paste( Player, EntityList, ConstraintList, HeadEntityIdx, Offset, HoldAngle, Shooting_Ent, PastewoConst )
	
	local CreatedEntities = {}
	
	//
	// Create the Entities
	//
	for EntID, Ent in pairs( EntityList ) do
		
		CreatedEntities[ EntID ] = AdvDupe.CreateEntityFromTable( Player, Ent, EntID, Offset, HoldAngle )
		
		if ( CreatedEntities[ EntID ] and CreatedEntities[ EntID ]:IsValid() )
			and not ( CreatedEntities[ EntID ].AdminSpawnable and !SinglePlayer() and (!Player:IsAdmin( ) or !Player:IsSuperAdmin() ) ) then
			
			Player:AddCleanup( "duplicates", CreatedEntities[ EntID ] )
			
			CreatedEntities[ EntID ].BoneMods = table.Copy( Ent.BoneMods )
			CreatedEntities[ EntID ].EntityMods = table.Copy( Ent.EntityMods )
			CreatedEntities[ EntID ].PhysicsObjects = table.Copy( Ent.PhysicsObjects )
			
			local NoFail, Result = pcall( duplicator.ApplyEntityModifiers, Player, CreatedEntities[ EntID ] )
			if ( !NoFail ) then
				Msg("AdvDupeERROR: ApplyEntityModifiers, Error: "..tostring(Result).."\n")
			end
			
			local NoFail, Result = pcall( duplicator.ApplyBoneModifiers, Player, CreatedEntities[ EntID ] )
			if ( !NoFail ) then
				Msg("AdvDupeERROR: ApplyBoneModifiers Error: "..tostring(Result).."\n")
			end
		
		elseif (CreatedEntities[ EntID ] and CreatedEntities[ EntID ].AdminSpawnable) then
			AdvDupe.SendClientError(Player, "Sorry, you can't cheat like that")
			Msg("AdvDupeERROR: "..tostring(Player).." tried to paste admin only prop "..(Ent.Class or "NIL").." Ent: "..EntID.."\n")
			if (CreatedEntities[ EntID ]:IsValid()) then CreatedEntities[ EntID ]:Remove() end
			CreatedEntities[ EntID ] = nil
		else
			Msg("AdvDupeERROR:Created Entity Bad! Class: "..(Ent.Class or "NIL").." Ent: "..EntID.."\n")
			if (CreatedEntities[ EntID ] and CreatedEntities[ EntID ]:IsValid()) then CreatedEntities[ EntID ]:Remove() end
			CreatedEntities[ EntID ] = nil
		end
		
	end
	
	//
	// Apply modifiers to the created entities
	//
	for EntID, Ent in pairs( CreatedEntities ) do	
		
		//AdvDupe.AfterPasteApply( Player, Ent, CreatedEntities )
		local NoFail, Result = pcall( AdvDupe.AfterPasteApply, Player, Ent, CreatedEntities ) )
		if ( !NoFail ) then
			Msg("AdvDupeERROR: AfterPasteApply, Error: "..tostring(Result).."\n")
		end
				
	end
	
	
	local CreatedConstraints = {}
	
	//
	// Create constraints
	//
	if ( !PastewoConst ) and ( ConstraintList ) then
		for k, Constraint in pairs( ConstraintList ) do
			
			local Entity = AdvDupe.CreateConstraintFromTable( Player, Constraint, CreatedEntities, Offset, HoldAngle )
			
			if ( Entity && Entity:IsValid() ) then
				table.insert( CreatedConstraints, Entity )
			else
				Msg("AdvDupeERROR:Could not make constraint type: "..(Constraint.Type or "NIL").."\n")
			end
			
		end
	end
	
	return CreatedEntities, CreatedConstraints
	
end


//
//	Paste of time
//
function AdvDupe.OverTimePasteStart( Player, inEntityList, inConstraintList, HeadEntityIdx, HitPos, HoldAngle, NumOfEnts, NumOfConst, PasteFrozen, PastewoConst )
	
	local EntityList = {}
	local EntIDList = {}
	EntIDList[1] = HeadEntityIdx
	for EntID, EntTable in pairs( inEntityList ) do
		EntityList[EntID] = inEntityList[EntID]
		if ( EntID != HeadEntityIdx ) then
			table.insert( EntIDList, EntID )
		end
	end
	
	local ConstraintList = {}
	for ConstID, ConstTable in pairs( inConstraintList ) do
		table.insert(ConstraintList, ConstTable)
	end
	
	local Shooting_Ent = MakeThinger(Player)
	
	T						= {}
	T.Player				= Player
	T.EntityList			= EntityList
	T.ConstraintList		= ConstraintList
	T.HeadEntityIdx			= HeadEntityIdx
	T.CallsInRun			= 0
	T.Stage					= 1
	T.LastID				= 1
	T.EntIDList				= EntIDList
	T.CreatedEntities		= {}
	T.CreatedConstraints	= {}
	T.HitPos				= HitPos
	T.HoldAngle				= HoldAngle
	T.Shooting_Ent			= Shooting_Ent
	T.Delay					= CurTime() + 0.2
	if ( PastewoConst ) then //guess how many ticks it will require so the progress bar looks right
		T.TotalTicks = math.ceil(NumOfEnts / PasteEntsPerTick) + math.ceil(NumOfEnts / PostEntityPastePerTick) + 5
	else
		T.TotalTicks = math.ceil(NumOfEnts / PasteEntsPerTick) + math.ceil(NumOfEnts / PostEntityPastePerTick) + math.ceil(NumOfConst / PasteConstsPerTick) + 5
	end
	T.PasteFrozen			= PasteFrozen
	T.PastewoConst			= PastewoConst
	
	table.insert(TimedPasteData, T)
	
end

function AdvDupe.OverTimePasteProcess( Player, EntityList, ConstraintList, HeadEntityIdx, Stage, LastID, EntIDList, CreatedEntities, CreatedConstraints, Shooting_Ent, DataNum, Offset, HoldAngle, PasteFrozen, PastewoConst )
	
	if Stage == 1 then
		
		if (DoPasteFX) then Shooting_Ent:EmitSound( "Airboat.FireGunRevDown" ) end
		
		for i = 1,PasteEntsPerTick do
			if EntIDList[ LastID ] then
				
				local EntID		= EntIDList[ LastID ]
				local EntTable	= EntityList[ EntID ]
				
				CreatedEntities[ EntID ] = AdvDupe.CreateEntityFromTable( Player, EntTable, EntID, Offset, HoldAngle )
				
				if ( CreatedEntities[ EntID ] and CreatedEntities[ EntID ]:IsValid() )
					and not (!CreatedEntities[ EntID ].Spawnable and CreatedEntities[ EntID ].AdminSpawnable) then
					
					//safe guard
					Player:AddCleanup( "duplicates", CreatedEntities[ EntID ] )
					
					CreatedEntities[ EntID ].BoneMods = table.Copy( EntTable.BoneMods )
					CreatedEntities[ EntID ].EntityMods = table.Copy( EntTable.EntityMods )
					CreatedEntities[ EntID ].PhysicsObjects = table.Copy( EntTable.PhysicsObjects )
					
					
					local NoFail, Result = pcall( duplicator.ApplyEntityModifiers, Player, CreatedEntities[ EntID ] )
					if ( !NoFail ) then
						Msg("AdvDupeERROR: ApplyEntityModifiers, Error: "..tostring(Result).."\n")
					end
					
					local NoFail, Result = pcall( duplicator.ApplyBoneModifiers, Player, CreatedEntities[ EntID ] )
					if ( !NoFail ) then
						Msg("AdvDupeERROR: ApplyBoneModifiers Error: "..tostring(Result).."\n")
					end
					
					
					//freeze it and make it not solid so it can't be altered while the rest is made
					if (CreatedEntities[ EntID ]:GetPhysicsObject():IsValid()) then
						CreatedEntities[ EntID ]:GetPhysicsObject():EnableMotion(false)
					end
					CreatedEntities[ EntID ]:SetNotSolid(true)
					if ( CreatedEntities[ EntID ] == CreatedEntities[ HeadEntityIdx ] ) then
						CreatedEntities[ EntID ]:SetParent( Shooting_Ent )
					else
						CreatedEntities[ EntID ]:SetParent( CreatedEntities[ HeadEntityIdx ] )
					end
					
					//do the effect
					if (DoPasteFX) and (math.random(5) > 3) then
						TingerFX( Shooting_Ent, CreatedEntities[ EntID ]:GetPos() )
						//DoPropSpawnedEffect( CreatedEntities[ EntID ] )
					end
					
				else
					Msg("AdvDupeERROR:Created Entity Bad! Class: "..(EntTable.Class or "NIL").." Ent: "..EntID.."\n")
					CreatedEntities[ EntID ] = nil
				end
				
				LastID = LastID + 1
				
			else
				LastID = 1
				Stage = 2
				break
			end
		end
		
	elseif Stage == 2 then
		
		//for EntID, Ent in pairs( CreatedEntities ) do	
		for i = 1,PostEntityPastePerTick do
			if EntIDList[ LastID ] then
				
				local EntID		= EntIDList[ LastID ]
				local Ent		= CreatedEntities[ EntID ]
				
				//AdvDupe.AfterPasteApply( Player, Ent, CreatedEntities )
				local NoFail, Result = pcall( AdvDupe.AfterPasteApply, Player, Ent, CreatedEntities ) )
				if ( !NoFail ) then
					Msg("AdvDupeERROR: AfterPasteApply, Error: "..tostring(Result).."\n")
				end
				
				LastID = LastID + 1
				
			else
				LastID = 1
				Stage = 3
				break
			end
		end
		
	elseif Stage == 3 then
		
		if ( PastewoConst ) then
			TimedPasteData[DataNum].Stage  = 4
			return
		end
		
		if (DoPasteFX) then Shooting_Ent:EmitSound( "Airboat.FireGunRevDown" ) end
		
		for i = 1,PasteConstsPerTick do
			if ConstraintList and ConstraintList[ LastID ] then
				
				local Constraint	= ConstraintList[ LastID ]
				
				local Entity = AdvDupe.CreateConstraintFromTable( Player, Constraint, CreatedEntities )
				
				if ( Entity ) and ( Entity:IsValid() ) then
					table.insert( CreatedConstraints, Entity )
					
					if (DoPasteFX) and (math.random(5) > 3) then
						TingerFX( Shooting_Ent, CreatedEntities[ Constraint.Entity[1].Index ]:GetPos() )
					end
					
				else
					Msg("AdvDupeERROR:Created Constraint Bad! Type= "..(Constraint.Type or "NIL").."\n")
					Entity = nil
				end
				
				LastID = LastID + 1
				
			else
				LastID = 1
				Stage = 4
				break
			end
		end
		
	elseif Stage == 4 then
		
		AdvDupe.ResetPositions( EntityList, ConstraintList )
		
		undo.Create( "Duplicator" )
			for k, ent in pairs( CreatedEntities ) do
				if (ent:IsValid()) then
					ent:SetNotSolid(false)
					ent:SetParent()
					if ( ent:GetPhysicsObject():IsValid() ) then
						local Phys = ent:GetPhysicsObject()
						if ( PasteFrozen ) or ( PastewoConst ) or ( EntityList[ k ].PhysicsObjects[0].Frozen ) then
							Player:AddFrozenPhysicsObject( ent, Phys )
						else
							Phys:EnableMotion(true)
						end
					end
					if ( ent.RDbeamlibDrawer ) then
						ent.RDbeamlibDrawer:SetParent( ent )
					end
					undo.AddEntity( ent )
					//AdvDupe.ApplyParenting( ent, k, EntityList, CreatedEntities ) --will crash
				else
					ent = nil
				end
			end
			undo.SetPlayer( Player )
		undo.Finish()
		
		Stage = 5 //done!
		
	end
	
	TimedPasteData[DataNum].Stage  = Stage
	
	if Stage < 5 then
		TimedPasteData[DataNum].LastID = LastID
	end
	
end



function AdvDupe.FinishPasting( TimedPasteData,TimedPasteDataCurrent )
	if ( TimedPasteData[TimedPasteDataCurrent].Shooting_Ent.Entity ) then
		TimedPasteData[TimedPasteDataCurrent].Shooting_Ent.Entity:Remove()
	end
	AdvDupe.HideGhost( TimedPasteData[TimedPasteDataCurrent].Player, false ) //unhide ghost now
	AdvDupe.SetPasting( TimedPasteData[TimedPasteDataCurrent].Player, false ) //allow the player to paste again
	
	AdvDupe.SetPercent(TimedPasteData[TimedPasteDataCurrent].Player, 100)
	timer.Simple(.1, AdvDupe.SetPercent, TimedPasteData[TimedPasteDataCurrent].Player, -1)
	
	table.remove(TimedPasteData,TimedPasteDataCurrent)
end



//
//	Generic function for duplicating stuff
//
function AdvDupe.GenericDuplicatorFunction( Player, data, ID )
	if (!data) or (!data.Class) then return false end
	
	--Msg("AdvDupeInfo: Generic make function for Class: "..data.Class.." Ent: ".."\n")
	
	local Entity = ents.Create( data.Class )
	if (!Entity:IsValid()) then
		Msg("AdvDupeError: Unknown class \""..data.Class.."\", making hallow prop instead for ent: "..ID.."\n")
		Entity = ents.Create( "prop_physics" )
		Entity:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
	
	duplicator.DoGeneric( Entity, data )
	Entity:Spawn()
	Entity:Activate()
	duplicator.DoGenericPhysics( Entity, Player, data )
	
	table.Add( Entity:GetTable(), data )
	
	return Entity
end

//
//	Create an entity from a table.
//
function AdvDupe.CreateEntityFromTable( Player, EntTable, ID, Offset, HoldAngle )
	
	local EntityClass = duplicator.FindEntityClass( EntTable.Class )
	
	
	local NewPos, NewAngle = LocalToWorld( EntTable.LocalPos, EntTable.LocalAngle, Offset, HoldAngle )
	EntTable.Pos = NewPos
	EntTable.Angle = NewAngle
	if ( EntTable.PhysicsObjects ) then
		for Num, Object in pairs( EntTable.PhysicsObjects ) do
			local NewPos, NewAngle = LocalToWorld( Object.LocalPos, Object.LocalAngle, Offset, HoldAngle )
			Object.Pos = NewPos
			Object.Angle = NewAngle
		end
	end
	
	// This class is unregistered. Instead of failing try using a generic
	// Duplication function to make a new copy..
	if (!EntityClass) then
		return AdvDupe.GenericDuplicatorFunction( Player, EntTable, ID )
	end
	
	// Build the argument list
	if (!EntTable.arglist) then
		EntTable.arglist = {}
		
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
			
			EntTable.arglist[ iNumber ] = Arg
			
		end
	else	
		local fpos, fang = false, false //found ang and pos
		for iNumber, Key in pairs( EntityClass.Args ) do
			
			if ( Key == "pos" || Key == "position" || Key == "Pos") then
				EntTable.arglist[ iNumber ] = EntTable.Pos
				fpos = true
			end
			
			if ( Key == "ang" || Key == "Ang" || Key == "angle" || Key == "Angle" ) then
				EntTable.arglist[ iNumber ] = EntTable.Angle
				fang = true
			end
			
			if (fpos and fang) then break end
			
		end
	end
	
	// Create and return the entity
	//return EntityClass.Func( Player, unpack(EntTable.arglist) )
	local NoFail, Result
	if ( EntTable.Class == "prop_physics" ) then
		NoFail, Result = pcall( AdvDupe.MakeProp, Player, unpack(EntTable.arglist) )
	else
		NoFail, Result = pcall( EntityClass.Func, Player, unpack(EntTable.arglist) )
	end
	if ( !NoFail ) then
		Msg("AdvDupeERROR: CreateEntity failed to make \""..(EntTable.Class or "NIL" ).."\", Error: "..tostring(Result).."\n")
		AdvDupe.SendClientError( Player, "Failed to make \""..(EntTable.Class or "NIL").."\"" )
		return
	else
		return Result
	end
	
end

//
//	Make a constraint from a constraint table
//
function AdvDupe.CreateConstraintFromTable( Player, Constraint, EntityList, Offset, HoldAngle )
	if ( !Constraint ) then return end
	
	local Factory = duplicator.ConstraintType[ Constraint.Type ]
	if ( !Factory ) then return end
	
	local Args = {}
	for k, Key in pairs( Factory.Args ) do
		
		local Val = Constraint[ Key ]
		
		if ( Key == "pl" ) then Val = Player end
		
		for i=1, 6 do 
			if ( Constraint.Entity[ i ] ) then
				if ( Key == "Ent"..i ) or ( Key == "Ent" ) then	
					Val = EntityList[ Constraint.Entity[ i ].Index ] 
					if ( Constraint.Entity[ i ].World ) then
						Val = GetWorldEntity()
					else
						if (!Val) or (!Val:IsValid()) then
							Msg("AdvDupeERROR: Problem with = "..(Constraint.Type or "NIL").." Constraint. Could not find Ent: "..Constraint.Entity[ i ].Index.."\n")
							return
						end
					end
				end
				if ( Key == "Bone"..i ) or ( Key == "Bone" ) then Val = Constraint.Entity[ i ].Bone end
				if ( Key == "LPos"..i ) then
					
					if (Constraint.Entity[ i ].World && Constraint.Entity[ i ].LPos) then
						local NewPos, NewAngle = LocalToWorld( Constraint.Entity[ i ].LPos, Angle(0,0,0), Offset, HoldAngle )
						Constraint.Entity[ i ].LPosOld = Constraint.Entity[ i ].LPos
						Constraint.Entity[ i ].LPos = NewPos
					end
					
					Val = Constraint.Entity[ i ].LPos
				end
				if ( Key == "WPos"..i ) then Val = Constraint.Entity[ i ].WPos end
				if ( Key == "Length"..i ) then Val = Constraint.Entity[ i ].Length end
			end
		end
		
		// If there's a missing argument then unpack will stop sending at that argument
		if ( Val == nil ) then Val = false end
		
		table.insert( Args, Val )
		
	end
	
	//local Entity = Factory.Func( unpack(Args) )
	//return Entity
	
	
	
	if ( DebugWeldsByDrawingThem) and ( Constraint.Type == "Weld" ) then
		RDbeamlib.MakeSimpleBeam(
			EntityList[ Constraint.Entity[ 1 ].Index ], Vector(0,0,0), 
			EntityList[ Constraint.Entity[ 2 ].Index ], Vector(0,0,0), 
			"cable/cable2", Color(255,0,0,255), 1, true
		)
	end
	
	
	
	local NoFail, Result = pcall( Factory.Func, unpack(Args) )
	if ( !NoFail ) then
		Msg("AdvDupeERROR: CreateConstraint failed to make \""..(Constraint.Type or "NIL").."\", Error: "..tostring(Result).."\n")
		AdvDupe.SendClientError( Player, "Failed to make \""..(Constraint.Type or "NIL").."\"" )
		return
	else
		return Result
	end
	
end

//
//	Makes a physics prop with out the spawn effect (cause we don't need it)
//
function AdvDupe.MakeProp( Player, Pos, Ang, Model, PhysicsObjects, Data )

	// Uck.
	Data.Pos = Pos
	Data.Angle = Ang
	Data.Model = Model

	// Make sure this is allowed
	if ( !gamemode.Call( "PlayerSpawnProp", Player, Model ) ) then return end
	
	local Prop = ents.Create( "prop_physics" )
		duplicator.DoGeneric( Prop, Data )
	Prop:Spawn()
	Prop:Activate()
	
	duplicator.DoGenericPhysics( Prop, Player, Data )
	duplicator.DoFlex( Prop, Data.Flex, Data.FlexScale )
	
//	if ( Data && !Data.SkipSolidCheck ) then
//		timer.Simple( 0.01, CheckPropSolid, Prop, COLLISION_GROUP_NONE, COLLISION_GROUP_WORLD )
//	end

	// Tell the gamemode we just spawned something
	gamemode.Call( "PlayerSpawnedProp", Player, Model, Prop )
	//DoPropSpawnedEffect( Prop ) --fuck no
	
	return Prop
	
end

//
//	Apply after paste stuff
//
function AdvDupe.AfterPasteApply( Player, Ent, CreatedEntities )
	
	if ( Ent.PostEntityPaste ) then
		Ent:PostEntityPaste( Player, Ent, CreatedEntities )
	end
	
	//clean up
	if (Ent.EntityMods) then
		if (Ent.EntityMods.RDDupeInfo) then // fix: RDDupeInfo leak 
			Ent.EntityMods.RDDupeInfo = nil
		end
		if (Ent.EntityMods.WireDupeInfo) then 
			Ent.EntityMods.WireDupeInfo = nil
		end
	end
	
end

function AdvDupe.ApplyParenting( Ent, EntID, EntityList, CreatedEntities )

	if ( EntityList[ EntID ].SavedParentIdx ) then
		local Ent2 = CreatedEntities[ EntityList[ EntID ].SavedParentIdx ]
		if ( Ent2 ) and ( Ent2:IsValid() ) then
		if ( Ent == Ent2 ) then
			Msg("Ent == Ent2\n")
		else
			Ent:SetParent() //safe guard
			if ( Ent == Ent2:GetParent() ) then
				Ent2:SetParent()
			end
			Ent:SetParent( Ent2 )
			Msg("set "..EntID.." parent to "..EntityList[ EntID ].SavedParentIdx.."\n")
		end
		end
	end
	
end



//
// Lagacy paste stuff
//
// Paste duplicated ents
function AdvDupe.OldPaste( ply, Ents, Constraints, DupeInfo, DORInfo, HeadEntityID, offset )
	
	local constIDtable, entIDtable, CreatedConstraints, CreatedEnts = {}, {}, {}, {}
	local HeadEntity = nil
	
	
	Msg("\n=================--DoingLegacyPaste--=================\n")
	
	if (!Ents) then return false end
	
	
	for entID, EntTable in pairs( Ents ) do
		
		local Ent = nil
		
		local EntClass = EntTable.Class
		local EntType = duplicator.EntityClasses[EntClass]
		
		
		// Check the antities class is registered with the duplicator
		if EntClass and EntType then
			
			local Args = AdvDupe.PasteGetEntArgs( ply, EntTable, offset )
			
			// make the Entity
			if EntClass == "prop_physics" then //cause new prop swaner uses different args
				Ent = AdvDupe.OldMakeProp( ply, unpack(Args) )
			elseif EntClass == "gmod_wheel" then //cause new wheels use different args
				Ent = AdvDupe.OldMakeWheel( ply, unpack(Args) )
			else
				Ent = EntType.Func( ply, unpack(Args) )
			end
			
		elseif (EntClass) then
			Msg("Duplicator paste: Unknown ent class " .. (EntClass or "NIL") .. "\n")
		end
		
		if Ent and Ent:IsValid() then
			entIDtable[entID] = Ent
			table.insert(CreatedEnts,Ent)
			table.Add( Ent:GetTable(), EntTable )
			
			AdvDupe.PasteApplyEntMods( ply, Ent, EntTable )
		end
		
		if ( entID == HeadEntityID ) then
			HeadEntity = Ent
		end
		
	end
	
	
	
	for _, Constraint in pairs(Constraints) do
		
		local ConstraintType = duplicator.ConstraintType[Constraint.Type]
		
		// Check If the constraint type has been registered with the duplicator
		if Constraint.Type and ConstraintType then
			
			local Args, DoConstraint = AdvDupe.PasteGetConstraintArgs( ply, Constraint, entIDtable, offset )
			
			// make the constraint
			if DoConstraint then
				local const = ConstraintType.Func(unpack(Args))
				table.insert(CreatedConstraints,const)
				
				/*if (Constraint.ConstID) then
					constIDtable[Constraint.ConstID] = const
					Msg("Dupe add constraint ID: " .. Constraint.ConstID .. "\n")
				end*/
			end
			
		elseif (Constraint.Type) then
			Msg("Duplicator paste: Unknown constraint " .. (Constraint.Type or "NIL") .. "\n")
		end
	end
	
	AdvDupe.PasteApplyDupeInfo( ply, DupeInfo, entIDtable )
	
	AdvDupe.PasteApplyDORInfo( DORInfo, function(id) return entIDtable[id] end )
	
	
	/*for entid, motordata in pairs(Wheels) do
		local ent = entIDtable[entid]
		ent:GetTable():SetMotor( constIDtable[motordata.motor] )
		ent:GetTable():SetToggle( motordata.toggle )
	end*/
	
	
	//AdvDupe.PasteRotate( ply, HeadEntity, CreatedEnts ) //remember to turn ghost rotation back on too
	
	return CreatedEnts, CreatedConstraints
end

function AdvDupe.PasteGetEntArgs( ply, EntTable, offset )
	
	local EntArgs, Args, BoneArgs, nBone = {}, {}, nil, nil
	
	
	//these classes use different args than what new commands takes
	if EntTable.Class == "prop_physics"  then
		EntArgs = {"Pos", "Ang", "Model", "Vel", "aVel", "frozen"}
	elseif EntTable.Class == "gmod_wheel"  then
		EntArgs = {"Pos", "Ang", "model", "Vel", "aVel", "frozen", "key_f", "key_r"}
	else
		EntArgs = duplicator.EntityClasses[EntTable.Class].Args
	end
	
	for n,Key in pairs(EntArgs) do
		
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

// Legacy prop physics function
function AdvDupe.OldMakeProp( ply, Pos, Ang, Model, Vel, aVel, frozen )
	
	// check we're allowed to spawn
	if ( !ply:CheckLimit( "props" ) ) then return end
	local Ent = ents.Create( "prop_physics" )
		Ent:SetModel( Model )
		Ent:SetAngles( Ang )
		Ent:SetPos( Pos )
	Ent:Spawn()
	
	// apply velocity If required
	if ( Ent:GetPhysicsObject():IsValid() ) then
		Phys = Ent:GetPhysicsObject()
		Phys:SetVelocity(Vel or 0)
		Phys:AddAngleVelocity(aVel or 0)
		Phys:EnableMotion(frozen != true)
	end
	Ent:Activate()
	
	// tell the gamemode we just spawned something
	ply:AddCount( "props", Ent )
	
	local ed = EffectData()
		ed:SetEntity( Ent )
	util.Effect( "propspawn", ed )
	
	return Ent	
end

// Legacy prop phyics function
function AdvDupe.OldMakeWheel( pl, Pos, Ang, Model, Vel, aVel, frozen, key_f, key_r )

	if ( !pl:CheckLimit( "wheels" ) ) then return false end

	local wheel = ents.Create( "gmod_wheel" )
	if ( !wheel:IsValid() ) then return end
	
	wheel:SetModel(Model )
	wheel:SetPos( Pos )
	wheel:SetAngles( Ang )
	wheel:Spawn()
	
	wheel:GetTable():SetPlayer( pl )

	if ( wheel:GetPhysicsObject():IsValid() ) then
	
		Phys = wheel:GetPhysicsObject()
		if Vel then Phys:SetVelocity(Vel) end
		if aVel then Phys:AddAngleVelocity(aVel) end
		Phys:EnableMotion(frozen != true)
		
	end

	wheel:GetTable().model = model
	wheel:GetTable().key_f = key_f
	wheel:GetTable().key_r = key_r
	
	wheel:GetTable().KeyBinds = {}
	
	// Bind to keypad
	wheel:GetTable().KeyBinds[1] = numpad.OnDown( 	pl, 	key_f, 	"WheelForward", 	wheel, 	true )
	wheel:GetTable().KeyBinds[2] = numpad.OnUp( 	pl, 	key_f, 	"WheelForward", 	wheel, 	false )
	wheel:GetTable().KeyBinds[3] = numpad.OnDown( 	pl, 	key_r, 	"WheelReverse", 	wheel, 	true )
	wheel:GetTable().KeyBinds[4] = numpad.OnUp( 	pl, 	key_r, 	"WheelReverse", 	wheel, 	false )
	
	pl:AddCount( "wheels", wheel )
	
	return wheel
	
end

function AdvDupe.PasteApplyEntMods( ply, Ent, EntTable )
	
	for ModifierType, Modifier in pairs(AdvDupe.OldEntityModifiers) do
		if EntTable[ModifierType] then
			Msg("Applying Mod Type: "..ModifierType.."\n")
			local args = {}
			
			for n,arg in pairs(Modifier.Args) do
				args[n] = EntTable[ModifierType][arg]
			end
			
			Modifier.Func( ply, Ent, unpack(args))
		end
	end
	
	//Apply PhysProp data
	if EntTable.Bones then
		for BoneID,Args in pairs(EntTable.Bones) do
			if Args["physprops"] then
				local Data = {}
				for n,arg in pairs({"motionb", "gravityb", "mass", "dragb", "drag", "buoyancy", "rotdamping", "speeddamping", "material"}) do
					Data[n] = Args["physprops"][arg]
				end
				local PhysObject = Ent:GetPhysicsObjectNum( BoneID )
				AdvDupe.OldSetPhysProp( Player, Ent, BoneID, PhysObject, Data )
			end
		end
	end
	
end

//legacy EntityModifiers for color and material
AdvDupe.OldEntityModifiers = {}
AdvDupe.OldEntityModifiers.colour = {}
AdvDupe.OldEntityModifiers.colour.Args = {"r","g","b","a", "mode", "fx"}
AdvDupe.OldEntityModifiers.material = {}
AdvDupe.OldEntityModifiers.material.Args = {"mat"}
//AdvDupe.OldSetColour
function AdvDupe.OldEntityModifiers.colour.Func( pl, Entity, r,g,b,a, mode, fx )

	Entity:SetColor( r,g,b, a )
	Entity:SetRenderMode(mode)
	Entity:SetKeyValue("renderfx", fx)
	
	local Data = {}
	Data.Color = {}
	Data.Color.r, Data.Color.g, Data.Color.b, Data.Color.a = r,g,b,a
	Data.RenderMode = mode
	Data.RenderFX = fx
	for k, v in pairs( Data ) do Entity[ k ] = v end

	return true
end
//AdvDupe.OldSetMaterial
function AdvDupe.OldEntityModifiers.material.Func( pl, Entity, mat )

	if (!mat) then return end
	if (!Entity || !Entity:IsValid()) then return end

	Entity:SetMaterial( mat )
	//Entity:GetTable().material = {mat = mat}
	Entity.MaterialOverride = mat
	
	return true

end

//the data table uses the old names instead
function AdvDupe.OldSetPhysProp( pl, ent, BoneID, Bone, Data )
		
		if ( !Bone ) then
			Bone = Entity:GetPhysicsObjectNum( BoneID )
			if ( !Bone || !Bone:IsValid() ) then 
				Msg("SetPhysProp: Error applying attributes to invalid physics object!\n")
			return end
		end
		
		
		// Set the physics properties on the bone
		Data2 = {}
		if (Data.gravityb!= nil )	then
			PhysBone:EnableGravity( gravityb )
			Data2.GravityToggle = gravityb
		end
		if (Data.material!= nil)		then 
			PhysBone:EnableGravity( gravityb )
			Data2.Material = material
		end
		if (Data.motionb != nil )	then Bone:EnableMotion( Data.motionb ) end
		if (Data.mass!=nil)			then Bone:SetMass( Data.mass ) end
		if (Data.dragb!=nil)		then Bone:EnableDrag( Data.dragb ) end
		if (Data.drag!=nil)			then Bone:SetDragCoefficient( Data.drag ) end
		if (Data.buoyancy!=nil)		then Bone:SetBuoyancyRatio( Data.buoyancy ) end
		if (Data.rotdamping!=nil)	then Bone:SetDamping( PhysBone:GetSpeedDamping(), Data.rotdamping ) end
		if (Data.speeddamping!=nil)	then Bone:SetDamping( Data.speeddamping, PhysBone:GetRotDamping() ) end
		
		// Add the settings to the bone's table
		if not ent:GetTable().Bones then ent:GetTable().Bones = {} end
		if not ent:GetTable().Bones[Bone] then ent:GetTable().Bones[Bone] = {} end
		
		// Copy these to the new object
		for k, v in pairs(Data2) do
			Entity.PhysicsObjects = Entity.PhysicsObjects or {}
			Entity.PhysicsObjects[ BoneID ] = Entity.PhysicsObjects[ BoneID ] or {}
			Entity.PhysicsObjects[ BoneID ][k] = v 
		end
		
		// HACK HACK
		// If we don't do this the prop will be motion enabled and will
		// slide through the world with no gravity.
		if ( !Bone:IsMoveable() ) then
			Bone:EnableMotion( true )
			Bone:EnableMotion( false )
		end
		
	end

// Get the args to make the constraints
function AdvDupe.PasteGetConstraintArgs( ply, Constraint, entIDtable, offset )
	local Args = {}
	local DoConstraint = true
	local ConstraintType = duplicator.ConstraintType[Constraint.Type]
	
	// Get the args that we need from the ConstraintType table
	for n,key in pairs(ConstraintType.Args) do
		
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
function AdvDupe.PasteApplyDupeInfo( ply, DupeInfoTable, entIDtable )
	if (!DupeInfoTable) then return end
	for id, infoTable in pairs(DupeInfoTable) do
		local ent = entIDtable[id]
		if (ent) and (ent:IsValid()) and (infoTable) and (ent.ApplyDupeInfo) then
			ent:ApplyDupeInfo( ply, ent, infoTable, function(id) return entIDtable[id] end )
		end
	end
end

// Apply DORInfo for DeleteOnRemove
function AdvDupe.PasteApplyDORInfo( DORInfoTable, GetentID )
	
	for id, DORInfo in pairs(DORInfoTable) do
		local ent = GetentID(id)
		if (ent) and (ent:IsValid()) and (DORInfo) then
			//ent:SetDeleteOnRemoveInfo(DORInfo, function(id) return GetentID(id) end)
			
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
/*function AdvDupe.PasteRotate( ply, HeadEntity, CreatedEnts )
	
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
		
		HeadEntity:SetAngles( angle - AdvDupe[ply].HoldAngle )
		
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
*/

// Returns all ents & constraints in a system
/*	function duplicator.GetEnts(ent, EntTable, ConstraintTable)

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
*/

//
//	Register camera entity class
//	fixes key not being saved (Conna)
local function CamRegister(Player, Pos, Ang, Key, Locked, Toggle, Vel, aVel, Frozen, Nocollide)
	if (!Key) then return end
	
	local Camera = ents.Create("gmod_cameraprop")
	Camera:SetAngles(Ang)
	Camera:SetPos(Pos)
	Camera:Spawn()
	Camera:SetKey(Key)
	Camera:SetPlayer(Player)
	Camera:SetLocked(Locked)
	Camera.toggle = Toggle
	Camera:SetTracking(NULL, Vector(0))
	
	if (Toggle == 1) then
		numpad.OnDown(Player, Key, "Camera_Toggle", Camera)
	else
		numpad.OnDown(Player, Key, "Camera_On", Camera)
		numpad.OnUp(Player, Key, "Camera_Off", Camera)
	end
	
	if (Nocollide) then Camera:GetPhysicsObject():EnableCollisions(false) end
	
	// Merge table
	local Table = {
		key			= Key,
		toggle 		= Toggle,
		locked      = Locked,
		pl			= Player,
		nocollide 	= nocollide
	}
	table.Merge(Camera:GetTable(), Table)
	
	// remove any camera that has the same key defined for this player then add the new one
	local ID = Player:UniqueID()
	GAMEMODE.CameraList[ID] = GAMEMODE.CameraList[ID] or {}
	local List = GAMEMODE.CameraList[ID]
	if (List[Key] and List[Key] != NULL ) then
		local Entity = List[Key]
		Entity:Remove()
	end
	List[Key] = Camera
	return Camera
	
end
duplicator.RegisterEntityClass("gmod_cameraprop", CamRegister, "Pos", "Ang", "key", "locked", "toggle", "Vel", "aVel", "frozen", "nocollide")




//Garry's functions copied from duplicator STOOL
//Make them global so pasters can use of them too
//
// Converts to world so that the entities will be spawned in the correct positions
function AdvDupe.ConvertEntityPositionsToWorld( EntTable, Offset, HoldAngle )
	for k, Ent in pairs( EntTable ) do
		local NewPos, NewAngle = LocalToWorld( Ent.LocalPos, Ent.LocalAngle, Offset, HoldAngle )
		Ent.Pos = NewPos
		Ent.Angle = NewAngle
		// And for physics objects
		if ( Ent.PhysicsObjects ) then
			for Num, Object in pairs( Ent.PhysicsObjects ) do
				local NewPos, NewAngle = LocalToWorld( Object.LocalPos, Object.LocalAngle, Offset, HoldAngle )
				Object.Pos = NewPos
				Object.Angle = NewAngle
			end
		end
	end
end

// Move the world positions
function AdvDupe.ConvertConstraintPositionsToWorld( Constraints, Offset, HoldAngle )
	if (!Constraints) then return end
	for k, Constraint in pairs( Constraints ) do
		if ( Constraint.Entity ) then
			for k, Entity in pairs( Constraint.Entity ) do
				if (Entity.World && Entity.LPos) then
					local NewPos, NewAngle = LocalToWorld( Entity.LPos, Angle(0,0,0), Offset, HoldAngle )
					Entity.LPosOld = Entity.LPos
					Entity.LPos = NewPos
				end
			end
		end
	end
end

// Resets the positions of all the entities in the table
function AdvDupe.ResetPositions( EntTable, Constraints )

	for k, Ent in pairs( EntTable ) do
		Ent.Pos = Ent.LocalPos * 1
		Ent.Angle = Ent.LocalAngle * 1
		// And for physics objects
		if ( Ent.PhysicsObjects ) then
			for Num, Object in pairs( Ent.PhysicsObjects ) do
				Object.Pos = Object.LocalPos * 1
				Object.Angle = Object.LocalAngle * 1
			end
		end
	end
	
	if (!Constraints) then return end
	for k, Constraint in pairs( Constraints ) do
		if ( Constraint.Entity ) then
			for k, Entity in pairs( Constraint.Entity ) do
				if (Entity.LPosOld) then
					Entity.LPos = Entity.LPosOld
					Entity.LPosOld = nil
				end
			end
		end
	end
	
end

// Converts the positions from world positions to positions local to Offset
function AdvDupe.ConvertPositionsToLocal( EntTable, Constraints, Offset, HoldAngle )

	for k, Ent in pairs( EntTable ) do
		Ent.Pos = Ent.Pos - Offset
		Ent.LocalPos = Ent.Pos * 1
		Ent.LocalAngle = Ent.Angle * 1
		if ( Ent.PhysicsObjects ) then
			for Num, Object in pairs(Ent.PhysicsObjects) do
				Object.Pos = Object.Pos - Offset
				Object.LocalPos = Object.Pos * 1
				Object.LocalAngle = Object.Angle * 1
				Object.Pos = nil
				Object.Angle = nil
			end
		end
	end
	
	// If the entity is constrained to the world we want to move the points to be
	// relative to where we're clicking
	if (!Constraints) then return end
	for k, Constraint in pairs( Constraints ) do
		if ( Constraint.Entity ) then
			for k, Entity in pairs( Constraint.Entity ) do
				if (Entity.World && Entity.LPos) then
					Entity.LPos = Entity.LPos - Offset
				end
			end
		end
	end

end




Msg("==== Advanced Duplicator v."..AdvDupe.Version.." server module installed! ====\n")
