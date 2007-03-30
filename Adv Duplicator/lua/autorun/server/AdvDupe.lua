
AddCSLuaFile( "autorun/client/cl_advdupe.lua" )
AddCSLuaFile( "autorun/shared/dupeshare.lua" )

include( "autorun/shared/dupeshare.lua" )
if (!dupeshare) then Msg("===ADVDupe: Error! dupeshare module not loaded") end
/*---------------------------------------------------------
   Advanced Duplicator module
   Author: TAD2020
   Thanks to: TheApathetic, SatriAli, Erkle
---------------------------------------------------------*/

AdvDupe = {}


if (CLIENT) then return end



//Garry's functions copied from duplicator STOOL
//Make them global so pasters can use of them too
//
// Converts to world so that the entities will be spawned in the correct positions
//
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

//
// Move the world positions
//
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


//
// Resets the positions of all the entities in the table
//
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

//
// Converts the positions from world positions to positions local to Offset
//
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
				
			end
		end

	end
	
	// If the entity is constrained to the world we want to move the points to be
	// relative to where we're clicking
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







/*---------------------------------------------------------
  Process and save given dupe tables to file
---------------------------------------------------------*/
function AdvDupe.SaveDupeTablesToFile( pl, EntTables, ConstraintTables, DupeInfo, DORInfo, HeadEntityIdx, HoldAngle, HoldPos, filename, desc, debugsave )
	
	//save to a sub folder for each player
	//local dir = "adv_duplicator/"..dupeshare.GetPlayerName(pl)
	if (!AdvDupe[pl:UniqueID()]) then AdvDupe[pl:UniqueID()] = {} end
	local dir = AdvDupe[pl:UniqueID()].cdir or AdvDupe.GetPlayersFolder(pl)
	
	//get and check the that filename contains no illegal characters
	local filename = dupeshare.ReplaceBadChar(filename)
	//tostring(pl:GetInfo( "adv_duplicator_save_filename" )))
	
	filename = dupeshare.FileNoOverWriteCheck( dir, filename )
	
	
	//save to file
	local temp = {}
	
	//let's only save the junk we're acctually going to load
	temp.HeadEntityIdx		= HeadEntityIdx
	temp.HoldAngle			= HoldAngle
	temp.HoldPos			= HoldPos
	
	//make these tables smaller cause there too fucking huge otherwise
	if (debugsave) then
		temp.EntTables			= EntTables
		temp.ConstraintTables	= ConstraintTables
	else
		temp.EntTables, temp.ConstraintTables = AdvDupe.CompactTables( EntTables, ConstraintTables )
	end
	
	//add file versioning, this comes in handy when then save format changes
	temp["VersionInfo"] = {}
	
	local currentfileversion = 0.61
	if (debugsave) then
		currentfileversion = 0.601 //set the file version back 0.009 versions
		temp["VersionInfo"]["FileInfo"]			= "Advanced Duplicator Save File (DebugSave)"
	else
		temp["VersionInfo"]["FileInfo"]			= "Advanced Duplicator Save File"
	end
	temp["VersionInfo"]["FileVersion"]		= currentfileversion
	
	local Creator							= pl:GetName()	or "unknown"
	temp["VersionInfo"]["Creator"]			= Creator
	
	local desc								= desc 			or "none"
	temp["VersionInfo"]["Desc"]				= desc
	
	local NumOfEnts							= table.Count(EntTables)		or 0
	temp["VersionInfo"]["NumOfEnts"]		= NumOfEnts
	
	local NumOfConst						= table.Count(ConstraintTables)	or 0
	temp["VersionInfo"]["NumOfConst"]		= NumOfConst
	
	//prepare the table and save it to file
	temp = dupeshare.PrepareTableToSave(temp)
	
	temp = util.TableToKeyValues(temp)
	file.Write(filename, temp)
	
	return filename, Creator, desc , NumOfEnts, NumOfConst, currentfileversion //for sending to client after saving
