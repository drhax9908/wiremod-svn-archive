function ENT:InitializeGPUOpcodeNames()
	self:InitializeOpcodeNames()

	//---------------------------------------------------------------------------------------------------------------------
	// GPU Opcodes
	//---------------------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["drect_test"]     = 200 //DRECT_TEST		: Draw retarded stuff
	self.DecodeOpcode["dexit"]          = 201 //DEXIT		: End current frame execution
	self.DecodeOpcode["dclr"]           = 202 //DCLR		: Clear screen color to black
	self.DecodeOpcode["dclrtex"]        = 203 //DCLRTEX		: Clear background with texture
	self.DecodeOpcode["dvxflush"]       = 204 //DVXFLUSH		: Flush current vertex buffer to screen
	self.DecodeOpcode["dvxclear"]       = 205 //DVXCLEAR		: Clear vertex buffer
	self.DecodeOpcode["derrorexit"]     = 206 //DERROREXIT		: Exit error handler
	self.DecodeOpcode["dsetbuf_spr"]    = 207 //DSETBUF_SPR		: Set frame buffer to sprite buffer
	self.DecodeOpcode["dsetbuf_fbo"]    = 208 //DSETBUF_FBO		: Set frame buffer to view buffer
	self.DecodeOpcode["dbindbuf_spr"]   = 209 //DBINDBUF_SPR	: Bind sprite buffer as texture
	//- Pipe controls and one-operand opcodes -----------------------------------------------------------------------------
	self.DecodeOpcode["dvxpipe"]        = 210 //DVXPIPE X		: Vertex pipe = X					[INT]
	self.DecodeOpcode["dcvxpipe"]       = 211 //DCVXPIPE X		: Coordinate vertex pipe = X				[INT]
	self.DecodeOpcode["denable"]        = 212 //DENABLE X		: Enable parameter X					[INT]
	self.DecodeOpcode["ddisable"]       = 213 //DDISABLE X		: Disable parameter X					[INT]
	self.DecodeOpcode["dclrscr"]        = 214 //DCLRSCR X		: Clear screen with color X				[COLOR]
	self.DecodeOpcode["dcolor"]         = 215 //DCOLOR X		: Set current color to X				[COLOR]
	self.DecodeOpcode["dbindtexture"]   = 216 //DBINDTEXTURE X	: Bind texture						[STRING]
	self.DecodeOpcode["dsetfont"]	    = 217 //DSETFONT X		: Set current font to X					[FONTID]
	self.DecodeOpcode["dsetsize"]	    = 218 //DSETSIZE X		: Set font size to X					[INT]
	self.DecodeOpcode["dmove"]	    = 219 //DMOVE X		: Set offset position to X				[2F]
	//- Rendering opcodes -------------------------------------------------------------------------------------------------
	self.DecodeOpcode["dvxdata_2f"]     = 220 //DVXDATA_2F X,Y	: Draw solid 2d polygon    (OFFSET,NUMVALUES)		[2F,INT]
	self.DecodeOpcode["dvxpoly"]        = 220 //
	self.DecodeOpcode["dvxdata_2f_tex"] = 221 //DVXDATA_2F_TEX X,Y	: Draw textured 2d polygon (OFFSET,NUMVALUES)		[2F+UV,INT]
	self.DecodeOpcode["dvxtexpoly"]     = 221 //
	self.DecodeOpcode["dvxdata_3f"]     = 222 //DVXDATA_3F X,Y	: Draw solid 3d polygon    (OFFSET,NUMVALUES)		[3F,INT]
	self.DecodeOpcode["dvxdata_3f_tex"] = 223 //DVXDATA_3F_TEX X,Y	: Draw textured 3d polygon (OFFSET,NUMVALUES)		[3F+UV,INT]
	self.DecodeOpcode["dvxdata_wf"]     = 224 //DVXDATA_WF X,Y	: Draw wireframe 3d polygon    (OFFSET,NUMVALUES)	[3F,INT]
	self.DecodeOpcode["drect"]          = 225 //DRECT X,Y		: Draw rectangle (XY1,XY2)				[2F,2F]
	self.DecodeOpcode["dcircle"]        = 226 //DCIRCLE X,Y		: Draw circle (XY,R)					[2F,F]
	self.DecodeOpcode["dline"]          = 227 //DLINE X,Y		: Draw line (XY1,XY2)					[2F,2F]
	self.DecodeOpcode["drectwh"]        = 228 //DRECTWH X,Y		: Draw rectangle (XY,WH)				[2F,2F]
	self.DecodeOpcode["dtrectwh"]       = 229 //DTRECTWH X,Y	: Draw textured rectangle (XY1,XY2)			[2F,2F]
	//- More rendering ----------------------------------------------------------------------------------------------------
	self.DecodeOpcode["dtransform2f"]   = 230 //DTRANSFORM2F X,Y	: Transform Y, save to X				[2F,2F]
	self.DecodeOpcode["dtransform3f"]   = 231 //DTRANSFORM3F X,Y	: Transform Y, save to X				[3F,3F]
	self.DecodeOpcode["dscrsize"]       = 232 //DSCRSIZE X,Y	: Set screen size					[F,F]
	self.DecodeOpcode["drotatescale"]   = 233 //DROTATESCALE X,Y	: Rotate and scale
	self.DecodeOpcode["dorectwh"]       = 234 //DORECTWH X,Y	: Draw outlined rectangle (XY1,XY2)			[2F,2F]
	self.DecodeOpcode["docircle"]       = 235 //DOCIRCLE X,Y	: Draw outlined circle (XY1,XY2)			[2F,2F]
