include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

local data = {}
function CLAPI(um)
	data={um:ReadVector(),um:ReadVector(),um:ReadLong()}
end
usermessage.Hook("Advdata",CLAPI) 

function ENT:Draw()
	self.BaseClass.Draw(self)
	if(data[3] == 1) then
		self.Entity:DrawModel()
		local laser = Material("cable/redlaser")
		render.SetMaterial(laser)
		render.DrawBeam(data[1],data[2],2,0,12.5,Color(255,0,0,255))
	end
    Wire_Render(self.Entity)
end