end

/*---------------------------------------------------------
  Load and return dupe tables from given file
---------------------------------------------------------*/
function AdvDupe.LoadDupeTableFromFile( filepath )
	
	if ( !file.Exists(filepath) ) then return end
	
	//load from file
	local temp	= file.Read(filepath)
	temp 		= util.KeyValuesToTable(temp)
	
	if ( temp["VersionInfo"] or temp["versioninfo"] ) then //file ueses a different meathod os stroing FullCase
		Msg("Loading old legacy file type\n")
		temp = dupeshare.RebuildTableFromLoad_Old(temp)
	else
		Msg("Loading new file type\n")
		temp = dupeshare.RebuildTableFromLoad(temp)
	end
	
	//check the file was loaded and we understand it's version then load the data in to the tables
	if (temp) and (temp["VersionInfo"]["FileVersion"] >= 0.6) then
		Msg("Loaded new file "..filepath.."  version: "..temp.VersionInfo.FileVersion.."\n")
		
		return temp.EntTables, temp.ConstraintTables, {},{}, temp.HeadEntityIdx, temp.HoldAngle, temp.HoldPos, false, temp.VersionInfo.Creator, temp.VersionInfo.Desc, temp.VersionInfo.NumOfEnts, temp.VersionInfo.NumOfConst, temp.VersionInfo.FileVersion
		
	//Legacy versions, there are no version 0.5 files
	elseif (temp) and (temp["VersionInfo"]["FileVersion"] <= 0.4) then
		Msg("Loaded old legacy file "..filepath.."  version: "..temp.VersionInfo.FileVersion.."\n")
		
		if (temp["VersionInfo"]["FileVersion"] <= 0.2) then
			temp.DupeInfo = {}
			for id, entTable in pairs(temp.Ents) do
				if (entTable.DupeInfo) then
					temp.DupeInfo[id] = entTable.DupeInfo
				end
			end
		end
		
		return temp.Ents, temp.Constraints, temp.DupeInfo, (temp.DORInfo or {}), temp.HeadEntID, temp.HoldAngle, Vector(0,0,0), true, temp.VersionInfo.Creator, temp.VersionInfo.Desc, temp.VersionInfo.NumOfEnts, temp.VersionInfo.NumOfConst, temp.VersionInfo.FileVersion
		
	else
		Msg("\nFILE FAILED TO LOAD! something is wrong with this file:  "..filepath.."\n")
	end
	
end


/*---------------------------------------------------------
  Prepreares Tables For Save
   Compacts the size of the table by
   returning what will be needed
---------------------------------------------------------*/
function AdvDupe.CompactTables( EntityList, ConstraintList )

	local SavableEntities = {}
	for k, v in pairs( EntityList ) do
		
		SavableEntities[ k ] = AdvDupe.SavableEntityFromTable( v )
		
		SavableEntities[ k ].BoneMods = table.Copy( v.BoneMods )
		SavableEntities[ k ].EntityMods = table.Copy( v.EntityMods )
		SavableEntities[ k ].PhysicsObjects = table.Copy( v.PhysicsObjects )
		
	end
	
	local SavableConstraints = {}
	for k, Constraint in pairs( ConstraintList ) do
		
		local SavableConst = AdvDupe.SavableConstraintFromTable( Constraint )
		
		if ( SavableConst ) then
			table.insert( SavableConstraints, SavableConst )
		end
		
	end
	
	return SavableEntities, SavableConstraints
	
end

