AddCSLuaFile( "autorun/RDBeamLib.lua" )

//***********************************************************
//		Linked Entities Client Side Beam Library
//	By: TAD2020
//	Designed for use in Shanjaq's Resource Distribution mod
//***********************************************************
local ThisRDBeamLibVersion = 0.5

//
//	Check if there was another version loaded before this one and override if older, skip is same or newer
//
if (RDbeamlib) and (RDbeamlib.Version) and (RDbeamlib.Version > ThisRDBeamLibVersion) then
	Msg("======== A Newer Version of RD BeamLib Detected ========\n"..
		"======== This ver: "..ThisRDBeamLibVersion.." || Detected ver: "..RDbeamlib.Version.." || Skipping\n")
	return
elseif (RDbeamlib) and (RDbeamlib.Version) and (RDbeamlib.Version == ThisRDBeamLibVersion) then
	Msg("======== The Same Version of RD BeamLib Detected || Skipping ========\n")
	return
elseif (RDbeamlib) and (RDbeamlib.Version) then
	Msg("======== Am Older Version of RD BeamLib Detected ========\n"..
		"======== This ver: "..ThisRDBeamLibVersion.." || Detected ver: "..RDbeamlib.Version.." || Overriding\n")
end

RDbeamlib = {}
RDbeamlib.Version = ThisRDBeamLibVersion

//	All beam data is stored here
// Format is BeamData[ source_ent ][ dest_ent ]
local BeamData = {}

//
//	adds beam data to the outbox
//
local DelaySendBeamData = {}
local function AddDelaySendBeamData( info, beam_data, ply )
	table.insert(DelaySendBeamData, { info = info, beam_data = beam_data, ply = ply } )
end
local ExtraDelaySendBeamData = {}
local function AddExtraDelaySendBeamData( info, beam_data, ply )
	table.insert(ExtraDelaySendBeamData, { info = info, beam_data = beam_data, ply = ply } )
end

//
//	checks if the source_ent and dest_ent are valid and will clear data as needed
//
local function SourceEntValid( source_ent )
	if (source_ent == NULL) then
		RDbeamlib.ClearAllBeamsOnEnt( source_ent )
		return false
	end
	return true
end
local function SourceAndDestEntValid( source_ent, dest_ent )
	if (BeamData[ dest_ent ]) and (BeamData[ dest_ent ][ source_ent ]) then
		RDbeamlib.ClearBeam( dest_ent, source_ent )
	end
	if (source_ent) and (source_ent:IsValid()) then
		if (dest_ent) and (dest_ent:IsValid()) then
			return true
		elseif (BeamData[ source_ent ]) and (BeamData[ source_ent ][ dest_ent ]) then
			RDbeamlib.ClearBeam( source_ent, dest_ent )
		end
	elseif (BeamData[ source_ent ]) then
		RDbeamlib.ClearAllBeamsOnEnt( source_ent )
	end
	return false
end

//
//	makes a simple beam from a source ent to dest ent
//
function RDbeamlib.MakeSimpleBeam(source_ent, start_pos, dest_ent, dest_pos, material, color, width, NoCheckLength)
	if (!SourceAndDestEntValid( source_ent, dest_ent )) then return end
	
	if (SERVER) and ( !source_ent.RDbeamlibDrawer ) and ( !dest_ent.RDbeamlibDrawer ) then
		local Drawer = ents.Create( "Beam_Drawer" )
		Drawer:SetPos( source_ent:GetPos() )
		Drawer:SetAngles( source_ent:GetAngles() )
		Drawer:SetParent( source_ent )
		Drawer:Spawn()
		Drawer:Activate()
		source_ent:DeleteOnRemove( Drawer )
		Drawer:SetEnt( source_ent, not NoCheckLength )
		source_ent.RDbeamlibDrawer = Drawer
		source_ent.Entity:SetNetworkedEntity( "RDbeamlibDrawer", Drawer )
	elseif (SERVER) and ( !source_ent.RDbeamlibDrawer ) and ( dest_ent.RDbeamlibDrawer ) then
		local ent = source_ent
		local pos = start_pos
		source_ent = dest_ent
		start_pos = dest_pos
		dest_ent = ent
		dest_pos = pos
	end
	
	BeamData[ source_ent ]							= BeamData[ source_ent ] or {}
	BeamData[ source_ent ][ dest_ent ]				= {}
	BeamData[ source_ent ][ dest_ent ].start_pos	= start_pos
	BeamData[ source_ent ][ dest_ent ].dest_pos		= dest_pos
	BeamData[ source_ent ][ dest_ent ].material		= material
	BeamData[ source_ent ][ dest_ent ].width		= width
	BeamData[ source_ent ][ dest_ent ].color		= color
	
	if (SERVER) then
		BeamData[ source_ent ][ dest_ent ].colv = Vector(color.r, color.g, color.b)
		BeamData[ source_ent ][ dest_ent ].Length = ( dest_ent:GetPos() - source_ent:GetPos() ):Length() + (RD_EXTRA_LINK_LENGTH or 64)
		
		local info			= {}
		info.type			= "simple"
		info.source_ent		= source_ent
		info.dest_ent		= dest_ent
		
		AddDelaySendBeamData( info, BeamData[ source_ent ][ dest_ent ], ply )
	end
	
