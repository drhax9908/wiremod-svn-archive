
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Value"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(value)
	
	if type(value) != "table" then 
		local v = value
		value = {}
		value[1] = tostring(v)
	end
	
	local adjoutputs = {}
	for k,v in pairs(value) do
		adjoutputs[k] = "Value"..tostring(k)
	end
	
	self.value = value
	//this is where storing the values as strings comes in
	Wire_AdjustOutputs(self.Entity, adjoutputs, value)
	
	local txt = ""
	
	for k,v in pairs(value) do
		//line break after 4 values
		//if (k == 5) or (k == 9) then txt = txt.."\n" end
		txt = txt .. "1: " .. v
		if (k < #value) then txt = txt .. "\n" end
		Wire_TriggerOutput(self.Entity, adjoutputs[k], tonumber(v))
	end
	
	self:SetOverlayText(txt)
	
end
