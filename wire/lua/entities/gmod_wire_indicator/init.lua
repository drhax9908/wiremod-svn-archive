
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Indicator"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.A = 0
	self.AR = 0
	self.AG = 0
	self.AB = 0
	self.AA = 0
	self.B = 0
	self.BR = 0
	self.BG = 0
	self.BB = 0
	self.BA = 0

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.B = b or 1
	self.BR = br or 0
	self.BG = bg or 255
	self.BB = bb or 0
	self.BA = ba or 255

	local factor = math.max(0, math.min(self.Inputs.A.Value-self.A/(self.B-self.A), 1))
	self:TriggerInput("A", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local factor = math.Clamp((value-self.A)/(self.B-self.A), 0, 1)
		self:ShowOutput(factor)

		local r = math.Clamp((self.BR-self.AR)*factor+self.AR, 0, 255)
		local g = math.Clamp((self.BG-self.AG)*factor+self.AG, 0, 255)
		local b = math.Clamp((self.BB-self.AB)*factor+self.AB, 0, 255)
		local a = math.Clamp((self.BA-self.AA)*factor+self.AA, 0, 255)
		self.Entity:SetColor(r, g, b, a)
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Color = " .. string.format("%.1f", (value * 100)) .. "%" )
		self.PrevOutput = value
	end
end


function MakeWireIndicator( pl, Model, Ang, Pos, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, nocollide, Vel, aVel, frozen )
	if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end
	
	local wire_indicator = ents.Create( "gmod_wire_indicator" )
	if (!wire_indicator:IsValid()) then return false end
	
	wire_indicator:SetModel( Model )
	wire_indicator:SetMaterial( material )
	wire_indicator:SetAngles( Ang )
	wire_indicator:SetPos( Pos )
	wire_indicator:Spawn()
	
	wire_indicator:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	wire_indicator:SetPlayer(pl)
	
	if ( nocollide == true ) then wire_indicator:SetCollisionGroup(COLLISION_GROUP_WORLD) end
	
	local ttable = {
		a	= a,
		ar	= ar,
		ag	= ag,
		ab	= ab,
		aa	= aa,
		b	= b,
		br	= br,
		bg	= bg,
		bb	= bb,
		ba	= ba,
		material = material,
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_indicator:GetTable(), ttable )
	
	pl:AddCount( "wire_indicators", wire_indicator )
	
	return wire_indicator
end

duplicator.RegisterEntityClass("gmod_wire_indicator", MakeWireIndicator, "Model", "Ang", "Pos", "a", "ar", "ag", "ab", "aa", "b", "br", "bg", "bb", "ba", "material", "nocollide", "Vel", "aVel", "frozen")

function MakeWire7Seg( pl, Model, Ang, Pos, Norm, a, ar, ag, ab, aa, b, br, bg, bb, ba, nocollide, Vel, aVel, frozen  )
	
	if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end
	
	local wire_indicators = {}
	
	//make the center one first so we can get use its OBBMins/OBBMaxs
	wire_indicators[1] = ents.Create( "gmod_wire_indicator" )
	if (!wire_indicators[1]:IsValid()) then return false end
	wire_indicators[1]:SetModel( Model )
	wire_indicators[1]:SetAngles( Ang + Angle(90, 0, 0) )
	wire_indicators[1]:SetPos( Pos )
	wire_indicators[1]:Spawn()
	wire_indicators[1]:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	wire_indicators[1]:SetPlayer(pl)
	wire_indicators[1]:SetNetworkedString("WireName", "G")
	pl:AddCount( "wire_indicators", wire_indicators[1] )
	local min = wire_indicators[1]:OBBMins(wire_indicators[1])
	Pos = Pos - Norm * min.x //correct Pos for thichness of segment
	wire_indicators[1]:SetPos( Pos + Ang:Up() )
	
	local ttable = {
		a	= a,
		ar	= ar,
		ag	= ag,
		ab	= ab,
		aa	= aa,
		b	= b,
		br	= br,
		bg	= bg,
		bb	= bb,
		ba	= ba,
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_indicators[1]:GetTable(), ttable )

	local max = wire_indicators[1]:OBBMaxs(wire_indicators[1])
	
	local angles = {Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 90 ), Angle( 90, 0, 0 ), Angle( 90, 0, 0 )}
	local vectors = {Vector( 1, (-1 * max.y), max.y ), Vector( 1, (-1 * max.y), (-1 * max.y) ), Vector( 1, max.y, max.y ), Vector( 1, max.y, (-1 * max.y) ), Vector( 1, 0, (2 * max.y) ), Vector( 1, 0, (-2 * max.y) ) }
	local segname = {"B", "C", "F", "E", "A", "D"}
	
	for x=2, 7 do
		wire_indicators[x] = ents.Create( "gmod_wire_indicator" )
		if (!wire_indicators[x]:IsValid()) then return false end
		wire_indicators[x]:SetModel( Model )
		wire_indicators[x]:SetPos( Pos + Ang:Up() * vectors[x-1].X + Ang:Forward() * -1 * vectors[x-1].Z + Ang:Right() * vectors[x-1].Y )
		wire_indicators[x]:SetAngles( Ang + angles[x-1] )
		wire_indicators[x]:Spawn()
		wire_indicators[x]:Setup(cmin, ar, ag, ab, aa, cmax, br, bg, bb, ba)
		wire_indicators[x]:SetPlayer(pl)
		wire_indicators[x]:SetNetworkedString("WireName", segname[x-1])
		if ( nocollide == true ) then wire_indicators[x]:GetPhysicsObject():EnableCollisions( false ) end
		table.Merge(wire_indicators[x]:GetTable(), ttable )
		pl:AddCount( "wire_indicators", wire_indicators[x] )
		
		//weld this segment to eveyone before it
		for y=1,x do
			const = constraint.Weld( wire_indicators[x], wire_indicators[y], 0, 0, 0, true, true )
		end
		wire_indicators[x-1]:DeleteOnRemove( wire_indicators[x] ) //when one is removed, all are. a linked chain
	end
	wire_indicators[7]:DeleteOnRemove( wire_indicators[1] ) //loops chain back to first
	
	return wire_indicators
end

