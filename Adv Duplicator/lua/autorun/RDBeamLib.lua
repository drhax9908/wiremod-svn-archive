AddCSLuaFile( "autorun/RDBeamLib.lua" )

//***********************************************************
//		Linked Entities Client Side Beam Library
//	By: TAD2020
//	Designed for use in Shanjaq's Resource Distribution mod
//***********************************************************
local ThisRDBeamLibVersion = 0.25

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
function RDbeamlib.MakeSimpleBeam(source_ent, start_pos, dest_ent, dest_pos, material, color, width)
	if (!SourceAndDestEntValid( source_ent, dest_ent )) then return end
	
	//things the draw overide doesn't work on
	local Ent1_class = source_ent:GetClass()
	if (Ent1_class == "prop_vehicle_prisoner_pod")
	or (Ent1_class == "prop_vehicle_airboat")
	or (Ent1_class == "prop_vehicle_jeep") then
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
	
	if (CLIENT) then
		// override some functions for the beams, but only do it once!!!!
		if (!source_ent.OldDrawFunction) then
			// make this ent draw it's beams
			source_ent.OldDrawFunction = source_ent.Draw
			source_ent.Draw = function(self)
				RDbeamlib.BeamRender(self.Entity)
				if (WireAddon) then Wire_Render(self.Entity) end
				self:OldDrawFunction(self)
			end
			
			//save the orginal render bounds for compariason
			local bbmin, bbmax = source_ent:GetRenderBounds()
			source_ent.OrgRBWS_bbmin = source_ent:LocalToWorld(bbmin)
			source_ent.OrgRBWS_bbmax = source_ent:LocalToWorld(bbmax)
			
			// make the ent update it's render bounds
			source_ent.OldThinkFunction = source_ent.Think
			source_ent.Think = function(self)
				if (CurTime() >= (self.NextRBUpdate or 0)) then
					RDbeamlib.UpdateRenderBounds(self.Entity)
					if (WireAddon) then Wire_UpdateRenderBounds(self.Entity) end
				    self.NextRBUpdate = CurTime()+3
				end
				self:OldThinkFunction(self)
			end
		end
		RDbeamlib.UpdateRenderBounds(source_ent)
	end
	
	//same here, but for both
	if (!source_ent.OldOnRemoveFunction) then
		// make the end remove its beams when removed
		source_ent.OldOnRemoveFunction = source_ent.OnRemove
		source_ent.OnRemove = function(self)
			RDbeamlib.ClearAllBeamsOnEnt(self.Entity)
			self:OldOnRemoveFunction(self)
		end
	end
	
	if (SERVER) then
		// make the ent check the length of it's links
		if (!source_ent.OldThinkFunction) then
			source_ent.OldThinkFunction = source_ent.Think
			source_ent.Think = function(self)
				if (CurTime() >= (self.NextCheckLengthTime or 0)) then
					RDbeamlib.CheckLength(self.Entity)
					self.NextCheckLengthTime = CurTime() + ( math.random(30, 60) / 100 )
				end
				self:OldThinkFunction(self)
			end
		end
		
		BeamData[ source_ent ][ dest_ent ].colv = Vector(color.r, color.g, color.b)
		BeamData[ source_ent ][ dest_ent ].Length = ( dest_ent:GetPos() - source_ent:GetPos() ):Length() + (RD_EXTRA_LINK_LENGTH or 64)
		
		local info			= {}
		info.type			= "simple"
		info.source_ent		= source_ent
		info.dest_ent		= dest_ent
		
		AddDelaySendBeamData( info, BeamData[ source_ent ][ dest_ent ], ply )
	end
	
end

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
		
		umsg.Start( "RcvRDClearBeam", ply )
			umsg.Entity(	info.source_ent )
			umsg.Entity(	info.dest_ent )
		umsg.End()
		
	elseif (info.type == "clearallentbeams") then
		
		umsg.Start( "RcvRDClearAllBeamsOnEnt", ply )
			umsg.Entity(	info.source_ent )
		umsg.End()
		
	end
	
end


//
//	sends all the BeamData to a player when they connect to the server
//
local function SendAll( ply )
	--Msg("==sending beam data too "..tostring(ply).."\n")
	
	for source_ent, source_ent_table in pairs(BeamData) do
		for dest_ent, beam_data in pairs(source_ent_table) do
			
			local info			= {}
			info.type			= "simple"
			info.source_ent		= source_ent
			info.dest_ent		= dest_ent
			
			AddDelaySendBeamData( info, beam_data, ply )
			
			/*local info			= {}
			info.type			= "simple"
			info.source_ent		= source_ent
			info.dest_ent		= dest_ent
			
			AddDelaySendBeamData( info, BeamData[ source_ent ][ dest_ent ], ply )*/
			
		end
	end
end
local function FullUpdateEntityBeamVars( ply )
	--Msg("==starting timer for sending beam data too "..tostring(ply).."\n")
	timer.Simple(2, SendAll, ply)
end