function AdvDupe.SavableEntityFromTable( EntTable )

	local EntityClass = duplicator.FindEntityClass( EntTable.Class )
	local SavableEntity = {}
	SavableEntity.Class = EntTable.Class
	
	if ( EntTable.Model ) then SavableEntity.Model = EntTable.Model end
	if ( EntTable.Angle ) then SavableEntity.Angle = EntTable.Angle end
	if ( EntTable.Pos ) then SavableEntity.Pos = EntTable.Pos end
	if ( EntTable.LocalPos ) then SavableEntity.LocalPos = EntTable.LocalPos end
	if ( EntTable.LocalAngle ) then SavableEntity.LocalAngle = EntTable.LocalAngle end
	
	if (!EntityClass) then
		return SavableEntity
	end
	
	for iNumber, Key in pairs( EntityClass.Args ) do
		
		SavableEntity[ Key ] = EntTable[ Key ]
		
		/*local Arg = nil
		
		// Translate keys from old system
		if ( Key == "pos" || Key == "position" ) then Key = "Pos" end
		if ( Key == "ang" || Key == "Ang" || Key == "angle" ) then Key = "Angle" end
		if ( Key == "model" ) then Key = "Model" end
		
		Arg = EntTable[ Key ]
		
		// Special keys
		//if ( Key == "Data" ) then Arg = EntTable end
		
		SavableEntity[ Key ] = Arg*/
		
	end
	
	return SavableEntity
	
end

function AdvDupe.SavableConstraintFromTable( Constraint )

	local Factory = duplicator.ConstraintType[ Constraint.Type ]
	if ( !Factory ) then return end
	
	local SavableConst = {}
	SavableConst.Type = Constraint.Type
	SavableConst.Entity = table.Copy( Constraint.Entity )
	if (Constraint.Entity1) then SavableConst.Entity1 = table.Copy( Constraint.Entity1 ) end
	
	for k, Key in pairs( Factory.Args ) do
		if (!string.find(Key, "Ent") or string.len(Key) != 4)
		and (!string.find(Key, "Bone") or string.len(Key) != 5)
		and (Key != "Ent") and (Key != "Bone") then
			SavableConst[ Key ] = Constraint[ Key ]
		end
	end
	
	return SavableConst

end




if (dupeshare and dupeshare.PublicDirs) then
	AdvDupe.PublicDirs = {}
	for k, v in pairs(dupeshare.PublicDirs) do
		AdvDupe.PublicDirs[v] = dupeshare.BaseDir.."/"..v
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
	
	local dir = AdvDupe[pl:UniqueID()].cdir
	local foldername = dupeshare.ReplaceBadChar(string.Implode(" ", args))
	
	AdvDupe.FileOpts(pl, "makedir", foldername, dir)
	
	/*local dir = AdvDupe[pl:UniqueID()].cdir.."/"..dupeshare.ReplaceBadChar(args[1])
	
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
	local dir	= AdvDupe[pl:UniqueID()].cdir
	local dir2	= AdvDupe[pl:UniqueID()].cdir2
	
	AdvDupe.FileOpts(pl, action, filename, dir, dir2)
	
end
concommand.Add("adv_duplicator_fileopts", FileOptsCommand)

local function FileOptsRenameCommand(pl, cmd, args)
	Msg("rename cmd\n")
	if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
	
	//local filename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename" ))..".txt"
	local filename = pl:GetInfo( "adv_duplicator_load_filename" )
	local dir	= AdvDupe[pl:UniqueID()].cdir
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
function AdvDupe.SendClientError(pl, errormsg)
	if !pl:IsValid() or !pl:IsPlayer() or !errormsg or type(errormsg) != "String" then return end
	//pl:SendLua( "dvdupeclient.Error( \""..errormsg.."\" )" )
	umsg.Start("AdvDupeCLError", pl)
		umsg.String(errormsg)
	umsg.End()
end

function AdvDupe.UpdateList(pl)
	local tool = pl:GetActiveWeapon()
	if (dupeshare.CurrentToolIsDuplicator(tool, true)) then
		tool:GetTable():GetToolObject():UpdateList()
	end
end



/*---------------------------------------------------------
	Recieves file from client
---------------------------------------------------------*/
function AdvDupe.RecieveFileContentStart( pl, cmd, args )
	if !pl:IsValid() or !pl:IsPlayer() then return end
	
	Msg("DupeRecieveFileContentStart recieving file: "..args[1].."\n")
	
	if (!AdvDupe[pl:UniqueID()]) then AdvDupe[pl:UniqueID()] = {} end
	
	AdvDupe[pl:UniqueID()].templast		= tonumber(args[1])
	//AdvDupe[pl:UniqueID()].tempdir		= args[2]
	AdvDupe[pl:UniqueID()].tempfilename	= args[2]
	AdvDupe[pl:UniqueID()].tempnum		= 0
	AdvDupe[pl:UniqueID()].tempfile		= {}
	
