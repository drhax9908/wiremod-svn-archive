//Advanced Duplicator by TAD2020
//Build on Garry Duplicator Technology

TOOL.Category		= "Construction"
TOOL.Name			= "Advanced Duplicator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_adv_duplicator_name", "Advanced Duplicator" )
    language.Add( "Tool_adv_duplicator_desc", "Duplicate an entity, or group of entities" )
    language.Add( "Tool_adv_duplicator_0", "Right click to copy, Reload places Paster" )
    language.Add( "Tool_duplicator_1", "Now left click to paste, Reload places Paster" )
end


TOOL.ClientConVar[ "simple" ]			= 0
TOOL.ClientConVar[ "save_filename" ]	= ""
TOOL.ClientConVar[ "load_filename" ]	= ""
TOOL.ClientConVar[ "load_filename2" ]	= ""
TOOL.ClientConVar[ "load_filename_cl" ]	= ""
TOOL.ClientConVar[ "file_desc" ]		= ""
TOOL.ClientConVar[ "delay" ]			= 0
TOOL.ClientConVar[ "undo_delay" ]		= 0
TOOL.ClientConVar[ "range" ]			= "1500"
TOOL.ClientConVar[ "show_beam" ]		= "1"

cleanup.Register( "duplicates" )


// Paste a copy
function TOOL:LeftClick( trace )
	
	if ( CLIENT ) then	return true	end
	if (!self.Entities) then return end
	
	local angle  = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll = 0	
	
	local Ents, Constraints = nil,nil
	
	if self.Legacy then
		
		//paste using legacy data
		Msg("===doing old paste===\n")
		Ents, Constraints = AdvDupe.OldPaste( self:GetOwner(), self.Entities, self.Constraints, self.DupeInfo, self.DORInfo, HeadEntityID, trace.HitPos )
		
	else
		
		// Create the entities at the clicked position at the angle we're facing right now	
		AdvDupe.ConvertEntityPositionsToWorld( self.Entities, trace.HitPos, angle - self.HoldAngle )
		AdvDupe.ConvertConstraintPositionsToWorld( self.Constraints, trace.HitPos, angle - self.HoldAngle )
		
		Msg("===doing new paste===\n")
		Ents, Constraints = duplicator.Paste( self:GetOwner(), self.Entities, self.Constraints )//, self.DupeInfo, self.DORInfo )
		
		AdvDupe.ResetPositions( self.Entities, self.Constraints )
		
	end
	
	// Add all of the created entities
	//  to the undo system under one undo.
	undo.Create( "Duplicator" )
		
		for k, ent in pairs( Ents ) do
			undo.AddEntity( ent )
			self:GetOwner():AddCleanup( "duplicates", ent ) 
		end
		
		undo.SetPlayer( self:GetOwner() )
		
	undo.Finish()
	
	return true
	
end

// Put The stuff we're pointing at in the 'clipboard'
function TOOL:RightClick( trace )
	
	if (!trace.Entity ||
		!trace.Entity:IsValid() ||
		trace.Entity:IsPlayer() )
	then
	
		self.Entities = nil
		self:ReleaseGhostEntity()
		self.GhostEntities = {}
		
		return false
	
	end

	local StartPos = trace.Entity:GetPos()

	self:ReleaseGhostEntity()

	if ( CLIENT ) then return true end
	
	// Get the distance from the floor
	local tr = {}
	tr.start = StartPos
	tr.endpos = StartPos + Vector(0,0,-1024)
	tr.mask = MASK_NPCSOLID_BRUSHONLY
	local tr_floor = util.TraceLine( tr )
	if (tr_floor.Hit) then 

		StartPos = StartPos  + Vector(0,0,-1) * tr_floor.Fraction * 1024
	
	end
	
	// Copy the entities
	local Entities, Constraints = duplicator.Copy( trace.Entity )
	
	local angle  = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll = 0
	
	// Convert the positions to local
	AdvDupe.ConvertPositionsToLocal( Entities, Constraints, StartPos, angle )

	// Store stuff for pasting/ghosting
	self.HeadEntityIdx	= trace.Entity:EntIndex()
	self.HoldAngle 		= angle
	self.HoldPos 		= StartPos
	self.Entities		= Entities
	self.Constraints	= Constraints
	self.Legacy			= false
	
	self:GetOwner():SendLua( "AdvDupeClient.FileLoaded=false" )
	self:GetOwner():SendLua( "AdvDupeClient.Copied=true" )
	
	self:StartGhostEntities( Entities )
	
	return true
	
end


//
//TODO: update paster to support new duplicator code
//
//make a paster ent
function TOOL:Reload( trace )
	if (CLIENT) then return true end
	
	local pl = self:GetOwner()
	local pln = self:GetOwner():UniqueID()
	
	if (!AdvDupe[pln].Ents) then return false end
	
	local paster = ents.Create( "gmod_adv_dupe_paster" )
	if (!paster:IsValid()) then return false end
	
	//paster:SetPos( pl:GetShootPos() + pl:GetAimVector() * 32 )
	//paster:SetAngles( pl:GetAimVector() )
	paster:SetPos( trace.HitPos )
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	paster:SetAngles( Ang )
	
	paster:Spawn()
	paster:SetPlayer( pl )
	
	local min = paster:OBBMins()
	paster:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local phys = paster:GetPhysicsObject()
	if (phys:IsValid()) then phys:EnableMotion(false) end
	//paster:SetNotSolid(true)

	local ttable = {pl = pl}
	table.Merge(paster:GetTable(), ttable )
	
	undo.Create("Paster")
		undo.AddEntity( paster )
		undo.SetPlayer( pl )
	undo.Finish()
	
	local delay 		= self:GetClientNumber( "delay" )
	local undo_delay	= self:GetClientNumber( "undo_delay" )
	local range			= self:GetClientNumber("range")
	local show_beam		= (self:GetClientNumber("show_beam") == 1)
	
	paster:Setup(
		table.Copy(self.Entities),
		table.Copy(self.Constraints),
		table.Copy(self.DupeInfo),
		self.HeadEntityIdx, self.HoldAngle, self.HoldPos, delay, undo_delay, range, show_beam
	)
	
	
	return true
end

//just because
function TOOL.BuildCPanel( CPanel )
	
	CPanel:AddControl( "Header", { Text = "#Tool_adv_duplicator_name", Description	= "#Tool_adv_duplicator_desc" }  )

end


