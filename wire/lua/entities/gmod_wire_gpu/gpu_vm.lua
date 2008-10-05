include('entities/gmod_wire_cpu/cpu_vm.lua')		//Include ZCPU VM
include('entities/gmod_wire_cpu/cpu_opcodes.lua')	//Include ZCPU opcodes
include('entities/gmod_wire_cpu/cpu_bitwise.lua')	//Include bitwise operations
include('gpu_opcodes.lua')				//Override ZCPU opcodes
include('gpu_clientbus.lua')				//Own GPU bus
include('gpu_interrupt.lua')				//Own GPU interrupts

function ENT:GPUHardReset()
	self.HandleError = 0
	self:GPUFrameReset()
	//for i = 0, 63487 do
	//	if (self.ROMMemory[i]) then
	//		self:WriteCell(i,self.ROMMemory[i])
	//	end
	//end
	//self:GPUFrameReset()

	self.EntryPoint = {}
	self.EntryPoint[0] = 0
end

function ENT:GPUFrameReset()
	self:Reset()

	//Remove junk:
	self.Page = nil
	self.IDTR = nil
	self.EF = nil
	self.PF = nil
	self.IF = nil
	self.LADD = nil
	self.BusLock = nil
	self.Idle = nil
	self.CPAGE = nil

	self.ESP = 32767

	self.TIMER = self.PrevTime

	//Initialize GPU
	self:GPUResetRegisters()
	self:GPUMathReset()
end

function ENT:GPUResetRegisters()
	//self:WriteCell(65533,0) //Restore first page

	//Hardware control registers:
	//[65535] - CLK
	//[65534] - RESET
	//[65533] - <reserved>
	//[65532] - Vertex mode (render vertex instead of RT)

	self.Memory[65535] = 1
	self.Memory[65534] = 0
	self.Memory[65533] = 0
	self.Memory[65532] = 0

	//Image control:
	//[65525] - Horizontal image scale
	//[65524] - Vertical image scale
	//[65523] - Hardware scale
	//[65522] - Rotation (0 - 0*, 1 - 90*, 2 - 180*, 3 - 270*)
	//[65521] - Sprite size [32]

	self.Memory[65525] = 1
	self.Memory[65524] = 1
	self.Memory[65523] = 0
	self.Memory[65522] = 0
	self.Memory[65521] = 32

	//Vertex pipe controls:
	//[65515] - Image width (800)
	//[65514] - Image height (600)
	//[65513] - Real screen ratio
	//[65512] - Focal length (vertex pipe)

	self.Memory[65515] = 800
	self.Memory[65514] = 600
	self.Memory[65513] = 0
	self.Memory[65512] = 100

	//Cursor control:
	//[65505] - Cursor X (0..1)
	//[65504] - Cursor Y (0..1)
	//[65503] - Cursor visible

	self.Memory[65505] = 0
	self.Memory[65504] = 0
	self.Memory[65503] = 0

	//Brightness control:
	//[65495] - Brightness W
	//[65494] - Brightness R
	//[65493] - Brightness G
	//[65492] - Brightness B
	//[65491] - Contrast W
	//[65490] - Contrast R
	//[65489] - Contrast G
	//[65488] - Contrast B

	self.Memory[65495] = 1
	self.Memory[65494] = 1
	self.Memory[65493] = 1
	self.Memory[65492] = 1
	self.Memory[65491] = 0
	self.Memory[65490] = 0
	self.Memory[65489] = 0
	self.Memory[65488] = 0

	//Rendering settings
	//[65485] - Circle quality (3..128)
	//[65484] - Offset Point X
	//[65483] - Offset Point Y
	//[65482] - Rotation (rad)
	//[65481] - Scale
	//[65480] - Center point X
	//[65479] - Center point Y
	//[65478] - Circle start (rad)
	//[65477] - Circle end (rad)

	self.Memory[65485] = 32
	self.Memory[65484] = 0
	self.Memory[65483] = 0
	self.Memory[65482] = 0
	self.Memory[65481] = 1
	self.Memory[65480] = 0
	self.Memory[65479] = 0
	self.Memory[65478] = 0
	self.Memory[65477] = 3.141592*2


	//=================================
	//[64512] - last register
	//Ports:
	//[63488]..[64511] - External ports
end

