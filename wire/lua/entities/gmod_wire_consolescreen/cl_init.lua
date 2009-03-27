if (not EmuFox) then
	include('shared.lua')
end

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH


function ENT:Initialize()
	self.Memory1 = {}
	self.Memory2 = {}

	for i = 0, 2047 do
		self.Memory1[i] = 0
	end

	//Caching control:
	//[2020] - Force cache refresh
	//[2021] - Cached blocks size (up to 28, 0 if disabled)
	//Hardware image control:
	//[2022] - Screen ratio (read only)
	//[2023] - Hardware scale
	//[2024] - Rotation (0 - 0*, 1 - 90*, 2 - 180*, 3 - 270*)
	//[2025] - Brightness White
	//[2026] - Brightness B
	//[2027] - Brightness G
	//[2028] - Brightness R
	//[2029] - Vertical scale (1)
	//[2030] - Horizontal scale (1)
	//
	//Shifting control:
	//[2031] - Low shift column
	//[2032] - High shift column
	//[2033] - Low shift row
	//[2034] - High shift row
	//
	//Character output control:
	//[2035] - Charset, always 0
	//[2036] - Brightness (additive)
	//
	//Control registers:
	//[2037] - Shift cells (number of cells, >0 right, <0 left)
	//[2038] - Shift rows (number of rows, >0 shift up, <0 shift down)
	//[2039] - Hardware Clear Row (Writing clears row)
	//[2040] - Hardware Clear Column (Writing clears column)
	//[2041] - Hardware Clear Screen
	//[2042] - Hardware Background Color (000)
	//
	//Cursor control:
	//[2043] - Cursor Blink Rate (0.50)
	//[2044] - Cursor Size (0.25)
	//[2045] - Cursor Address
	//[2046] - Cursor Enabled
	//
	//[2047] - Clk

	self.Memory1[2022] = 3/4
	self.Memory1[2023] = 0
	self.Memory1[2024] = 0
	self.Memory1[2025] = 1
	self.Memory1[2026] = 1
	self.Memory1[2027] = 1
	self.Memory1[2028] = 1
	self.Memory1[2029] = 1
	self.Memory1[2030] = 1
	self.Memory1[2031] = 0
	self.Memory1[2032] = 29
	self.Memory1[2033] = 0
	self.Memory1[2034] = 17
	self.Memory1[2035] = 0
	self.Memory1[2036] = 0

	self.Memory1[2042] = 000
	self.Memory1[2043] = 0.5
	self.Memory1[2044] = 0.25
	self.Memory1[2045] = 0
	self.Memory1[2046] = 0

	for i = 0, 2047 do
		self.Memory2[i] = self.Memory1[i]
	end

	self.LastClk = 0

	self.PrevTime = CurTime()
	self.IntTimer = 0

	self.NeedRefresh = true
	self.Flash = false
	self.FrameNeedsFlash = false

	self.FramesSinceRedraw = 0
	self.NewClk = 1

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
usermessage.Hook("consolescreen_datamessage", ConsoleScreen_DataMessage) 

function ENT:ReadCell(Address,value)
	if ((Address >= 0) && (Address < 2048)) then
		return self.Memory2[Address]
	else
		return nil
	end	
end

function ENT:WriteCell(Address,value)
	if ((Address >= 0) && (Address < 2048)) then
		if (Address == 2047) then
			self.NewClk = value