end
concommand.Add("DupeRecieveFileContentStart", AdvDupe.RecieveFileContentStart)

function AdvDupe.RecieveFileContent( pl, cmd, args )
	if !pl:IsValid() or !pl:IsPlayer() then return end
	
	Msg("recieving piece ")
	if (args[1] == "") or (!args[1]) then return end
	AdvDupe[pl:UniqueID()].tempnum = AdvDupe[pl:UniqueID()].tempnum + 1
	
	Msg(args[1].." / "..AdvDupe[pl:UniqueID()].templast.." received: "..AdvDupe[pl:UniqueID()].tempnum.."\n")
	
	AdvDupe[pl:UniqueID()].tempfile[tonumber(args[1])] = args[2]
	
end
concommand.Add("_DFC", AdvDupe.RecieveFileContent)

function AdvDupe.RecieveFileContentFinish( pl, cmd, args )
	if !pl:IsValid() or !pl:IsPlayer() then return end
	
	local filepath = dupeshare.FileNoOverWriteCheck( AdvDupe.GetPlayersFolder(pl), AdvDupe[pl:UniqueID()].tempfilename )
	Msg("saving recieved file to "..filepath.."\n")
	AdvDupe.RecieveFileContentSave( pl, filepath )
end
concommand.Add("DupeRecieveFileContentFinish", AdvDupe.RecieveFileContentFinish)

function AdvDupe.RecieveFileContentSave( pl, filepath )
	
	//reassemble the pieces
	local temp = ""
	for k, v in pairs(AdvDupe[pl:UniqueID()].tempfile) do
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
	
	umsg.Start("AdvDupeClientSendFinished", pl)
	umsg.End()
end




/*---------------------------------------------------------
	Sends a file to the client
---------------------------------------------------------*/
function AdvDupe.SaveAndSendSaveToClient( pl, filename, desc )
	local filepath = AdvDupe.SaveToFile( pl, filename, desc )
	AdvDupe.SendSaveToClient( pl, filepath )
end

