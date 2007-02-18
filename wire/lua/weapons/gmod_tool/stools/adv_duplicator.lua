
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
TOOL.ClientConVar[ "load_filename" ] = ""
TOOL.ClientConVar[ "file_desc" ] = ""

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
				duplicator[self:GetOwner():UniqueID()].Ents[ EntID ] = nil
			end
		end
		
		duplicator[self:GetOwner():UniqueID()].Constraints = {}
		Ents, Constraints = { [ trace.Entity:EntIndex() ] = trace.Entity }, {}
		
	end
	
	local angle  = self:GetOwner():GetAngles()
		angle.pitch = 0
		angle.roll = 0
	
	local HoldAngle = angle - trace.Entity:GetAngles()
	
	local pl = self:GetOwner()
	local pln = pl:UniqueID()
	duplicator[pln].HeadEntID = trace.Entity:EntIndex()
	duplicator[pln].HoldAngle = HoldAngle
	duplicator.LoadedFile = false
	
	if !SinglePlayer() then
		self:SendGhostToClient()
	else
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
	
	util.PrecacheModel( model )
	
	// We do ghosting serverside in single player
	// It's done clientside in multiplayer
	if (SERVER && !SinglePlayer()) then return end
	if (CLIENT && SinglePlayer()) then return end
	
	if ( !model or model == "" ) then
		Msg("Model is NULL!\n")
		model = "models/props_junk/watermelon01.mdl"
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
	GhostEntity:SetNotSolid( true );
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
	if (CLIENT) then return end
	
	local pl = self:GetOwner()
	local pln = self:GetOwner():UniqueID()
	if (!duplicator[pln]) or (!duplicator[pln].HeadEntID) then return end //gonna need data also seems to stop client ghost in mp
	
	// Clear any existing ghosts
	self:ReleaseGhostEntity()
	
	// set us up some tables
	self.GhostEntities	= {}
	self.GhostOffset	= {}
	
	//get the point where we are currently looking
	local tr	= utilx.GetPlayerTrace( pl )
	local trace	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	duplicator.offset = trace.HitPos
	
	
	//local Ents = pl:GetTable().Duplicator.Ents
	local Ents = duplicator[pln].Ents
	
	
	//load and make the ghost
	for entID, EntTable in pairs(Ents) do
		local entClass = EntTable.Class
		
		if entClass then
			//get the args for this class
			local entArgs = duplicator.GetEntClassArgs(entClass)
			
			if entArgs then //check that we know how to dupe this class
				
				local Args = { model="", pos=Vector(0,0,0), ang=Vector(0,0,0) }
				
				for n,Key in pairs(entArgs) do
					if type(Key) != "table" then
						local Arg = EntTable[Key]
						key = string.lower(Key)
						
						if key == "ang"	or key == "angle" then
							Args.ang = Arg or Vector(0,0,0)
						elseif key == "pos"	or key == "position" then
							Args.pos = Arg + duplicator.offset or Vector(0,0,0)
						elseif key == "mdl"	or key == "model" or key == "smodel" then 
							Args.model = Arg
						end
					end
				end
				
				local GhostEntity = self:MakeGhostEntity_Duplicator( Args.model, Args.pos, Args.ang )
				
				if ( GhostEntity ) then
					self.GhostEntities[entID]	= GhostEntity
					self.GhostOffset[entID]		= Args.pos - duplicator.offset
					
					if ( entID == duplicator[pln].HeadEntID ) then
						self.GhostHead		= GhostEntity
						self.GhostHeadOff	= Args.pos - duplicator.offset
					end
				end
			
			elseif (EntClass) then
				Msg("Duplicator Paste: Unknown class " .. EntClass .. "\n")
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
	
	if (!CLIENT) then
		ent:SetAngles( angle - duplicator[self:GetOwner():UniqueID()].HoldAngle )
	else
		ent:SetAngles( angle - duplicator.HoldAngle )
	end
	
end

