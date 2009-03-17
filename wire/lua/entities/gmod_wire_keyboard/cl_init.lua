
include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local BlockFrame

function Wire_BlockInput(pl,cmd,args)
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
	end

	if (GetConVarString("wire_keyboard_sync") == "1") then
		BlockFrame = vgui.Create("Panel")
		BlockFrame:SetSize(10,10)
		BlockFrame:SetPos(-100,-100)
		BlockFrame:SetVisible(true)
		BlockFrame:MakePopup()
	end
end
concommand.Add("wire_keyboard_blockinput", Wire_BlockInput)

function Wire_ReleaseInput(pl,cmd,args)
	if (BlockFrame) then
		BlockFrame:SetVisible(false)
		BlockFrame = nil
	end
end
concommand.Add("wire_keyboard_releaseinput", Wire_ReleaseInput)

KeyEvents = {}

function WireKeyboardThink()
	if (WIRE_CLIENT_INSTALLED) then
		for i=1,130 do
			if(input.IsKeyDown(i) && !KeyEvents[i]) then 
				// The key has been pressed
				KeyEvents[i] = true
				LocalPlayer():ConCommand("wire_keyboard_press p "..i)
			elseif(!input.IsKeyDown(i) && KeyEvents[i]) then 
				// The key has been released
				KeyEvents[i] = false
				LocalPlayer():ConCommand("wire_keyboard_press r "..i)
			end
		end
	end
end

hook.Add("CalcView", "WireKeyboardThink", WireKeyboardThink)