function ENT:InitializeGPUVariableSet()
	self:InitializeCPUVariableSet()

	self.CPUVariable[24] = nil	//IDTR
	self.CPUVariable[27] = nil	//LADD

	self.CPUVariable[32] = nil	//IF
	self.CPUVariable[33] = nil	//PF
	self.CPUVariable[34] = nil	//EF

	self.CPUVariable[45] = nil	//BusLock
	self.CPUVariable[46] = nil	//IDLE
	self.CPUVariable[47] = nil	//INTR

	self.CPUVariable[52] = nil	//NIDT
end

function ENT:InitializeGPULookupTables()
	self:InitializeLookupTables()

	for i=1000,2024 do
		self.ParamFunctions_1[i] = function() return self:ReadCell(63488+self.PrecompileData[self.XEIP].dRM1-1000) end
		self.ParamFunctions_2[i] = function() return self:ReadCell(63488+self.PrecompileData[self.XEIP].dRM2-1000) end
		self.WriteBackFunctions[i] = function(Result) self:WriteCell(63488+self.PrecompileData[self.XEIP].dRM1-1000,Result) end
		self.WriteBackFunctions2[i] = function(Result) self:WriteCell(63488+self.PrecompileData[self.XEIP].dRM2-1000,Result) end
	end

end

function ENT:GPUExecute()
	self.DeltaTime = CurTime()-(self.PrevTime or CurTime())
	self.PrevTime = (self.PrevTime or CurTime())+self.DeltaTime

	self.TIMER = self.TIMER + self.DeltaTime
	self.TMR = self.TMR + 1

	if (!self.IP) then
		self:Interrupt(5,0)
		return
	end

	self.XEIP = self.IP+self.CS
	self.CPAGE = math.floor(self.XEIP / 128)

	//Dynamic precompiler: check if opcode was precompiled
	if (self.PrecompileData[self.XEIP]) then
		//Simulate read
		self.IP = self.IP + self.PrecompileData[self.XEIP].Size
		self.CODEBYTES = self.CODEBYTES + self.PrecompileData[self.XEIP].Size

		//Verify opcode
		if (self.PrecompileData[self.XEIP].Valid) then
			//Execute
			local Result = self.PrecompileData[self.XEIP].Execute()
			if (Result) then
				if (Result == "Read error") then
					self:Interrupt(5,1) //Read error during execute
				else
					self.PrecompileData[self.XEIP].WriteBack(Result)
				end
			end
		else
			if (self.PrecompileData[self.XEIP].UnknownOpcode) then
				self:Interrupt(4,self.PrecompileData[self.XEIP].Opcode) //Unknown Opcode
			else
				self:Interrupt(5,2) //Internal/opcode read error
			end
		end
	else
		self:Precompile(self.XEIP)
	end
end

function ENT:GPUMathInit()
	self.FontNames = {}
	self.FontNames[0] = "Lucida Console"
	self.FontNames[1] = "Courier New"
	self.FontNames[2] = "Trebuchet"
	self.FontNames[3] = "Arial"
	self.FontNames[4] = "Times New Roman"

	self:GPUMathReset()
end

function ENT:GPUMathReset()
	self.CurrentTexture = "models/duckeh/buttons/1"
	self.ColorTexture = "models/duckeh/buttons/1"

	self.StringCache = {}

	//CVertex pipes:
	//0 - direct (0..512 or 0..1024 range)
	//1 - mapped to screen (set by special registers in GPU)
	//2 - mapped to 0..1 range
	//3 - mapped to -1..1 range

	//Vertex pipes:
	//0 - XY mapping
	//1 - YZ mapping
	//2 - XZ mapping
	//3 - XYZ projective mapping
	//4 - XY mapping + matrix
	//5 - XYZ projective mapping + matrix

	//Entry points:
	//[0] 	DRAW	Called when screen is being drawn
	//[1]	INIT	Called when screen is initialized (reuploaded)
	//[2]	USE	Called when screen is used
	//[3]   ERROR   Called when GPU error occurs (instead of DRAW)
	//[4]	ASYNC	Called when GPU is reset, for running asynchrounous thread

	//DDisable/DEnable parameters:
	//[0]	VERTEX_ZSORT		Enable or disable ZSorting in vertex buffer (sorted on flush)
	//[1]	VERTEX_LIGHTING		Enable or disable vertex lighting
	//[2]	VERTEX_BUFFER		Enable or disable vertex buffer
	//[3]	VERTEX_CULLING		Enable or disable culling on faces
	//[4]	

	self.CVertexPipe = 0
	self.VertexPipe = 0

	self.VectorMode = 2	//2=2f; 3=3f

	self.VertexBufEnabled = false
	self.VertexBufZSort = false
	self.VertexLighting = false
	self.VertexCulling = false

	self.VertexBuffer = {}
	self.VertexBufferCount = 0

	self.Lights = {}

	self.CurFont = 0
	self.CurFontSize = 12
	self.CurColor = {0, 0, 0, 255}

	self.TransformMatrix = {}
	
	self.TransformMatrix[0]  = 1
	self.TransformMatrix[1]  = 0
	self.TransformMatrix[2]  = 0
	self.TransformMatrix[3]  = 0
	
	self.TransformMatrix[4]  = 0
	self.TransformMatrix[5]  = 1
	self.TransformMatrix[6]  = 0
	self.TransformMatrix[7]  = 0
	
	self.TransformMatrix[8]  = 0
	self.TransformMatrix[9]  = 0
	self.TransformMatrix[10] = 1
	self.TransformMatrix[11] = 0

	self.TransformMatrix[12] = 0
	self.TransformMatrix[13] = 0
	self.TransformMatrix[14] = 0
	self.TransformMatrix[15] = 1