//			return
		end
		if (self.NewClk == 1) then
			self.Memory1[Address] = value //Vis mem
			self.Memory2[Address] = value //Invis mem
			self.NeedRefresh = true
		else
			self.Memory2[Address] = value //Invis mem
		end
		
		//2038 - Shift rows (number of rows, >0 shift down, <0 shift up)
		//2039 - Hardware Clear Row (Writing clears row)
		//2040 - Hardware Clear Column (Writing clears column)
		//2041 - Hardware Clear Screen
	
		if (Address == 2037) then
			local delta = value
			local low = math.floor(math.Clamp(self.Memory1[2031],0,29))
			local high = math.floor(math.Clamp(self.Memory1[2032],0,29))
			if (delta > 0) then
				for j = low,high do
					for i = 29,delta do
					if (self.NewClk == 1) then
						self.Memory1[j*60+i*2] = self.Memory1[j*60+i*2-delta*2]
						self.Memory1[j*60+i*2+1] = self.Memory1[j*60+i*2+1-delta*2]
					end
					self.Memory2[j*60+i*2] = self.Memory2[j*60+i*2-delta*2]
					self.Memory2[j*60+i*2+1] = self.Memory2[j*60+i*2+1-delta*2]
				end
			end
			for j = low,high do
				for i = 0, delta-1 do
					if (self.NewClk == 1) then
						self.Memory1[j*60+i*2] = 0
						self.Memory1[j*60+i*2+1] = 0
					end
						self.Memory2[j*60+i*2] = 0
						self.Memory2[j*60+i*2+1] = 0
					end
				end
			else
				delta = -delta
				for j = low,high do
					for i = 0,29-delta do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i*2] = self.Memory1[j*60+i*2+delta*2]
							self.Memory1[j*60+i*2+1] = self.Memory1[j*60+i*2+1+delta*2]
						end
						self.Memory2[j*60+i*2] = self.Memory2[j*60+i*2+delta*2]
						self.Memory2[j*60+i*2+1] = self.Memory2[j*60+i*2+1+delta*2]
					end
				end
				for j = low,high do
					for i = 29-delta+1,29 do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i*2] = 0
							self.Memory1[j*60+i*2+1] = 0
						end
						self.Memory2[j*60+i*2] = 0
						self.Memory2[j*60+i*2+1] = 0
					end
				end
			end
		end
		if (Address == 2038) then
			local delta = value
			local low = math.floor(math.Clamp(self.Memory1[2033],0,17))
			local high = math.floor(math.Clamp(self.Memory1[2034],0,17))
			if (delta > 0) then
				for j = low, high-delta do
					for i = 0, 59 do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i] = self.Memory1[(j+delta)*60+i]
						end
						self.Memory2[j*60+i] = self.Memory2[(j+delta)*60+i]
					end
				end
				for j = high-delta+1,high do
					for i = 0, 59 do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i] = 0
						end
						self.Memory2[j*60+i] = 0
					end
				end
			else
				delta = -delta
				for j = low+delta,high do
					for i = 0, 59 do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i] = self.Memory1[(j-delta)*60+i]
						end
						self.Memory2[j*60+i] = self.Memory2[(j-delta)*60+i]
					end
				end
				for j = low,low+delta-1 do
					for i = 0, 59 do
						if (self.NewClk == 1) then
							self.Memory1[j*60+i] = 0
						end
						self.Memory2[j*60+i] = 0
					end
				end
			end
		end
		if (Address == 2039) then
			for i = 0, 59 do
				self.Memory1[value*60+i] = 0
				self.Memory2[value*60+i] = 0
			end
			self.NeedRefresh = true
		end
		if (Address == 2040) then
			for i = 0, 17 do
				self.Memory1[i*60+value] = 0
				self.Memory2[i*60+value] = 0
			end
			self.NeedRefresh = true
		end
		if (Address == 2041) then
			for i = 0, 18*30*2 do 
				self.Memory1[i] = 0
				self.Memory2[i] = 0
			end
			self.NeedRefresh = true
		end

		if (self.LastClk ~= self.NewClk) then
			self.LastClk = self.NewClk //swap the memory if clock changes
			self.Memory1 = table.Copy(self.Memory2)

			self.NeedRefresh = true
		end
		return true
	end
	return false
end

