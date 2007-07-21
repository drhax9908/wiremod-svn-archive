/////////////////////////////////////////
//	Advanced Duplicator by TAD2020	//
//	Built on Garry Duplicator Technology	//
//	but most of that's been writen by now	//
/////////////////////////////////////////

TOOL.Category		= "Construction"
TOOL.Name			= "#AdvancedDuplicator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "AdvancedDuplicator", "Advanced Duplicator" )
    language.Add( "Tool_adv_duplicator_name", "Advanced Duplicator" )
    language.Add( "Tool_adv_duplicator_desc", "Duplicate an entity, or group of entities" )
    language.Add( "Tool_adv_duplicator_0", "Right click to copy, Reload places Paster" )
    language.Add( "Tool_duplicator_1", "Now left click to paste, Reload places Paster" )
end


TOOL.ClientConVar[ "save_filename" ]	= ""
TOOL.ClientConVar[ "load_filename" ]	= ""
TOOL.ClientConVar[ "load_filename2" ]	= ""
TOOL.ClientConVar[ "load_filename_cl" ]	= ""
TOOL.ClientConVar[ "file_desc" ]		= ""
TOOL.ClientConVar[ "delay" ]			= 0
TOOL.ClientConVar[ "undo_delay" ]		= 0
TOOL.ClientConVar[ "range" ]			= "1500"
TOOL.ClientConVar[ "show_beam" ]		= "1"
TOOL.ClientConVar[ "debugsave" ]		= "0"
TOOL.ClientConVar[ "LimitedGhost" ]		= "0"
TOOL.ClientConVar[ "pasterkey" ]		= -1
TOOL.ClientConVar[ "pasterundo_key" ]	= -1
TOOL.ClientConVar[ "height" ]			= 0
TOOL.ClientConVar[ "angle" ]			= 0
TOOL.ClientConVar[ "worldOrigin" ]		= 0
TOOL.ClientConVar[ "pastefrozen" ]		= 0
TOOL.ClientConVar[ "pastewoconst" ]		= 0

cleanup.Register( "duplicates" )

TOOL.Info = {}
TOOL.Pasting = false

//
// Paste a copy
//
function TOOL:LeftClick( trace )
	
	if ( CLIENT ) then	return true	end
	if ( self:GetPasting() ) or (!self.Entities) then return end
	
	local Snaping = self:GetOwner():KeyDown(IN_SPEED)
	
	local angle  = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll = 0
	
	if ( Snaping ) then
		angle.yaw = math.Round( angle.yaw / 45 ) * 45
	end
	angle.yaw = angle.yaw + self:GetClientNumber( "angle" )
	
	local Ents, Constraints = nil,nil
	
	if ( self.Legacy ) then
		
		//paste using legacy data
		Msg("===doing old paste===\n")
		Ents, Constraints = AdvDupe.OldPaste( self:GetOwner(), self.Entities, self.Constraints, self.DupeInfo, self.DORInfo, self.HeadEntityIdx, trace.HitPos )
		
	elseif ( !self.Legacy ) then
		
		AdvDupe.SetPasting( self:GetOwner(), true )
		self:HideGhost(true)
		self:SetPercentText("Pasting")
		
		local PasteFrozen = ( self:GetClientNumber( "pastefrozen" ) == 1 )
		local PastewoConst = ( self:GetClientNumber( "pastewoconst" ) == 1 )
		
		if ( self:GetClientNumber( "worldOrigin" ) == 0 ) then
			local HoldAngle = self.HoldAngle
			//HoldAngle.yaw = self:GetClientNumber( "angle" )
			AdvDupe.StartPaste( self:GetOwner(), self.Entities, self.Constraints, self.HeadEntityIdx, trace.HitPos + Vector(0,0,self:GetClientNumber( "height" )), angle - HoldAngle, self.NumOfEnts, self.NumOfConst, PasteFrozen, PastewoConst  )
		else
			AdvDupe.StartPaste( self:GetOwner(), self.Entities, self.Constraints, self.HeadEntityIdx, self.StartPos + Vector(0,0,self:GetClientNumber( "height" )), Angle(0,0,0), self.NumOfEnts, self.NumOfConst, PasteFrozen, PastewoConst )
		end
		
	else
		return false
	end
	
	return true
	
end