function AdvDupe.SendSaveToClient( pl, filename )
	local pln = pl:UniqueID()
	if (!AdvDupe[pln]) then AdvDupe[pln] = {} end
	if (AdvDupe[pln].temp) then return end //then were sending already and give up
	
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
	
	AdvDupe[pln].temp = file.Read(filepath)
	
	//AdvDupe[pln].temp = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(AdvDupe[pln].temp,"\t\t\"__name\"\t\t","|mn"),"\t\t\"__type\"\t\t","|mt"),"\t\t\t\"V\"\t\t","|mv|"),"\t\t\t\"DupeInfo\"","|mD"),"\"Number\"\n","|mN"),"\"String\"\n","|mS"),"\"Angle\"\n","|mA"),"\"Vector\"\n","|mV"),"\"Bool\"\n","|mB"),"\"Class\"","|mC"),"\"material\"","|mm"),"\"prop_physics\"","|mp"),"\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n","|VI"),"\"models","|wm"),"\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t","|NC"),"\"nocollide\"\n","|nc"),"\"HeadEntID\"\n","|HE"),"\n\t}\n\t\"holdangle\"\n\t{\n","|ha"),"\t\t\"Y\"\t\t\"","|qY"),"\t\t\"z\"\t\t\"","|qz"),"\t\t\"x\"\t\t\"","|qx"),"\t\t\"A\"\t\t\"","|qA"),"\t\t\"B\"\t\t\"","|qB"),"\t\t\"g\"\t\t\"","|qg"),"\t\t\"r\"\t\t\"","|qr"),"\t\t\"p\"\t\t\"","|qp"),"\"HoldAngle\"\n","|HA"),"\t\t\t\t","|4"),"\t\t\t","|3"),"name","|N")
	
	AdvDupe[pln].temp = dupeshare.Compress(AdvDupe[pln].temp, false)
	
	local len = string.len(AdvDupe[pln].temp)
	local last = math.ceil(len / 220) + 1 //+1 because the client counts the first piece recieved as 1 not 0
	
	umsg.Start("AdvDupeRecieveSaveStart", pl)
		umsg.Short(last)
		umsg.String(filename)
		umsg.String(ndir)
	umsg.End()
	Msg("sending file \""..filename..".txt\" in "..tostring(last).." pieces. len: "..tostring(len).."\n")
	
	AdvDupe.SendSaveToClientData(pl, pln, len, 0, last)
	
end

function AdvDupe.SendSaveToClientData(pl, pln, len, offset, last)
	
	for k=0,1 do //sends two pieces
		
		if ((offset + k + 1) <= last) then
			Msg("sending string: "..tostring((offset + k) * 220).." / "..len.." k: "..k.." piece: "..(offset + k + 1).." / "..last.."\n")
			umsg.Start("AdvDupeRecieveSaveData", pl)
				umsg.Short(offset + k + 1) //cause sometimes these are reccieved out of order
				
				if ((offset + k + 1) == last) then
					umsg.String(string.Right(AdvDupe[pln].temp, (len - ((last - 2) * 220))))
					//umsg.String(string.sub(AdvDupe[pln].temp, ((offset + k) * 220)))
					Msg("send last piece\n")
					//inform the client they finished downloading in case they didn't notice
					umsg.Start("AdvDupeClientDownloadFinished", pl)
					umsg.End()
				else
					umsg.String(string.Right(string.Left(AdvDupe[pln].temp, ((offset + k) * 220)),220))
					//local pos = ((offset + k) * 220)
					//umsg.String(string.sub(AdvDupe[pln].temp, pos, (pos +220) ))
				end
				
			umsg.End()
		else
			break
		end
	end
	
	if (offset + 3) <= last then
		timer.Simple( 0.1, AdvDupe.SendSaveToClientData, pl, pln, len, (offset + 2), last )
	else
		AdvDupe[pln].temp = nil //clear this to send again
	end
	
end







