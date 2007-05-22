
TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Address Bus"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_addressbus_name", "Address bus tool (Wire)" )
    language.Add( "Tool_wire_addressbus_desc", "Spawns an address bus. Address spaces may overlap!" )
    language.Add( "Tool_wire_addressbus_0", "Primary: Create/Update address bus" )
	language.Add( "sboxlimit_wire_addressbuss", "You've hit address buses limit!" )
	language.Add( "undone_wiredigitalscreen", "Undone Address Bus" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_addressbuss', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "addrspace1sz" ] = 0
TOOL.ClientConVar[ "addrspace2sz" ] = 0
TOOL.ClientConVar[ "addrspace3sz" ] = 0
TOOL.ClientConVar[ "addrspace4sz" ] = 0
TOOL.ClientConVar[ "addrspace1st" ] = 0
TOOL.ClientConVar[ "addrspace2st" ] = 0
TOOL.ClientConVar[ "addrspace3st" ] = 0
TOOL.ClientConVar[ "addrspace4st" ] = 0

cleanup.Register( "wire_addressbuss" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_addressbus" && trace.Entity.pl == ply ) then
		trace.Entity.MemStart[1] = self:GetClientInfo( "addrspace1st" ) + 1 - 1 //Dont laugh, without it
		trace.Entity.MemStart[2] = self:GetClientInfo( "addrspace2st" ) + 1 - 1 //it wont work!!!
		trace.Entity.MemStart[3] = self:GetClientInfo( "addrspace3st" ) + 1 - 1
		trace.Entity.MemStart[4] = self:GetClientInfo( "addrspace4st" ) + 1 - 1
		trace.Entity.MemEnd[1] = trace.Entity.MemStart[1] + self:GetClientInfo( "addrspace1sz" ) - 1
		trace.Entity.MemEnd[2] = trace.Entity.MemStart[2] + self:GetClientInfo( "addrspace2sz" ) - 1
		trace.Entity.MemEnd[3] = trace.Entity.MemStart[3] + self:GetClientInfo( "addrspace3sz" ) - 1
		trace.Entity.MemEnd[4] = trace.Entity.MemStart[4] + self:GetClientInfo( "addrspace4sz" ) - 1
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_addressbuss" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_addressbus = MakeWireAddressBus( ply, Ang, self:GetClientInfo( "addrspace1st" ), 
							self:GetClientInfo( "addrspace2st" ), 
							self:GetClientInfo( "addrspace3st" ), 
							self:GetClientInfo( "addrspace4st" ),
							self:GetClientInfo( "addrspace1sz" ), 
							self:GetClientInfo( "addrspace2sz" ), 
							self:GetClientInfo( "addrspace3sz" ), 
							self:GetClientInfo( "addrspace4sz" ), trace.HitPos, Smodel )
	local min = wire_addressbus:OBBMins()
	wire_addressbus:SetPos( trace.HitPos - trace.HitNormal * min.z )

	wire_addressbus.MemStart[1] = self:GetClientInfo( "addrspace1st" ) + 1 - 1 //Dont laugh, without it
	wire_addressbus.MemStart[2] = self:GetClientInfo( "addrspace2st" ) + 1 - 1 //it wont work!!!
	wire_addressbus.MemStart[3] = self:GetClientInfo( "addrspace3st" ) + 1 - 1
	wire_addressbus.MemStart[4] = self:GetClientInfo( "addrspace4st" ) + 1 - 1
	wire_addressbus.MemEnd[1] = wire_addressbus.MemStart[1] + self:GetClientInfo( "addrspace1sz" ) - 1
	wire_addressbus.MemEnd[2] = wire_addressbus.MemStart[2] + self:GetClientInfo( "addrspace2sz" ) - 1
	wire_addressbus.MemEnd[3] = wire_addressbus.MemStart[3] + self:GetClientInfo( "addrspace3sz" ) - 1
	wire_addressbus.MemEnd[4] = wire_addressbus.MemStart[4] + self:GetClientInfo( "addrspace4sz" ) - 1

	local const = WireLib.Weld(wire_addressbus, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireAddressBus")
		undo.AddEntity( wire_addressbus )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_addressbuss", wire_addressbus )

	return true
end

if (SERVER) then

	function MakeWireAddressBus( pl, Ang, Mem1st, Mem2st, Mem3st, Mem4st, Mem1sz, Mem2sz, Mem3sz, Mem4sz, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_addressbuss" ) ) then return false end
		
		local wire_addressbus = ents.Create( "gmod_wire_addressbus" )
		if (!wire_addressbus:IsValid()) then return false end
		wire_addressbus:SetModel(Smodel)

		wire_addressbus:SetAngles( Ang )
		wire_addressbus:SetPos( Pos )
		wire_addressbus:Spawn()
		
		//FIXME: I cant do anything with it right now
//		wire_addressbus.MemStart[1] = Mem1st + 1 - 1
//		wire_addressbus.MemStart[2] = Mem2st + 1 - 1
//		wire_addressbus.MemStart[3] = Mem3st + 1 - 1
//		wire_addressbus.MemStart[4] = Mem4st + 1 - 1
//		wire_addressbus.MemEnd[1] = Mem1st + Mem1sz - 1
//		wire_addressbus.MemEnd[2] = Mem2st + Mem2sz - 1
//		wire_addressbus.MemEnd[3] = Mem3st + Mem3sz - 1
//		wire_addressbus.MemEnd[4] = Mem4st + Mem4sz - 1

		wire_addressbus:SetPlayer(pl)
			
		//KTNX TAD!

		local ttable = {
			pl = pl,
			Smodel = Smodel,
			Mem1st = Mem1st,
			Mem2st = Mem2st,
			Mem3st = Mem3st,
			Mem4st = Mem4st,
			Mem1sz = Mem1sz,
			Mem2sz = Mem2sz,
			Mem3sz = Mem3sz,
			Mem4sz = Mem4sz,
		}
		
		table.Merge(wire_addressbus:GetTable(), ttable )
		
		pl:AddCount( "wire_addressbuss", wire_addressbus )
		
		return wire_addressbus
		
	end

	duplicator.RegisterEntityClass("gmod_wire_addressbus", MakeWireAddressBus, "Ang", "Mem1st", "Mem2st", "Mem3st", "Mem4st", "Mem1sz", "Mem2sz", "Mem3sz", "Mem4sz", "Pos", "Smodel")

end

function TOOL:UpdateGhostWireAddressBus( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_addressbus" || trace.Entity:IsPlayer()) then

		ent:SetNoDraw( true )
		return

	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireAddressBus( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_addressbus_name", Description = "#Tool_wire_addressbus_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_addressbus",
		
		Options = {
			Default = {
				wire_addressbus_addrspace1st = "0",
				wire_addressbus_addrspace1sz = "0",
				wire_addressbus_addrspace2st = "0",
				wire_addressbus_addrspace2sz = "0",
				wire_addressbus_addrspace3st = "0",
				wire_addressbus_addrspace3sz = "0",
				wire_addressbus_addrspace4st = "0",
				wire_addressbus_addrspace4sz = "0",
			}
		},
		
		CVars = {
			[0] = "wire_addressbus_addrspace1st",
			[1] = "wire_addressbus_addrspace1sz",
			[2] = "wire_addressbus_addrspace2st",
			[3] = "wire_addressbus_addrspace2sz",
			[4] = "wire_addressbus_addrspace3st",
			[5] = "wire_addressbus_addrspace3sz",
			[6] = "wire_addressbus_addrspace4st",
			[7] = "wire_addressbus_addrspace4sz",
		}
	})
	
	panel:AddControl("Slider", {
		Label = "Address space 1 offset",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace1st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 1 size",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace1sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 2 offset",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace2st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 2 size",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace2sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 3 offset",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace3st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 3 size",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace3sz"
	})

	panel:AddControl("Slider", {
		Label = "Address space 4 offset",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace4st"
	})

	panel:AddControl("Slider", {
		Label = "Address space 4 size",
		Type = "Integer",
		Min = "0",
		Max = "256",
		Command = "wire_addressbus_addrspace4sz"
	})
end
	
