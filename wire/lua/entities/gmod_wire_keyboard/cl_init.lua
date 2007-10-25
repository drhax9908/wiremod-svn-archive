
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local BlockFrame

function Wire_BlockInput(pl,cmd,args)
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end

	BlockFrame = vgui.Create("Panel")
	BlockFrame:SetSize(10,10)
	BlockFrame:SetPos(-100,-100)
	BlockFrame:SetVisible(true)
	BlockFrame:MakePopup()
end
concommand.Add("wire_keyboard_blockinput", Wire_BlockInput)

function Wire_ReleaseInput(pl,cmd,args)
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end
end
concommand.Add("wire_keyboard_releaseinput", Wire_ReleaseInput)

function ENT:Initialize()
	self.KeyEvents = {}
end

function ENT:Think()
	for i=1,130 do
		if(input.IsKeyDown(i) && !self.KeyEvents[i]) then 
			// The key has been pressed
			self.KeyEvents[i] = true
			LocalPlayer():ConCommand("wire_keyboard_press press "..i)
		elseif(!input.IsKeyDown(i) && self.KeyEvents[i]) then 
			// The key has been released
			self.KeyEvents[i] = false
			LocalPlayer():ConCommand("wire_keyboard_press release "..i)
		end
	end

	self.Entity:NextThink(CurTime()+0.05)
end