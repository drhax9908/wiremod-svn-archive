include('shared.lua')
include('gpu_vm.lua')
include('gpu_opcodes.lua')
include('gpu_clientbus.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

WireGPU_HookedGPU = nil

function ENT:Initialize()
	self.IsGPU = true
	self.PrevTime = CurTime()

	self.Debug = false

	self.Memory = {}
	self.ROMMemory = {}

	self.PrecompileData = {}
	self.PrecompileMemory = {}

	self:InitGraphicTablet()
	self:InitializeGPUOpcodeTable()
	self:InitializeGPULookupTables()
	self:InitializeGPUVariableSet()
	self:InitializeErrors()
	self:GPUMathInit()
	self:GPUHardReset()

	self.FramesSinceRedraw = 0
	self.FrameRateRatio = 4
	self.FrameInstructions = 0

	WireGPU_NeedRenderTarget(self:EntIndex())
//	WireGPU_NeedRenderTarget(self:EntIndex())

	self.OF = CreateClientConVar("gpu_of",0,false,false)
	self.OR = CreateClientConVar("gpu_or",0,false,false)
	self.OU = CreateClientConVar("gpu_ou",0,false,false)
	self.Scale = CreateClientConVar("gpu_scale",0,false,false)
	self.Ratio = CreateClientConVar("gpu_ratio",1,false,false)
	self.MinFrameRateRatio = CreateClientConVar("wire_gpu_frameratio",4,false,false)
end

function ENT:OnUse()
	//if (WireGPU_HookedGPU == self) then
	//	WireGPU_HookedGPU = nil
	//else
	//	WireGPU_HookedGPU = self
	//end
	self:DoCall(2,4000)
end

function ENT:OnRemove()
	WireGPU_ReturnRenderTarget(self:EntIndex())
//	WireGPU_ReturnRenderTarget(10002*(2*self:EntIndex()+1))
end

function DebugMessage(msg)
	Msg("============================================\n")
	Msg(msg.."\n")
end

function WireGPU_MemoryMessage(umsg)
	local ent = ents.GetByIndex(umsg:ReadLong())
	local cachebase = umsg:ReadLong()
	local cachesize = umsg:ReadLong()

	if ((ent) && (ent.Memory)) then
		if (cachebase >= 0) && (cachebase + cachesize < 65537) then
			for i=0,cachesize-1 do
				local value = umsg:ReadFloat()

				ent:WriteCell(cachebase+i,value)
				ent.ROMMemory[cachebase+i] = value
				if (cachebase+i == 65534) then
					ent:GPUHardReset()
				end
			end
		end
	end
end
usermessage.Hook("wiregpu_memorymessage", WireGPU_MemoryMessage) 

function ENT:SVN_Version()
	local SVNString = "$Revision: 000$"

	return tonumber(string.sub(SVNString,12,14))
end

function ENT:DoCall(callid,calldepth)
	if (callid != 0) then Msg("Call "..callid.."\n") end

	if ((self.EntryPoint) && (self.EntryPoint[callid])) then
		self:GPUFrameReset()

		self.IP = self.EntryPoint[callid]
		local cmdcount = 0
		while ((cmdcount < calldepth) && (self.INTR == 0)) do
			self:GPUExecute()
			cmdcount = cmdcount + 1
			self.FrameInstructions = self.FrameInstructions + 1
		end
	end
end

function ENT:OutputError(intnumber,intparam)
	local ErrorText = "Unknown error"
	if (self.ErrorText[intnumber]) then
		ErrorText = self.ErrorText[intnumber]
	end
	draw.DrawText(
"GPU Error   = \n"..
"Parameter   = \n"..
"Instruction = \n"..
"Error       = \n",
	"WireGPU_ConsoleFont",16,16,Color(255,64,64,255),0)
	draw.DrawText(
"              "..intnumber.."\n"..
"              "..intparam.."\n"..
"              "..self.XEIP.."\n"..
"              "..ErrorText.."\n",
	"WireGPU_ConsoleFont",16,16,Color(255,255,255,255),0)
end

function ENT:Draw()
	self.Entity:DrawModel()

	local DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+DeltaTime
	self.DeltaTime = DeltaTime

	self.FrameBuffer = WireGPU_GetMyRenderTarget(self:EntIndex())
	//self.SpriteBuffer = WireGPU_GetMyRenderTarget(10002*(2*self:EntIndex()+1))

	local FrameRate = self.MinFrameRateRatio:GetFloat() or 2//self.FrameRateRatio
	self.FramesSinceRedraw = self.FramesSinceRedraw + 1
	self.FrameInstructions = 0
	if (self.FramesSinceRedraw >= FrameRate) then
		self.FramesSinceRedraw = 0
		local oldw = ScrW()
		local oldh = ScrH()

		local OldRT = render.GetRenderTarget()
		local NewRT = self.FrameBuffer
	 	render.SetRenderTarget(NewRT) 
	 	render.SetViewPort(0,0,512,512)
	 	cam.Start2D() 
			if (self:ReadCell(65533) == 1) then
		 		surface.SetDrawColor(0,0,0,255)
		 		surface.DrawRect(0,0,512,512)
			end
			if (self:ReadCell(65535) == 1) then
				if (self.EntryPoint[3]) && (self.HandleError == 1) then
					self:DoCall(3,FrameRate*600)
				else
					self:DoCall(0,FrameRate*600)
				end
			end
	 	cam.End2D()
	 	render.SetViewPort(0,0,oldw,oldh)
	 	render.SetRenderTarget(OldRT) 
	end

	if (WireGPU_Monitors[self.Entity:GetModel()]) && (WireGPU_Monitors[self.Entity:GetModel()].OF) then
		OF = WireGPU_Monitors[self.Entity:GetModel()].OF
		OU = WireGPU_Monitors[self.Entity:GetModel()].OU
		OR = WireGPU_Monitors[self.Entity:GetModel()].OR
		Res = WireGPU_Monitors[self.Entity:GetModel()].RS
		RatioX = WireGPU_Monitors[self.Entity:GetModel()].RatioX
		Rot90 = WireGPU_Monitors[self.Entity:GetModel()].rot90

		self:WriteCell(65513,RatioX)
	else
		OF = self.OF:GetFloat() or 0
		OU = self.OU:GetFloat() or 0
		OR = self.OR:GetFloat() or 0
		Res = self.Scale:GetFloat() or 1
		RatioX = self.Ratio:GetFloat() or 1
	end
	
	local ang = self.Entity:GetAngles()
	local rot = Vector(-90,90,0)
	if (Rot90) then
		rot = Vector(180,90,0)
	end

	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), 	rot.z)
	
	local pos = self.Entity:GetPos()+(self.Entity:GetForward()*OF)+(self.Entity:GetUp()*OU)+(self.Entity:GetRight()*OR)

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture",self.FrameBuffer)

	cam.Start3D2D(pos,ang,Res)
		local w = 512*math.Clamp(self:ReadCell(65525),0,1)
		local h = 512*math.Clamp(self:ReadCell(65524),0,1)
		local x = -w/2
		local y = -h/2

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-256,-256,512/RatioX,512)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(WireGPU_texScreen)
		WireGPU_DrawScreen(x,y,w/RatioX,h,self:ReadCell(65522),self:ReadCell(65523))

		//self.workingDistance = 256

		local trace = {}
		trace.start = LocalPlayer():GetShootPos()
		trace.endpos = (LocalPlayer():GetAimVector() * self.workingDistance) + trace.start
		trace.filter = LocalPlayer()
		local trace = util.TraceLine(trace)
		
		if (trace.Entity == self.Entity) then
			local pos = self.Entity:WorldToLocal(trace.HitPos)
			local cx = (self.x1 - pos.y) / (self.x1 - self.x2)
			local cy = (self.y1 - pos.z) / (self.y1 - self.y2)

			self:WriteCell(65505,cx)
			self:WriteCell(65504,cy)
			
			if (self:ReadCell(65503) == 1) and (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
				surface.SetDrawColor(255,255,255,255)
				surface.SetTexture(surface.GetTextureID("gui/arrow"))
				surface.DrawTexturedRectRotated(-256+cx*512/RatioX,-256+cy*512,32,32,45)
			end
		end
	cam.End3D2D()
	
	WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
	Wire_Render(self.Entity)
end

//function drawBrickTexture()
//	//local mat = Material("models\duckeh\buttons\0")
//	//local tex = surface.GetTextureID("models\duckeh\buttons\0")
//
//	//local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
//	//WireGPU_matScreen:SetMaterialTexture("$basetexture","phoenix_storms/wire/pcb_green")
//
//	surface.SetDrawColor(255,255,255,255)
//	surface.SetTexture(surface.GetTextureID(""))
//	surface.DrawTexturedRect(ScrW()*0.5-256,ScrH()*0.5-256,512,512)
//
//	//WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
//
//	if (WireGPU_HookedGPU) then
//		local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
//		WireGPU_matScreen:SetMaterialTexture("$basetexture",WireGPU_HookedGPU.FrameBuffer)
//
//		local w = 512*math.Clamp(WireGPU_HookedGPU:ReadCell(65525),0,1)
//		local h = 512*math.Clamp(WireGPU_HookedGPU:ReadCell(65524),0,1)
//		local x = -w/2
//		local y = -h/2
//
//		surface.SetDrawColor(255,255,255,255)
//		surface.SetTexture(WireGPU_texScreen)
//		WireGPU_DrawScreen(x,y,w/RatioX,h,WireGPU_HookedGPU:ReadCell(65522),WireGPU_HookedGPU:ReadCell(65523))
//
//		WireGPU_matScreen:SetMaterialTexture("$basetexture",OldTex)
//	end
//end
//hook.Add("HUDPaint","DrawTheBricks",drawBrickTexture) 

function ENT:IsTranslucent()
	return true
end