//old copy, won't need
// Copy ents & Constraints
/*function AdvDupe.Copy( ply, StartEnt, offset )
	
	// Get all the ents & constraints in the system
	local EntTable, ConstraintTable  = duplicator.GetEnts(StartEnt)
	
	// Clear plys duplicator table
	AdvDupe[ply:UniqueID()] = { Ents = {}, Constraints = {}, HeadEntID = StartEnt:EntIndex(), DupeInfo = {}, DORInfo = {}, Wheels = {} }
	
	// Get info required to re-create each entity
	for EntID, Ent in pairs(EntTable) do
		local EntClass = Ent:GetClass()
			
		// Check the entity class is registered with the duplicator
		local EntType = duplicator.EntityClasses[EntClass]
		if EntType then
			
			AdvDupe[ply:UniqueID()].Ents[EntID] = AdvDupe.CopyGetEntArgs( ply, Ent, offset, EntClass)
			// yeah, just one line now
			
			if Ent:GetTable().BuildDupeInfo then
				AdvDupe[ply:UniqueID()].DupeInfo[EntID] = Ent:GetTable():BuildDupeInfo()
			end
			
			AdvDupe[ply:UniqueID()].DORInfo[EntID] = Ent:GetDeleteOnRemoveInfo()
			
			//special case for wheels
			if (EntClass == "gmod_wheel") or (EntClass == "gmod_wire_wheel") then
				AdvDupe[ply:UniqueID()].Wheels[EntID] = {}
				AdvDupe[ply:UniqueID()].Wheels[EntID].motor = Ent:GetTable():GetMotor():EntIndex()
				AdvDupe[ply:UniqueID()].Wheels[EntID].toggle = Ent:GetTable():GetToggle()
			end
			
		//elseif (EntClass) then
		else
			Msg("Duplicator copy: Unknown class " .. (EntClass or "NIL") .. "\n")
			
			local EntTable = Ent:GetTable()
			EntTable.Class = Ent:GetClass()
			
			// Generic stuff
			EntTable.Model 	= Ent:GetModel()
			EntTable.Pos	= Ent:GetPos() - offset
			EntTable.Angle	= Ent:GetAngles()
		
			//player:GetTable().Duplicator.Ents[ EntID ] = EntTable
			AdvDupe[ply:UniqueID()].Ents[EntID] = EntTable
			
		end
	end
	
	
	// Get info required to re-create each constraint
	for constID, Constraint in pairs(ConstraintTable) do
		
		
		// check the constraint has been registered with the duplicator
		local ConstraintType = duplicator.ConstraintType[Constraint:GetTable().Type]
		if ConstraintType then
			
			local ctable, doconstraint = AdvDupe.CopyGetConstArgs( Constraint, function(id) return EntTable[id] end )
			
			if doconstraint then
				if (type(constID) == "number") then
					ctable.ConstID = constID
				end
				
				ctable.ConstID = Constraint:EntIndex()
				
				table.insert(AdvDupe[ply:UniqueID()].Constraints, ctable)
			end
			
		elseif (Constraint:GetTable().Type) then
			Msg("Duplicator copy: Unknown constraint " .. (Constraint:GetTable().Type or "NIL") .. "\n")
		end
		
	end
	
	Msg("\n=======================--Copyed--=======================\n")
	
	return EntTable, ConstraintTable
end
*/

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



/*---------------------------------------------------------
	Name: AdvDupe.Paste* sub functions
	Desc: functions used during AdvDupe.Paste
---------------------------------------------------------*/
/*function AdvDupe.CopyGetEntArgs( ply, Ent, offset, EntClass )
	
	local etable	= {Class = EntClass}
	local BoneArgs	= nil
	local EntityTable = Ent:GetTable()
	local EntType = duplicator.EntityClasses[EntClass]
	
	// Get the args needed to recreate this ent
	for _, arg in pairs(EntType.Args) do
		
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
				
				for ModifierType, _ in pairs(duplicator.GetEntityBoneModifiers()) do
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
	
	for ModifierType, _ in pairs(duplicator.EntityModifiers) do
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
*/
/*function AdvDupe.CopyGetConstArgs( Constraint, GetEntByID )
	
	ctable = {Type = Constraint:GetTable().Type}
	local doconstraint = true
	
	local ConstraintType = duplicator.ConstraintType[Constraint:GetTable().Type]
	
	for _,Key in pairs(ConstraintType.Args) do
		
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
*/


/*---------------------------------------------------------
	Name: AdvDupe.Paste* sub functions
	Desc: functions used during AdvDupe.Paste
---------------------------------------------------------*/
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
	
	/*for Type, ModFunction in pairs( duplicator.EntityModifiers ) do
		Msg("Mod type: "..Type.."\n")
		//I hope this works
		if EntTable[Type] then
			ModFunction( ply, Ent, EntTable[Type] )
		end
	end*/
	
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
	
	
	/*if EntTable.decals then
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
			,EntTable.decals,Ent
		)
	end*/
	
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
		
		HeadEntity:SetAngles( angle - AdvDupe[ply:UniqueID()].HoldAngle )
		
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


