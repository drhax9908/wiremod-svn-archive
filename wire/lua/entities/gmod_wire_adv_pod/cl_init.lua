include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH
podinfo = {}
 function CLAPI( um )
	podinfo.string1 = um:ReadVector()
	podinfo.string2 = um:ReadVector()
	podinfo.string3 = um:ReadLong()
 end

usermessage.Hook("AdvPodInfo", CLAPI) 

function ENT:Draw()
	self.BaseClass.Draw(self)
	if (podinfo.string3 == 1) then
		self.Entity:DrawModel()
		local laser = Material( "cable/redlaser" )
		render.SetMaterial( laser )
		render.DrawBeam( podinfo.string1, podinfo.string2, 2, 0, 12.5, Color(255, 0, 0, 255))
	end
    Wire_Render(self.Entity)
end