end

duplicator.RegisterEntityClass("Beam_Drawer", function() return end, "pl" )


//
//	Clears the beam between two ents
//
function RDbeamlib.ClearBeam( source_ent, dest_ent )
	if (BeamData[ source_ent ]) and (BeamData[ source_ent ][ dest_ent ]) then
		BeamData[ source_ent ][ dest_ent ] = nil
	end
	if (BeamData[ dest_ent ]) and (BeamData[ dest_ent ][ source_ent ]) then
		BeamData[ dest_ent ][ source_ent ] = nil
	end
	if (CLIENT) then
		RDbeamlib.UpdateRenderBounds(source_ent)
		RDbeamlib.UpdateRenderBounds(dest_ent)
	end
	if (SERVER) then
		
		for _, data in pairs (ExtraDelaySendBeamData) do
			if (data.type == "simple") and (data.source_ent == source_ent) and (data.dest_ent == dest_ent) then
				data = nil
			end
		end
		
		local info			= {}
		info.type			= "clearbeam"
		info.source_ent		= source_ent
		info.dest_ent		= dest_ent
		
		AddDelaySendBeamData( info, {}, ply )
	end
end

//
//	Clears all beams from/to ent
//
function RDbeamlib.ClearAllBeamsOnEnt( source_ent )
	if (BeamData[ source_ent ]) then
		BeamData[ source_ent ] = nil
	end
	for ent, beamstable in pairs(BeamData) do
		if (BeamData[ent][ source_ent ]) then
			BeamData[ent][ source_ent ] = nil
		end
		if ent == NULL then BeamData[ent] = nil end
	end
	if (CLIENT) then
		RDbeamlib.UpdateRenderBounds(source_ent)
	end
	if (SERVER) then
		
		for _, data in pairs (ExtraDelaySendBeamData) do
			if (data.type == "simple") and ((data.source_ent == source_ent) or (data.dest_ent == source_ent)) then
				data = nil
			end
		end
		
		local info			= {}
		info.type			= "clearallentbeams"
		info.source_ent		= source_ent
		
		AddDelaySendBeamData( info, {}, ply )
	end
end


/////////////////////////////
//	Server Side Functions
/////////////////////////////
if (SERVER) then

//
//	checks the links' lengths and breaks if they're too long
//		TODO: this should make some kinda snapping noise when the link is borken
for i=1,3 do
	util.PrecacheSound( "physics/metal/metal_computer_impact_bullet"..i..".wav" )
end
util.PrecacheSound( "physics/metal/metal_box_impact_soft2.wav" )
function RDbeamlib.CheckLength( source_ent )
	if ( BeamData[ source_ent ] ) then
		for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
			if (dest_ent:IsValid()) then
				local length = ( dest_ent:GetPos() - source_ent:GetPos() ):Length()
				if  ( length > (beam_data.Length or RD_MAX_LINK_LENGTH or 2048) ) then
					if ( (beam_data.LengthOver or 0) > 4 )
					or ( length > (RD_MAX_LINK_LENGTH or 2048) )
					or ( length > (beam_data.Length or RD_MAX_LINK_LENGTH or 2048) + ((RD_EXTRA_LINK_LENGTH or 64) * 1.5) ) then
						source_ent:EmitSound("physics/metal/metal_computer_impact_bullet"..math.random(1,3)..".wav", 500) 
						dest_ent:EmitSound("physics/metal/metal_computer_impact_bullet"..math.random(1,3)..".wav", 500)
						Dev_Unlink(source_ent, dest_ent)
					else
						beam_data.LengthOver = (beam_data.LengthOver or 0) + 1
						local vol = 30 * beam_data.LengthOver
						source_ent:EmitSound("physics/metal/metal_box_impact_soft2.wav", vol) 
						dest_ent:EmitSound("physics/metal/metal_box_impact_soft2.wav", vol)
					end
				elseif ( beam_data.LengthOver ) and ( beam_data.LengthOver > 0 ) then
					beam_data.LengthOver = 0
				end
			else
				RDbeamlib.ClearBeam( source_ent, dest_ent )
			end
		end
	end