function ENT:DrawGraphicsChar(c,x,y,w,h,r,g,b)
	surface.SetDrawColor(r,g,b,255)

	if (c == 128) then
		vertex = {}

		//Generate vertex data
		vertex[1] = {}
		vertex[1]["x"] = x
		vertex[1]["y"] = y+h

		vertex[2] = {}
		vertex[2]["x"] = x+w
		vertex[2]["y"] = y+h

		vertex[3] = {}
		vertex[3]["x"] = x+w
		vertex[3]["y"] = y
		surface.DrawPoly(vertex)
	end

	if (c == 129) then
		vertex = {}

		//Generate vertex data
		vertex[1] = {}
		vertex[1]["x"] = x
		vertex[1]["y"] = y+h

		vertex[2] = {}
		vertex[2]["x"] = x
		vertex[2]["y"] = y

		vertex[3] = {}
		vertex[3]["x"] = x+w
		vertex[3]["y"] = y+h
		surface.DrawPoly(vertex)
	end

	if (c == 130) then
		vertex = {}

		//Generate vertex data
		vertex[1] = {}
		vertex[1]["x"] = x
		vertex[1]["y"] = y+h

		vertex[2] = {}
		vertex[2]["x"] = x+w
		vertex[2]["y"] = y

		vertex[3] = {}
		vertex[3]["x"] = x
		vertex[3]["y"] = y
		surface.DrawPoly(vertex)
	end

	if (c == 131) then
		vertex = {}

		//Generate vertex data
		vertex[1] = {}
		vertex[1]["x"] = x
		vertex[1]["y"] = y

		vertex[2] = {}
		vertex[2]["x"] = x+w
		vertex[2]["y"] = y

		vertex[3] = {}
		vertex[3]["x"] = x+w
		vertex[3]["y"] = y+h
		surface.DrawPoly(vertex)
	end
end

