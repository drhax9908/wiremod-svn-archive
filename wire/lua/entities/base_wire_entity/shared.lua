

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName		= "Wire Entity"
ENT.Author			= "Erkle"
ENT.Contact			= "ErkleMad@gmail.com"
ENT.Purpose			= "Base for all wired SEnts"
ENT.Instructions	= ""

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

ENT.IsWire          = true


function ENT:GetOverlayText()
	local name = self.Entity:GetNetworkedString("WireName")
	local txt = self.BaseClass.BaseClass.GetOverlayText(self) or ""

	if (name) and (name ~= "") then
	    if (txt == "") then
	        return "- " .. name .. " -"
	    end

	    return "- " .. name .. " -\n" .. txt
	end
	
	return txt
end
