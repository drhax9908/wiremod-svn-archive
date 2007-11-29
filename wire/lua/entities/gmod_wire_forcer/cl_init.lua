include('shared.lua')


function ENT:Initialize()
	mx, mn = self.Entity:GetRenderBounds()
	self.Entity:SetRenderBounds( mn + Vector(0,0,128), mx, 0 )
end

function ENT:Draw()
	self.BaseClass.Draw(self)
	
	local beam_length = self:GetBeamLength()
	if (beam_length > 0) then
		local start = self.Entity:GetPos() + self.Entity:GetUp()*self.Entity:OBBMaxs().z
		local endpos = start + (self.Entity:GetUp() * beam_length)
		
		local bbmin, bbmax = self.Entity:GetRenderBounds()
		local lspos = self.Entity:WorldToLocal(start)
		local lepos = self.Entity:WorldToLocal(endpos)
		if (lspos.x < bbmin.x) then bbmin.x = lspos.x end
		if (lspos.y < bbmin.y) then bbmin.y = lspos.y end
		if (lspos.z < bbmin.z) then bbmin.z = lspos.z end
		if (lspos.x > bbmax.x) then bbmax.x = lspos.x end
		if (lspos.y > bbmax.y) then bbmax.y = lspos.y end
		if (lspos.z > bbmax.z) then bbmax.z = lspos.z end
		if (lepos.x < bbmin.x) then bbmin.x = lepos.x end
		if (lepos.y < bbmin.y) then bbmin.y = lepos.y end
		if (lepos.z < bbmin.z) then bbmin.z = lepos.z end
		if (lepos.x > bbmax.x) then bbmax.x = lepos.x end
		if (lepos.y > bbmax.y) then bbmax.y = lepos.y end
		if (lepos.z > bbmax.z) then bbmax.z = lepos.z end
		self.Entity:SetRenderBounds(bbmin, bbmax, Vector()*6)

		local trace = {}
		trace.start = start
		trace.endpos = endpos
		trace.filter = { self.Entity }
		if (self.Entity:GetNetworkedInt("TraceWater") == 1) then trace.mask = MASK_ALL end

		local trace = util.TraceLine(trace)
		if (trace.Hit) then
			endpos = trace.HitPos
		end

		render.SetMaterial(Material("tripmine_laser"))
		render.DrawBeam(start, endpos, 6, 0, 10, Color(self.Entity:GetColor()))
		if(self:GetForceBeam()==true)then
		  render.SetMaterial(Material("Models/effects/comball_tape"))
		  render.DrawBeam(start, endpos, 6, 0, 10, Color(255,255,255,255))
		end
	end
end

function ENT:Think()
end