function TOOL:SendGhostToClient(fileload)
	if (CLIENT) then return end
	if (SERVER && SinglePlayer()) then return end
	
	local pl = self:GetOwner()
	Msg("=====\nsentghosttoclient pl = ")
	Msg(tostring(pl))
	local pln = pl:UniqueID()
	
	Msg("\nstart send ghost data\n")
	if (!duplicator[pln].Ents) then return false end
	local ents = duplicator[pln].Ents
	local HeadEntID = duplicator[pln].HeadEntID
	
	if (fileload) then
		//get the point where we are currently looking
		local tr	= utilx.GetPlayerTrace( pl )
		local trace	= util.TraceLine( tr )
		if (!trace.Hit) then return end
		duplicator.offset = trace.HitPos
	end
	
	local entscount = table.Count(duplicator[pln].Ents)
	if (entscount > 50) then entscount = 50 end
	Msg("entscount:  "..entscount.."\n")
	self:SendGhostDataHeadToClient( HeadEntID, duplicator.offset, duplicator[pln].HoldAngle, entscount )
	
	local sendnum = 1
	local Args = {}
	
	Msg("sending headent "..HeadEntID.."\n")
	Args = self:GetGhostArgsForClient( HeadEntID, ents[HeadEntID] )
	self:SendGhostDataUMsgToClient( HeadEntID, Args )
	
	
	for entID, EntTable in pairs(ents) do
		if (entID != HeadEntID) then
			Args = self:GetGhostArgsForClient( entID, EntTable )
			self:SendGhostDataUMsgToClient( entID, Args )
		end
		
		sendnum = sendnum + 1
		if (sendnum == 50) then return end //only send 50
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
	Msg("start send ent ( "..entID.." ) data, class: "..(entClass or 0).."\n")
	
	if entClass then
		//get the args for this class
		local entArgs = duplicator.GetEntClassArgs(entClass)
		
		if entArgs then //check that we know how to dupe this class
			
			local Args = { model="", pos=Vector(0,0,0), ang=Vector(0,0,0) }
			
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


function TOOL:UpdateList()

	if (!self:GetOwner():IsValid()) then return false end
	if (!self:GetOwner():IsPlayer()) then return false end
	
	local dir = "adv_duplicator"
	local ndir = dir.."/"..string.gsub(self:GetOwner():GetName(), ":", "_")

	self:GetOwner():SendLua( "if ( !duplicator ) then duplicator={} end" )
	self:GetOwner():SendLua( "duplicator.LoadList={}" )
	
	if ( file.Exists(dir) && file.IsDir(dir) ) then
	
		for key, val in pairs( file.Find( dir.."/*" ) ) do
		
			if ( !file.IsDir( dir.."/"..val ) ) then
			
				self:GetOwner():SendLua( "table.insert(duplicator.LoadList,\"".. val .."\")" )
				
			end
			
		end
		
	end
	
	if ( file.Exists(ndir) && file.IsDir(ndir) ) then
	
		for key, val in pairs( file.Find( ndir.."/*" ) ) do
		
			if ( !file.IsDir( ndir.."/"..val ) ) then
			
				self:GetOwner():SendLua( "table.insert(duplicator.LoadList,\"".. val .."\")" )
				
			end
			
		end
		
	end
	
	// Force user to update list
	self:GetOwner():SendLua( "AdvDuplicator_UpdateControlPanel()" )
	
end

function TOOL:Deploy()
	
	if ( CLIENT ) then return end
	
	if (duplicator[self:GetOwner():UniqueID()]) then self:StartGhostEntities() end
	
	self:UpdateList()
	
end