function ENT:Draw()
	self.Entity:DrawModel()

	local DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+DeltaTime
	self.IntTimer = self.IntTimer + DeltaTime

	self.RTTexture = WireGPU_GetMyRenderTarget(self:EntIndex())

	local NewRT = self.RTTexture
	local OldRT = render.GetRenderTarget()

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture",self.RTTexture)

	self.FramesSinceRedraw = self.FramesSinceRedraw + 1

	if (self.NeedRefresh == true) then
		self.FramesSinceRedraw = 0
		self.NeedRefresh = false
		self.FrameNeedsFlash = false

		local oldw = ScrW()
		local oldh = ScrH()

	 	render.SetRenderTarget(NewRT) 
	 	render.SetViewPort(0,0,512,512)
	 	cam.Start2D()
			//Draw terminal here
			//W/H = 16
			local szx = 512/31
			local szy = 512/19

			local ch = self.Memory1[2042]

			local hb = 24*math.fmod(ch,10)
			local hg = 24*math.fmod(math.floor(ch / 10),10)
			local hr = 24*math.fmod(math.floor(ch / 100),10)
			surface.SetDrawColor(hr,hg,hb,255)
			surface.DrawRect(0,0,512,512)

			for ty = 0, 17 do
				for tx = 0, 29 do
					local a = tx + ty*30
					local c1 = self.Memory1[2*a]
					local c2 = self.Memory1[2*a+1]

					local cback = math.floor(c2 / 1000)
					local cfrnt = c2 - math.floor(c2 / 1000)*1000

					local fb = math.Clamp(24*math.fmod(cfrnt,10) + self.Memory1[2036],0,255)
					local fg = math.Clamp(24*math.fmod(math.floor(cfrnt / 10),10) + self.Memory1[2036],0,255)
					local fr = math.Clamp(24*math.fmod(math.floor(cfrnt / 100),10) + self.Memory1[2036],0,255)
					local bb = math.Clamp(24*math.fmod(cback,10) + self.Memory1[2036],0,255)
					local bg = math.Clamp(24*math.fmod(math.floor(cback / 10),10) + self.Memory1[2036],0,255)
					local br = math.Clamp(24*math.fmod(math.floor(cback / 100),10) + self.Memory1[2036],0,255)

					if (self.Flash == true) && (cback > 999) then
						fb,bb = bb,fb
						fg,bg = bg,fg
						fr,br = br,fr
					end

					if (cback > 999) then
						self.FrameNeedsFlash = true
					end

					if (c1 > 255) then c1 = 0 end
					if (c1 < 0) then c1 = 0 end

					if (cback ~= 0) then
						surface.SetDrawColor(br,bg,bb,255)
						surface.DrawRect(tx*szx+szx/2,ty*szy+szy/2,szx*1.2,szy*1.2)
					else
						surface.SetDrawColor(hr,hg,hb,255)
						surface.DrawRect(tx*szx+szx/2,ty*szy+szy/2,szx*1.2,szy*1.2)
					end

					if (c1 ~= 0) && (cfrnt ~= 0) then
						if (c1 <= 127) then
							draw.DrawText(string.char(c1),"WireGPU_ConsoleFont",
							tx*szx+szx/8+szx/2,ty*szy+szy/4+szy/2,
							Color(math.Clamp(fr*self.Memory1[2028]*self.Memory1[2025],0,255),
							      math.Clamp(fg*self.Memory1[2027]*self.Memory1[2025],0,255),
							      math.Clamp(fb*self.Memory1[2026]*self.Memory1[2025],0,255),
							      255),0)
						else
							self:DrawGraphicsChar(c1,tx*szx+szx/2,ty*szy+szy/2,szx,szy,
								math.Clamp(fr*self.Memory1[2028]*self.Memory1[2025],0,255),
								math.Clamp(fg*self.Memory1[2027]*self.Memory1[2025],0,255),
								math.Clamp(fb*self.Memory1[2026]*self.Memory1[2025],0,255))
						end
					end
				end
			end

			if (self.Memory1[2045] > 1080) then self.Memory1[2045] = 1080 end
			if (self.Memory1[2045] < 0) then self.Memory1[2045] = 0 end
			if (self.Memory1[2044] > 1) then self.Memory1[2044] = 1 end
			if (self.Memory1[2044] < 0) then self.Memory1[2044] = 0 end

			if (self.Memory1[2046] >= 1) then
				if (self.Flash == true) then
					local a = math.floor(self.Memory1[2045] / 2)
	
					local tx = a - math.floor(a / 30)*30
					local ty = math.floor(a / 30)

					local c = self.Memory1[2*a+1]
					local cback = 999-math.floor(c / 1000)
					local bb = 24*math.fmod(cback,10)
					local bg = 24*math.fmod(math.floor(cback / 10),10)
					local br = 24*math.fmod(math.floor(cback / 100),10)

					surface.SetDrawColor(math.Clamp(br*self.Memory1[2028]*self.Memory1[2025],0,255),
							     math.Clamp(bg*self.Memory1[2027]*self.Memory1[2025],0,255),
							     math.Clamp(bb*self.Memory1[2026]*self.Memory1[2025],0,255),
							     255)
					surface.DrawRect(
						tx*szx+szx/2,
						ty*szy+szy/2+szy*1.2*(1-self.Memory1[2044]),
						szx*1.2,
						szy*1.2*self.Memory1[2044])
				end
			end
	 	cam.End2D()
	 	render.SetViewPort(0,0,oldw,oldh)
	 	render.SetRenderTarget(OldRT) 
	end

	if (self.FrameNeedsFlash == true) then
		if (self.IntTimer < self.Memory1[2043]) then
			if (self.Flash == false) then
				self.NeedRefresh = true
			end
			self.Flash = true
		end

		if (self.IntTimer >= self.Memory1[2043]) then
			if (self.Flash == true) then
				self.NeedRefresh = true
			end
			self.Flash = false
		end

		if (self.IntTimer >= self.Memory1[2043]*2) then
			self.IntTimer = 0
		end
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
		local w = 512*math.Clamp(self.Memory1[2030],0,1)
		local h = 512*math.Clamp(self.Memory1[2029],0,1)
		local x = -w/2
		local y = -h/2

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-256,-256,512/RatioX,512)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(WireGPU_texScreen)
		WireGPU_DrawScreen(x,y,w/RatioX,h,self.Memory1[2024],self.Memory1[2023])
	cam.End3D2D()

	WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
