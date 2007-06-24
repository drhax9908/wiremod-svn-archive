--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"
ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Spawnable			= false
ENT.AdminSpawnable		= false


--[[
function ENT:SetLine(num, text)
	self.Entity:SetNetworkedString("TLine"..num, text)
end

function ENT:GetLine(num)
	return self.Entity:GetNetworkedString("TLine"..num)
end
]]--
--example manual calls of inputs
--Wire_AdjustInputs(self.Entity, {"A"})
--Wire_AdjustInputs(self.Entity, {"A","B"})

--wire_text_screen_table = {}