if SERVER then
	
	
	//Serverside save of duplicated ents
	local function AdvDupeSS_Save( pl, _, args )

		if !pl:IsValid() 
		or !pl:IsPlayer() 
		//or !pl:GetTable().Duplicator 
		or !duplicator[pl:UniqueID()] 
		then return end

		//save to file
		duplicator.SaveToFile( pl, tostring(pl:GetInfo( "adv_duplicator_save_filename" )), tostring(pl:GetInfo( "adv_duplicator_file_desc" )) )
		
		pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_save", AdvDupeSS_Save )
	
	//Load duplicated ents from file
	local function AdvDupeSS_Load( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_load_filename" )
		else filename = tostring(args[1]) end
		
		duplicator.LoadFromFile( pl, filename )
		
		if ( pl:GetActiveWeapon():GetClass() == "gmod_tool" ) then
			//pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():StartGhostEntities()")
			pl:GetActiveWeapon():GetTable():GetToolObject():StartGhostEntities()
			pl:GetActiveWeapon():GetTable():GetToolObject():SendGhostToClient(true)
			pl:SendLua(  "LocalPlayer():GetActiveWeapon():GetTable():GetToolObject():UpdateGhostEntities()" )
		end
	end
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
		/*local str = {}
		str["ents"] = pl:GetTable().Duplicator.Ents
		str["const"] = pl:GetTable().Duplicator.Constraints
		str["head"] = pl:GetTable().Duplicator.HeadEntID
		temp["holdangle"] = duplicator.HoldAngle
		str = duplicator.PrepareTableToSave(str)
		str = util.TableToKeyValues(str)*/
		
		
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
	
	
	
	local function AdvDupeSS_StartGhostEntities( pl, command, args )
		pl:GetWeapon( "gmod_tool" ):GetTable():GetToolObject():StartGhostEntities()
	end
	concommand.Add( "adv_duplicator_startghost", AdvDupeSS_StartGhostEntities )
	
	
	
	
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
							params.Options[v].adv_duplicator_load_filename = v
						end
					end
			CPanel:AddControl( "ListBox", params )
				
			local params = {}
				params.Text = "Load File"
				params.Command = "adv_duplicator_load"
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
			
			CPanel:AddControl("TextBox", {
				Label = "Description:",
				Height = 180,
				Command = "adv_duplicator_file_desc"})
		end
	
	end
	
	
	
	
	local function AdvDuplicator_ClientGhostDataHead( um )
		Msg("=========\ngot ghost head data  ==========    ")
		duplicator.HeadEntID	= um:ReadShort()
		duplicator.offset		= um:ReadVector()
		duplicator.HoldAngle	= um:ReadAngle()
		
		local tool = LocalPlayer():GetActiveWeapon():GetTable():GetToolObject()	
		tool:ReleaseGhostEntity()
		tool.GhostEntities	= {}
		tool.GhostOffset	= {}
		tool.NumToRecieve	= um:ReadShort()
		tool.NumRecieved	= 0
		Msg("HeadEntID= "..duplicator.HeadEntID.."\nNumToRecieve= "..tool.NumToRecieve.."\n==========\n")
	end
	usermessage.Hook("ClientGhostDataHead", AdvDuplicator_ClientGhostDataHead)
	
	
	local function AdvDuplicator_ClientGhostData( um )
		local entID	= um:ReadShort()
		Msg("getting ghost data  for ent: "..entID.."    ")
		
		local tool = LocalPlayer():GetActiveWeapon():GetTable():GetToolObject()
		tool.NumRecieved = tool.NumRecieved + 1
		if (entID == 0) then return end
		
		local model	= um:ReadString()
		local pos	= um:ReadVector()
		local ang	= um:ReadAngle()
		
		Msg("model: "..model.."\n")
		
		local GhostEntity = tool:MakeGhostEntity_Duplicator( model, (pos + duplicator.offset), ang )
		
		if ( GhostEntity ) then
			//Msg("ghost ent good\n")
			tool.GhostEntities[entID]	= GhostEntity
			tool.GhostOffset[entID]		= pos
			
			if ( entID == duplicator.HeadEntID ) then
				Msg("ghost head ent found \n")
				tool.GhostHead		= GhostEntity
				tool.GhostHeadOff	= pos
			end
		end
		
		
		if (tool.NumToRecieve == tool.NumRecieved) then
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
	usermessage.Hook("ClientGhostData", AdvDuplicator_ClientGhostData)
	
	
end