end


//
//	for duplicating
//
function RDbeamlib.GetBeamTable( source_ent )
	return BeamData[ source_ent ] or {}
end


//
//	sends a packet of BeamData to player(s)
//
local function SendBeamData( info, beam_data, ply )
	if ( ply ) and ( !ply:IsValid() or !ply:IsPlayer() ) then return end //ply is was set but no longer exists
	
	if (info.type == "simple") then
		if (!SourceAndDestEntValid( info.source_ent, info.dest_ent )) then return end
		
		umsg.Start( "RcvRDBeamSimple", ply )
			umsg.Entity(	info.source_ent )
			umsg.Entity(	info.dest_ent )
			umsg.Vector(	beam_data.start_pos or Vector(0,0,0) )
			umsg.Vector(	beam_data.dest_pos or Vector(0,0,0) )
			umsg.String(	beam_data.material )
			umsg.Vector(	beam_data.colv )
			umsg.Float(		beam_data.width )
		umsg.End()
		
	elseif (info.type == "clearbeam") then
		if (!SourceAndDestEntValid( info.source_ent, info.dest_ent )) then return end
		
		umsg.Start( "RcvRDClearBeam", ply )
			umsg.Entity(	info.source_ent )
			umsg.Entity(	info.dest_ent )
		umsg.End()
		
	elseif (info.type == "clearallentbeams") then
		if (!SourceEntValid( source_ent )) then return end
		
		umsg.Start( "RcvRDClearAllBeamsOnEnt", ply )
			umsg.Entity(	info.source_ent )
		umsg.End()
		
	end
	
end


//
//	function to spam all the BeamData the server has
//
local function spamBeamData()
	/*Msg("\n\n================= BeamData ======================\n\n")
		PrintTable(BeamData)
	Msg("\n=============== end BeamData ==================\n")*/
	Msg("===Size: "..table.Count(BeamData).."\n")
end
concommand.Add( "RDBeamLib_PrintBeamData", spamBeamData )


//
//	includes the local BeamData in the save file
//		Mostly copied from NetVars module
local function Save( save )
	// Remove baggage
	for k, v in pairs(BeamData) do
		if ( k == NULL ) then
			BeamData[k] = nil
		else
			for k2, v2 in pairs(v) do
				if ( k2 == NULL ) then
					BeamData[k][k2] = nil
				end
			end
		end
	end
	saverestore.WriteTable( BeamData, save )
end
local function Restore( restore )
	BeamData = saverestore.ReadTable( restore )
end
saverestore.AddSaveHook( "EntityRDBeamVars", Save )
saverestore.AddRestoreHook( "EntityRDBeamVars", Restore )


//
//	sends queried data to clients
//		TODO: add cut off for when there is a lot of data waiting to be sent
local NextBeamVarsDelayedSendTime = 0
local NormalOpMode = true