function TOOL:Think()
	//not much to think about.
	
	self:UpdateGhostEntities()
	
end


/*---------------------------------------------------------
   Starts up the ghost entities
---------------------------------------------------------*/
function TOOL:StartGhostEntities( EntityTable )
	
	self:ReleaseGhostEntity()
	self.GhostEntities = {}
	if self.Legacy then return end //TODO: no ghosting support for lagcey loads, table are too fucking different
	
	self.GhostEntities[ self.HeadEntityIdx ] = self:MakeGhostFromTable( EntityTable[ self.HeadEntityIdx ], self.GhostEntities[ self.HeadEntityIdx ] )
	
	
	self.Weapon:SetNetworkedEntity( "GhostEntity", self.GhostEntities[ self.HeadEntityIdx ] )
	self.Weapon:SetNetworkedVector( "HeadPos", self.GhostEntities[ self.HeadEntityIdx ].Pos )
	self.Weapon:SetNetworkedAngle( 	"HeadAngle", self.GhostEntities[ self.HeadEntityIdx ].Angle )	
	
	if ( !self.GhostEntities[ self.HeadEntityIdx ] || !self.GhostEntities[ self.HeadEntityIdx ]:IsValid()  ) then
		
		self.GhostEntities = nil
		return
		
	end
	
	for k, entTable in pairs( EntityTable ) do
		
		if ( !self.GhostEntities[ k ] ) then
			self.GhostEntities[ k ] = self:MakeGhostFromTable( entTable, self.GhostEntities[ self.HeadEntityIdx ] )
		end
		
	end

end

// Make the ghost entities
function TOOL:MakeGhostFromTable( EntTable, pParent )

	local GhostEntity = nil
	
	if ( EntTable.Model:sub( 1, 1 ) == "*" ) then
		GhostEntity = ents.Create( "func_physbox" )
	else
		GhostEntity = ents.Create( "prop_physics" )
	end
	
	// If there are too many entities we might not spawn..
	if ( !GhostEntity || GhostEntity == NULL ) then return end
	
	// If we're a ragdoll set our model  as a watermelon
	if ( EntTable.Class == "prop_ragdoll" ) then
		GhostEntity:SetModel( "models/props_junk/watermelon01.mdl" )
	else
		GhostEntity:SetModel( EntTable.Model )
	end
	
	GhostEntity:SetPos( EntTable.Pos )
	GhostEntity:SetAngles( EntTable.Angle )
	GhostEntity:Spawn()
	
	GhostEntity:DrawShadow( false )
	GhostEntity:SetMoveType( MOVETYPE_NONE )
	GhostEntity:SetSolid( SOLID_VPHYSICS );
	GhostEntity:SetNotSolid( true )
	GhostEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
	GhostEntity:SetColor( 255, 255, 255, 150 )
	
	GhostEntity.Pos 	= EntTable.Pos
	GhostEntity.Angle 	= EntTable.Angle - self.HoldAngle
	
	if ( pParent ) then
		GhostEntity:SetParent( pParent )
	end
	
	return GhostEntity
	
end

/*---------------------------------------------------------
   Update the ghost entity positions
---------------------------------------------------------*/
function TOOL:UpdateGhostEntities()

	if (SERVER && !self.GhostEntities) then return end

	local tr = utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end

	local GhostEnt = nil
	
	if ( SERVER ) then
		GhostEnt = self.GhostEntities[ self.HeadEntityIdx ]
	else
		GhostEnt = self.Weapon:GetNetworkedEntity( "GhostEntity", nil )
		GhostEnt.Pos = self.Weapon:GetNetworkedVector( "HeadPos", Vector(0,0,0) )
		GhostEnt.Angle = self.Weapon:GetNetworkedAngle( "HeadAngle", Angle(0,0,0) )		
	end
	
	if (!GhostEnt || !GhostEnt:IsValid()) then 
		// HACKKKK - this should be done in ReleaseGhostEntity
		self.GhostEntities = nil
	return end
	
	GhostEnt:SetMoveType( MOVETYPE_VPHYSICS )
	GhostEnt:SetNotSolid( true )
	
	local angle  = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll = 0

	local PhysObj = GhostEnt:GetPhysicsObject()
	if ( PhysObj && PhysObj:IsValid() ) then
	
		PhysObj:EnableMotion( false )
		PhysObj:SetPos( GhostEnt.Pos + trace.HitPos )
		PhysObj:SetAngle( GhostEnt.Angle + angle )
		PhysObj:Wake()
		
	else
	
		if ( CLIENT ) then
			GhostEnt:PhysicsInit( SOLID_VPHYSICS )
		end
	
	end
		
end


function TOOL:Deploy()
	
	if ( self.Entities ) then
		self:StartGhostEntities( self.Entities )
	end
	
	if ( CLIENT ) then return end
	
	self.stage		= 0
	self.thinker	= 0
	
	if !AdvDupe[self:GetOwner():UniqueID()] then AdvDupe[self:GetOwner():UniqueID()] = {} end
	AdvDupe[self:GetOwner():UniqueID()].cdir = AdvDupe.GetPlayersFolder(self:GetOwner())
	AdvDupe[self:GetOwner():UniqueID()].cdir2 = ""
	
	self:GetOwner():SendLua( "AdvDupeClient.CLcdir=\""..dupeshare.BaseDir.."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.CLcdir2=\""..dupeshare.BaseDir.."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.CurMenu=\"main\"" )
	
	self:UpdateList()
	
end




function TOOL:SaveFile( filename, desc )
	if ( CLIENT ) then return end
	if (!filename) or (!self.Entities) then return end
	
	local Filename, Creator, Desc, NumOfEnts, NumOfConst, FileVersion = AdvDupe.SaveDupeTablesToFile( self:GetOwner(), 
		self.Entities, self.Constraints, self.DupeInfo, self.DORInfo,
		self.HeadEntityIdx, self.HoldAngle, self.HoldPos,
		filename, desc
	)
	
		self:GetOwner():SendLua( "AdvDupeClient.FileLoaded=true" )
		self:GetOwner():SendLua( "AdvDupeClient.Copied=false" )
		
		self:GetOwner():SendLua( "AdvDupeClient.LoadedFilename=\""..Filename.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedCreator=\""..Creator.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedDesc=\""..Desc.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfEnts=\""..NumOfEnts.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfConst=\""..NumOfConst.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedFileVersion=\""..FileVersion.."\"" )
	
	self:UpdateList()
	