//while Keepupright doesn't get it's table saved rigth, replace the functions that don't
if duplicator.ConstraintType.Keepupright.Args[1] == "Ent" then
	Msg("==AdvDupe: Keepupright Ent not Ent1==\n")

	/*----------------------------------------------------------------------
		Returns this entities constraints table
		This is for the future, because ideally the constraints table will eventually look like this - and we won't have to build it every time.
	----------------------------------------------------------------------*/
	function constraint.GetTable( ent )

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
	  Make a constraint from a constraint table
	---------------------------------------------------------*/
	function duplicator.CreateConstraintFromTable( Constraint, EntityList )

		local Factory = duplicator.ConstraintType[ Constraint.Type ]
		if ( !Factory ) then return end
		
		Msg("CreateConstraint.Type= "..Constraint.Type.."\n")
		
		local Args = {}
		for k, Key in pairs( Factory.Args ) do
		
			local Val = Constraint[ Key ]
			
			for i=1, 6 do 
				if ( Constraint.Entity[ i ] ) then
					if ( Key == "Ent"..i ) or ( Key == "Ent" ) then	
						Val = EntityList[ Constraint.Entity[ i ].Index ] 
						if ( Constraint.Entity[ i ].World ) then
							Val = GetWorldEntity()
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
	
	
	function duplicator.GenericDuplicatorFunction( Player, data )
		if (!data) or (!data.Class) then return false end
		
		Msg("GenDupe.data.Class= "..data.Class.."\n")
		
		local Entity = ents.Create( data.Class )
		if (!Entity:IsValid()) then return false end
		Entity:SetModel( data.Model )
		Entity:Spawn()
		
		duplicator.DoGeneric( Entity, data )
		
		Entity:Activate()
		
		table.Add( Entity:GetTable(), data )
		
		return Entity
		
	end
	
	
	function duplicator.CreateEntityFromTable( Player, EntTable )
		
		local EntityClass = duplicator.FindEntityClass( EntTable.Class )
		
		// This class is unregistered. Instead of failing try using a generic
		// Duplication function to make a new copy..
		if (!EntityClass) then
			
			return duplicator.GenericDuplicatorFunction( Player, EntTable )
			
		end
		
		Msg("CreateEntity.Class= "..EntTable.Class.."\n")
		
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
	
end

/*function constraint.Keepupright( Ent, Ang, Bone, angularlimit )

	if ( !CanConstrain( Ent, Bone ) ) then return false end
	if ( Ent:GetClass() != "prop_physics" && Ent:GetClass() != "prop_ragdoll" ) then return false end
	if ( !angularlimit or angularlimit < 0 ) then return end
	
	local Phys = Ent:GetPhysicsObjectNum(Bone)

	// Remove any KU's already on entity
	constraint.RemoveConstraints( Ent, "Keepupright" )
	
	onStartConstraint( Ent )

		local Constraint = ents.Create( "phys_keepupright" )
			Constraint:SetAngles( Ang )
			Constraint:SetKeyValue( "angularlimit", angularlimit )
			Constraint:SetPhysConstraintObjects( Phys, Phys )
		Constraint:Spawn()
		Constraint:Activate()
	
	onFinishConstraint( Ent )
	AddConstraintTable( Ent, Constraint )
	
	local ctable = 
	{
		Type 			= "Keepupright",
		Ent1 			= Ent1,
		Bone1 			= Bone1,
		Ang 			= Ang,
		angularlimit 	= angularlimit
	}
	Constraint:SetTable( ctable )
	
	return Constraint
	
end

duplicator.RegisterConstraint( "Keepupright", constraint.Keepupright, "Ent", "Ang", "Bone", "angularlimit" )*/



Msg("--- Wire duplicator v.0.61 server module installed! ---\n")
