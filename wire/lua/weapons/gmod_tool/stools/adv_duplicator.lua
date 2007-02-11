
TOOL.Category		= "Construction"
TOOL.Name			= "Advanced Duplicator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_adv_duplicator_name", "Advanced Duplicator" )
    language.Add( "Tool_adv_duplicator_desc", "Duplicate an entity, or group of entities" )
    language.Add( "Tool_adv_duplicator_0", "Right click to copy a group of entities" )
    language.Add( "Tool_duplicator_1", "Now left click to paste a copy" )
end


TOOL.ClientConVar[ "simple" ] = 0
TOOL.ClientConVar[ "save_filename" ] = ""

// Saving totally sucks. This whole thing needs to be re-written so don't do anything with it yet.
// Oops, I added this on my own before I noticed they had tried to do this already
--local ENABLE_SAVING = true

cleanup.Register( "duplicates" )


// Paste a copy
function TOOL:LeftClick( trace )

	if ( CLIENT ) then	return true	end
	
	Ents, Constraints = duplicator.Paste( self:GetOwner(), trace.HitPos )
	
	if (!Ents) then return false end
	
	for _, ent in pairs( Ents )		do self:GetOwner():AddCleanup( "duplicates", ent ) end
	for _, ent in pairs( Constraints )	do self:GetOwner():AddCleanup( "duplicates", ent ) end
	
	if (Ents) then return true end
	
end

// Put The stuff we're pointing at in the 'clipboard'
function TOOL:RightClick( trace )

	if (!trace.Entity) then return false end
	if (!trace.Entity:IsValid()) then return false end
	if (trace.Entity:IsPlayer()) then return false end

	local StartPos = trace.Entity:GetPos()

	local offset = {
			start = StartPos,
			endpos = StartPos + Vector( 0,0,-1024),
			mask = MASK_NPCWORLDSTATIC
			   }

	duplicator.offset = util.TraceLine( offset ).HitPos

	self:ReleaseGhostEntity()

	if ( CLIENT ) then return true end

	// Call the duplicator module to get all the stuff constrained to the trace.ent
	local Ents, Constraints = duplicator.Copy( self:GetOwner(), trace.Entity, duplicator.offset )
	local simple = self:GetClientNumber( "simple" ) == 1

	// this should tide us over until the whole thing gets re-written
	if simple then

		for EntID,Ent in pairs(Ents) do 
			if Ent != trace.Entity then
				self:GetOwner():GetTable().Duplicator.Ents[ EntID ] = nil
			end
		end

		self:GetOwner():GetTable().Duplicator.Constraints = {}
		Ents, Constraints = { [ trace.Entity:EntIndex() ] = trace.Entity }, {}

	end

	local angle  = self:GetOwner():GetAngles()
		angle.pitch = 0
		angle.roll = 0

	local HoldAngle = angle - trace.Entity:GetAngles()

	duplicator.HeadEntID = trace.Entity:EntIndex()
	duplicator.HoldAngle = HoldAngle

	if !SinglePlayer() then

			// Send the Ents to the client so we can do ghosts
			local str = ""

			for EntID,Ent in pairs(Ents) do
			
				if Ent:IsValid() then
					str = str .. EntID..","
					if string.len(str) > 222 then break end		// Don't send too many ents (Will max out at around 50, which should be enough)
				end
				
			end
		
			// Todo! Use umsg to send messages!
		
			self:GetOwner():SendLua( "duplicator.GhostEnts={" .. str .. "}")
			self:GetOwner():SendLua( "duplicator.HeadEntID=" .. duplicator.HeadEntID )
			self:GetOwner():SendLua( "duplicator.HoldAngle=Angle(" .. HoldAngle.pitch .. ", " .. HoldAngle.yaw .. ", " .. HoldAngle.roll .. ")" )
			self:GetOwner():SendLua( "duplicator.offset=Vector(" .. duplicator.offset.x .. ", " .. duplicator.offset.y .. ", " .. duplicator.offset.z .. ")" )
		
		self.Weapon:CallOnClient( "StartGhostEntities", "" )
		
	else
	
		duplicator.GhostEnts = {}
		
		for EntID, Ent in pairs( Ents ) do
		
			if Ent:IsValid() then
				duplicator.GhostEnts[EntID] = EntID
			end
			
		end
				
		self:StartGhostEntities()
	end
	
	return true