end

function TOOL:LoadFile( filepath )
	if ( CLIENT ) then return end
	
	local Entities, Constraints, DupeInfo, DORInfo, HeadEntityIdx, HoldAngle, HoldPos, Legacy, Creator, Desc, NumOfEnts, NumOfConst, FileVersion = AdvDupe.LoadDupeTableFromFile( filepath )
	
	if Entities then
		self:ReleaseGhostEntity()
		
		self.HeadEntityIdx	= HeadEntityIdx
		self.HoldAngle 		= HoldAngle
		self.HoldPos 		= HoldPos
		
		self.Entities		= Entities
		self.Constraints	= Constraints
		self.DupeInfo		= DupeInfo
		self.DORInfo		= DORInfo
		
		self.Legacy			= Legacy
		
		self:GetOwner():SendLua( "AdvDupeClient.FileLoaded=true" )
		self:GetOwner():SendLua( "AdvDupeClient.Copied=false" )
		
		self:GetOwner():SendLua( "AdvDupeClient.LoadedFilename=\""..filepath.."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedCreator=\""..(Creator or "n/a").."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedDesc=\""..(Desc or "n/a").."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfEnts=\""..(NumOfEnts or "n/a").."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfConst=\""..(NumOfConst or "n/a").."\"" )
		self:GetOwner():SendLua( "AdvDupeClient.LocadedFileVersion=\""..(FileVersion or "n/a").."\"" )
		
		self:UpdateList()
		
		self:StartGhostEntities( self.Entities )
	end
	
end

function TOOL:UpdateList()
	if (!self:GetOwner():IsValid()) then return false end
	if (!self:GetOwner():IsPlayer()) then return false end
	
	self:GetOwner():SendLua( "if ( !duplicator ) then AdvDupeClient={} end" )
	
	local cdir = AdvDupe[self:GetOwner():UniqueID()].cdir
	--Msg("cdir= "..cdir.."\n")
	self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs={}" )
	self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles={}" )
	self:GetOwner():SendLua( "AdvDupeClient.SScdir=\""..cdir.."\"" )
	
	if (cdir != AdvDupe.GetPlayersFolder(self:GetOwner())) then
		self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/..\"] = \""..dupeshare.UpDir(cdir).."\"" )
	end
	
	if ( file.Exists(cdir) && file.IsDir(cdir)) then
		for key, val in pairs( file.Find( cdir.."/*" ) ) do
			if ( !file.IsDir( cdir.."/"..val ) ) then
				self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles[\""..val.."\"] = \""..cdir.."/"..val.."\"" )
			elseif  ( file.IsDir( cdir.."/"..val ) ) then
				self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/"..val.."\"] = \""..cdir.."/"..val.. "\"" )
			end
		end
	end
	
	
	if (AdvDupe[self:GetOwner():UniqueID()].cdir2 != "") then
		
		local cdir2 = AdvDupe[self:GetOwner():UniqueID()].cdir2
		--Msg("cdir2= "..cdir2.."\n")
		self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs2={}" )
		self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles2={}" )
		self:GetOwner():SendLua( "AdvDupeClient.SScdir2=\""..cdir2.."\"" )
		
		if (cdir2 != AdvDupe.GetPlayersFolder(self:GetOwner())) then
			self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs2[\"/..\"] = \""..dupeshare.UpDir(cdir2).."\"" )
		end
		
		if ( file.Exists(cdir2) && file.IsDir(cdir2)) then
			for key, val in pairs( file.Find( cdir2.."/*" ) ) do
				if ( !file.IsDir( cdir2.."/"..val ) ) then
					self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles2[\""..val.."\"] = \""..cdir2.."/"..val.."\"" )
				elseif  ( file.IsDir( cdir2.."/"..val ) ) then
					self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs2[\"/"..val.."\"] = \""..cdir2.."/"..val.. "\"" )
				end
			end
		end
		
	end
	
	
	// Force user to update list
	self:GetOwner():SendLua( "AdvDuplicator_UpdateControlPanel()" )
	
end




