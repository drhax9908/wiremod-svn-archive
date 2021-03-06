
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Weight"
ENT.OverlayDelay = 0.1

local MODEL = Model("models/props_interiors/pot01a.mdl")

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Weight"})
	self.Outputs = Wire_CreateOutputs(self.Entity,{"Weight"})
	self:ShowOutput(self.Entity:GetPhysicsObject():GetMass())
end

function ENT:TriggerInput(iname,value)
    if(value>0)then
		local phys = self.Entity:GetPhysicsObject()
		if ( phys:IsValid() ) then 
			phys:SetMass(value)
			phys:Wake()
	        self:ShowOutput(value)
	        Wire_TriggerOutput(self.Entity,"Weight",value)
		end
    end
    return true
end

function ENT:Think()
	self.BaseClass.Think(self)
end

function ENT:Setup()
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Weight: "..tostring(value) )
end


function MakeWireWeight( pl, Pos, Ang, model, frozen )
	if ( !pl:CheckLimit( "wire_weights" ) ) then return false end

	local wire_weight = ents.Create( "gmod_wire_weight" )
	if (!wire_weight:IsValid()) then return false end

	wire_weight:SetAngles( Ang )
	wire_weight:SetPos( Pos )
	wire_weight:SetModel( Model(model or MODEL) )
	wire_weight:Spawn()

	if wire_weight:GetPhysicsObject():IsValid() then
		wire_weight:GetPhysicsObject():EnableMotion(!frozen)
	end

	wire_weight:SetPlayer( pl )
	wire_weight.pl = pl
	
	pl:AddCount( "wire_weights", wire_weight )
	pl:AddCleanup( "gmod_wire_weight", wire_weight )
	
	return wire_weight
end
duplicator.RegisterEntityClass("gmod_wire_weight", MakeWireWeight, "Pos", "Ang", "Model", "frozen")