hook.Add( "PlayerInitialSpawn", "FullUpdateEntityBeamVars_hook", FullUpdateEntityBeamVars )
concommand.Add( "RDBeamLib_FullUpdateEntityBeamVars",  FullUpdateEntityBeamVars)
concommand.Add( "RDBeamLib_SendAllEntityBeamVars",  SendAll)


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
	if (CurTime() >= NextBeamVarsDelayedSendTime) and (#DelaySendBeamData > 0) then
		
		if (NormalOpMode) and (#DelaySendBeamData > 20) then
			
			--Msg("RDBeam leaving NormalOpMode | "..#DelaySendBeamData.."\n")
			NormalOpMode = false
			--when a shit load has be added, delay for a few seconds to allow other things to calm down
			NextBeamVarsDelayedSendTime = CurTime() +  3
			--Msg("RDBeam delay 3\n")
			return
			
		elseif (!NormalOpMode) and (#DelaySendBeamData < 20) then
			
			NormalOpMode = true
			--Msg("RDBeam retruning to NormalOpMode\n")
			
		end
		
		
		if (NormalOpMode) then --during normal mode, we send the whole buffer every 0.05 sec
			
			for _, data in pairs (DelaySendBeamData) do
				if (data) and (data.info) then
					SendBeamData( data.info, data.beam_data, data.ply )
				end
			end
			DelaySendBeamData = {}
			NextBeamVarsDelayedSendTime = CurTime() +  .05
			
		else --otherswise send 10 every 1/4 sec
			
			--Msg("RDBeam sending non-NormalOpMode data | "..#DelaySendBeamData.."\n")
			for i=1,10 do
				local data = table.remove(DelaySendBeamData, 1)
				if (data) and (data.info) then
					SendBeamData( data.info, data.beam_data, data.ply )
				end
			end
			NextBeamVarsDelayedSendTime = CurTime() +  .25
			
		end
		
		
	end
end
hook.Add("Think", "RDBeamLib_Think", BeamVarsDelayedSend)


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
    if (not source_ent:IsValid()) then return end
	if (DisableBeamRender > 0) then return end
	
	if ( BeamData[ source_ent ] ) then
		
		//local bbmin = source_ent:LocalToWorld(source_ent:OBBMins())
		//local bbmax = source_ent:LocalToWorld(source_ent:OBBMaxs())
		//local bbmin, bbmax = source_ent:GetRenderBounds()
		//bbmin = source_ent:LocalToWorld(bbmin)
		//bbmax = source_ent:LocalToWorld(bbmax)
		local bbmin = source_ent.OrgRBWS_bbmin
		local bbmax = source_ent.OrgRBWS_bbmax
		
		for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
		    
			if (beam_data.width or 0 > 0) and (dest_ent:IsValid()) then
				
				local startpos	= source_ent:LocalToWorld(beam_data.start_pos)
				local endpos	= dest_ent:LocalToWorld(beam_data.dest_pos)
				local width	= beam_data.width
				local color = beam_data.color
				local scroll = CurTime() * BEAM_SCROLL_SPEED
				
				render.SetMaterial( Material(beam_data.material) )
				render.DrawBeam(startpos, endpos, width, scroll, scroll+(endpos-startpos):Length()/10, color)
				
				if (startpos.x < bbmin.x) then bbmin.x = startpos.x end
				if (startpos.y < bbmin.y) then bbmin.y = startpos.y end
				if (startpos.z < bbmin.z) then bbmin.z = startpos.z end
				if (startpos.x > bbmax.x) then bbmax.x = startpos.x end
				if (startpos.y > bbmax.y) then bbmax.y = startpos.y end
				if (startpos.z > bbmax.z) then bbmax.z = startpos.z end
				
				if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
				if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
				if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
				if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
				if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
				if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
			else
				beam_data = nil
			end
		end
		
		source_ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
		
	end
end


//
//	updates the render bounds on source_ent
//		TODO: this should be run by the source_ent once in a while
function RDbeamlib.UpdateRenderBounds(source_ent)
	if (!source_ent) or (!source_ent:IsValid()) then return end
	
	//local bbmin = source_ent:LocalToWorld(source_ent:OBBMins())
	//local bbmax = source_ent:LocalToWorld(source_ent:OBBMaxs())
	//local bbmin, bbmax = source_ent:GetRenderBounds()
	//bbmin = source_ent:LocalToWorld(bbmin)
	//bbmax = source_ent:LocalToWorld(bbmax)
	local bbmin = source_ent.OrgRBWS_bbmin or source_ent:LocalToWorld(source_ent:OBBMins())
	local bbmax = source_ent.OrgRBWS_bbmax or source_ent:LocalToWorld(source_ent:OBBMaxs())
	
	if (BeamData[ source_ent ]) then
		
		for dest_ent, beam_data in pairs( BeamData[ source_ent ] ) do
			if (dest_ent:IsValid()) then
				local startpos = source_ent:LocalToWorld(beam_data.start_pos)
				local endpos = dest_ent:LocalToWorld(beam_data.dest_pos)
				
				if (startpos.x < bbmin.x) then bbmin.x = startpos.x end
				if (startpos.y < bbmin.y) then bbmin.y = startpos.y end
				if (startpos.z < bbmin.z) then bbmin.z = startpos.z end
				if (startpos.x > bbmax.x) then bbmax.x = startpos.x end
				if (startpos.y > bbmax.y) then bbmax.y = startpos.y end
				if (startpos.z > bbmax.z) then bbmax.z = startpos.z end
				
				if (endpos.x < bbmin.x) then bbmin.x = endpos.x end
				if (endpos.y < bbmin.y) then bbmin.y = endpos.y end
				if (endpos.z < bbmin.z) then bbmin.z = endpos.z end
				if (endpos.x > bbmax.x) then bbmax.x = endpos.x end
				if (endpos.y > bbmax.y) then bbmax.y = endpos.y end
				if (endpos.z > bbmax.z) then bbmax.z = endpos.z end
			end
		end
		
	end
	
	source_ent:SetRenderBoundsWS(bbmin, bbmax, Vector()*6)
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