if SERVER then
	
	
	//Serverside save of duplicated ents
	local function AdvDupeSS_Save( pl, _, args )

		if !pl:IsValid() 
		or !pl:IsPlayer() 
		//or !pl:GetTable().Duplicator 
		//or !AdvDupe[pl:UniqueID()] 
		then return end
		
		local tool = pl:GetActiveWeapon()
		if !dupeshare.CurrentToolIsDuplicator(tool, true) then return end
		if (!tool:GetTable():GetToolObject().Entities) then return end
		if (tool:GetTable():GetToolObject().Legacy) then
			AdvDupe.SendClientError(pl, "Cannot Save Loaded Legacy Data!")
		end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_save_filename" )
		else filename = tostring(args[1]) end
		
		local desc = ""
		if !args[2] //if a filename wasn't passed with a arg, then get the selection in the panel
		then desc = pl:GetInfo( "adv_duplicator_file_desc" )
		else desc = tostring(args[2]) end
		
		//save to file
		//AdvDupe.SaveToFile( pl, tostring(filename), tostring(desc) )
		
		tool:GetTable():GetToolObject():SaveFile( tostring(filename), tostring(desc) )
		
		//tool:GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_save", AdvDupeSS_Save )
	
	//Load duplicated ents from file
	/*local function AdvDupeSS_Load( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool, true)) then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_load_filename" )
		//then filepath = tool:GetTable():GetToolObject().load_filename2
		else filename = tostring(args[1]) end
		
		AdvDupe.LoadFromFile( pl, filename )
		
		if (dupeshare.CurrentToolIsDuplicator(tool, true)) then
			//pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():StartGhostEntities()")
			tool:GetTable():GetToolObject():StartGhostEntities()
			tool:GetTable():GetToolObject():SendGhostToClient(true)
			pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():UpdateGhostEntities()" )
		end
	end
	concommand.Add( "adv_duplicator_load", AdvDupeSS_Load )*/
	
	
	//Load duplicated file or open folder
	local function AdvDupeSS_Open( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool, true)) then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		//then filepath = tool:GetTable():GetToolObject().load_filename2
		then filepath = pl:GetInfo( "adv_duplicator_load_filename" )
		else filepath = tostring(args[1]) end
		
		
		if ( file.Exists(filepath) && file.IsDir(filepath) ) then
			//dupeshare.UsePWSys
			tool:GetTable():GetToolObject().cdir = filepath
			tool:GetTable():GetToolObject():UpdateList()
			
		elseif ( file.Exists(filepath) && !file.IsDir(filepath) ) then
			
			//AdvDupe.LoadFromFile( pl, filepath )
			
			tool:GetTable():GetToolObject():LoadFile( filepath )
			
			//pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():StartGhostEntities()")
			//tool:GetTable():GetToolObject():StartGhostEntities()
			//tool:GetTable():GetToolObject():SendGhostToClient(true)
			//pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():UpdateGhostEntities()" )
			
		else //list must be outdated, refresh it
			tool:GetTable():GetToolObject():UpdateList()
			return
		end
		
	end
	concommand.Add( "adv_duplicator_open", AdvDupeSS_Open )
	
	local function AdvDupeSS_OpenDir(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool, true)) then return end
		
		/*local dir = ""
		if args[2] then
			for k,v in pairs(args) do
				dir = dir.." "..v
			end
		else
			dir = args[1]
		end*/
		local dir = string.Implode(" ", args)
		
		if ( file.Exists(dir) && file.IsDir(dir) ) then
			//dupeshare.UsePWSys
			AdvDupe[pl:UniqueID()].cdir = dir
		/*elseif ( file.Exists(args[1]) && !file.IsDir(args[1]) ) then
			tool:GetTable():GetToolObject().load_filename2 = args[1]*/
		end
		
		tool:GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_open_dir", AdvDupeSS_OpenDir )
	
	
	local function AdvDupeSS_OpenDir2(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool, true)) then return end
		
		if (!args[1]) then
			AdvDupe[pl:UniqueID()].cdir2 = AdvDupe[pl:UniqueID()].cdir
		else
			/*local dir = ""
			if args[2] then
				for k,v in pairs(args) do
					dir = dir.." "..v
				end
			else
				dir = args[1]
			end*/
			local dir = string.Implode(" ", args)
			if ( file.Exists(dir) && file.IsDir(dir) ) then
				//dupeshare.UsePWSys
				AdvDupe[pl:UniqueID()].cdir2 = dir
			end
		end
		
		tool:GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_open_dir2", AdvDupeSS_OpenDir2 )
	
	// Clientside save of duplicated ents
	local function AdvDupeCL_Save( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		//or !pl:GetTable().Duplicator 
		or !AdvDupe[pl:UniqueID()] 
		then return end

		//save to file
		AdvDupe.SaveAndSendSaveToClient( pl, tostring(pl:GetInfo( "adv_duplicator_save_filename" )), tostring(pl:GetInfo( "adv_duplicator_file_desc" )) )
		
		AdvDupe.UpdateList(pl)
	end
	concommand.Add( "adv_duplicator_save_cl", AdvDupeCL_Save )
	
	//sends the selected file to the client
	local function AdvDupeSS_ClSend( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_load_filename" )
		else filename = tostring(args[1]) end
		
		AdvDupe.SendSaveToClient( pl, filename )
		
		pl:SendLua( "AdvDuplicator_UpdateControlPanel()" )
	end
	concommand.Add( "adv_duplicator_send_cl", AdvDupeSS_ClSend )
	
	
	//allow the client to refresh the list
	local function AdvDupeSS_UpdateLoadList( pl, command, args )
		if args[1] then AdvDupe[pl:UniqueID()].cdir2 = "" end
		
		AdvDupe.UpdateList(pl)
	end
	concommand.Add( "adv_duplicator_updatelist", AdvDupeSS_UpdateLoadList )
	
	
	
	/*local function AdvDupeSS_StartGhostEntities( pl, command, args )
		local tool = pl:GetActiveWeapon()
		if (dupeshare.CurrentToolIsDuplicator(tool)) then
			tool:GetTable():GetToolObject():StartGhostEntities()
		end
	end
	concommand.Add( "adv_duplicator_startghost", AdvDupeSS_StartGhostEntities )*/
	
	
	
	
else	// CLIENT

	function AdvDuplicator_UpdateControlPanel()
		
		local CPanel = GetControlPanel( "adv_duplicator" )
		if (!CPanel) then return end
		
		//clear the panel so we can make it again!
		CPanel:ClearControls()
		CPanel:AddHeader()
		CPanel:AddDefaultControls()
		
		local menu = AdvDupeClient.CurMenu
		
		//build the folder lists, if we'll need them
		local ServerDirParams = {}
		local ClientDirParams = {}
		if (menu == "main") or (!menu) or (menu == "") or (menu == "serverdir") or (menu == "clientupload") then
			ServerDirParams.Height = 180
			ServerDirParams.Options = {}
			if (!SinglePlayer()) then
				ServerDirParams.Label = "Server: "..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "")
			else
				ServerDirParams.Label = "Local: "..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "")
			end
			Msg("cdir= "..ServerDirParams.Label.."\n")
			
			if ( AdvDupeClient.LoadListDirs ) then
				for k,v in pairs( AdvDupeClient.LoadListDirs ) do
					ServerDirParams.Options[k] = {}
					ServerDirParams.Options[k].adv_duplicator_open_dir = v
				end
			end
			if ( AdvDupeClient.LoadListFiles ) then
				for k,v in pairs( AdvDupeClient.LoadListFiles ) do
					ServerDirParams.Options[k] = {}
					ServerDirParams.Options[k].adv_duplicator_load_filename = v
				end
			end
		end
		if (menu == "clientupload") or (menu == "clientdir") then
			ClientDirParams.Label = "Local: "..string.gsub(AdvDupeClient.CLcdir, dupeshare.BaseDir, "")
			Msg("local cdir= "..ClientDirParams.Label.."\n")
			
			ClientDirParams.Height = 180
			ClientDirParams.Options = {}
			if (AdvDupeClient.CLcdir != dupeshare.BaseDir) then
				ClientDirParams.Options["/.."] = {}
				ClientDirParams.Options["/.."].adv_duplicator_open_cl = dupeshare.UpDir(AdvDupeClient.CLcdir)
			end
			if ( file.Exists(AdvDupeClient.CLcdir) && file.IsDir(AdvDupeClient.CLcdir) ) then
				for key, val in pairs( file.Find( AdvDupeClient.CLcdir.."/*" ) ) do
					if ( !file.IsDir( AdvDupeClient.CLcdir.."/"..val ) ) then
						ClientDirParams.Options[val] = {}
						ClientDirParams.Options[val].adv_duplicator_load_filename_cl = AdvDupeClient.CLcdir.."/"..val
					elseif  ( file.IsDir( AdvDupeClient.CLcdir.."/"..val ) ) then
						ClientDirParams.Options["/"..val] = {}
						ClientDirParams.Options["/"..val].adv_duplicator_open_cl = AdvDupeClient.CLcdir.."/"..val
					end
				end
			end
		end
		
		local ServerDir2Params = {}
		local ClientDir2Params = {}
		if (menu == "serverdir") then
		ServerDir2Params.Height = 180
			ServerDir2Params.Options = {}
			if (!SinglePlayer()) then
				ServerDirParams.Label = "Source: Server:"..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "")
				ServerDir2Params.Label = "Destination: Server:"..string.gsub(AdvDupeClient.SScdir2, dupeshare.BaseDir, "")
			else
				ServerDirParams.Label = "Local Source: "..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "")
				ServerDir2Params.Label = "Local Destination: "..string.gsub(AdvDupeClient.SScdir2, dupeshare.BaseDir, "")
			end
			Msg("cdir2= "..ServerDir2Params.Label.."\n")
			
				if ( AdvDupeClient.LoadListDirs2 ) then
					for k,v in pairs( AdvDupeClient.LoadListDirs2 ) do
						ServerDir2Params.Options[k] = {}
						ServerDir2Params.Options[k].adv_duplicator_open_dir2 = v
					end
				end
				if ( AdvDupeClient.LoadListFiles2 ) then
					for k,v in pairs( AdvDupeClient.LoadListFiles2 ) do
						ServerDir2Params.Options[k] = {}
						ServerDir2Params.Options[k].adv_duplicator_load_filename2 = v
					end
				end
		elseif (menu == "clientdir") then
			ClientDirParams.Label = "Local Source: "..string.gsub(AdvDupeClient.CLcdir, dupeshare.BaseDir, "")
			ClientDir2Params.Label = "Local Destination: "..string.gsub(AdvDupeClient.CLcdir2, dupeshare.BaseDir, "")
			Msg("local cdir2= "..ClientDir2Params.Label.."\n")
			
			ClientDir2Params.Height = 180
			ClientDir2Params.Options = {}
			if (AdvDupeClient.CLcdir2 != dupeshare.BaseDir) then
				ClientDir2Params.Options["/.."] = {}
				ClientDir2Params.Options["/.."].adv_duplicator_open_cl2 = dupeshare.UpDir(AdvDupeClient.CLcdir2)
			end
			if ( file.Exists(AdvDupeClient.CLcdir2) && file.IsDir(AdvDupeClient.CLcdir2) ) then
				for key, val in pairs( file.Find( AdvDupeClient.CLcdir2.."/*" ) ) do
					if ( !file.IsDir( AdvDupeClient.CLcdir2.."/"..val ) ) then
						ClientDir2Params.Options[val] = {}
						ClientDir2Params.Options[val].adv_duplicator_load_filename_cl2 = AdvDupeClient.CLcdir2.."/"..val
					elseif  ( file.IsDir( AdvDupeClient.CLcdir2.."/"..val ) ) then
						ClientDir2Params.Options["/"..val] = {}
						ClientDir2Params.Options["/"..val].adv_duplicator_open_cl2 = AdvDupeClient.CLcdir2.."/"..val
					end
				end
			end
		end
		
		
		//show the current menu
		if (menu == "main") or (!menu) or (menu == "") then
			
			
			
			if (!SinglePlayer()) then
				CPanel:AddControl( "Label", { Text = "Server Menu (save and load)" })
			else
				CPanel:AddControl( "Label", { Text = "Main Menu (save and load)" })
			end
			
			CPanel:AddControl( "ListBox", ServerDirParams )
			
			CPanel:AddControl( "Button", {
				Text = "Open",
				Command = "adv_duplicator_open" })
			
			
			if (SinglePlayer()) then
				/*local params = {}
					params.Text = "Load Selected File"
					params.Command = "adv_duplicator_load"
				CPanel:AddControl( "Button", params )*/
				
				/*CPanel:AddControl( "Button", {
					Text = "#Duplicator_save",
					Command = "adv_duplicator_save" })*/
				
				CPanel:AddControl( "Button", {
					Text = "Save",
					Command = "adv_duplicator_save_gui" })
				
				CPanel:AddControl( "Button", {
					Text = "Open Folder Manager Menu",
					Command = "adv_duplicator_cl_menu serverdir" })
			else
				/*local params = {}
					params.Text = "Load Selected File From Server"
					params.Command = "adv_duplicator_load"
				CPanel:AddControl( "Button", params )*/
				
				/*CPanel:AddControl( "Button", {
					Text = "Save To Server",
					Command = "adv_duplicator_save" })*/
				
				CPanel:AddControl( "Button", {
					Text = "Save To Server",
					Command = "adv_duplicator_save_gui" })
				
				/*CPanel:AddControl( "Button", {
					Text = "Save to Server Then Download",
					Command = "adv_duplicator_save_cl" })*/
				
				CPanel:AddControl( "Button", {
					Text = "Open Upload/Download Menu",
					Command = "adv_duplicator_cl_menu clientupload" })
				
				CPanel:AddControl( "Button", {
					Text = "Open Server Folder Manager Menu",
					Command = "adv_duplicator_cl_menu serverdir" })
			end
		
			/*CPanel:AddControl("TextBox", {
				Label = "Filename:",
				Command = "adv_duplicator_save_filename" })
			
			CPanel:AddControl("TextBox", {
				Label = "Description:",
				Command = "adv_duplicator_file_desc" })*/
			
			//TODO: fix paster
			/*CPanel:AddControl( "Button", {
				Text = "Open Paster Menu",
				Command = "adv_duplicator_cl_menu paster" })*/
			
			
			
			if (AdvDupeClient.FileLoaded) then
				
				CPanel:AddControl( "Label", { Text = "File Loaded: \""..string.gsub(AdvDupeClient.LoadedFilename, dupeshare.BaseDir, "").."\"" })
				CPanel:AddControl( "Label", { Text = "Creator: "..AdvDupeClient.LocadedCreator })
				CPanel:AddControl( "Label", { Text = "Desc: "..AdvDupeClient.LocadedDesc })
				CPanel:AddControl( "Label", { Text = "NumOfEnts: "..AdvDupeClient.LocadedNumOfEnts })
				CPanel:AddControl( "Label", { Text = "NumOfConst: "..AdvDupeClient.LocadedNumOfConst })
				CPanel:AddControl( "Label", { Text = "FileVersion: "..AdvDupeClient.LocadedFileVersion })
				
			elseif (AdvDupeClient.Copied) then
				CPanel:AddControl( "Label", { Text = "Unsaved Data Stored in Clipboard" })
			else
				CPanel:AddControl( "Label", { Text = "No Data in Clipboard" })
			end
			
		elseif (menu == "serverdir") then
			
			CPanel:AddControl( "Button", {
				Text = "--Back--",
				Command = "adv_duplicator_cl_menu main" })
			
			if (!SinglePlayer()) then
				CPanel:AddControl( "Label", { Text = "Server Folder Management" })
			else
				CPanel:AddControl( "Label", { Text = "Local Folder Management" })
			end
			
			//1st folder list
			CPanel:AddControl( "ListBox", ServerDirParams )
			
			CPanel:AddControl( "Button", {
				Text = "Make New Folder",
				Command = "adv_duplicator_makedir_gui server" })
			
			if (!SinglePlayer()) and (dupeshare.UsePWSys) then
				CPanel:AddControl( "Button", {
				Text = "Add/Change Password for Current Folder",
				Command = "adv_duplicator_changepass" })
			end
			
			
			CPanel:AddControl( "Button", {
				Text = "Rename",
				Command = "adv_duplicator_renamefile_gui server" })
				
			CPanel:AddControl( "Button", {
				Text = "Copy",
				Command = "adv_duplicator_fileopts copy" })
			
			CPanel:AddControl( "Button", {
				Text = "Move",
				Command = "adv_duplicator_fileopts move" })
			
			CPanel:AddControl( "Button", {
				Text = "Delete",
				Command = "adv_duplicator_fileopts delete" })
			
			
			
			
			//2nd folder list
			CPanel:AddControl( "ListBox", ServerDir2Params )
			
			
			
		elseif (menu == "paster") then
			
			
			CPanel:AddControl( "Button", {
				Text = "--Back--",
				Command = "adv_duplicator_cl_menu main" })
			
			
			CPanel:AddControl( "Label", { Text = "Paster Settings (make with reload)" })
			
			CPanel:AddControl( "Slider", { 
				Label	= "Spawn Delay",
				Type	= "Float",
				Min		= "0",
				Max		= "100",
				Command	= "adv_duplicator_delay"})

			CPanel:AddControl( "Slider", { 
				Label	= "Automatic Undo Delay",
				Type	= "Float",
				Min		= "0",
				Max		= "100",
				Command	= "adv_duplicator_undo_delay"})
			
			CPanel:AddControl("Slider", {
				Label = "Range",
				Type = "Float",
				Min = "0",
				Max = "1000",
				Command = "adv_duplicator_range"})
			
			CPanel:AddControl("CheckBox", {
				Label = "Show Beam",
				Command = "adv_duplicator_show_beam"})
			
			
			
		elseif (menu == "clientupload") then
			
			
			CPanel:AddControl( "Button", {
				Text = "--Back--",
				Command = "adv_duplicator_cl_menu main" })
			
			
			if (!SinglePlayer()) then
			
				CPanel:AddControl( "Label", { Text = "Upload/Download Menu" })
				
				CPanel:AddControl( "Label", { Text = "Files on Server" })
				
				CPanel:AddControl( "ListBox", ServerDirParams )
				
				if AdvDupeClient.downloading then
					CPanel:AddControl( "Label", { Text = "==Download in Progress==" })
				else
					CPanel:AddControl( "Button", {
						Text = "Download Selected File",
						Command = "adv_duplicator_send_cl" })
				end
				
				if AdvDupeClient.sending then
					CPanel:AddControl( "Label", { Text = "==Upload in Progress==" })
				else
					CPanel:AddControl( "Button", {
						Text = "Upload File to server",
						Command = "adv_duplicator_upload_cl"})
				end
				
				CPanel:AddControl( "Label", { Text = "Local Files" })
				
				CPanel:AddControl( "ListBox", ClientDirParams )
				
				
				CPanel:AddControl( "Button", {
					Text = "Open Local Folder Manager Menu",
					Command = "adv_duplicator_cl_menu clientdir" })
				
			end
			
			
		elseif (menu == "clientdir") then
			
			
			CPanel:AddControl( "Button", {
				Text = "--Back--",
				Command = "adv_duplicator_cl_menu clientupload" })
			
			
			if (!SinglePlayer()) then
				
				CPanel:AddControl( "Label", { Text = "Local Folder Management" })
				
				CPanel:AddControl( "ListBox", ClientDirParams )
				
				CPanel:AddControl( "Button", {
					Text = "Make New Folder",
					Command = "adv_duplicator_makedir_gui client" })
				
				CPanel:AddControl( "Button", {
					Text = "Rename",
					Command = "adv_duplicator_renamefile_gui client" })
				
				CPanel:AddControl( "Button", {
					Text = "Copy",
					Command = "adv_duplicator_cl_fileopts copy" })
				
				CPanel:AddControl( "Button", {
					Text = "Move",
					Command = "adv_duplicator_cl_fileopts move" })
				
				CPanel:AddControl( "Button", {
					Text = "Delete",
					Command = "adv_duplicator_cl_fileopts delete" })
				
				CPanel:AddControl( "ListBox", ClientDir2Params )
				
			end
			
			
		end
	
	end
	
	
	
	function AdvDupeCL_Menu(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() or !args[1] then return end
		
		AdvDupeClient.CurMenu = args[1]
		
		if args[1] == "serverdir" then
			LocalPlayer():ConCommand("adv_duplicator_open_dir2")
		else
			//AdvDuplicator_UpdateControlPanel()
			LocalPlayer():ConCommand("adv_duplicator_updatelist 1")
		end
		
	end
	concommand.Add( "adv_duplicator_cl_menu", AdvDupeCL_Menu )
	
	
	local function AdvDupeCl_OpenDir(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		if ( file.Exists(args[1]) && file.IsDir(args[1]) ) then
			AdvDupeClient.CLcdir = args[1]
		end
		
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	end
	concommand.Add( "adv_duplicator_open_cl", AdvDupeCl_OpenDir )
	
	local function AdvDupeCl_OpenDir2(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		if ( file.Exists(args[1]) && file.IsDir(args[1]) ) then
			AdvDupeClient.CLcdir2 = args[1]
		end
		
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	end
	concommand.Add( "adv_duplicator_open_cl2", AdvDupeCl_OpenDir2 )
	
	
	
	
	local function AdvDupeCL_UpLoad( pl, command, args )
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with an arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_load_filename_cl" )
		else filename = tostring(args[1]) end
		
		AdvDupeClient.UpLoadFile( pl, filename )
		
		AdvDuplicator_UpdateControlPanel()
	end
	concommand.Add( "adv_duplicator_upload_cl", AdvDupeCL_UpLoad )
	
	
	
	
	/*local function AdvDupeCL_ClientGhostDataHead( um )
		Msg("=========\ngot ghost head data  ==========    ")
		if (!dupeshare.CurrentToolIsDuplicator(LocalPlayer():GetActiveWeapon(), true)) then
			Msg("current tool is not the duplicator!\n")
			return
		end
		
		AdvDupeClient.ghost.HeadEntID	= um:ReadShort()
		AdvDupeClient.ghost.offset		= um:ReadVector()
		AdvDupeClient.ghost.HoldAngle	= um:ReadAngle()
		
		//maybe this should be a gobal table instead, incase the tool is not out while ghost data is being recieved
		local tool = LocalPlayer():GetActiveWeapon():GetTable():GetToolObject()	
		tool:ReleaseGhostEntity()
		tool.GhostEntities	= {}
		tool.GhostOffset	= {}
		tool.NumToRecieve	= um:ReadShort()
		tool.NumRecieved	= 0
		Msg("HeadEntID= "..AdvDupeClient.ghost.HeadEntID.."\nNumToRecieve= "..tool.NumToRecieve.."\n==========\n")
	end
	usermessage.Hook("ClientGhostDataHead", AdvDupeCL_ClientGhostDataHead)
	
	
	local function AdvDupeCL_ClientGhostData( um )
		local entID	= um:ReadShort()
		--Msg("getting ghost data  for ent: "..entID.."    ")
		
		local tool = LocalPlayer():GetActiveWeapon():GetTable():GetToolObject()
		tool.NumRecieved = tool.NumRecieved + 1
		if (entID == 0) then return end
		
		local model	= um:ReadString()
		local pos	= um:ReadVector()
		local ang	= um:ReadAngle()
		
		--Msg("model: "..model.."\n")
		
		local GhostEntity = tool:MakeGhostEntity_Duplicator( model, (pos + AdvDupeClient.ghost.offset), ang )
		
		if ( GhostEntity ) then
			//Msg("ghost ent good\n")
			tool.GhostEntities[entID]	= GhostEntity
			tool.GhostOffset[entID]		= pos
			
			if ( entID == AdvDupeClient.ghost.HeadEntID ) then
				--Msg("ghost head ent found \n")
				tool.GhostHead		= GhostEntity
				tool.GhostHeadOff	= pos
			elseif (tool.GhostHead) then //cause we send the head first, we can do this
				GhostEntity:SetParent( tool.GhostHead )
			end
		end
		
		
		if (tool.NumRecieved >= tool.NumToRecieve) then
			Msg("client ghost finishing\n")
			if (!tool.GhostHead) then 
				Msg("client Duplicator Error, no head entity!\n") 
				tool:ReleaseGhostEntity()
				return
			end
			for k, ent in pairs ( tool.GhostEntities ) do
				if ( tool.GhostHead != ent ) then
					ent:SetParent( tool.GhostHead )
				end
			end
		end
	end
	usermessage.Hook("ClientGhostData", AdvDupeCL_ClientGhostData)*/
	
end

/*old functions
/*---------------------------------------------------------
   Make a ghost entity
---------------------------------------------------------*
/*function TOOL:MakeGhostEntity_Duplicator( model, pos, angle )
	
	if ( !model or model == "" ) then
		//Msg("Model is NULL!\n")
		model = "models/props_junk/watermelon01.mdl"
	end
	
	util.PrecacheModel( model )
	
	// We do ghosting serverside in single player
	// It's done clientside in multiplayer
	if (SERVER && !SinglePlayer()) then return end
	if (CLIENT && SinglePlayer()) then return end
	
	local GhostEntity = ents.Create( "prop_physics" )
	
	// If there's too many entities we might not spawn..
	if ( !GhostEntity || GhostEntity == NULL ) then return end
	
	if ( !util.IsValidProp( model ) ) then
		model = "models/props_junk/watermelon01.mdl"
	end
	
	GhostEntity:SetModel( model )
	GhostEntity:SetPos( pos )
	GhostEntity:SetAngles( angle )
	GhostEntity:Spawn()
	
	GhostEntity:SetMoveType( MOVETYPE_NONE )
	GhostEntity:SetSolid( SOLID_NONE );
	GhostEntity:SetNotSolid( true );
	GhostEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
	GhostEntity:SetColor( 255, 255, 255, 150 )
	
	return GhostEntity
	
end
*
/*---------------------------------------------------------
   Starts up the ghost entities
---------------------------------------------------------*
/*function TOOL:StartGhostEntities()
	// We do ghosting serverside in single player
	// It's done clientside in multiplayer
	if (SERVER && !SinglePlayer()) then return end
	if (CLIENT && SinglePlayer()) then return end
	if (CLIENT) then return end
	
	local pl = self:GetOwner()
	local pln = self:GetOwner():UniqueID()
	if (!AdvDupe[pln]) or (!AdvDupe[pln].HeadEntID) then return end //gonna need data also seems to stop client ghost in mp
	
	// Clear any existing ghosts
	self:ReleaseGhostEntity()
	
	// set us up some tables
	self.GhostEntities	= {}
	self.GhostOffset	= {}
	
	//get the point where we are currently looking
	local tr	= utilx.GetPlayerTrace( pl )
	local trace	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	AdvDupeClient.ghost.offset = trace.HitPos
	
	
	//local Ents = pl:GetTable().Duplicator.Ents
	local Ents = AdvDupe[pln].Ents
	
	
	//load and make the ghost
	for entID, EntTable in pairs(Ents) do
		local entClass = EntTable.Class
		local entArgs = duplicator.EntityClasses[entClass].Args
		
		if entClass and entArgs then //check that we know how to dupe this class
			//get the args for this class
			//local entArgs = AdvDupe.GetEntClassArgs(entClass)
			
			local Args = { model="models/props_junk/watermelon01.mdl", pos=Vector(0,0,0), ang=Vector(0,0,0) }
			
			for n,Key in pairs(entArgs) do
				if type(Key) != "table" then
					local Arg = EntTable[Key]
					key = string.lower(Key)
					
					if key == "ang"	or key == "angle" then
						Args.ang = Arg or Vector(0,0,0)
					elseif key == "pos"	or key == "position" then
						Args.pos = Arg + AdvDupeClient.ghost.offset or Vector(0,0,0)
					elseif key == "mdl"	or key == "model" or key == "smodel" then 
						Args.model = Arg
					end
				end
			end
			
			local GhostEntity = self:MakeGhostEntity_Duplicator( Args.model, Args.pos, Args.ang )
			
			if ( GhostEntity ) then
				self.GhostEntities[entID]	= GhostEntity
				self.GhostOffset[entID]		= Args.pos - AdvDupeClient.ghost.offset
				
				if ( entID == AdvDupe[pln].HeadEntID ) then
					self.GhostHead		= GhostEntity
					self.GhostHeadOff	= Args.pos - AdvDupeClient.ghost.offset
				end
			end
			
		elseif (entClass) then
			Msg("Duplicator Paste: Unknown class " .. (entClass or "NIL") .. "\n")
		end
	end
	
	if (!self.GhostHead) then 
		Msg("Duplicator Error, no head entity!\n") 
		self:ReleaseGhostEntity()
		return
	end
	
	for k, ent in pairs ( self.GhostEntities ) do
		if ( self.GhostHead != ent ) then
			ent:SetParent( self.GhostHead )
		end
	end
	
end

function TOOL:UpdateGhostEntities()

	if (!self.GhostEntities) then return end

	local tr = utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	local ent = self.GhostHead
	
	if (!ent) then return end
	if (ent == NULL) then return end

	ent:SetPos( trace.HitPos + self.GhostHeadOff )
	
	/*local angle = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll 	= 0
	
	if (!CLIENT) then
		ent:SetAngles( angle - AdvDupe[self:GetOwner():UniqueID()].HoldAngle )
	else
		ent:SetAngles( angle - AdvDupeClient.ghost.HoldAngle )
	end*
	
end

function TOOL:SendGhostToClient(fileload)
	if (CLIENT) then return end
	if (SERVER && SinglePlayer()) then return end
	
	local pl = self:GetOwner()
	Msg("=====\nsentghosttoclient pl = "..tostring(pl).."\n")
	
	if (!dupeshare.CurrentToolIsDuplicator(pl:GetActiveWeapon(), true)) then
		Msg("Player does not have duplicator out!\n")
		return
	end
	
	local pln = pl:UniqueID()
	
	--Msg("start send ghost data\n")
	if (!AdvDupe[pln]) or (!AdvDupe[pln].Ents) then return false end
	local ents = AdvDupe[pln].Ents
	local HeadEntID = AdvDupe[pln].HeadEntID
	
	if (fileload) then
		//get the point where we are currently looking
		local tr	= utilx.GetPlayerTrace( pl )
		local trace	= util.TraceLine( tr )
		if (!trace.Hit) then return end
		AdvDupeClient.ghost.offset = trace.HitPos
	end
	
	local entscount = table.Count(AdvDupe[pln].Ents)
	if (entscount > 50) then entscount = 50 end
	--Msg("entscount:  "..entscount.."\n")
	self:SendGhostDataHeadToClient( HeadEntID, AdvDupeClient.ghost.offset, AdvDupe[pln].HoldAngle, entscount )
	
	local sendnum = 1
	local Args = {}
	
	--Msg("sending headent "..HeadEntID.."\n")
	Args = self:GetGhostArgsForClient( HeadEntID, ents[HeadEntID] )
	self:SendGhostDataUMsgToClient( HeadEntID, Args )
	
	
	for entID, EntTable in pairs(ents) do
		if (entID != HeadEntID) then
			Args = self:GetGhostArgsForClient( entID, EntTable )
			self:SendGhostDataUMsgToClient( entID, Args )
		end
		
		sendnum = sendnum + 1
		if (sendnum > 50) then return end //only send 50
	end
end

function TOOL:SendGhostDataHeadToClient( HeadEntID, offset, HoldAngle, entscount )
	umsg.Start("ClientGhostDataHead", pl)
		umsg.Short(HeadEntID)
		umsg.Vector(offset)
		umsg.Angle(HoldAngle)
		umsg.Short(entscount)
	umsg.End()
end

function TOOL:GetGhostArgsForClient( entID, EntTable )
	if (CLIENT) then return end
	local entClass = EntTable.Class
	--Msg("start send ent ( "..entID.." ) data, class: "..(entClass or 0).."\n")
	
	local entArgs = duplicator.EntityClasses[entClass].Args
	
	if entClass and entArgs then //check that we know how to dupe this class
		//get the args for this class
		//local entArgs = AdvDupe.GetEntClassArgs(entClass)
		
		local Args = { model="models/props_junk/watermelon01.mdl", pos=Vector(0,0,0), ang=Vector(0,0,0) }
		
		for n,Key in pairs(entArgs) do
			if type(Key) != "table" then
				local Arg = EntTable[Key]
				key = string.lower(Key)
				
				if key == "ang"	or key == "angle" then
					Args.ang = Arg or Vector(0,0,0)
				elseif key == "pos"	or key == "position" then
					Args.pos = Arg or Vector(0,0,0)
				elseif key == "mdl"	or key == "model" or key == "smodel" then 
					Args.model = Model(Arg)
				end
			end
		end
		
		return Args
		
	end
	
	return false
	
end

function TOOL:SendGhostDataUMsgToClient( entID, Args )
	if (CLIENT) then return end
	if (Args) then
		umsg.Start("ClientGhostData", pl)
			umsg.Short(entID)
			umsg.String(Args.model)
			umsg.Vector(Args.pos)
			umsg.Angle(Args.ang)
		umsg.End()
	else
		umsg.Start("ClientGhostData", pl)
			umsg.Short(0)
		umsg.End()
	end
end


//makes the ghost disappear so we can see what we are doing
function TOOL:HideGhost(hide)
	if (CLIENT) then return end
	if (SERVER && !SinglePlayer()) then return end
	
	if (hide) then
		for _, ghostent in pairs( self.GhostEntities ) do
			ghostent:SetColor( 255, 255, 255, 0 )
		end
	else
		for _, ghostent in pairs( self.GhostEntities ) do
			ghostent:SetColor( 255, 255, 255, 150 )
		end
	end
end*/