//
// Put the stuff in the 'clipboard'
//
function TOOL:RightClick( trace )
	
	if ( self:GetPasting() ) then return end
	--self:SetPercentText("Copying")
	
	local AddToSelection = self:GetOwner():KeyDown(IN_SPEED) and (!self.Legacy) and (!self.FileLoaded) and (self.Copied)
	
	if ( !AddToSelection ) and ( !trace.Entity || !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then
		self:ClearClipBoard()
		return true
	end
	
	if ( CLIENT ) then return true end
	
	self:SetPercentText("Copying...")
	
	local StartPos
	if (AddToSelection) then
		StartPos = self.OrgStartPos
		self.Entities = self.Entities or {}
		self.Constraints = self.Constraints or {}
	else
		StartPos = trace.HitPos
		self:ReleaseGhostEntity()
		self.GhostEntitiesCount = 0
		
		self.Entities = {}
		self.Constraints = {}
		
		// Get the distance from the floor
		local tr = {}
		tr.start = StartPos
		tr.endpos = StartPos + Vector(0,0,-1024)
		tr.mask = MASK_NPCSOLID_BRUSHONLY
		local tr_floor = util.TraceLine( tr )
		if (tr_floor.Hit) then 
			StartPos = StartPos  + Vector(0,0,-1) * tr_floor.Fraction * 1024
		end
	end
	
	AdvDupe.Copy( trace.Entity, self.Entities, self.Constraints, StartPos )
	
	if (AddToSelection) then
		if ( !self.GhostEntities[ self.HeadEntityIdx ] || !self.GhostEntities[ self.HeadEntityIdx ]:IsValid() ) then
			self:StartGhostEntities( self.Entities, self.HeadEntityIdx, self.HoldPos, self.HoldAngle )
		else
			self:SetPercentText("Ghosting")
			//self:AddToGhost()
			NextAddGhostTime = CurTime() + .2
			self.UnfinishedGhost = true
		end
	else
		local angle  = self:GetOwner():GetAngles()
		angle.pitch = 0
		angle.roll = 0
		
		self.HeadEntityIdx	= trace.Entity:EntIndex()
		self.HoldAngle 		= angle
		self.HoldPos 		= trace.Entity:WorldToLocal( StartPos )
		self.StartPos		= StartPos
		self.Legacy			= false
		self.OrgStartPos	= StartPos
		
		self:StartGhostEntities( self.Entities, self.HeadEntityIdx, self.HoldPos, self.HoldAngle )
		
	end
	
	local NumOfEnts		= table.Count(self.Entities)	or 0
	local NumOfConst	= table.Count(self.Constraints)	or 0
	self.NumOfEnts		= NumOfEnts
	self.NumOfConst		= NumOfConst
	
	self.FileLoaded		= false
	self.Copied			= true
	
	self.Info				= {}
	self.Info.Creator		= self:GetOwner():GetName()	or "unknown"
	self.Info.FilePath		= "unsaved data"
	self.Info.Desc			= ""
	self.Info.FileVersion	= ""
	self.Info.FileDate		= ""
	self.Info.FileTime		= ""
	
	self:UpdateLoadedFileInfo()
	
	self:SetPercent(100)
	
	return true
	
end


//
//make a paster ent
function TOOL:Reload( trace )
	if ( self:GetPasting() ) then return end
	if (CLIENT) then return true end
	if self.Legacy then
		self:GetOwner():SendLua( "GAMEMODE:AddNotify('Paster does not support old saves!', NOTIFY_GENERIC, 7);" )
		return false
	end
	if (!self.Entities) then
		self:GetOwner():SendLua( "GAMEMODE:AddNotify('No copied data for Paster!', NOTIFY_GENERIC, 7);" )
		return false
	end
	
	local paster = ents.Create( "gmod_adv_dupe_paster" )
	if (!paster:IsValid()) then return false end
	
	paster:SetPos( trace.HitPos )
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	paster:SetAngles( Ang )
	
	paster:Spawn()
	paster:SetPlayer( self:GetOwner() )
	
	local min = paster:OBBMins()
	paster:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local phys = paster:GetPhysicsObject()
	if (phys:IsValid()) then phys:EnableMotion(false) end
	
	undo.Create("Paster")
		undo.AddEntity( paster )
		undo.SetPlayer( self:GetOwner() )
	undo.Finish()
	
	local delay 		= self:GetClientNumber( "delay" )
	local undo_delay	= self:GetClientNumber( "undo_delay" )
	local range			= self:GetClientNumber( "range" )
	local show_beam		= self:GetClientNumber( "show_beam" ) == 1
	local key			= self:GetClientNumber( "pasterkey" )
	local undo_key 		= self:GetClientNumber( "pasterundo_key" )
	local PasteFrozen = ( self:GetClientNumber( "pastefrozen" ) == 1 )
	local PastewoConst = ( self:GetClientNumber( "pastewoconst" ) == 1 )
	
	paster:Setup(
		table.Copy(self.Entities),
		table.Copy(self.Constraints),
		self.HoldAngle, delay, undo_delay, range, show_beam, self.HeadEntityIdx,
		self.NumOfEnts, self.NumOfConst, PasteFrozen, PastewoConst
	)
	
	if key > -1 then numpad.OnDown( self:GetOwner(), key, "PasterCreate", paster, true ) end
	if undo_key > -1 then numpad.OnDown( self:GetOwner(), undo_key, "PasterUndo", paster, true ) end
	
	return true
end

//just because
function TOOL.BuildCPanel( CPanel )
	
	CPanel:AddControl( "Header", { Text = "#Tool_adv_duplicator_name", Description	= "#Tool_adv_duplicator_desc" }  )

end

local NextAddGhostTime = 0
function TOOL:Think()
	//not much to think about.
	
	if ( !self:GetPasting() ) and ( self.UnfinishedGhost ) and ( CurTime() >= NextAddGhostTime ) then
		self:AddToGhost()
		NextAddGhostTime = CurTime() + AdvDupe.GhostAddDelay(self:GetOwner())
	end
	
	self:UpdateGhostEntities()
	
end

//
//	Make the ghost entities
//
function TOOL:MakeGhostFromTable( EntTable, pParent, HoldAngle, HoldPos )
	if ( !EntTable ) then return end
	
	local GhostEntity = nil
	
	if ( EntTable.Model:sub( 1, 1 ) == "*" ) then
		GhostEntity = ents.Create( "func_physbox" )
	else
		GhostEntity = ents.Create( "prop_physics" )
	end
	
	// If there are too many entities we might not spawn..
	if ( !GhostEntity || GhostEntity == NULL ) then return end
	
	// If we're a ragdoll set our model  as a watermelon
	/*if ( EntTable.Class == "prop_ragdoll" ) then
		GhostEntity:SetModel( "models/props_junk/watermelon01.mdl" )
	else
		end*/
		
	GhostEntity:SetModel( EntTable.Model )
	
	GhostEntity:SetPos( EntTable.LocalPos + HoldPos )
	GhostEntity:SetAngles( EntTable.LocalAngle )
	GhostEntity:Spawn()
	
	GhostEntity:DrawShadow( false )
	GhostEntity:SetMoveType( MOVETYPE_NONE )
	GhostEntity:SetSolid( SOLID_VPHYSICS );
	GhostEntity:SetNotSolid( true )
	GhostEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
	GhostEntity:SetColor( 255, 255, 255, 150 )
	
	GhostEntity.Pos 	= EntTable.LocalPos
	GhostEntity.Angle 	= EntTable.LocalAngle - HoldAngle
	
	if ( pParent ) then
		GhostEntity:SetParent( pParent )
	end
	
	// If we're a ragdoll send our bone positions
	if ( EntTable.Class == "prop_ragdoll" ) then
		for k, v in pairs( EntTable.PhysicsObjects ) do
			local lPos = v.LocalPos
			// The physics object positions are stored relative to the head entity
			if ( pParent ) then
				lPos = pParent:LocalToWorld( v.LocalPos )
				lPos = GhostEntity:WorldToLocal( v.LocalPos )
			else
				lPos = lPos + HoldPos
			end
			GhostEntity:SetNetworkedBonePosition( k, lPos, v.LocalAngle )
		end	
	end
	
	return GhostEntity
	
end


//
//	Starts up the ghost entities
//
function TOOL:StartGhostEntities( EntityTable, Head, HoldPos, HoldAngle )
	
	self:ReleaseGhostEntity()
	self.GhostEntities = {}
	self.GhostEntitiesCount = 0
	if self.Legacy then return end //no ghosting support for lagcey loads, table are too fucking different
	
	// Make the head entity first
	self.GhostEntities[ Head ] = self:MakeGhostFromTable( EntityTable[ Head ], self.GhostEntities[ Head ], HoldAngle, HoldPos )
	
	// Set NW vars for clientside
	self.Weapon:SetNetworkedEntity( "GhostEntity", self.GhostEntities[ Head ] )
	self.Weapon:SetNetworkedVector( "HeadPos", self.GhostEntities[ Head ].Pos )
	self.Weapon:SetNetworkedAngle( 	"HeadAngle", self.GhostEntities[ Head ].Angle )	
	self.Weapon:SetNetworkedVector( "HoldPos", HoldPos )
	self.Weapon:SetNetworkedAngle( "HoldAngle", EntityTable[ Head ].LocalAngle )
	
	if ( !self.GhostEntities[ Head ] || !self.GhostEntities[ Head ]:IsValid() ) then
		self.GhostEntities = nil
		self.UnfinishedGhost = false
		return
	end
	
	self:SetPercentText("Ghosting")
	
	self.GhostEntitiesCount = 1
	NextAddGhostTime = CurTime() + .2
	self.UnfinishedGhost = true
	
	/*Msg("======\n")
	for k,v in pairs ( self.Weapon:GetTable().Tool.adv_duplicator ) do
		Msg(k.." = "..tostring(v).."\n")
	end
	Msg("======\n")*/
	
end

//
//	Update the ghost entity positions
//
function TOOL:UpdateGhostEntities()
	
	if (SERVER && !self.GhostEntities) then return end
	
	local tr = utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	local Snaping = self:GetOwner():KeyDown(IN_SPEED)
	
	local angle  = self:GetOwner():GetAngles()
	angle.pitch = 0
	angle.roll = 0
	
	if ( Snaping ) then
		angle.yaw = math.Round( angle.yaw / 45 ) * 45
	end
	angle.yaw = angle.yaw + self:GetClientNumber( "angle" )
	
	local GhostEnt = nil
	local HoldPos = nil
	
	if ( SERVER ) then
		GhostEnt = self.GhostEntities[ self.HeadEntityIdx ]
		HoldPos = self.HoldPos
		
		local height = self:GetClientNumber( "height" )
		self.Weapon:SetNetworkedFloat( "height", height )	
		
		if ( !self.StartPos ) or ( self:GetClientNumber( "worldOrigin" ) == 0 ) then
			trace.HitPos = trace.HitPos + Vector(0,0,height)
			self.Weapon:SetNetworkedBool( "worldOrigin", ( self:GetClientNumber( "worldOrigin" ) == 1 ) )
		elseif ( self.StartPos ) then
			self.Weapon:SetNetworkedBool( "worldOrigin", ( self:GetClientNumber( "worldOrigin" ) == 1 ) )
			self.Weapon:SetNetworkedVector( "StartPos", self.StartPos )
			trace.HitPos = self.StartPos + Vector(0,0,height)
		end
		
	else
		GhostEnt = self.Weapon:GetNetworkedEntity( "GhostEntity", nil )
		GhostEnt.Pos = self.Weapon:GetNetworkedVector( "HeadPos", Vector(0,0,0) )
		GhostEnt.Angle = self.Weapon:GetNetworkedAngle( "HeadAngle", Angle(0,0,0) )		
		HoldPos = self.Weapon:GetNetworkedVector( "HoldPos", Vector(0,0,0) )
		
		if ( !self.Weapon:GetNetworkedBool( "worldOrigin" ) ) then
			trace.HitPos = trace.HitPos + Vector(0,0,self.Weapon:GetNetworkedFloat( "height" ))
		else
			trace.HitPos = self.Weapon:GetNetworkedVector( "StartPos" ) + Vector(0,0,self.Weapon:GetNetworkedFloat( "height" ))
		end
		
	end
	
	if (!GhostEnt || !GhostEnt:IsValid()) then 
		self.GhostEntities = nil
	return end
	
	GhostEnt:SetMoveType( MOVETYPE_VPHYSICS )
	GhostEnt:SetNotSolid( true )
	
	local TargetPos = GhostEnt:GetPos() - GhostEnt:LocalToWorld( HoldPos )
	
	local PhysObj = GhostEnt:GetPhysicsObject()
	if ( PhysObj && PhysObj:IsValid() ) then
		
		PhysObj:EnableMotion( false )
		PhysObj:SetPos( TargetPos + trace.HitPos )
		
		if ( !self.Weapon:GetNetworkedBool( "worldOrigin" ) ) then
			PhysObj:SetAngle( GhostEnt.Angle + angle )
		else
			PhysObj:SetAngle( self.Weapon:GetNetworkedAngle( "HoldAngle" ) )
		end
		
		PhysObj:Wake()
		
	else
		
		// Give the head ghost entity a physics object
		// This way the movement will be predicted on the client
		if ( CLIENT ) then
			GhostEnt:PhysicsInit( SOLID_VPHYSICS )
		end
		
	end
	
end

//
//	Add more ghost ents
//
function TOOL:AddToGhost()
	local LimitedGhost = ( self:GetClientNumber( "LimitedGhost" ) == 1 ) or AdvDupe.LimitedGhost(self:GetOwner())
	if ( !LimitedGhost and self.GhostEntitiesCount < AdvDupe.GhostLimitNorm(self:GetOwner()) )
	or ( LimitedGhost and self.GhostEntitiesCount < AdvDupe.GhostLimitLimited(self:GetOwner()) ) then
		
		if ( !self.GhostEntities[self.HeadEntityIdx] || !self.GhostEntities[self.HeadEntityIdx]:IsValid() ) then
			self.GhostEntities = nil
			self.UnfinishedGhost = false
			return
		end
		
		if ( AdvDupe[self:GetOwner()].PercentText != "Ghosting" ) then
			self:SetPercentText("Ghosting")
		end
		
		self.GhostEntities[self.HeadEntityIdx]:SetPos(		self.Entities[self.HeadEntityIdx].LocalPos + self.HoldPos )
		self.GhostEntities[self.HeadEntityIdx]:SetAngles(	self.Entities[self.HeadEntityIdx].LocalAngle )
		self.GhostEntities[self.HeadEntityIdx].Pos 		=	self.Entities[self.HeadEntityIdx].LocalPos
		self.GhostEntities[self.HeadEntityIdx].Angle 	=	self.Entities[self.HeadEntityIdx].LocalAngle - self.HoldAngle
		self.Weapon:SetNetworkedVector( "HeadPos",			self.GhostEntities[self.HeadEntityIdx].Pos )
		self.Weapon:SetNetworkedAngle( 	"HeadAngle",		self.GhostEntities[self.HeadEntityIdx].Angle )	
		self.Weapon:SetNetworkedVector( "HoldPos",			self.HoldPos )
		
		local ghostcount = 0
		for k, entTable in pairs( self.Entities ) do
			if ( !self.GhostEntities[ k ] ) then
				self.GhostEntities[ k ] = self:MakeGhostFromTable( entTable, self.GhostEntities[self.HeadEntityIdx], self.HoldAngle, self.HoldPos )
				
				/*umsg.Start("AdvDupe_AddGhost", self:GetOwner())
					umsg.Short( BeamNetVars.CommonStringToIndex( EntTable.Class ) )
					umsg.Short( BeamNetVars.CommonStringToIndex( EntTable.Model ) )
					umsg.Vector( EntTable.LocalPos )
					umsg.Angle( EntTable.LocalAngle )
				umsg.End()*/
				
				ghostcount = ghostcount + 1
				self.GhostEntitiesCount = self.GhostEntitiesCount + 1
			end
			if ( ghostcount == AdvDupe.GhostsPerTick(self:GetOwner()) ) then
				self.UnfinishedGhost = true
				self:SetPercent( 100 * self.GhostEntitiesCount / math.min(500, self.NumOfEnts) )
				return
			end
		end
		
	end
	
	self.UnfinishedGhost = false
	self:SetPercent(100)
	timer.Simple(.1, AdvDupe.SetPercent, self:GetOwner(), -1) //hide progress bar
end

//
//	Hides/Unhides ghost
//
function TOOL:HideGhost(Hide)
	if ( !self.GhostEntities ) then return end
	for k,v in pairs( self.GhostEntities ) do
		if ( v:IsValid() ) then
			v:SetNoDraw(Hide)
		else
			self.GhostEntities[k] = nil
		end
	end
end



function TOOL:Deploy()
	
	if ( CLIENT ) then return end
	
	if ( self.Entities ) then
		//self:StartGhostEntities( self.Entities, self.HeadEntityIdx, self.HoldPos, self.HoldAngle )
		if ( !self:GetPasting() ) then self:HideGhost(false) end
	end
	
	if !AdvDupe[self:GetOwner()] then AdvDupe[self:GetOwner()] = {} end
	AdvDupe[self:GetOwner()].cdir = AdvDupe.GetPlayersFolder(self:GetOwner())
	AdvDupe[self:GetOwner()].cdir2 = ""
	
	//
	//	TODO: Replace these with umsging
	self:GetOwner():SendLua( "AdvDupeClient.CLcdir=\""..dupeshare.BaseDir.."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.CLcdir2=\""..dupeshare.BaseDir.."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.MyBaseDir=\""..AdvDupe[self:GetOwner()].cdir.."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.CurMenu=\"main\"" )
	
	self:UpdateLoadedFileInfo()
	
	self:UpdateList()
	
	//timer.Simple(.1, AdvDupe.SetPercent, self:GetOwner(), -1) //hide progress bar
	
end

function TOOL:Holster()
	self:HideGhost(true)
end


function TOOL:UpdateLoadedFileInfo()
	self:GetOwner():SendLua( "AdvDupeClient.FileLoaded="..tostring(self.FileLoaded) )
	self:GetOwner():SendLua( "AdvDupeClient.Copied="..tostring(self.Copied) )
	self:GetOwner():SendLua( "AdvDupeClient.LoadedFilename=\""..(self.Info.Filepath or "").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedCreator=\""..(self.Info.Creator or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedDesc=\""..(self.Info.Desc or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfEnts=\""..(self.NumOfEnts or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedNumOfConst=\""..(self.NumOfConst or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedFileVersion=\""..(self.Info.FileVersion or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedFileFileDate=\""..(self.Info.FileDate or "n/a").."\"" )
	self:GetOwner():SendLua( "AdvDupeClient.LocadedFileFileTime=\""..(self.Info.FileTime or "n/a").."\"" )
	if ( self.StartPos ) then
		self:GetOwner():SendLua( "AdvDupeClient.HasStartPos=true" )
	else
		self:GetOwner():SendLua( "AdvDupeClient.HasStartPos=false" )
	end
end


function TOOL:ClearClipBoard()
	
	self:ReleaseGhostEntity()
	self.GhostEntities = {}
	self.GhostEntitiesCount = 0
	self.UnfinishedGhost = false
	self.HeadEntityIdx	= nil
	self.HoldAngle 		= nil
	self.HoldPos 		= nil
	self.StartPos		= nil
	self.Entities		= nil
	self.Constraints	= nil
	self.FileLoaded		= false
	self.Copied			= false
	if (SERVER) then
		self:SetPercent(-1)
		self:GetOwner():SendLua( "AdvDupeClient.FileLoaded=false" )
		self:GetOwner():SendLua( "AdvDupeClient.Copied=false" )
	end
	
	self:GetOwner():ConCommand( "adv_duplicator_height 0")
	self:GetOwner():ConCommand( "adv_duplicator_angle 0")
	self:GetOwner():ConCommand( "adv_duplicator_worldOrigin 0")
	self:GetOwner():ConCommand( "adv_duplicator_pastefrozen 0")
	self:GetOwner():ConCommand( "adv_duplicator_pastewoconst 0")
	
end


function TOOL:SaveFile( filename, desc )
	if ( CLIENT ) then return end
	if (!filename) or (!self.Entities) then return end
	if (self.Legacy) or (!self.Copied) then return end
	
	local Filename, Creator, Desc, NumOfEnts, NumOfConst, FileVersion = AdvDupe.SaveDupeTablesToFile( 
		self:GetOwner(), self.Entities, self.Constraints,
		self.HeadEntityIdx, self.HoldAngle, self.HoldPos,
		filename, desc, self.StartPos, (self:GetClientNumber( "debugsave" ) == 1)
	)
	
	self.NumOfEnts		= NumOfEnts
	self.NumOfConst		= NumOfConst
	
	self.FileLoaded			= true
	self.Copied				= false
	
	self.Info				= {}
	self.Info.Creator		= Creator
	self.Info.FilePath		= filepath
	self.Info.Desc			= Desc
	self.Info.FileVersion	= FileVersion
	self.Info.FileDate		= FileDate
	self.Info.FileTime		= FileTime
	
	self:UpdateLoadedFileInfo()
	
	self:UpdateList()
	
	self:HideGhost(false)
	self:SetPercentText("Saving")
	
end

function TOOL:LoadFile( filepath )
	if ( CLIENT ) then return end
	
	self:ClearClipBoard()
	
	self:SetPercentText("Loading")
	
	AdvDupe.LoadDupeTableFromFile( self:GetOwner(), filepath )
	
end

function TOOL:LoadFileCallBack( filepath, Entities, Constraints, DupeInfo, DORInfo, HeadEntityIdx, HoldAngle, HoldPos, Legacy, Creator, Desc, NumOfEnts, NumOfConst, FileVersion, FileDate, FileTime, StartPos )
	if ( CLIENT ) then return end
	
	if Entities then
		
		self.HeadEntityIdx	= HeadEntityIdx
		self.HoldAngle 		= HoldAngle or Angle(0,0,0)
		self.HoldPos 		= HoldPos or Vector(0,0,0)
		self.StartPos 		= StartPos
		
		self.Entities		= Entities
		self.Constraints	= Constraints or {}
		self.DupeInfo		= DupeInfo
		self.DORInfo		= DORInfo
		
		self.NumOfEnts		= NumOfEnts
		self.NumOfConst		= NumOfConst
		
		self.Legacy			= Legacy
		
		self.FileLoaded		= true
		self.Copied			= false
		
		self.Info				= {}
		self.Info.Creator		= Creator
		self.Info.FilePath		= filepath
		self.Info.Desc			= Desc
		self.Info.FileVersion	= FileVersion
		self.Info.FileDate		= FileDate
		self.Info.FileTime		= FileTime
		
		//self:GetOwner():ConCommand( "adv_duplicator_angle "..self.HoldAngle.yaw)
		
		self:UpdateLoadedFileInfo()
		
		self:UpdateList()
		
		self:SetPercent(100)
		
		self:StartGhostEntities( self.Entities, self.HeadEntityIdx, self.HoldPos, self.HoldAngle )
	end
	
end


function TOOL:UpdateList()
	if (!self:GetOwner():IsValid()) then return false end
	if (!self:GetOwner():IsPlayer()) then return false end
	
	self:GetOwner():SendLua( "if ( !duplicator ) then AdvDupeClient={} end" )
	
	if !AdvDupe[self:GetOwner()] then AdvDupe[self:GetOwner()] = {} end
	if !AdvDupe[self:GetOwner()].cdir then
		AdvDupe[self:GetOwner()].cdir = AdvDupe.GetPlayersFolder(self:GetOwner())
	end
	
	
	local cdir = AdvDupe[self:GetOwner()].cdir
	--Msg("cdir= "..cdir.."\n")
	self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs={}" )
	self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles={}" )
	self:GetOwner():SendLua( "AdvDupeClient.SScdir=\""..cdir.."\"" )
	
	//if ( cdir == dupeshare.BaseDir.."/=Public Folder=" ) then
	if ( cdir == dupeshare.BaseDir.."/=Public Folder=" ) or ( dupeshare.NamedLikeAPublicDir(dupeshare.GetFileFromFilename(cdir)) ) or ( cdir == "Contraption Saver Tool" ) then
		self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/..\"] = \""..AdvDupe.GetPlayersFolder(self:GetOwner()).."\"" )
	elseif ( cdir != AdvDupe.GetPlayersFolder(self:GetOwner()) ) then
		self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/..\"] = \""..dupeshare.UpDir(cdir).."\"" )
	else //is at root
		self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/=Public Folder=\"] = \""..dupeshare.BaseDir.."/=Public Folder=\"" )
		
		if ( file.Exists("Contraption Saver Tool") && file.IsDir("Contraption Saver Tool") ) then
			self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/=Contraption Saver Dir=\"] = \"Contraption Saver Tool\"" )
		end
	end
	
	if ( file.Exists(cdir) && file.IsDir(cdir) ) then
		for key, val in pairs( file.Find( cdir.."/*" ) ) do
			if ( !file.IsDir( cdir.."/"..val ) ) then
				//self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles[\""..val.."\"] = \""..cdir.."/"..val.."\"" )
				self:GetOwner():SendLua( "AdvDupeClient.LoadListFiles[\""..val.."\"] = \""..val.."\"" )
			elseif  ( file.IsDir( cdir.."/"..val ) ) then
				self:GetOwner():SendLua( "AdvDupeClient.LoadListDirs[\"/"..val.."\"] = \""..cdir.."/"..val.. "\"" )
			end
		end
	end
	
	
	if (AdvDupe[self:GetOwner()].cdir2 != "") then
		
		local cdir2 = AdvDupe[self:GetOwner()].cdir2
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


function TOOL:GetPasting()
	if ( SERVER ) and ( AdvDupe[self:GetOwner()] ) then return AdvDupe[self:GetOwner()].Pasting
	elseif ( CLIENT ) then return AdvDupeClient.Pasting end
end



if SERVER then
	
	//Serverside save of duplicated ents
	local function AdvDupeSS_Save( pl, _, args )
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local tool = pl:GetActiveWeapon()
		if !dupeshare.CurrentToolIsDuplicator(tool) then return end
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
		tool:GetTable():GetToolObject():SaveFile( tostring(filename), tostring(desc) )
		
	end
	concommand.Add( "adv_duplicator_save", AdvDupeSS_Save )
	
	
	//Load duplicated file or open folder
	local function AdvDupeSS_Open( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool)) then return end
		
		local filepath = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		//then filepath = tool:GetTable():GetToolObject().load_filename2
		then filepath = pl:GetInfo( "adv_duplicator_load_filename" )
		else filepath = tostring(args[1]) end
		
		filepath = AdvDupe[pl].cdir.."/"..filepath
		
		if ( file.Exists(filepath) && file.IsDir(filepath) ) then
			//dupeshare.UsePWSys
			tool:GetTable():GetToolObject().cdir = filepath
			tool:GetTable():GetToolObject():UpdateList()
			
		elseif ( file.Exists(filepath) && !file.IsDir(filepath) ) then
			
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
		if (!dupeshare.CurrentToolIsDuplicator(tool)) then return end
		
		local dir = string.Implode(" ", args)
		
		if ( file.Exists(dir) && file.IsDir(dir) ) then
			//dupeshare.UsePWSys
			AdvDupe[pl].cdir = dir
		/*elseif ( file.Exists(args[1]) && !file.IsDir(args[1]) ) then //uncomment to reenable open file on select
			tool:GetTable():GetToolObject().load_filename2 = args[1]*/
		end
		
		tool:GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_open_dir", AdvDupeSS_OpenDir )
	
	
	local function AdvDupeSS_OpenDir2(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local tool = pl:GetActiveWeapon()
		if (!dupeshare.CurrentToolIsDuplicator(tool)) then return end
		
		if (!args[1]) then
			AdvDupe[pl].cdir2 = AdvDupe[pl].cdir
		else
			local dir = string.Implode(" ", args)
			if ( file.Exists(dir) && file.IsDir(dir) ) then
				//dupeshare.UsePWSys
				AdvDupe[pl].cdir2 = dir
			end
		end
		
		tool:GetTable():GetToolObject():UpdateList()
		
	end
	concommand.Add( "adv_duplicator_open_dir2", AdvDupeSS_OpenDir2 )
	
	// Clientside save of duplicated ents
	/*local function AdvDupeCL_Save( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		//or !pl:GetTable().Duplicator 
		or !AdvDupe[pl] 
		then return end

		//save to file
		AdvDupe.SaveAndSendSaveToClient( pl, tostring(pl:GetInfo( "adv_duplicator_save_filename" )), tostring(pl:GetInfo( "adv_duplicator_file_desc" )) )
		
		AdvDupe.UpdateList(pl)
	end
	concommand.Add( "adv_duplicator_save_cl", AdvDupeCL_Save )*/
	
	//sends the selected file to the client
	local function AdvDupeSS_ClSend( pl, command, args )
		
		if !pl:IsValid() 
		or !pl:IsPlayer() 
		then return end
		
		local filename = ""
		if !args[1] //if a filename wasn't passed with a arg, then get the selection in the panel
		then filename = pl:GetInfo( "adv_duplicator_load_filename" )
		else filename = tostring(args[1]) end
		
		filename = AdvDupe[pl].cdir.."/"..filename
		
		AdvDupe.SendSaveToClient( pl, filename )
		
		pl:SendLua( "AdvDuplicator_UpdateControlPanel()" )
	end
	concommand.Add( "adv_duplicator_send_cl", AdvDupeSS_ClSend )
	
	
	//allow the client to refresh the list
	local function AdvDupeSS_UpdateLoadList( pl, command, args )
		if args[1] then AdvDupe[pl].cdir2 = "" end
		
		AdvDupe.UpdateList(pl)
	end
	concommand.Add( "adv_duplicator_updatelist", AdvDupeSS_UpdateLoadList )
	
	
	function TOOL:SetPercentText( Txt )
		AdvDupe.SetPercentText( self:GetOwner(), Txt )
	end
	
	function TOOL:SetPercent( Percent )
		/*umsg.Start("AdvDupe_Update_Percent", self:GetOwner())
			umsg.Short(Percent)
		umsg.End()*/
		AdvDupe.SetPercent(self:GetOwner(), Percent)
	end
	
	
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
			ServerDirParams.Height = 260
			ServerDirParams.Options = {}
			if (!SinglePlayer()) then
				ServerDirParams.Label = "Server: "..string.gsub(AdvDupeClient.SScdir, AdvDupeClient.MyBaseDir, "")
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
				if ( AdvDupeClient.CLcdir == "Contraption Saver Tool" ) then
					ClientDirParams.Options["/.."] = {}
					ClientDirParams.Options["/.."].adv_duplicator_open_cl = dupeshare.BaseDir
				else
					ClientDirParams.Options["/.."] = {}
					ClientDirParams.Options["/.."].adv_duplicator_open_cl = dupeshare.UpDir(AdvDupeClient.CLcdir)
				end
			else
				if ( file.Exists("Contraption Saver Tool") && file.IsDir("Contraption Saver Tool") ) then
					ClientDirParams.Options["=Contraption Saver Dir="] = {}
					ClientDirParams.Options["=Contraption Saver Dir="].adv_duplicator_open_cl = "Contraption Saver Tool"
				end
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
				ServerDirParams.Label = "Source: Server:"..string.gsub(AdvDupeClient.SScdir, AdvDupeClient.MyBaseDir, "")
				ServerDir2Params.Label = "Destination: Server:"..string.gsub(AdvDupeClient.SScdir2, AdvDupeClient.MyBaseDir, "")
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
				if ( AdvDupeClient.CLcdir2 == "Contraption Saver Tool" ) then
					ClientDir2Params.Options["/.."] = {}
					ClientDir2Params.Options["/.."].adv_duplicator_open_cl = dupeshare.BaseDir
				else
					ClientDir2Params.Options["/.."] = {}
					ClientDir2Params.Options["/.."].adv_duplicator_open_cl2 = dupeshare.UpDir(AdvDupeClient.CLcdir2)
				end
			else
				if ( file.Exists("Contraption Saver Tool") && file.IsDir("Contraption Saver Tool") ) then
					ClientDir2Params.Options["=Contraption Saver Dir="] = {}
					ClientDir2Params.Options["=Contraption Saver Dir="].adv_duplicator_open_cl2 = "Contraption Saver Tool"
				end
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
				
				CPanel:AddControl( "Button", {
					Text = "Save",
					Command = "adv_duplicator_save_gui" })
				
				CPanel:AddControl( "Button", {
					Text = "Open Folder Manager Menu",
					Command = "adv_duplicator_cl_menu serverdir" })
			else
				
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
			
			CPanel:AddControl( "Button", {
				Text = "Open Paster Menu",
				Command = "adv_duplicator_cl_menu paster" })
			
			if (AdvDupeClient.FileLoaded) then
				
				CPanel:AddControl( "Label", { Text = "File Loaded: \""..string.gsub(AdvDupeClient.LoadedFilename, dupeshare.BaseDir, "").."\"" })
				CPanel:AddControl( "Label", { Text = "Creator: "..AdvDupeClient.LocadedCreator })
				CPanel:AddControl( "Label", { Text = "Desc: "..AdvDupeClient.LocadedDesc })
				CPanel:AddControl( "Label", { Text = "Date: "..AdvDupeClient.LocadedFileFileDate })
				CPanel:AddControl( "Label", { Text = "Time: "..AdvDupeClient.LocadedFileFileTime })
				CPanel:AddControl( "Label", { Text = "NumOfEnts: "..AdvDupeClient.LocadedNumOfEnts })
				CPanel:AddControl( "Label", { Text = "NumOfConst: "..AdvDupeClient.LocadedNumOfConst })
				CPanel:AddControl( "Label", { Text = "FileVersion: "..(AdvDupeClient.LocadedFileVersion or "n/a") })
				
			elseif (AdvDupeClient.Copied) then
				CPanel:AddControl( "Label", { Text = "Unsaved Data Stored in Clipboard" })
			else
				CPanel:AddControl( "Label", { Text = "No Data in Clipboard" })
			end
			
			/*CPanel:AddControl("CheckBox", {
				Label = "Debug Save (larger file):",
				Command = "adv_duplicator_debugsave"
			})*/
			
			if (AdvDupeClient.FileLoaded) or (AdvDupeClient.Copied) then
				
				CPanel:AddControl("Slider", {
					Label = "Height Offset:",
					Type = "Integer",
					Min = "-128",
					Max = "128",
					Command = "adv_duplicator_height"
				})
				
				CPanel:AddControl("Slider", {
					Label = "Angle Offset:",
					Type = "Integer",
					Min = "-180",
					Max = "180",
					Command = "adv_duplicator_angle"
				})
				
				CPanel:AddControl("CheckBox", {
					Label = "Paste Frozen:",
					Command = "adv_duplicator_pastefrozen"
				})
				
				CPanel:AddControl("CheckBox", {
					Label = "Paste w/o Constraints (and frozen):",
					Command = "adv_duplicator_pastewoconst"
				})
				
			end
			
			CPanel:AddControl("CheckBox", {
				Label = "Limited Ghost:",
				Command = "adv_duplicator_LimitedGhost"
			})
			
			if ( AdvDupeClient.HasStartPos ) then
				CPanel:AddControl("CheckBox", {
					Label = "Paste at Original Location:",
					Command = "adv_duplicator_worldOrigin"
				})
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
				Command = "adv_duplicator_confirmdelete_gui server" })
				//Command = "adv_duplicator_fileopts delete" })
			
			
			
			
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
			
			local params = { 
				Label		= "#Spawn Key",
				Label2		= "#Undo Key",
				Command		= "adv_duplicator_pasterkey",
				Command2	= "adv_duplicator_pasterundo_key",
				ButtonSize	= "22",
			}
			CPanel:AddControl( "Numpad",  params )
			
			
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
				elseif ( AdvDupeClient.CanDownload() ) then
					CPanel:AddControl( "Button", {
						Text = "Download Selected File",
						Command = "adv_duplicator_send_cl" })
				else
					CPanel:AddControl( "Label", { Text = "Server Disabled Downloads" })
				end
				
				if AdvDupeClient.sending then
					CPanel:AddControl( "Label", { Text = "==Upload in Progress==" })
				elseif ( AdvDupeClient.CanUpload() ) then
					CPanel:AddControl( "Button", {
						Text = "Upload File to server",
						Command = "adv_duplicator_upload_cl"})
				else
					CPanel:AddControl( "Label", { Text = "Server Disabled Uploads" })
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
					Command = "adv_duplicator_confirmdelete_gui client" })
					//Command = "adv_duplicator_cl_fileopts delete" })
				
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
			LocalPlayer():ConCommand("adv_duplicator_updatelist 1")
		end
		
	end
	concommand.Add( "adv_duplicator_cl_menu", AdvDupeCL_Menu )
	
	
	local function AdvDupeCl_OpenDir(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local dir = string.Implode(" ", args)
		
		if ( file.Exists(dir) && file.IsDir(dir) ) then
			AdvDupeClient.CLcdir = dir
		end
		
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	end
	concommand.Add( "adv_duplicator_open_cl", AdvDupeCl_OpenDir )
	
	local function AdvDupeCl_OpenDir2(pl, command, args)
		if !pl:IsValid() or !pl:IsPlayer() then return end
		
		local dir = string.Implode(" ", args)
		
		if ( file.Exists(dir) && file.IsDir(dir) ) then
			AdvDupeClient.CLcdir2 = dir
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
	
	
	
	//not used yet
	/*local function UMAddGhost( um )
		local tool = LocalPlayer():GetActiveWeapon()
		if ( dupeshare.CurrentToolIsDuplicator(tool) ) then
			
			EntTable = {}
			EntTable.Class = BeamNetVars.CommonStringFromIndex( um:ReadShort() )
			EntTable.Model = BeamNetVars.CommonStringFromIndex( um:ReadShort() )
			EntTable.LocalPos = um:ReadVector()
			EntTable.LocalAngle = um:ReadAngle()
			
			GhostEnt = tool:GetNetworkedEntity( "GhostEntity", nil )
			HoldAngle = tool:GetNetworkedAngle( "HoldAngle", Angle(0,0,0) )		
			HoldPos = tool:GetNetworkedVector( "HoldPos", Vector(0,0,0) )
			
			self.GhostEntities[ k ] = self:MakeGhostFromTable( EntTable, GhostEnt, HoldAngle, HoldPos )
			
		end
	end
	usermessage.Hook("AdvDupe_AddGhost", UMAddGhost)*/
	
	
end