local function BeamVarsDelayedSend()
	if (CurTime() >= NextBeamVarsDelayedSendTime) and (#DelaySendBeamData > 0 or #ExtraDelaySendBeamData > 0) then
		
		/*if (NormalOpMode) and (#DelaySendBeamData > 20) then
			
			Msg("RDBeam leaving NormalOpMode | "..#DelaySendBeamData.."\n")
			NormalOpMode = false
			--when a shit load has be added, delay for a few seconds to allow other things to calm down
			NextBeamVarsDelayedSendTime = CurTime() +  .5
			--Msg("RDBeam delay 3\n")
			return
			
		elseif (!NormalOpMode) and (#DelaySendBeamData < 20) then
			
			NormalOpMode = true
			Msg("RDBeam retruning to NormalOpMode\n")
			
		end*/
		
		
		if (#DelaySendBeamData > 50) then
			if (NormalOpMode) then
				Msg("==========RD Beam leaving NormalOpMode | "..#DelaySendBeamData.."\n")
				NormalOpMode = false
			end
			NextBeamVarsDelayedSendTime = CurTime() +  .25
		else
			if (!NormalOpMode) then
				Msg("==========RD Beam returning to NormalOpMode | "..#DelaySendBeamData.."\n")
				NormalOpMode = true
			end
			NextBeamVarsDelayedSendTime = CurTime() +  .05
		end
		
		
		
		//if (NormalOpMode) then --during normal mode, we send the whole buffer every 0.05 sec
			
			for _, data in pairs (DelaySendBeamData) do
				if (data) and (data.info) then
					SendBeamData( data.info, data.beam_data, data.ply )
				end
			end
			DelaySendBeamData = {}
			
			//we send a few entities' ExtraDelaySendBeamData each tick
			for i = 1,5 do
				local data = table.remove(ExtraDelaySendBeamData, 1)
				if (data) and (data.info) then
					SendBeamData( data.info, data.beam_data, data.ply )
					data = nil
				else
					break
				end
			end
			
			NextBeamVarsDelayedSendTime = CurTime() +  .05
			
		/*	NextBeamVarsDelayedSendTime = CurTime() +  .05
			
		else --otherswise send 10 every 1/4 sec
			
			--Msg("RDBeam sending non-NormalOpMode data | "..#DelaySendBeamData.."\n")
			for i=1,10 do
				local data = table.remove(DelaySendBeamData, 1)
				if (data) and (data.info) then
					SendBeamData( data.info, data.beam_data, data.ply )
				end
			end
			NextBeamVarsDelayedSendTime = CurTime() +  .25
			
		end*/
		
		
	end
end
hook.Add("Think", "RDBeamLib_Think", BeamVarsDelayedSend)


//
//	sends all the BeamData to a player when they connect to the server
//
local function SendAll( ply )
	Msg("==sending RDbeam data to "..tostring(ply).."\n")
	
	for source_ent, source_ent_table in pairs(BeamData) do
		for dest_ent, beam_data in pairs(source_ent_table) do
			
			local info			= {}
			info.type			= "simple"
			info.source_ent		= source_ent
			info.dest_ent		= dest_ent
			
			//AddDelaySendBeamData( info, beam_data, ply )
			AddExtraDelaySendBeamData( info, beam_data, ply )
			
		end
	end
end
local function FullUpdateEntityBeamVars( ply )
	Msg("==starting timer for sending RDBeam data to "..tostring(ply).."\n")
	timer.Simple(5, SendAll, ply)
	hook.Add("Think", "RDBeamLib_Think", BeamVarsDelayedSend)
end
hook.Add( "PlayerInitialSpawn", "FullUpdateEntityRDBeamVars", FullUpdateEntityBeamVars )
concommand.Add( "RDBeamLib_FullUpdateEntityBeamVars",  FullUpdateEntityBeamVars)
concommand.Add( "RDBeamLib_SendAllEntityBeamVars",  SendAll)


end


//
//	check for any beam date for NULL ents and removes it
//		TODO: figure out if we'll need this on
/*local function BeamVarsCleanup()
	Msg("Running BeamVarsCleanup\n")
	for source_ent, source_ent_table in pairs(BeamData) do
		if (source_ent == NULL) then
			BeamData[source_ent] = nil
		/*else	
			for dest_ent, beam_data in pairs(source_ent_table) do
				if (dest_ent == NULL) then
					BeamData[source_ent][dest_ent] = nil
				end
			end*
		end
	end
end
timer.Create( "RDBeamVarsCleanUp", 35, 0, BeamVarsCleanup )*/



/////////////////////////////
//	Client Side Functions
/////////////////////////////
if (CLIENT) then

local BEAM_SCROLL_SPEED = 0.5
local DisableBeamRender = 0

//
//	renders all the beams on the source_ent
//
function RDbeamlib.BeamRender( source_ent )
    if ( !source_ent or !source_ent:IsValid() ) then return end
	if (DisableBeamRender > 0) then return end
	
	if ( BeamData[ source_ent ] ) then
		
		local bbmin = Vector(16,16,16)
		local bbmax = Vector(-16,-16,-16)
		
		for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
		    
			if (beam_data.width or 0 > 0) and (dest_ent:IsValid()) then
				
				local startpos	= source_ent:LocalToWorld(beam_data.start_pos)
				local endpos	= dest_ent:LocalToWorld(beam_data.dest_pos)
				local width	= beam_data.width
				local color = beam_data.color
				local scroll = CurTime() * BEAM_SCROLL_SPEED
				
				render.SetMaterial( Material(beam_data.material) )
				render.DrawBeam(startpos, endpos, width, scroll, scroll+(endpos-startpos):Length()/10, color)
				
				/*if (beam_data.start_pos.x < bbmin.x) then bbmin.x = beam_data.start_pos.x end
				if (beam_data.start_pos.y < bbmin.y) then bbmin.y = beam_data.start_pos.y end
				if (beam_data.start_pos.z < bbmin.z) then bbmin.z = beam_data.start_pos.z end
				if (beam_data.start_pos.x > bbmax.x) then bbmax.x = beam_data.start_pos.x end
				if (beam_data.start_pos.y > bbmax.y) then bbmax.y = beam_data.start_pos.y end
				if (beam_data.start_pos.z > bbmax.z) then bbmax.z = beam_data.start_pos.z end
				
				endpos	= source_ent:WorldToLocal( endpos )
				if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
				if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
				if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
				if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
				if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
				if (endpos.z > bbmax.z) then bbmax.z = endpos.z end*/
			else
				beam_data = nil
			end
		end
		
		//source_ent.Entity:GetNetworkedEntity( "RDbeamlibDrawer" ):SetRenderBounds( bbmin, bbmax )
		
	end
end


//
//	updates the render bounds on source_ent
//		TODO: this should be run by the source_ent once in a while
function RDbeamlib.UpdateRenderBounds(source_ent)
	if (!source_ent) or (!source_ent:IsValid()) then return end
	
	local Drawer = source_ent.Entity:GetNetworkedEntity( "RDbeamlibDrawer" )
	if ( !Drawer:IsValid() ) then return end
	
	local bbmin = Vector(16,16,16)
	local bbmax = Vector(-16,-16,-16)
	
	if (BeamData[ source_ent ]) then
		
		for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
			if (dest_ent:IsValid()) then
				if (beam_data.start_pos.x < bbmin.x) then bbmin.x = beam_data.start_pos.x end
				if (beam_data.start_pos.y < bbmin.y) then bbmin.y = beam_data.start_pos.y end
				if (beam_data.start_pos.z < bbmin.z) then bbmin.z = beam_data.start_pos.z end
				if (beam_data.start_pos.x > bbmax.x) then bbmax.x = beam_data.start_pos.x end
				if (beam_data.start_pos.y > bbmax.y) then bbmax.y = beam_data.start_pos.y end
				if (beam_data.start_pos.z > bbmax.z) then bbmax.z = beam_data.start_pos.z end
				
				local endpos = source_ent:WorldToLocal( dest_ent:LocalToWorld( beam_data.dest_pos ) )
				if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
				if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
				if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
				if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
				if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
				if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
			end
		end
		
	end
	
	Drawer:SetRenderBounds( bbmin, bbmax )
	
end


//
//	turns off beam rendering
//
local function BeamRenderDisable(pl, cmd, args)
	if not args[1] then return end
	DisableBeamRender = tonumber(args[1])
end
concommand.Add( "cl_RDBeamLib_DisableRender", BeamRenderDisable )


//
//	umsg Recv'r functions
//
local function RecvBeamSimple( m )
	
	local source_ent	= m:ReadEntity()
	local dest_ent		= m:ReadEntity()
	local start_pos		= m:ReadVector()
	local dest_pos		= m:ReadVector()
	local material		= m:ReadString()
	local colv			= m:ReadVector()
	local color			= Color(colv.x, colv.y, colv.z, 255)
	local width			= m:ReadFloat()
	
	RDbeamlib.MakeSimpleBeam(source_ent, start_pos, dest_ent, dest_pos, material, color, width)
	
end
usermessage.Hook( "RcvRDBeamSimple", RecvBeamSimple )

local function RecvClearBeam( m )
	local source_ent	= m:ReadEntity()
	local dest_ent		= m:ReadEntity()
	RDbeamlib.ClearBeam( source_ent, dest_ent )
end
usermessage.Hook( "RcvRDClearBeam", RecvClearBeam )

local function RecvClearAllBeamsOnEnt( m )
	local source_ent	= m:ReadEntity()
	RDbeamlib.ClearAllBeamsOnEnt( source_ent )
end
usermessage.Hook( "RcvRDClearAllBeamsOnEnt", RecvClearAllBeamsOnEnt )


//
//	test function to clear BeamData, for testing FullUpdate function
//
local function ClearBeamData()
	BeamData = {}
end
concommand.Add( "RDBeamLib_ClearBeamData", ClearBeamData )


//
//	function to spam all the BeamData the client has
//
local function spamCLBeamData()
	/*Msg("\n\n================= CLBeamData ======================\n\n")
		PrintTable(BeamData)
	Msg("\n=============== end CLBeamData ==================\n\n")*/
	Msg("===Size: "..table.Count(BeamData).."\n")
end
concommand.Add( "RDBeamLib_PrintCLBeamData", spamCLBeamData )




end

Msg("======== RD BeamLib v"..RDbeamlib.Version.." Installed ========\n")

