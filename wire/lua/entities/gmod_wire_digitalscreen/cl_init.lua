if (not EmuFox) then
	include('shared.lua')
end

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH


function ENT:Initialize()
	self.Memory1 = {}
	self.Memory2 = {}

	self.LastClk = 0
	self.NewClk = 1
	self.NeedRefresh = true
	self.RefreshPixels = {}
	self.RefreshRows = {}

	self.Width = 32
	self.Height = 32

	for i=1,self.Height do
		self.RefreshRows[i] = i-1
	end

	//0..786431 - RGB data

	//1048570 - Clear row
	//1048571 - Clear column
	//1048572 - Height
	//1048573 - Width
	//1048574 - Hardware Clear Screen
	//1048575 - CLK

	WireGPU_NeedRenderTarget(self:EntIndex())
end

function ENT:OnRemove()
	WireGPU_ReturnRenderTarget(self:EntIndex())
end

function ConsoleScreen_DataMessage(um)
	local ent = ents.GetByIndex(um:ReadLong())
	local clk = um:ReadLong()
	local datasize = um:ReadLong()
	for i=1,datasize do
		local address = um:ReadLong()
		local value = um:ReadFloat()
		if (ent) && (ent.Memory1) && (ent.Memory2) then
			ent.NewClk = clk
			ent:WriteCell(address,value)
		end
	end
end
usermessage.Hook("digitalscreen_datamessage", ConsoleScreen_DataMessage)

function ENT:ReadCell(Address,value)
	if ((Address >= 0) && (Address < 1048576)) then
		return self.Memory2[Address]
	else
		return nil
	end	
end

function ENT:WriteCell(Address,value)
	if ((Address >= 0) && (Address < 1048576)) then
		if (Address == 1048575) then
			self.NewClk = value
		end
		//print("recv: "..Address.." pixs: "..#self.RefreshPixels)
		if (self.NewClk == 1) then
			self.Memory1[Address] = value //Vis mem
			self.Memory2[Address] = value //Invis mem
			self.NeedRefresh = true
			self.RefreshPixels[#self.RefreshPixels+1] = Address
		else
			self.Memory2[Address] = value //Invis mem
		end

		if (Address == 1048574) then
			self.Memory1 = {}
			self.Memory2 = {}
			self.NeedRefresh = true
			for i=1,self.Height do
				self.RefreshRows[i] = i-1
			end
		end
		if (Address == 1048572) then
			self.Height = value
			self.NeedRefresh = true
			for i=1,self.Height do
				self.RefreshRows[i] = i-1
			end
		end
		if (Address == 1048573) then
			self.Width = value
			self.NeedRefresh = true
			for i=1,self.Height do
				self.RefreshRows[i] = i-1
			end
		end

		if (self.LastClk ~= self.NewClk) then
			self.LastClk = self.NewClk //swap the memory if clock changes
			self.Memory1 = table.Copy(self.Memory2)

			self.NeedRefresh = true
			for i=1,self.Height do
				self.RefreshRows[i] = i-1
			end
		end
		return true
	end
	return false
end

function ENT:RedrawPixel(a)
	//local a = x + y*self.Width
	if (a >= self.Width*self.Height) then return end
	local c = self.Memory1[a]
	if (not c) then c = 0 end
	local x = a % self.Width
	local y = math.floor(a / self.Width)

	local crgb = math.floor(c / 1000)
	local cgray = c - math.floor(c / 1000)*1000

	local cb = 24*math.fmod(crgb,10)
	local cg = 24*math.fmod(math.floor(crgb / 10),10)
	local cr = 24*math.fmod(math.floor(crgb / 100),10)

	local xstep = (512/self.Width)
	local ystep = (512/self.Height)

	surface.SetDrawColor(cgray+cr,cgray+cg,cgray+cb,255)
	surface.DrawRect(x*xstep,y*ystep,xstep,ystep)
end

function ENT:RedrawRow(y)
	local xstep = (512/self.Width)
	local ystep = (512/self.Height)
	local a = y*self.Width
	if (a >= self.Width*self.Height) then return end

	for x=0,self.Width-1 do
		local c = self.Memory1[a+x]
		if (not c) then c = 0 end
	
		local crgb = math.floor(c / 1000)
		local cgray = c - math.floor(c / 1000)*1000
	
		local cb = 24*math.fmod(crgb,10)
		local cg = 24*math.fmod(math.floor(crgb / 10),10)
		local cr = 24*math.fmod(math.floor(crgb / 100),10)
	
		surface.SetDrawColor(cgray+cr,cgray+cg,cgray+cb,255)
		surface.DrawRect(x*xstep,y*ystep,xstep,ystep)
	end
end

function ENT:Draw()
	self.Entity:DrawModel()

	self.RTTexture = WireGPU_GetMyRenderTarget(self:EntIndex())

	local NewRT = self.RTTexture
	local OldRT = render.GetRenderTarget()

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture",self.RTTexture)

	if (self.NeedRefresh == true) then
		self.NeedRefresh = false

		local oldw = ScrW()
		local oldh = ScrH()

	 	render.SetRenderTarget(NewRT) 
	 	render.SetViewPort(0,0,512,512)
	 	cam.Start2D()
			local pixels = 0
			local idx = 1

			if (#self.RefreshRows > 0) then
				idx = #self.RefreshRows
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawRow(self.RefreshRows[idx])
					self.RefreshRows[idx] = nil
					idx = idx - 1
					pixels = pixels + self.Width
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			else
				idx = #self.RefreshPixels
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawPixel(self.RefreshPixels[idx])
					self.RefreshPixels[idx] = nil
					idx = idx - 1
					pixels = pixels + 1
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			end
	 	cam.End2D()
	 	render.SetViewPort(0,0,oldw,oldh)
	 	render.SetRenderTarget(OldRT) 
	end

	if (EmuFox) then
		return
	end

	if (WireGPU_Monitors[self.Entity:GetModel()]) && (WireGPU_Monitors[self.Entity:GetModel()].OF) then
		OF = WireGPU_Monitors[self.Entity:GetModel()].OF
		OU = WireGPU_Monitors[self.Entity:GetModel()].OU
		OR = WireGPU_Monitors[self.Entity:GetModel()].OR
		Res = WireGPU_Monitors[self.Entity:GetModel()].RS
		RatioX = WireGPU_Monitors[self.Entity:GetModel()].RatioX
	else
		OF = 0
		OU = 0
		OR = 0
		Res = 1
		RatioX = 1
	end
	
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), 	rot.z)
	
	local pos = self.Entity:GetPos()+(self.Entity:GetForward()*OF)+(self.Entity:GetUp()*OU)+(self.Entity:GetRight()*OR)

	cam.Start3D2D(pos,ang,Res)
		local w = 512
		local h = 512
		local x = -w/2
		local y = -h/2

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-256,-256,512/RatioX,512)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(WireGPU_texScreen)
		WireGPU_DrawScreen(x,y,w/RatioX,h,0,0)
	cam.End3D2D()

	WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end