//	self.DecodeOpcode[""]               = 236 //DOPOLY X,Y		: Draw outlined polygon					[2F,INT]
//	self.DecodeOpcode[""]               = 237 //DCSCREEN X,Y	: Draw console screen					[2F,CONSOLE_STRUCT]
//	self.DecodeOpcode[""]               = 238 //DDSCREEN X,Y	: Draw digital screen					[2F,DIGITAL_STRUCT]
//	self.DecodeOpcode[""]               = 239 //DPOLYLIST X,Y	: Draw polygon list					[2F,POLYLIST_STRUCT]
	//- Writing and lighting ----------------------------------------------------------------------------------------------
	self.DecodeOpcode["dwrite"]         = 240 //DWRITE X,Y		: Write Y to coordinates X				[2F,STRING]
	self.DecodeOpcode["dwritei"]        = 241 //DWRITEI X,Y		: Write INT Y to coordinates X 				[2F,I]
	self.DecodeOpcode["dwritef"]        = 242 //DWRITEF X,Y		: Write 1F Y to coordinates X 				[2F,F]
	self.DecodeOpcode["dentrypoint"]    = 243 //DENTRYPOINT X,Y	: Set entry point X to address Y			[INT,INT]
	self.DecodeOpcode["dsetlight"]      = 244 //DSETLIGHT X,Y	: Set light X to Y (Y points to [pos,color])		[INT,3F+COLOR]
	self.DecodeOpcode["dgetlight"]      = 245 //DGETLIGHT X,Y	: Get light Y to X (X points to [pos,color])		[INT,3F+COLOR]
	self.DecodeOpcode["dwritefmt"]      = 246 //DWRITEFMT X,Y	: Write formatted string Y to coordinates X		[2F,STRING+PARAMS]
	self.DecodeOpcode["dwritefix"]      = 247 //DWRITEFIX X,Y	: Write fixed value Y to coordinates X			[2F,F]
//	self.DecodeOpcode[""]               = 248 //DTEXTWIDTH X,Y	: Return text width of Y				[INT,STRING]
//	self.DecodeOpcode[""]               = 249 //DTEXTHEIGHT X,Y	: Return text height of Y				[INT,STRING]
	//---------------------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["dhaschanged"]    = 258 //DHASCHANGED X,Y	: CMPR = HasChanged(Memory[X...Y])			[INT,INT]
	self.DecodeOpcode["dloopxy"]        = 259 //DLOOPXY X,Y		: IF DX>0 {IP=X;IF CX>0{CX--}ELSE{DX--;CX=Y}}		[INT,INT]
	//- Misc --------------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["mload"]          = 271 //MLOAD X		: Load matrix X into view matrix			[MATRIX]
	self.DecodeOpcode["mread"]          = 272 //MREAD X		: Write view matrix into matrix X			[MATRIX]
	self.DecodeOpcode["dt"]             = 274 //DT X		: X -> Frame DeltaTime					[F]
	self.DecodeOpcode["dstrprecache"]   = 275 //DSTRPRECACHE X	: Read and cache string					[STRING]
	self.DecodeOpcode["dshade"]         = 276 //DSHADE X		: COLOR = COLOR * X					[F]
	self.DecodeOpcode["dsetwidth"]      = 277 //DSETWIDTH X		: LINEWIDTH = X						[F]
	//- Extra drawing -----------------------------------------------------------------------------------------------------
	self.DecodeOpcode["ddframe"]        = 280 //DDFRAME X		: Draw bordered frame					[BORDER_STRUCT]
	self.DecodeOpcode["ddbar"]          = 281 //DDBAR X		: Draw progress bar					[BAR_STRUCT]
	self.DecodeOpcode["ddgauge"]        = 282 //DDGAUGE X		: Draw gauge needle					[GAUGE_STRUCT]
	//- Sprites -----------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["dspritesize"]    = 290 //DSPRITESIZE X,Y	: Set sprite size in X,Y				[INT,INT]
	self.DecodeOpcode["dtosprite"]      = 291 //DTOSPRITE X,Y	: Copy region Y to sprite X				[INT,4F]
	self.DecodeOpcode["dfromsprite"]    = 292 //DFROMSPRITE X,Y	: Copy sprite Y	to region X				[4F,INT]
	self.DecodeOpcode["dsprite"]        = 293 //DSPRITE X,Y		: Draw sprite Y to position X				[2F,INT]
	self.DecodeOpcode["dmuldt"]         = 294 //DMULDT X,Y		: X = Y * dT						[2F,2F]
	//- 3D ----------------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["drotate"]        = 300 //DROTATE X		: Rotate(X)						[4F]
	self.DecodeOpcode["dtranslate"]     = 301 //DTRANSLATE X	: Translate(X)						[4F]
	self.DecodeOpcode["dscale"]         = 302 //DSCALE X		: Scale(X)						[4F]

	

	//Bordered frames info:
	//X points to array of 2f's:
	//[PosX;PosY][Width;Height][HighlightPointer;ShadowPointer][FacePointer;BorderSize]
	//---------------------------------------------------------------------------------------------------------------------
end

