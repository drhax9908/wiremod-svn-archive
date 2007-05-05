
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Data Transferer"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, {"Send","A","B","C","D","E","F","G","H"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"A","B","C","D","E","F","G","H"})
	self.Sending = false
	self.Values = {};
	self.Values["A"] = 0
	self.Values["B"] = 0
	self.Values["C"] = 0
	self.Values["D"] = 0
	self.Values["E"] = 0
	self.Values["F"] = 0
	self.Values["G"] = 0
	self.Values["H"] = 0
	
	self.Range = 25000
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:TriggerInput(iname, value)
    if(iname == "Send")then
        if(value > 0)then
            self.Sending = true
        else
            self.Sending = false
        end
	elseif(iname == "A") then
		self.Values.A = value
	elseif(iname == "B") then
		self.Values.B = value
	elseif(iname == "C") then
		self.Values.C = value
	elseif(iname == "D") then
		self.Values.D = value      
	elseif(iname == "E") then
		self.Values.E = value 
	elseif(iname == "F") then
		self.Values.F = value 
	elseif(iname == "G") then
		self.Values.G = value 
	elseif(iname == "H") then
		self.Values.H = value 
	end
end

function ENT:Think()
	local vStart = self.Entity:GetPos()
	local vForward = self.Entity:GetUp()
	
    local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self.Range)
	   trace.filter = { self.Entity }
	local trace = util.TraceLine( trace ) 
	
	local ent = trace.Entity

    if not (ent && ent:IsValid() &&
    (trace.Entity:GetClass() == "gmod_wire_data_transferer" ||
     trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ||
      trace.Entity:GetClass() == "gmod_wire_data_store" ))then 
        if(Color(self.Entity:GetColor()) != Color(255,255,255,255))then
            self.Entity:SetColor(255, 255, 255, 255)
        end
    return false 
    end
    
    if(Color(self.Entity:GetColor()) != Color(0,255,0,255))then
        self.Entity:SetColor(0, 255, 0, 255)
    end
    
    if(trace.Entity:GetClass() == "gmod_wire_data_transferer")then
    Wire_TriggerOutput(ent,"A",self.Values.A)
    Wire_TriggerOutput(ent,"B",self.Values.B)
    Wire_TriggerOutput(ent,"C",self.Values.C)
    Wire_TriggerOutput(ent,"D",self.Values.D)
    Wire_TriggerOutput(ent,"E",self.Values.E)
    Wire_TriggerOutput(ent,"F",self.Values.F)
    Wire_TriggerOutput(ent,"G",self.Values.G)
    Wire_TriggerOutput(ent,"H",self.Values.H)
    elseif(trace.Entity:GetClass() == "gmod_wire_data_satellitedish")then
        Wire_TriggerOutput(ent.Transmitter,"A",self.Values.A)
        Wire_TriggerOutput(ent.Transmitter,"B",self.Values.B)
        Wire_TriggerOutput(ent.Transmitter,"C",self.Values.C)
        Wire_TriggerOutput(ent.Transmitter,"D",self.Values.D)
        Wire_TriggerOutput(ent.Transmitter,"E",self.Values.E)
        Wire_TriggerOutput(ent.Transmitter,"F",self.Values.F)
        Wire_TriggerOutput(ent.Transmitter,"G",self.Values.G)
        Wire_TriggerOutput(ent.Transmitter,"H",self.Values.H)
    elseif(trace.Entity:GetClass() == "gmod_wire_data_store")then
        Wire_TriggerOutput(self.Entity,"A",ent.Values.A)
        Wire_TriggerOutput(self.Entity,"B",ent.Values.B)
        Wire_TriggerOutput(self.Entity,"C",ent.Values.C)
        Wire_TriggerOutput(self.Entity,"D",ent.Values.D)
        Wire_TriggerOutput(self.Entity,"E",ent.Values.E)
        Wire_TriggerOutput(self.Entity,"F",ent.Values.F)
        Wire_TriggerOutput(self.Entity,"G",ent.Values.G)
        Wire_TriggerOutput(self.Entity,"H",ent.Values.H)
        if(self.Sending)then
            ent.Values.A = self.Entity.Inputs["A"].Value
            ent.Values.B = self.Entity.Inputs["B"].Value
            ent.Values.C = self.Entity.Inputs["C"].Value
            ent.Values.D = self.Entity.Inputs["D"].Value
            ent.Values.E = self.Entity.Inputs["E"].Value
            ent.Values.F = self.Entity.Inputs["F"].Value
            ent.Values.G = self.Entity.Inputs["G"].Value
            ent.Values.H = self.Entity.Inputs["H"].Value
        end
    end
    self.Entity:NextThink(CurTime()+0.125)
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Data Transferer" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