end

function ENT:Transform(x,y)
	local transx = x+self:ReadCell(65484)
	local transy = y+self:ReadCell(65483)

//	if ((self:ReadCell(65482) != 0) || (self:ReadCell(65481) != 1)) then
//		local centerx = self:ReadCell(65480)
//		local centery = self:ReadCell(65479)
//
//		local vd = math.sqrt((x-centerx)*(x-centerx)+(y-centery)*(y-centery)) + 0.0001
//		local vx = x / vd
//		local vy = y / vd
//
//		local acos = math.acos(vx)
//		local asin = math.asin(vy)
//
//		acos = acos + self:ReadCell(65482)
//		asin = asin + self:ReadCell(65482)
//
//		transx = math.cos(acos) * vd * self:ReadCell(65481)
//		transy = math.sin(asin) * vd * self:ReadCell(65481)
//	end

	    if (self.CVertexPipe == 0) then
		transx = transx
	elseif (self.CVertexPipe == 1) then
		transx = (transx/self:ReadCell(65515))*512
	elseif (self.CVertexPipe == 2) then
		transx = transx*512
	elseif (self.CVertexPipe == 3) then
		transx = 256+transx*256
	end

	    if (self.CVertexPipe == 0) then
		transy = transy
	elseif (self.CVertexPipe == 1) then
		transy = (transy/self:ReadCell(65514))*512
	elseif (self.CVertexPipe == 2) then
		transy = transy*512
	elseif (self.CVertexPipe == 3) then
		transy = 256+transy*256
	end

	local trans = {}
	trans["x"] = transx
	trans["y"] = transy
	return trans
end

//FIXME: I can do faster vertex transform...
function ENT:VertexTransform(coord)
	local resultcoord = coord
	if (!coord) then return end

	if (self.VertexPipe == 0) then
		if (!coord["x"]) then coord["x"] = 0 end
		if (!coord["y"]) then coord["y"] = 0 end

		resultcoord = self:Transform(coord["x"],coord["y"])
	elseif (self.VertexPipe == 1) then
		if (!coord["y"]) then coord["y"] = 0 end
		if (!coord["z"]) then coord["z"] = 0 end

		resultcoord = self:Transform(coord["y"],coord["z"])
	elseif (self.VertexPipe == 2) then
		if (!coord["x"]) then coord["x"] = 0 end
		if (!coord["z"]) then coord["z"] = 0 end

		resultcoord = self:Transform(coord["x"],coord["z"])
	elseif (self.VertexPipe == 3) then
		if (!coord["x"]) then coord["x"] = 0 end
		if (!coord["y"]) then coord["y"] = 0 end
		if (!coord["z"]) then coord["z"] = 0 end

		resultcoord["x"] = 256+256*(coord["z"]+coord["x"]+1000*self:ReadCell(65512))/(coord["z"]+1000*self:ReadCell(65512))
		resultcoord["y"] = 256+256*(coord["z"]+coord["y"]+1000*self:ReadCell(65512))/(coord["z"]+1000*self:ReadCell(65512))
	elseif (self.VertexPipe == 4) then
		if (!coord["x"]) then coord["x"] = 0 end
		if (!coord["y"]) then coord["y"] = 0 end

		local transx = self.TransformMatrix[0*4+0] * coord["x"] +
			       self.TransformMatrix[0*4+1] * coord["y"] +
			       self.TransformMatrix[0*4+2] * 0 +
			       self.TransformMatrix[0*4+3] * 1

		local transy = self.TransformMatrix[1*4+0] * coord["x"] +
			       self.TransformMatrix[1*4+1] * coord["y"] +
			       self.TransformMatrix[1*4+2] * 0 +
			       self.TransformMatrix[1*4+3] * 1

		resultcoord = self:Transform(transx,transy)
	elseif (self.VertexPipe == 5) then
		if (!coord["x"]) then coord["x"] = 0 end
		if (!coord["y"]) then coord["y"] = 0 end
		if (!coord["z"]) then coord["z"] = 0 end

		local acoord = coord
		acoord["x"] =   self.TransformMatrix[0*4+0] * coord["x"] +
			        self.TransformMatrix[0*4+1] * coord["y"] +
			        self.TransformMatrix[0*4+2] * coord["z"] +
			        self.TransformMatrix[0*4+3] * 0

		acoord["y"] =   self.TransformMatrix[1*4+0] * coord["x"] +
			        self.TransformMatrix[1*4+1] * coord["y"] +
			        self.TransformMatrix[1*4+2] * coord["z"] +
			        self.TransformMatrix[1*4+3] * 0

		acoord["z"] = 4+self.TransformMatrix[2*4+0] * coord["x"] +
			        self.TransformMatrix[2*4+1] * coord["y"] +
			        self.TransformMatrix[2*4+2] * coord["z"] +
			        self.TransformMatrix[2*4+3] * 0

		resultcoord["x"] = 256+256*self:ReadCell(65512)*(acoord["x"])/(acoord["z"])
		resultcoord["y"] = 256+256*self:ReadCell(65512)*(acoord["y"])/(acoord["z"])
	end
	return resultcoord