function ENT:InitializeGPUOpcodeTable()
	self:InitializeASMOpcodes()
	self:InitializeOpcodeTable()
					//ZCPU-only opcodes:
	self.OpcodeTable[16]  = nil	//RD
	self.OpcodeTable[17]  = nil	//WD
	self.OpcodeTable[28]  = nil	//SPG
	self.OpcodeTable[29]  = nil	//CPG
	self.OpcodeTable[37]  = nil	//HALT
	self.OpcodeTable[41]  = nil	//IRET
	self.OpcodeTable[42]  = nil	//STI
	self.OpcodeTable[43]  = nil	//CLI
	self.OpcodeTable[44]  = nil	//STP
	self.OpcodeTable[45]  = nil	//CLP
	self.OpcodeTable[46]  = nil	//STD
	self.OpcodeTable[48]  = nil	//STE
	self.OpcodeTable[49]  = nil	//CLE
	self.OpcodeTable[70]  = nil	//NMIINT
	self.OpcodeTable[95]  = nil	//ERPG
	self.OpcodeTable[96]  = nil	//WRPG
	self.OpcodeTable[97]  = nil	//RDPG
	self.OpcodeTable[99]  = nil	//LIDTR
	self.OpcodeTable[100] = nil	//STATESTORE
	self.OpcodeTable[109] = nil	//STATERESTORE
	self.OpcodeTable[110] = nil	//NMIRET
	self.OpcodeTable[111] = nil	//IDLE
	self.OpcodeTable[113] = nil	//RLADD
	self.OpcodeTable[122] = nil	//SPP
	self.OpcodeTable[123] = nil	//CPP
	self.OpcodeTable[124] = nil	//SRL
	self.OpcodeTable[125] = nil	//GRL

	//------------------------------------------------------------
	self.OpcodeTable[84] = function (Param1,Param2)	//IN
		return self:ReadCell(63488+Param2)
	end
	self.OpcodeTable[85] = function (Param1,Param2)	//OUT
		self:WriteCell(63488+Param1,Param2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[200] = function (Param1, Param2)	//DRECT_TEST
 		surface.SetDrawColor(math.abs(255*math.sin(self.TIMER)),math.abs(255*math.sin(self.TIMER*2)),math.abs(255*math.sin(self.TIMER*3)),255)
 		surface.DrawRect(math.abs(460*math.sin(self.TIMER/7)),math.abs(460*math.cos(self.TIMER/5)),32,32) 
	end
	self.OpcodeTable[201] = function (Param1, Param2)	//DEXIT
 		self.INTR = 1 //trigger suicide
	end
	self.OpcodeTable[202] = function (Param1, Param2)	//DCLR
 		surface.SetDrawColor(0,0,0,255)
 		surface.DrawRect(0,0,512,512) 
	end
	self.OpcodeTable[203] = function (Param1, Param2)	//DCLRTEX
 		surface.SetDrawColor(255,255,255,255)
 		surface.DrawTexturedRect(0,0,512,512) 
	end

	self.VertexSortFunc = function(a,b)
		local centera = {}
		local centerb = {}

		centera["x"] = (a[1].trans["x"] + a[2].trans["x"] + a[3].trans["x"]) / 3
		centera["y"] = (a[1].trans["y"] + a[2].trans["y"] + a[3].trans["y"]) / 3
		centera["z"] = (a[1].trans["z"] + a[2].trans["z"] + a[3].trans["z"]) / 3
	
		centerb["x"] = (b[1].trans["x"] + b[2].trans["x"] + b[3].trans["x"]) / 3
		centerb["y"] = (b[1].trans["y"] + b[2].trans["y"] + b[3].trans["y"]) / 3
		centerb["z"] = (b[1].trans["z"] + b[2].trans["z"] + b[3].trans["z"]) / 3
	
		local dista = math.sqrt(centera["x"]*centera["x"]+
				        centera["y"]*centera["y"]+
				        centera["z"]*centera["z"])
	
		local distb = math.sqrt(centerb["x"]*centerb["x"]+
				        centerb["y"]*centerb["y"]+
				        centerb["z"]*centerb["z"])
	
		return dista<distb
	end
	self.OpcodeTable[204] = function (Param1, Param2)	//DVXFLUSH
		if (self.VertexBufEnabled == true) then
			for i=0,self.VertexBufferCount-1 do
				if (self.VertexBuffer[i][1]) then self.VertexBuffer[i][1] = self:VertexTransform(self.VertexBuffer[i][1]) end
				if (self.VertexBuffer[i][2]) then self.VertexBuffer[i][2] = self:VertexTransform(self.VertexBuffer[i][2]) end
				if (self.VertexBuffer[i][3]) then self.VertexBuffer[i][3] = self:VertexTransform(self.VertexBuffer[i][3]) end
				if (self.VertexBuffer[i][4]) then self.VertexBuffer[i][4] = self:VertexTransform(self.VertexBuffer[i][4]) end
			end

			if self.VertexBufZSort == true then
				table.sort(self.VertexBuffer,self.VertexSortFunc) 
			end

			local newcolor = self.CurColor
			local newtexture = nil//self.CurrentTexture

			for i=0,self.VertexBufferCount-1 do
				if (self.VertexBuffer[i].SetColor) then
					newcolor = self.VertexBuffer[i].SetColor
				end
				if (self.VertexBuffer[i].SetTexture) then
					newtexture = self.VertexBuffer[i].SetTexture
				end

				local Cull = false

				//Msg("vertex "..i.."\n")

				if (self.VertexCulling == true) || (self.VertexLighting == true) then //fixme lua error on 2d vertexes
					local v1 = Vector(self.VertexBuffer[i][1].trans.x,self.VertexBuffer[i][1].trans.y,self.VertexBuffer[i][1].trans.z)
					local v2 = Vector(self.VertexBuffer[i][2].trans.x,self.VertexBuffer[i][2].trans.y,self.VertexBuffer[i][2].trans.z)
					local v3 = Vector(self.VertexBuffer[i][3].trans.x,self.VertexBuffer[i][3].trans.y,self.VertexBuffer[i][3].trans.z)
					local vpos = (v1+v2+v3) * 1/3
					local normal = (v1 - v2):Cross(v2 - v3)
					normal:Normalize()

					if (self.VertexCulling == true) then
						local dot = normal:Dot(Vector(0,0,1))
						if (dot > 0) then Cull = true end
					end

					if (Cull == false) then
						local diffusecolor = {}
						diffusecolor.x = 0
						diffusecolor.y = 0
						diffusecolor.z = 0
						diffusecolor.w = 255

						for i=0,7 do //apply lights
							if (self.Lights[i]) then
								local plight = self.Lights[i].pos
								local vlight = Vector(plight.x,plight.y,plight.z)
								local vvec = (vpos - vlight):Normalize()
								local brightness = self.Lights[i].col.w
								local diffuse = -normal:Dot(vlight)

								if (diffuse < 0) then diffuse = 0 end
								diffuse = diffuse * brightness
	
								diffusecolor.x = math.Clamp(diffusecolor.x + self.Lights[i].col.x * diffuse,0,255)
								diffusecolor.y = math.Clamp(diffusecolor.y + self.Lights[i].col.y * diffuse,0,255)
								diffusecolor.z = math.Clamp(diffusecolor.z + self.Lights[i].col.z * diffuse,0,255)
							end
						end

						newcolor = diffusecolor //FIXME: take in current color into account
					end
				end
				if (Cull == false) then//
					//if (newtexture) then
					//	self:BindTexture(newtexture)
					//else
					//	self:BindColor()
					//end
					//self:BindColor()
					surface.SetDrawColor(newcolor.x,newcolor.y,newcolor.z,newcolor.w)
					surface.DrawPoly(self.VertexBuffer[i])
				end
			end
	
	 		self.VertexBuffer = {}
			self.VertexBufferCount = 0
		end
	end
	self.OpcodeTable[205] = function (Param1, Param2)	//DVXCLEAR
		if self.VertexBufEnabled == true then
	 		self.VertexBuffer = {}
			self.VertexBufferCount = 0
		end
	end
	self.OpcodeTable[206] = function (Param1, Param2)	//DERROREXIT
		self.INTR = 1
		self.HandleError = 0
	end
	//------------------------------------------------------------
	self.OpcodeTable[210] = function (Param1, Param2)	//DVXPIPE
		self.VertexPipe = math.Clamp(Param1,0,5)
	end
	self.OpcodeTable[211] = function (Param1, Param2)	//DCVXPIPE
		self.CVertexPipe = math.Clamp(Param1,0,3)
	end
	self.OpcodeTable[212] = function (Param1, Param2)	//DENABLE
		if (Param1 == 0) then
			self.VertexBufEnabled = true
		elseif (Param1 == 1) then
			self.VertexBufZSort = true
		elseif (Param1 == 2) then
			self.VertexLighting = true
		elseif (Param1 == 3) then
			self.VertexCulling = true
		end
	end
	self.OpcodeTable[213] = function (Param1, Param2)	//DDISABLE
		if (Param1 == 0) then
			self.VertexBufEnabled = false
		elseif (Param1 == 1) then
			self.VertexBufZSort = false
		elseif (Param1 == 2) then
			self.VertexLighting = false
		elseif (Param1 == 3) then
			self.VertexCulling = false
		end

	end
	self.OpcodeTable[214] = function (Param1, Param2)	//DCLRSCR
		local tcolor = self:TransformColor(self:Read4f(Param1))
		self.CurColor = tcolor

 		surface.SetDrawColor(tcolor.x,tcolor.y,tcolor.z,tcolor.w)
 		surface.DrawRect(0,0,512,512)

		if (not self.VertexBuffer[self.VertexBufferCount]) then
			self.VertexBuffer[self.VertexBufferCount] = {}
		end
		self.VertexBuffer[self.VertexBufferCount].SetColor = tcolor
	end
	self.OpcodeTable[215] = function (Param1, Param2)	//DCOLOR
		local tcolor = self:TransformColor(self:Read4f(Param1))
		self.CurColor = tcolor

 		surface.SetDrawColor(tcolor.x,tcolor.y,tcolor.z,tcolor.w)
		if (not self.VertexBuffer[self.VertexBufferCount]) then
			self.VertexBuffer[self.VertexBufferCount] = {}
		end
		self.VertexBuffer[self.VertexBufferCount].SetColor = tcolor
	end
	self.OpcodeTable[216] = function (Param1, Param2)	//DBINDTEXTURE
		if (Param2 != 0) then
			local addr = Param2
			if (not self.StringCache[addr]) then
				self.StringCache[addr] = self:ReadStr(addr)
			end
			self.CurrentTexture = self.StringCache[addr]
		else
			self.CurrentTexture = self.ColorTexture
		end

		self:BindTexture(self.CurrentTexture)
		if (not self.VertexBuffer[self.VertexBufferCount]) then
			self.VertexBuffer[self.VertexBufferCount] = {}
		end
		self.VertexBuffer[self.VertexBufferCount].SetTexture = self.CurrentTexture
	end
	self.OpcodeTable[217] = function (Param1, Param2)	//DSETFONT
		self.CurFont = math.floor(math.Clamp(Param1,0,#self.FontNames-1))
	end
	self.OpcodeTable[218] = function (Param1, Param2)	//DSETSIZE
 		self.CurFontSize = math.floor(math.Clamp(Param1,4,200))
	end
	self.OpcodeTable[219] = function (Param1, Param2)	//DMOVE
		if (Param1 == 0) then
 			self:WriteCell(65484,0)
 			self:WriteCell(65483,0)
		else			
	 		self:WriteCell(65484,self:ReadCell(Param1+0))
	 		self:WriteCell(65483,self:ReadCell(Param1+1))
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[220] = function (Param1, Param2)	//DVXDATA_2F
		local vertexbuf = {} 
		for i=1,Param2 do vertexbuf[i] = {} end

		for i=1,Param2 do
			vertexbuf[i]["x"] = self:ReadCell(Param1+(i-1)*2+0)
			vertexbuf[i]["y"] = self:ReadCell(Param1+(i-1)*2+1)
			vertexbuf[i]["u"] = 0
			vertexbuf[i]["v"] = 0

			if (self.VertexBufEnabled == true) then
				self.VertexBuffer[self.VertexBufferCount] = vertexbuf
				self.VertexBufferCount = self.VertexBufferCount + 1
			else
				vertexbuf[i] = self:VertexTransform(vertexbuf[i])
			end
		end

		if (self.VertexBufEnabled ~= true) then
			surface.SetTexture(self.ColorTexture)
			surface.DrawPoly(vertexbuf)
		 	surface.SetTexture(self.CurrentTexture)
		end
	end
	self.OpcodeTable[221] = function (Param1, Param2)	//DVXDATA_2F_TEX
		local vertexbuf = {} 
		for i=1,Param2 do vertexbuf[i] = {} end

		for i=1,Param2 do
			vertexbuf[i]["x"] = self:ReadCell(Param1+(i-1)*4+0)
			vertexbuf[i]["y"] = self:ReadCell(Param1+(i-1)*4+1)
			vertexbuf[i]["u"] = self:ReadCell(Param1+(i-1)*4+2)
			vertexbuf[i]["v"] = self:ReadCell(Param1+(i-1)*4+3)

			if (self.VertexBufEnabled == true) then
				self.VertexBuffer[self.VertexBufferCount] = vertexbuf
				self.VertexBufferCount = self.VertexBufferCount + 1
			else
				vertexbuf[i] = self:VertexTransform(vertexbuf[i])
			end
		end
		if (self.VertexBufEnabled ~= true) then
			surface.DrawPoly(vertexbuf)
		end
	end
	self.OpcodeTable[222] = function (Param1, Param2)	//DVXDATA_3F
		local vertexbuf = {} 
		for i=1,3 do vertexbuf[i] = {} end

		for i=1,Param2 do
			for j=1,3 do vertexbuf[j] = {} end

			vertexbuf[1]["x"] = self:ReadCell(Param1+(i-1)*9+0)
			vertexbuf[1]["y"] = self:ReadCell(Param1+(i-1)*9+1)
			vertexbuf[1]["z"] = self:ReadCell(Param1+(i-1)*9+2)

			vertexbuf[2]["x"] = self:ReadCell(Param1+(i-1)*9+3)
			vertexbuf[2]["y"] = self:ReadCell(Param1+(i-1)*9+4)
			vertexbuf[2]["z"] = self:ReadCell(Param1+(i-1)*9+5)

			vertexbuf[3]["x"] = self:ReadCell(Param1+(i-1)*9+6)
			vertexbuf[3]["y"] = self:ReadCell(Param1+(i-1)*9+7)
			vertexbuf[3]["z"] = self:ReadCell(Param1+(i-1)*9+8)

			if (self.VertexBufEnabled == true) then
				self.VertexBuffer[self.VertexBufferCount] = vertexbuf
				self.VertexBufferCount = self.VertexBufferCount + 1
			else
				vertexbuf[1] = self:VertexTransform(vertexbuf[1])
				vertexbuf[2] = self:VertexTransform(vertexbuf[2])
				vertexbuf[3] = self:VertexTransform(vertexbuf[3])
			end
		end
		if (self.VertexBufEnabled ~= true) then
			surface.SetTexture(self.ColorTexture)
			surface.DrawPoly(vertexbuf)
		 	surface.SetTexture(self.CurrentTexture)
		end
	end
	self.OpcodeTable[223] = function (Param1, Param2)	//DVXDATA_3F_TEX
		local vertexbuf = {} 
		for i=1,3 do vertexbuf[i] = {} end

		for i=1,Param2 do
			vertexbuf[1]["x"] = self:ReadCell(Param1+(i-1)*15+0)
			vertexbuf[1]["y"] = self:ReadCell(Param1+(i-1)*15+1)
			vertexbuf[1]["z"] = self:ReadCell(Param1+(i-1)*15+2)

			vertexbuf[1]["u"] = self:ReadCell(Param1+(i-1)*15+3)
			vertexbuf[1]["v"] = self:ReadCell(Param1+(i-1)*15+4)

			vertexbuf[2]["x"] = self:ReadCell(Param1+(i-1)*15+5)
			vertexbuf[2]["y"] = self:ReadCell(Param1+(i-1)*15+6)
			vertexbuf[2]["z"] = self:ReadCell(Param1+(i-1)*15+7)

			vertexbuf[2]["u"] = self:ReadCell(Param1+(i-1)*15+8)
			vertexbuf[2]["v"] = self:ReadCell(Param1+(i-1)*15+9)

			vertexbuf[3]["x"] = self:ReadCell(Param1+(i-1)*15+10)
			vertexbuf[3]["y"] = self:ReadCell(Param1+(i-1)*15+11)
			vertexbuf[3]["z"] = self:ReadCell(Param1+(i-1)*15+12)

			vertexbuf[3]["u"] = self:ReadCell(Param1+(i-1)*15+13)
			vertexbuf[3]["v"] = self:ReadCell(Param1+(i-1)*15+14)

			if (self.VertexBufEnabled == true) then
				self.VertexBuffer[self.VertexBufferCount] = vertexbuf
				self.VertexBufferCount = self.VertexBufferCount + 1
			else
				vertexbuf[1] = self:VertexTransform(vertexbuf[1])
				vertexbuf[2] = self:VertexTransform(vertexbuf[2])
				vertexbuf[3] = self:VertexTransform(vertexbuf[3])
			end
		end
		if (self.VertexBufEnabled ~= true) then
			surface.DrawPoly(vertexbuf)
		end
	end
	self.OpcodeTable[225] = function (Param1, Param2)	//DRECT
		local vertexbuf = {} 
		for i=1,4 do vertexbuf[i] = {} end

		vertexbuf[1]["x"] = self:ReadCell(Param1+0)
		vertexbuf[1]["y"] = self:ReadCell(Param1+1)
		vertexbuf[1]["u"] = 0
		vertexbuf[1]["v"] = 0

		vertexbuf[2]["x"] = self:ReadCell(Param2+0)
		vertexbuf[2]["y"] = self:ReadCell(Param1+1)
		vertexbuf[2]["u"] = 1
		vertexbuf[2]["v"] = 0

		vertexbuf[3]["x"] = self:ReadCell(Param2+0)
		vertexbuf[3]["y"] = self:ReadCell(Param2+1)
		vertexbuf[3]["u"] = 1
		vertexbuf[3]["v"] = 1

		vertexbuf[4]["x"] = self:ReadCell(Param1+0)
		vertexbuf[4]["y"] = self:ReadCell(Param2+1)
		vertexbuf[4]["u"] = 0
		vertexbuf[4]["v"] = 1


		if (self.VertexBufEnabled == true) then
			self.VertexBuffer[self.VertexBufferCount] = vertexbuf
			self.VertexBufferCount = self.VertexBufferCount + 1
		else
			vertexbuf[1] = self:VertexTransform(vertexbuf[1])
			vertexbuf[2] = self:VertexTransform(vertexbuf[2])
			vertexbuf[3] = self:VertexTransform(vertexbuf[3])
			vertexbuf[4] = self:VertexTransform(vertexbuf[4])

 			surface.SetTexture(self.ColorTexture)
			surface.DrawPoly(vertexbuf)
		 	surface.SetTexture(self.CurrentTexture)
		end
	end
	self.OpcodeTable[226] = function (Param1, Param2)	//DCIRCLE
		local vertexbuf = {} 
		local numsides = math.Clamp(self:ReadCell(65485),3,64)
		local astart = self:ReadCell(65478)
		local aend = self:ReadCell(65477)
		local astep = (aend-astart) / numsides
		local c = self:Read2f(Param1)

		local r = Param2

		for i=1,3 do vertexbuf[i] = {} end

		for i=1,numsides do
			vertexbuf[1]["x"] = c.x + r*math.sin(astart+astep*(i+0))
			vertexbuf[1]["y"] = c.y + r*math.cos(astart+astep*(i+0))
			vertexbuf[1]["u"] = 0
			vertexbuf[1]["v"] = 0

			vertexbuf[2]["x"] = c.x
			vertexbuf[2]["y"] = c.y
			vertexbuf[2]["u"] = 0
			vertexbuf[2]["v"] = 0

			vertexbuf[3]["x"] = c.x + r*math.sin(astart+astep*(i+1))
			vertexbuf[3]["y"] = c.y + r*math.cos(astart+astep*(i+1))
			vertexbuf[3]["u"] = 0
			vertexbuf[3]["v"] = 0

			if (self.VertexBufEnabled == true) then	
				self.VertexBuffer[self.VertexBufferCount] = vertexbuf
				self.VertexBufferCount = self.VertexBufferCount + 1
			else
				vertexbuf[1] = self:VertexTransform(vertexbuf[1])
				vertexbuf[2] = self:VertexTransform(vertexbuf[2])
				vertexbuf[3] = self:VertexTransform(vertexbuf[3])

 				surface.SetTexture(self.ColorTexture)
				surface.DrawPoly(vertexbuf)
			 	surface.SetTexture(self.CurrentTexture)
			end
		end


	end
	self.OpcodeTable[227] = function (Param1, Param2)	//DLINE
		self:DrawLine(self:Read2f(Param1),self:Read2f(Param2))
	end
	self.OpcodeTable[228] = function (Param1, Param2)	//DRECTWH
		local vertexbuf = {} 
		for i=1,4 do vertexbuf[i] = {} end

		vertexbuf[1]["x"] = self:ReadCell(Param1+0)
		vertexbuf[1]["y"] = self:ReadCell(Param1+1)
		vertexbuf[1]["u"] = 0
		vertexbuf[1]["v"] = 0

		vertexbuf[2]["x"] = self:ReadCell(Param1+0)+self:ReadCell(Param2+0)
		vertexbuf[2]["y"] = self:ReadCell(Param1+1)
		vertexbuf[2]["u"] = 1
		vertexbuf[2]["v"] = 0

		vertexbuf[3]["x"] = self:ReadCell(Param1+0)+self:ReadCell(Param2+0)
		vertexbuf[3]["y"] = self:ReadCell(Param1+1)+self:ReadCell(Param2+1)
		vertexbuf[3]["u"] = 1
		vertexbuf[3]["v"] = 1

		vertexbuf[4]["x"] = self:ReadCell(Param1+0)
		vertexbuf[4]["y"] = self:ReadCell(Param1+1)+self:ReadCell(Param2+1)
		vertexbuf[4]["u"] = 0
		vertexbuf[4]["v"] = 1


		if (self.VertexBufEnabled == true) then
			self.VertexBuffer[self.VertexBufferCount] = vertexbuf
			self.VertexBufferCount = self.VertexBufferCount + 1
		else
			vertexbuf[1] = self:VertexTransform(vertexbuf[1])
			vertexbuf[2] = self:VertexTransform(vertexbuf[2])
			vertexbuf[3] = self:VertexTransform(vertexbuf[3])
			vertexbuf[4] = self:VertexTransform(vertexbuf[4])

 			surface.SetTexture(self.ColorTexture)
			surface.DrawPoly(vertexbuf)
		 	surface.SetTexture(self.CurrentTexture)
		end
	end
	self.OpcodeTable[229] = function (Param1, Param2)	//DTRECTWH
		local vertexbuf = {} 
		for i=1,4 do vertexbuf[i] = {} end

		vertexbuf[1]["x"] = self:ReadCell(Param1+0)
		vertexbuf[1]["y"] = self:ReadCell(Param1+1)
		vertexbuf[1]["u"] = 0
		vertexbuf[1]["v"] = 0

		vertexbuf[2]["x"] = self:ReadCell(Param2+0)
		vertexbuf[2]["y"] = self:ReadCell(Param1+1)
		vertexbuf[2]["u"] = 1
		vertexbuf[2]["v"] = 0

		vertexbuf[3]["x"] = self:ReadCell(Param2+0)
		vertexbuf[3]["y"] = self:ReadCell(Param2+1)
		vertexbuf[3]["u"] = 1
		vertexbuf[3]["v"] = 1

		vertexbuf[4]["x"] = self:ReadCell(Param1+0)
		vertexbuf[4]["y"] = self:ReadCell(Param2+1)
		vertexbuf[4]["u"] = 0
		vertexbuf[4]["v"] = 1


		if (self.VertexBufEnabled == true) then
			self.VertexBuffer[self.VertexBufferCount] = vertexbuf
			self.VertexBufferCount = self.VertexBufferCount + 1
		else
			vertexbuf[1] = self:VertexTransform(vertexbuf[1])
			vertexbuf[2] = self:VertexTransform(vertexbuf[2])
			vertexbuf[3] = self:VertexTransform(vertexbuf[3])
			vertexbuf[4] = self:VertexTransform(vertexbuf[4])

			surface.DrawPoly(vertexbuf)
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[230] = function (Param1, Param2)	//DTRANSFORM2F
		local tcoord = self:Read2f(Param2)
		tcoord = self:VertexTransform(tcoord)
		self:Write2f(Param1,tcoord)
	end
	self.OpcodeTable[231] = function (Param1, Param2)	//DTRANSFORM3F
		local tcoord = self:Read3f(Param1)
		tcoord = self:VertexTransform(tcoord)
		self:Write3f(Param1,tcoord)
	end
	self.OpcodeTable[232] = function (Param1, Param2)	//DSCRSIZE
		self:WriteCell(65515,Param1)
		self:WriteCell(65514,Param2)
	end
	self.OpcodeTable[233] = function (Param1, Param2)	//DROTATESCALE
		self:WriteCell(65482,Param1)
		self:WriteCell(65481,Param2)
	end
	self.OpcodeTable[234] = function (Param1, Param2)	//DORECTWH
		local vertexbuf = {} 
		for i=1,4 do vertexbuf[i] = {} end

		vertexbuf[1]["x"] = self:ReadCell(Param1+0)
		vertexbuf[1]["y"] = self:ReadCell(Param1+1)
		vertexbuf[2]["x"] = self:ReadCell(Param1+0)+self:ReadCell(Param2+0)
		vertexbuf[2]["y"] = self:ReadCell(Param1+1)
		vertexbuf[3]["x"] = self:ReadCell(Param1+0)+self:ReadCell(Param2+0)
		vertexbuf[3]["y"] = self:ReadCell(Param1+1)+self:ReadCell(Param2+1)
		vertexbuf[4]["x"] = self:ReadCell(Param1+0)
		vertexbuf[4]["y"] = self:ReadCell(Param1+1)+self:ReadCell(Param2+1)

		self:DrawLine(vertexbuf[1],vertexbuf[2])
		self:DrawLine(vertexbuf[2],vertexbuf[3])
		self:DrawLine(vertexbuf[3],vertexbuf[4])
		self:DrawLine(vertexbuf[4],vertexbuf[1])
	end
	//------------------------------------------------------------
	self.OpcodeTable[240] = function (Param1, Param2)	//DWRITE
		if (not self.StringCache[Param2]) then
			self.StringCache[Param2] = self:ReadStr(Param2)
		end
		local text = self.StringCache[Param2]

		self:FontWrite(Param1,text)
	end
	self.OpcodeTable[241] = function (Param1, Param2)	//DWRITEI
		self:FontWrite(Param1,math.floor(Param2))
	end
	self.OpcodeTable[242] = function (Param1, Param2)	//DWRITEF
		self:FontWrite(Param1,Param2)
	end
	self.OpcodeTable[243] = function (Param1, Param2)	//DENTRYPOINT
		self.EntryPoint[Param1] = Param2

	end
	self.OpcodeTable[244] = function (Param1, Param2)	//DSETLIGHT
		if (Param1 < 0) || (Param1 > 7) then
			self:Interrupt(19,0)
		else
			self.Lights[Param1] = {}
			self.Lights[Param1].pos = self:Read4f(Param2+0) //Pos
			self.Lights[Param1].col = self:Read4f(Param2+4) //Color
		end		
	end
	self.OpcodeTable[245] = function (Param1, Param2)	//DGETLIGHT
		if (Param1 < 0) || (Param1 > 7) then
			self:Interrupt(19,0)
		else
			if (self.Lights[Param1]) then
				self:Write3f(self.Lights[Param1]["pos"])
				self:Write3f(self.Lights[Param1]["col"])
			else
				self:Write3f(0)
				self:Write3f(0)
			end
		end		
	end
	self.OpcodeTable[246] = function (Param1, Param2)	//DWRITEFMT string.format(
		if (not self.StringCache[Param2]) then
			self.StringCache[Param2] = self:ReadStr(Param2)
		end
		local text = self.StringCache[Param2]
		local ptr = Param2 + string.len(text) + 2
		local ptr2 = self:ReadCell(65512)
		if (ptr2 ~= 0) then ptr = ptr2 end
		local finaltext = ""

		local inparam = false
		local lengthmod = nil

		while (text ~= "") do
			local chr = string.sub(text,1,1)
			text = string.sub(text,2,65536)

			if (inparam == false) then
				if (chr == "%") then
					inparam = true
				else
					finaltext = finaltext .. chr
				end
			else
				if (chr == ".") then
					chr = string.sub(text,1,1)
					text = string.sub(text,2,65536)

					if (tonumber(chr)) then
						lengthmod = tonumber(chr)
					end
				elseif (chr == "i") then
					if (lengthmod) then
						local digits = 0
						local num =  math.floor(self:ReadCell(ptr))
						local temp = num
						while (temp > 0) do
							digits = digits + 1
							temp = math.floor(temp / 10)
						end
						if (num == 0) then
							digits = 1
						end

						local fnum = tostring(num)
						while (digits < lengthmod) do
							digits = digits + 1
							fnum = "0"..fnum
						end

						finaltext = finaltext ..fnum
					else
						finaltext = finaltext .. math.floor(self:ReadCell(ptr))						
					end
					ptr = ptr + 1
					inparam = false
					lengthmod = nil
				elseif (chr == "f") then
					finaltext = finaltext .. self:ReadCell(ptr)
					ptr = ptr + 1
					inparam = false
					lengthmod = nil
				elseif (chr == "s") then
					local addr = self:ReadCell(ptr)
					if (not self.StringCache[addr]) then
						self.StringCache[addr] = self:ReadStr(addr)
					end
					local str = self.StringCache[addr]
					finaltext = finaltext .. str
					ptr = ptr + 1
					inparam = false
					lengthmod = nil
				elseif (chr == "t") then
					while (string.len(finaltext) % (lengthmod or 6) != 0) do
						finaltext = finaltext.." "
					end
					inparam = false
					lengthmod = nil
				elseif (chr == "%") then
					finaltext = finaltext .. "%"
					inparam = false
					lengthmod = nil
				end
			end
		end		

		self:FontWrite(Param1,finaltext)
	end
	self.OpcodeTable[247] = function (Param1, Param2)	//DWRITEFIX		
		local text = Param2
		if (Param2 == math.floor(Param2)) then
			text = text..".0"
		end

		self:FontWrite(Param1,text)
	end
	//------------------------------------------------------------
	self.OpcodeTable[271] = function (Param1, Param2) 	//MLOAD
		self.TransformMatrix = self:ReadMatrix(Param1)
	end
	self.OpcodeTable[272] = function (Param1, Param2) 	//MREAD
		self:WriteMatrix(Param1,self.TransformMatrix)
	end
	self.OpcodeTable[274] = function (Param1, Param2)	//DT
		self.Result = self.DeltaTime
	end
	self.OpcodeTable[275] = function (Param1, Param2)	//DSTRPRECACHE
		self.StringCache[Param1] = self:ReadStr(Param1)
	end
	self.OpcodeTable[276] = function (Param1, Param2)	//DSHADE
		self.CurColor.x = self.CurColor.x*Param1
		self.CurColor.y = self.CurColor.y*Param1
		self.CurColor.z = self.CurColor.z*Param1
		surface.SetDrawColor(self.CurColor.x,self.CurColor.y,self.CurColor.z,255)
	end
	self.OpcodeTable[277] = function (Param1, Param2)	//DSETWIDTH
		self:WriteCell(65476,Param1)
	end

	//------------------------------------------------------------
	self.OpcodeTable[280] = function (Param1, Param2)	//DDFRAME
		local v1 = self:Read2f(Param1+0) //x,y
		local v2 = self:Read2f(Param1+2) //w,h
		local v3 = self:Read2f(Param1+4) //c1,c2
		local v4 = self:Read2f(Param1+6) //c3,bordersize

		local cshadow = self:Read3f(v3.x)
		local chighlight = self:Read3f(v3.y)
		local cface = self:Read3f(v4.x)

		surface.SetDrawColor(cshadow.x,cshadow.y,cshadow.z,255)
		self:DrawRectangle(v4.y+v1.x     ,v4.y+v1.y,
				   v4.y+v2.x+v1.x,v4.y+v2.y+v1.y) //Shadow

		surface.SetDrawColor(chighlight.x,chighlight.y,chighlight.z,255)
		self:DrawRectangle(-v4.y+v1.x     ,-v4.y+v1.y,
				   -v4.y+v2.x+v1.x,-v4.y+v2.y+v1.y) //Highlight

		surface.SetDrawColor(cface.x,cface.y,cface.z,255)
		self:DrawRectangle(v1.x     ,v1.y,
				   v2.x+v1.x,v2.y+v1.y) //Face
	end
	//------------------------------------------------------------
	self.OpcodeTable[294] = function (Param1, Param2)	//DMULDT	
		return Param2*self.DeltaTime
	end
	//------------------------------------------------------------


	//bugs: missing fntslot clear function (not a bug: dont need one)
	//missing line drawing
	//missing circle line drawing
end