end

function TOOL.BuildCPanel( CPanel )
	
	CPanel:AddControl( "Header", { Text = "#Tool_adv_duplicator_name", Description	= "#Tool_adv_duplicator_desc" }  )
	CPanel:AddControl( "Checkbox", { Label = "#Simple Mode", Command = "adv_duplicator_simple" } )

end

function TOOL:Think()

	if (CLIENT) then
	
		local IsGhosts = (self.GhostEntities && #self.GhostEntities > 0)	
		if ( !IsGhosts && duplicator.GhostEnts && #duplicator.GhostEnts < 1 ) then return end 
		if ( !IsGhosts && duplicator.GhostEnts && #duplicator.GhostEnts > 0 ) then self:StartGhostEntities() end 
	
	end
	
	self:UpdateGhostEntities()
	
end

/*---------------------------------------------------------
   Make a ghost entity
---------------------------------------------------------*/
function TOOL:MakeGhostEntity_Duplicator( model, pos, angle )

	// We do ghosting serverside in single player
	// It's done clientside in multiplayer
	if (SERVER && !SinglePlayer()) then return end
	if (CLIENT && SinglePlayer()) then return end
	
	if ( !model ) then
		Msg("Model is NULL!\n")
		return
	end
	
	
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
	GhostEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
	GhostEntity:SetColor( 255, 255, 255, 150 )
	
	return GhostEntity
	
end

/*---------------------------------------------------------
   Starts up the ghost entities
---------------------------------------------------------*/
function TOOL:StartGhostEntities()

	// We do ghosting serverside in single player
	// It's done clientside in multiplayer
	if (SERVER && !SinglePlayer()) then return end
	if (CLIENT && SinglePlayer()) then return end

	// Clear any existing ghosts
	self:ReleaseGhostEntity()
	
	// set us up some tables
	self.GhostEntities = {}
	self.GhostOffset = {}
	
	// For each EntID we got sent, check it's still valid and make Ghost if it is.
	for id, EntID in pairs(duplicator.GhostEnts) do

		local Ent = Entity( EntID )

		if ( Ent:IsValid() ) then

			local GhostEntity = self:MakeGhostEntity_Duplicator( Ent:GetModel(), Ent:GetPos(), Ent:GetAngles() )
			
			if ( GhostEntity ) then
			
				self.GhostEntities[id]	= GhostEntity
				self.GhostOffset[id]		= Ent:GetPos() - duplicator.offset
				
				if ( EntID == duplicator.HeadEntID ) then
				
					self.GhostHead 	= GhostEntity
					self.GhostHeadOff = Ent:GetPos() - duplicator.offset
				
				end
				
			end
			
		end
	end
	
	if (!self.GhostHead) then 
	
			Msg("Duplicator Error, no head entity!") 
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
	
	local angle = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll 	= 0
	
	ent:SetAngles( angle - duplicator.HoldAngle )
	
end

function TOOL:UpdateList()

	if (!self:GetOwner():IsValid()) then return false end
	if (!self:GetOwner():IsPlayer()) then return false end
	
	local gdir = "adv_duplicator"
	local dir = "adv_duplicator/"..string.gsub(self:GetOwner():SteamID(), ":", "_")

	self:GetOwner():SendLua( "if ( !duplicator ) then duplicator={} end" )
	self:GetOwner():SendLua( "duplicator.LoadList={}" )
	
	if ( file.Exists(dir) && file.IsDir(dir) ) then
	
		for key, val in pairs( file.Find( dir.."/*" ) ) do
		
			if ( !file.IsDir( dir.."/"..val ) ) then
			
				self:GetOwner():SendLua( "table.insert(duplicator.LoadList,\"".. val .."\")" )
				
			end
			
		end
		
	end
	
	if ( file.Exists(gdir) && file.IsDir(gdir) ) then
	
		for key, val in pairs( file.Find( gdir.."/*" ) ) do
		
			if ( !file.IsDir( gdir.."/"..val ) ) then
			
				self:GetOwner():SendLua( "table.insert(duplicator.LoadList,\"".. val .."\")" )
				
			end
			
		end
		
	end
	
	// Force user to update list
	self:GetOwner():SendLua( "AdvDuplicator_UpdateControlPanel()" )
	
end

function TOOL:Deploy()

	if ( CLIENT ) then return end
	
	self:UpdateList()
	
end

if SERVER then
	
	
	//Serverside save of duplicated ents
	local function AdvDupeSS_Save( pl, _, args )

		if !pl:IsValid() 
		or !pl:IsPlayer() 
		or !pl:GetTable().Duplicator 
		then return end

		local dir = "adv_duplicator/"..string.gsub(pl:SteamID(), ":", "_")
		if	!file.Exists(dir)	then file.CreateDir(dir) 
		elseif	!file.IsDir(dir)	then return end
		
		//!!TODO!! check the that filename contains no illegal characters
		local filename = tostring(pl:GetInfo( "adv_duplicator_save_filename" ))..".txt"
		
		
		//save to file
		local temp = {}
		temp["ents"] = pl:GetTable().Duplicator.Ents
		temp["const"] = pl:GetTable().Duplicator.Constraints
		temp["head"] = pl:GetTable().Duplicator.HeadEntID
		temp["holdangle"] = duplicator.HoldAngle
		temp = duplicator.PrepareTableToSave(temp)
		temp = util.TableToKeyValues(temp)
		file.Write(dir.."/"..filename, temp)
		
		pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject():UpdateList()
		
		
	end
	
	

	//Load duplicated ents from file
	local function AdvDupeSS_Load( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		or !args[1]
		then return end

		local gdir = "adv_duplicator"
		local dir = gdir.."/"..string.gsub(pl:SteamID(), ":", "_")
		local filename = tostring(args[1])

		if !file.Exists(dir.."/"..filename) && !file.Exists(gdir.."/"..filename) then print("File not found") return end
		
		// Clear Ghost entity if one exists
		pl:GetWeapon("gmod_tool"):GetTable():GetToolObject():ReleaseGhostEntity()
		// This is ridiculous:
		if ( pl:GetActiveWeapon():GetClass() == "gmod_tool" ) then
			pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():ReleaseGhostEntity()" )
		end
		
		local filepath
		if ( file.Exists(gdir.."/"..filename) ) then filepath = gdir.."/"..filename end
		if ( file.Exists(dir.."/"..filename) ) then filepath = dir.."/"..filename end
		
		
		//load from file
		local temp = file.Read(filepath)
		temp = util.KeyValuesToTable(temp)
		tempents = duplicator.RebuildTableFromLoad(temp)
		if (!pl:GetTable().Duplicator) then pl:GetTable().Duplicator = {} end
		pl:GetTable().Duplicator.Ents = tempents["ents"]
		pl:GetTable().Duplicator.Constraints = tempents["const"]
		pl:GetTable().Duplicator.HeadEntID = tempents["head"]
		duplicator.HoldAngle = tempents["holdangle"]
		
		
		
		
		if ( pl:GetActiveWeapon():GetClass() == "gmod_tool" ) then
			pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():UpdateGhostEntities()" )
		end
	end
	
	
	
	concommand.Add( "adv_duplicator_save", AdvDupeSS_Save )
	concommand.Add( "adv_duplicator_load", AdvDupeSS_Load )
	
	
	
	
	// Clientside save of duplicated ents
	local function AdvDupeCL_Save( pl, command, args )

		if !pl:IsValid() 
		or !pl:IsPlayer() 
		or !pl:GetTable().Duplicator
		then return end

		local dir = "adv_duplicator"
		// Make the directory on the client, if it doesn't exist
		// Jesus fuck this is fucking awful.
		pl:SendLua(  "if !file.Exists('"..dir.."') then file.CreateDir('"..dir.."') elseif !file.IsDir('"..dir.."') then return end")
		
		//!!TODO!! check the that filename contains no illegal characters
		local filename = tostring(pl:GetInfo( "adv_duplicator_save_filename" ))
		local filestr = dir.."/"..filename
		
		
		//build save file
		local str = {}
		str["ents"] = pl:GetTable().Duplicator.Ents
		str["const"] = pl:GetTable().Duplicator.Constraints
		str["head"] = pl:GetTable().Duplicator.HeadEntID
		temp["holdangle"] = duplicator.HoldAngle
		str = duplicator.PrepareTableToSave(str)
		str = util.TableToKeyValues(str)
		
		
		local filewrite_start = "filex.Append('"..filestr.."','"
		local filewrite_end = "')"
		
		local maxchar = 254 - string.len( filewrite_start..filewrite_end )
		
		// Split up the string into groups of X characters
		local t={}
		local splitstr = ""
		for char in string.gmatch(str, "(.)") do
			if (string.len(splitstr) >= maxchar) then
				table.insert( t, splitstr )
				splitstr=""
			end
			splitstr = splitstr..char
		end
		table.insert( t, splitstr )
		
		// Delete the file if it already exists
		pl:SendLua(  "if ( file.Exists('"..filestr.."') ) then file.Delete('"..filestr.."') end" )
		
		// Now iterate over every string and send it to the client
		for k,v in pairs( t ) do
			pl:SendLua(  filewrite_start..v..filewrite_end )
		end
		
		print(dir.."/"..filename)
		
		pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject():UpdateList()
		
	end
	
	concommand.Add( "adv_duplicator_save_cl", AdvDupeCL_Save )
	
	
	
	
	local function AdvDupeSS_UpdateLoadList( pl, command, args )
		
		pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject():UpdateList()
		
	end
	
	concommand.Add( "adv_duplicator_updatelist", AdvDupeSS_UpdateLoadList )
	
	
	
else	// CLIENT

	function AdvDuplicator_UpdateControlPanel()
	
		local CPanel = GetControlPanel( "adv_duplicator" )
		
		if (CPanel != nil) then
		
			CPanel:ClearControls()
			CPanel:AddHeader()
			CPanel:AddDefaultControls()
			
			local params = {}
				params.Label = "#Duplicator_load"
				params.Height = 180
				params.Options = {}
					if ( duplicator.LoadList ) then
						for k,v in pairs( duplicator.LoadList ) do
							params.Options[v] = {}
							params.Options[v].adv_duplicator_load = v
						end
					end
				
				CPanel:AddControl( "ListBox", params )
				
			local params = {}
				params.Text = "Reload list"
				params.Command = "adv_duplicator_updatelist"
				
				CPanel:AddControl( "Button", params )	
			
			local params = {}
				params.Text = "#Duplicator_save"
				params.Command = "adv_duplicator_save"
				
				CPanel:AddControl( "Button", params )
				
			/*local params = {}
				params.Text = "#Duplicator_save_cl"
				params.Command = "adv_duplicator_save_cl"
				
				CPanel:AddControl( "Button", params )*/
				
			CPanel:AddControl("TextBox", {
				Label = "Filename:",
				Command = "adv_duplicator_save_filename"})
				
		end
	
	end
	
	
	
	local function AdvDuplicator_SaveGUI( pl, command, arguments )
		
		local filename = {}
		filename[1] = pl:GetInfo( "adv_duplicator_save_filename" )
		--filename[1] = "test1.txt"
		
		Msg("\nfilename: ")
		Msg(filename[1])
		
		local swep = pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject()
		if ( !swep:IsValid() ) then return end
		local tool = swep:GetTable():GetToolObject()
		tool:UpdateList()
		
		
		SS_Load( pl, command, filename)
		
		
		
		//this doesn't do anything apparently
		/*local frame = vgui.Create( "Frame" )
		frame:SetName( "DuplicatorSave" )	
		
		// Save Button
		
		local save = function( panel, message, param1, param2 )
		
			if (message != "Command") then return end
			
		end
		
		local button = vgui.Create( "Button", frame, "SaveButton" )
		button:SetActionFunction( save )
		button:SetCommand( "rark" )
		
		// Text Box
		
		local type = function( panel, message, param1, param2 )
		
			if (message != "TextChanged") then return end
			
		end
		
		local textbox = vgui.Create( "TextEntry", frame, "FileName" )
		textbox:SetActionFunction( type )
		
		frame:LoadControlsFromFile( "resource/ui/duplicatorsave.res" )	
		frame:SetKeyBoardInputEnabled( true )
		frame:SetMouseInputEnabled( true )
		frame:SetVisible( true )*/
		
	end
	concommand.Add( "adv_duplicator_save_gui", AdvDuplicator_SaveGUI )
	
	
	
	local function AdvDuplicator_SaveCLGUI()
		AdvDuplicator_SaveGUI()
	end
	concommand.Add( "adv_duplicator_save_cl_gui", AdvDuplicator_SaveCLGUI )
	
end