end

function ENT:TransformColor(color)
	local tcolor = color
	tcolor.x = color.x
	tcolor.y = color.y
	tcolor.z = color.z
	tcolor.w = 255//color.w
	return tcolor
end

function ENT:Read2f(addr)
	local resultcoord = {}
	resultcoord.x = self:ReadCell(addr+0)
	resultcoord.y = self:ReadCell(addr+1)
	resultcoord.z = 0
	resultcoord.w = 0
	return resultcoord
end

function ENT:Read3f(addr)
	local resultcoord = {}
	resultcoord.x = self:ReadCell(addr+0)
	resultcoord.y = self:ReadCell(addr+1)
	resultcoord.z = self:ReadCell(addr+2)
	resultcoord.w = 0
	return resultcoord
end

function ENT:Read4f(addr)
	local resultcoord = {}
	resultcoord.x = self:ReadCell(addr+0)
	resultcoord.y = self:ReadCell(addr+1)
	resultcoord.z = self:ReadCell(addr+2)
	resultcoord.w = self:ReadCell(addr+3)
	return resultcoord
end

function ENT:ReadMatrix(addr)
	local resultmx = {}
	for i=0,15 do
		resultmx[i] = self:ReadCell(addr+i)
	end
	return resultmx
end

function ENT:WriteMatrix(addr,resultmx)
	for i=0,15 do
		self:WriteCell(addr+i,resultmx[i])
	end
end

function ENT:Write2f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
end

function ENT:Write3f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
	self:WriteCell(addr+2,coord.z)
end

function ENT:Write4f(addr,coord)
	self:WriteCell(addr+0,coord.x)
	self:WriteCell(addr+1,coord.y)
	self:WriteCell(addr+2,coord.z)
	self:WriteCell(addr+3,coord.w)
end

function ENT:ReadStr(addr)
	local str = ""
	local cnt = 0
	local chr = 255
	while ((cnt < 255) && (chr != 0)) do
		chr = self:ReadCell(addr+cnt)
		if ((chr > 0) && (chr < 256)) then
			str = str..string.char(chr)
		else
			if (chr != 0) then
				self:Interrupt(23,chr)
				return ""
			end
		end
		cnt = cnt + 1
		if (cnt > 512) then
			self:Interrupt(23,addr)
			return ""
		end
	end
	return str
end

function ENT:FontWrite(posaddr,text)
	local vertexbuf = {}
	vertexbuf["x"] = self:ReadCell(posaddr+0)
	vertexbuf["y"] = self:ReadCell(posaddr+1)
	vertexbuf = self:VertexTransform(vertexbuf)

	surface.CreateFont(self.FontNames[self.CurFont], self.CurFontSize, 800, true, false,
			   "WireGPU_"..self.FontNames[self.CurFont]..self.CurFontSize)
	draw.DrawText(text,"WireGPU_"..self.FontNames[self.CurFont]..self.CurFontSize,
		      vertexbuf["x"],vertexbuf["y"],Color(self.CurColor.x,self.CurColor.y,self.CurColor.z,255),0)
end