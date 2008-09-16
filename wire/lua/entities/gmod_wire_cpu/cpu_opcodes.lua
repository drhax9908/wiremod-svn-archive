function ENT:InitializeOpcodeNames()
	self.DecodeOpcode = {}

	//-----------------------------------------------------------------------------	
	self.DecodeOpcode["jne"]    = 1   //JNE X      : IP = X, IF CMPR ~= 0
	self.DecodeOpcode["jnz"]    = 1   //JNZ X      : IP = X, IF CMPR ~= 0
	self.DecodeOpcode["jmp"]    = 2   //JMP X      : IP = X
	self.DecodeOpcode["jg"]     = 3   //JG X       : IP = X, IF CMPR > 0
	self.DecodeOpcode["jnle"]   = 3   //JNLE X     : IP = X, IF !(CMPR <= 0)
	self.DecodeOpcode["jge"]    = 4   //JGE X      : IP = X, IF CMPR >= 0
	self.DecodeOpcode["jnl"]    = 4   //JNL X      : IP = X, IF !(CMPR < 0)
	self.DecodeOpcode["jl"]     = 5   //JL X       : IP = X, IF CMPR < 0
	self.DecodeOpcode["jnge"]   = 5   //JNGE X     : IP = X, IF !(CMPR >= 0)
	self.DecodeOpcode["jle"]    = 6   //JLE X      : IP = X, IF CMPR <= 0
	self.DecodeOpcode["jng"]    = 6   //JNG X      : IP = X, IF !(CMPR > 0)
	self.DecodeOpcode["je"]     = 7   //JE X       : IP = X, IF CMPR = 0
	self.DecodeOpcode["jz"]     = 7   //JZ X       : IP = X, IF CMPR = 0
	self.DecodeOpcode["cpuid"]  = 8   //CPUID X    : EAX -> CPUID[X]
	self.DecodeOpcode["push"]   = 9   //PUSH X     : WRITE(ESP+SS,X); ESP = ESP + 1
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["add"]    = 10  //ADD X,Y    : X = X + Y
	self.DecodeOpcode["sub"]    = 11  //SUB X,Y    : X = X - Y
	self.DecodeOpcode["mul"]    = 12  //MUL X,Y    : X = X * Y
	self.DecodeOpcode["div"]    = 13  //DIV X,Y    : X = X / Y
	self.DecodeOpcode["mov"]    = 14  //MOV X,Y    : X = y
	self.DecodeOpcode["cmp"]    = 15  //CMP X,Y    : CMPR = X - Y
	self.DecodeOpcode["rd"]     = 16  //RD X,Y     : X = MEMORY[Y]
	self.DecodeOpcode["wd"]     = 17  //WD X,Y     : MEMORY[X] = Y
	self.DecodeOpcode["min"]    = 18  //MIN X,Y    : MIN(X,Y)
	self.DecodeOpcode["max"]    = 19  //MAX X,Y    : MAX(X,Y)
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["inc"]    = 20  //INC X      : X = X + 1
	self.DecodeOpcode["dec"]    = 21  //DEC X      : X = X - 1
	self.DecodeOpcode["neg"]    = 22  //NEG X      : X = -X
	self.DecodeOpcode["rand"]   = 23  //RAND X     : X = Random(0..1)
	self.DecodeOpcode["loop"]   = 24  //LOOP X     : IF ECX ~= 0 THEN JUMP X    2.00
	self.DecodeOpcode["loopa"]  = 25  //LOOP X     : IF EAX ~= 0 THEN JUMP X    2.00
	self.DecodeOpcode["loopb"]  = 26  //LOOP X     : IF EBX ~= 0 THEN JUMP X    2.00
	self.DecodeOpcode["loopd"]  = 27  //LOOP X     : IF EDX ~= 0 THEN JUMP X    2.00
	self.DecodeOpcode["spg"]    = 28  //SRD X      : PAGE(X) = READ ONLY	    2.00
	self.DecodeOpcode["cpg"]    = 29  //CRD X      : PAGE(X) = READ AND WRITE   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["pop"]    = 30  //POP X      : X <- STACK
	self.DecodeOpcode["call"]   = 31  //CALL X     : IP -> STACK; IP = X
	self.DecodeOpcode["bnot"]   = 32  //BNOT X     : X = BINARY NOT X
	self.DecodeOpcode["fint"]   = 33  //FINT X     : X = FLOOR(X)
	self.DecodeOpcode["frnd"]   = 34  //FRND X     : X = ROUND(X)
	self.DecodeOpcode["ffrac"]  = 35  //FFRAC X    : X = X - FLOOR(X)
	self.DecodeOpcode["finv"]   = 36  //FINV X     : X = 1 / X
	self.DecodeOpcode["halt"]   = 37  //HALT X     : HALT UNTIL PORT[X]
	self.DecodeOpcode["fshl"]   = 38  //FSHL X     : X = X * 2		   2.00
	self.DecodeOpcode["fshr"]   = 39  //FSHR X     : X = X / 2		   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["ret"]    = 40  //RET        : IP <- STACK
	self.DecodeOpcode["iret"]   = 41  //IRET       : IP <- STACK 		   2.00
	self.DecodeOpcode["sti"]    = 42  //STI        : IF = TRUE		   2.00
	self.DecodeOpcode["cli"]    = 43  //CLI        : IF = FALSE		   2.00
	self.DecodeOpcode["stp"]    = 44  //STP        : PF = TRUE		   2.00
	self.DecodeOpcode["clp"]    = 45  //CLP        : PF = FALSE		   2.00
	//self.DecodeOpcode[""]     = 46  //RESERVED   :
	self.DecodeOpcode["retf"]   = 47  //RETF       : IP,CS <- STACK		   2.00
	self.DecodeOpcode["ste"]    = 48  //STE        : EF = TRUE		   4.00
	self.DecodeOpcode["cle"]    = 49  //CLE        : EF = FALSE		   4.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["and"]    = 50  //FAND X,Y   : X = X AND Y
	self.DecodeOpcode["or"]     = 51  //FOR X,Y    : X = X OR Y
	self.DecodeOpcode["xor"]    = 52  //FXOR X,Y   : X = X XOR Y
	self.DecodeOpcode["fsin"]   = 53  //FSIN X,Y   : X = SIN Y
	self.DecodeOpcode["fcos"]   = 54  //FCOS X,Y   : X = COS Y
	self.DecodeOpcode["ftan"]   = 55  //FTAN X,Y   : X = TAN Y
	self.DecodeOpcode["fasin"]  = 56  //FASIN X,Y  : X = ASIN Y
	self.DecodeOpcode["facos"]  = 57  //FACOS X,Y  : X = ACOS Y
	self.DecodeOpcode["fatan"]  = 58  //FATAN X,Y  : X = ATAN Y
	self.DecodeOpcode["mod"]    = 59  //MOD X,Y    : X = X MOD Y		   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["bit"]    = 60  //BIT X,Y    : CMPR = BIT(X,Y)	   2.00
	self.DecodeOpcode["sbit"]   = 61  //SBIT X,Y   : BIT(X,Y) = 1		   2.00
	self.DecodeOpcode["cbit"]   = 62  //CBIT X,Y   : BIT(X,Y) = 0		   2.00
	self.DecodeOpcode["tbit"]   = 63  //TBIT X,Y   : BIT(X,Y) = ~BIT(X,Y)	   2.00
	self.DecodeOpcode["band"]   = 64  //BAND X,Y   : X = X BAND Y		   2.00
	self.DecodeOpcode["bor"]    = 65  //BOR X,Y    : X = X BOR Y		   2.00
	self.DecodeOpcode["bxor"]   = 66  //BXOR X,Y   : X = X BXOR Y		   2.00
	self.DecodeOpcode["bshl"]   = 67  //BSHL X,Y   : X = X BSHL Y		   2.00
	self.DecodeOpcode["bshr"]   = 68  //BSHR X,Y   : X = X BSHR Y		   2.00
	self.DecodeOpcode["jmpf"]   = 69  //JMPF X,Y   : CS = Y; IP = X		   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["nmiint"] = 70  //NMIINT X   : NMIINTERRUPT(X);	   4.00
	self.DecodeOpcode["cne"]    = 71  //CNE X      : CALL(X), IF CMPR ~= 0	   2.00
	self.DecodeOpcode["cnz"]    = 71  //CNZ X      : CALL(X), IF CMPR ~= 0	   2.00
	//self.DecodeOpcode[""]     = 72  //RESERVED   :
	self.DecodeOpcode["cg"]     = 73  //CG X       : CALL(X), IF CMPR > 0	   2.00
	self.DecodeOpcode["cnle"]   = 73  //CNLE X     : CALL(X), IF !(CMPR <= 0)  2.00
	self.DecodeOpcode["cge"]    = 74  //CGE X      : CALL(X), IF CMPR >= 0	   2.00
	self.DecodeOpcode["cnl"]    = 74  //CNL X      : CALL(X), IF !(CMPR < 0)   2.00
	self.DecodeOpcode["cl"]     = 75  //CL X       : CALL(X), IF CMPR < 0	   2.00
	self.DecodeOpcode["cnge"]   = 75  //CNGE X     : CALL(X), IF !(CMPR >= 0)  2.00
	self.DecodeOpcode["cle"]    = 76  //CLE X      : CALL(X), IF CMPR <= 0	   2.00
	self.DecodeOpcode["cng"]    = 76  //CNG X      : CALL(X), IF !(CMPR > 0)   2.00
	self.DecodeOpcode["ce"]     = 77  //CE X       : CALL(X), IF CMPR = 0	   2.00
	self.DecodeOpcode["cz"]     = 77  //CZ X       : CALL(X), IF CMPR = 0	   2.00
	self.DecodeOpcode["mcopy"]  = 78  //MCOPY X    : X BYTES(ESI) -> EDI	   2.00
	self.DecodeOpcode["mxchg"]  = 79  //MXCHG X    : X BYTES(ESI) <> EDI	   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["fpwr"]   = 80  //FPWR X,Y   : X = X ^ Y		   2.00
	self.DecodeOpcode["xchg"]   = 81  //XCHG X,Y   : X,Y = Y,X		   2.00
	self.DecodeOpcode["flog"]   = 82  //FLOG X,Y   : X = LOG(Y)		   2.00
	self.DecodeOpcode["flog10"] = 83  //FLOG10 X,Y : X = LOG10(Y)		   2.00
	self.DecodeOpcode["in"]     = 84  //IN X,Y     : X = PORT[Y]		   2.00
	self.DecodeOpcode["out"]    = 85  //OUT X,Y    : PORT[X] = Y		   2.00
	self.DecodeOpcode["fabs"]   = 86  //FABS X,Y   : X = ABS(Y)		   2.00
	self.DecodeOpcode["fsgn"]   = 87  //FSGN X,Y   : X = SIGN(Y)		   2.00
	self.DecodeOpcode["fexp"]   = 88  //FEXP X,Y   : X = EXP(Y)		   2.00
	self.DecodeOpcode["callf"]  = 89  //CALLF X,Y  : CS = Y; CALL(X)	   2.00
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["fpi"]    = 90  //FPI X      : X = PI			   2.00
	self.DecodeOpcode["fe"]     = 91  //FE X       : X = E			   2.00
	self.DecodeOpcode["int"]    = 92  //INT X      : INTERRUPT(X)		   2.00
	self.DecodeOpcode["tpg"]    = 93  //TPG X      : CMPR = TEST PAGE(X)	   2.00
	self.DecodeOpcode["fceil"]  = 94  //FCEIL X    : X = CEIL(X)		   2.00
	self.DecodeOpcode["erpg"]   = 95  //ERPG X     : ERASE ROM PAGE(X)	   2.00
	self.DecodeOpcode["wrpg"]   = 96  //WRPG X     : WRITE ROM PAGE(X)	   2.00
	self.DecodeOpcode["rdpg"]   = 97  //RDPG X     : READ ROM PAGE(X)	   2.00
	self.DecodeOpcode["timer"]  = 98  //TIMER X    : X = TIMER		   2.00
	self.DecodeOpcode["lidtr"]  = 99  //LIDTR X    : IDTR = X		   2.00
	//self.DecodeOpcode[""]     = 100 //RESERVED
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["jner"]   = 101 //JNER X     : IP = IP+X, IF CMPR ~= 0
	self.DecodeOpcode["jnzr"]   = 101 //JNZR X     : IP = IP+X, IF CMPR ~= 0
	self.DecodeOpcode["jmpr"]   = 102 //JMPR X     : IP = IP+X
	self.DecodeOpcode["jgr"]    = 103 //JGR X      : IP = IP+X, IF CMPR > 0
	self.DecodeOpcode["jnler"]  = 103 //JNLER X    : IP = IP+X, IF !(CMPR <= 0)
	self.DecodeOpcode["jger"]   = 104 //JGER X     : IP = IP+X, IF CMPR >= 0
	self.DecodeOpcode["jnlr"]   = 104 //JNLR X     : IP = IP+X, IF !(CMPR < 0)
	self.DecodeOpcode["jlr"]    = 105 //JLR X      : IP = IP+X, IF CMPR < 0
	self.DecodeOpcode["jnger"]  = 105 //JNGER X    : IP = IP+X, IF !(CMPR >= 0)
	self.DecodeOpcode["jler"]   = 106 //JLER X     : IP = IP+X, IF CMPR <= 0
	self.DecodeOpcode["jngr"]   = 106 //JNGR X     : IP = IP+X, IF !(CMPR > 0)
	self.DecodeOpcode["jer"]    = 107 //JER X      : IP = IP+X, IF CMPR = 0
	self.DecodeOpcode["jzr"]    = 107 //JZR X      : IP = IP+X, IF CMPR = 0
	self.DecodeOpcode["lneg"]   = 108 //LNEG X     : X = LOGic NEGATE(X)	   3.00
	//self.DecodeOpcode[""]     = 109 //RESERVED
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["nmiret"] = 110 //NMIRET     : NMIRESTORE;		   2.00
	self.DecodeOpcode["idle"]   = 111 //IDLE       : FORCE_CPU_IDLE;	   4.00
	self.DecodeOpcode["nop"]    = 112 //NOP        : <does nothing>		   5.00
	//self.DecodeOpcode[""]     = 113 //RESERVED
	//-----------------------------------------------------------------------------
	self.DecodeOpcode["cpuget"] = 120 //CPUGET X,Y : X = CPU[Y]		   5.00
	self.DecodeOpcode["cpuset"] = 121 //CPUSET X,Y : CPU[X] = Y		   5.00
	self.DecodeOpcode["spp"]    = 122 //SPP X,Y    : PAGE[X].Y = 1		   5.00
	self.DecodeOpcode["cpp"]    = 123 //CPP X,Y    : PAGE[X].Y = 0		   5.00
	self.DecodeOpcode["srl"]    = 124 //SRL X,Y    : PAGE[X].RunLevel = Y	   5.00
	self.DecodeOpcode["grl"]    = 125 //GRL X,Y    : X = PAGE[Y].RunLevel	   5.00
	self.DecodeOpcode["lea"]    = 126 //LEA X,Y    : X = ADDRESS(Y)		   5.00
	//-----------------------------------------------------------------------------


	//---------------------------------------------------------------------------------------------------------------------
	// GPU Opcodes
	//---------------------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["drect_test"]     = 200 //DRECT_TEST		: Draw retarded stuff
	self.DecodeOpcode["dexit"]          = 201 //DEXIT		: End current frame execution
	self.DecodeOpcode["dclr"]           = 202 //DCLR		: Clear screen color to black
	self.DecodeOpcode["dvxflush"]       = 203 //DVXFLUSH		: Flush current vertex data
	self.DecodeOpcode["dclrtex"]        = 204 //DCLRTEX		: Clear background with texture
	//- Pipe controls and one-operand opcodes -----------------------------------------------------------------------------
	self.DecodeOpcode["dvxpipe"]        = 210 //DVXPIPE X		: Vertex pipe = X					[INT]
	self.DecodeOpcode["dcvxpipe"]       = 211 //DCVXPIPE X		: Coordinate vertex pipe = X				[INT]
	self.DecodeOpcode["denable"]        = 212 //DENABLE X		: Enable parameter X					[INT]
	self.DecodeOpcode["dclrscr"]        = 213 //DCLRSCR X		: Clear screen with color X				[COLOR]
	self.DecodeOpcode["dcolor"]         = 214 //DCOLOR X		: Set current color to X				[COLOR]
	self.DecodeOpcode["dtex"]           = 215 //DTEX X		: Set current texture to X				[TEXSLOT]
	self.DecodeOpcode["dfnt"]           = 216 //DFNT X		: Set current hw font to X				[FNTSLOT]
	self.DecodeOpcode["ddisable"]       = 217 //DDISABLE X		: Disable parameter X					[INT]
	self.DecodeOpcode["dtexslotclr"]    = 218 //DTEXSLOTCLR X	: Clear texslot X					[TEXSLOT]
	self.DecodeOpcode["dstrslotclr"]    = 219 //DSTRSLOTCLR X	: Clear strslot X					[STRSLOT]
	//- Rendering opcodes -------------------------------------------------------------------------------------------------
	self.DecodeOpcode["drect"]          = 220 //DRECT X,Y		: Draw rectangle (XY1,XY2)				[2F,2F]
	self.DecodeOpcode["dcircle"]        = 221 //DCIRCLE X,Y		: Draw circle (XY,R)					[2F,F]
	self.DecodeOpcode["dvxpoly"]        = 222 //DVXPOLY X,Y		: Draw solid 2d polygon (OFFSET,NUMVALUES)		[2F,INT]
	self.DecodeOpcode["dvxdata_2f"]     = 222
	self.DecodeOpcode["dvxtexpoly"]     = 223 //DVXTEXPOLY X,Y	: Draw textured 2d polygon (OFFSET,NUMVALUES)		[2F+UV,INT]
	self.DecodeOpcode["dvxdata_2f_tex"] = 223
	self.DecodeOpcode["dvxdata_3f"]     = 224 //DVXDATA_3F X,Y 	: Send array of 3d vertexes to vertex buffer		[3F,INT]
	self.DecodeOpcode["dvxdata_3f_tex"] = 225 //DVXDATA_3F_TEX X,Y 	: Send array of 3d vertexe +UV coordinates to vbuffer	[3F+UV,INT]
	self.DecodeOpcode["dwrite"]         = 226 //DWRITE X,Y		: Write X too coordinates Y				[STRSLOT,2F]
	self.DecodeOpcode["dtransform2f"]   = 227 //DTRANSFORM2F X,Y	: Transform Y, save to X				[2F,2F]
	self.DecodeOpcode["dtransform3f"]   = 228 //DTRANSFORM3F X,Y	: Transform Y, save to X				[3F,3F]
	self.DecodeOpcode["dwritef"]        = 229 //DWRITEF X,Y		: Write 1F X too coordinates Y 				[F,2F]
	//- Font & texture control opcodes ------------------------------------------------------------------------------------
	self.DecodeOpcode["dloadtex"]       = 230 //DLOADTEX X,Y	: Load texture named Y (STRSLOT) into texslot X		[TEXSLOT,STRSLOT]
	self.DecodeOpcode["dloadfnt"]       = 231 //DLOADFNT X,Y	: Load font by ID Y into hw slot X			[FNTSLOT,STRSLOT]
	self.DecodeOpcode["dstrslot"]       = 232 //DSTRSLOT X,Y	: Load null-pointed string Y into slot X		[STRSLOT,STRING]
	self.DecodeOpcode["dentrypoint"]    = 233 //DENTRYPOINT X,Y	: Set entry point X to address Y			[INT,INT]
	self.DecodeOpcode["dscrmode"]       = 234 //DSCRMODE X,Y	: Set screen width and height to (X,Y) (pipe 2)		[INT,INT]
	self.DecodeOpcode["dsetlight"]      = 235 //DSETLIGHT X,Y	: Set light X to Y (Y points to [pos,color])		[INT,3F+COLOR]
	//- Vector math -------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["vadd"]           = 240 //VADD X,Y		: X = X + Y						[MODEF,MODEF]
	self.DecodeOpcode["vsub"]           = 241 //VSUB X,Y		: X = X - Y						[MODEF,MODEF]
	self.DecodeOpcode["vmul"]           = 242 //VMUL X,Y		: X = X * SCALAR Y					[MODEF,MODEF]
	self.DecodeOpcode["vdot"]           = 243 //VDOT X,Y		: X = X . Y						[MODEF,MODEF]
	self.DecodeOpcode["vcross"]         = 244 //VCROSS X,Y		: X = X x Y						[MODEF,MODEF]
	self.DecodeOpcode["vmov"]           = 245 //VMOV X,Y		: X = Y							[MODEF,MODEF]
	self.DecodeOpcode["vnorm"]          = 246 //VNORM X,Y		: X = NORMALIZE(Y)					[MODEF,MODEF]
	self.DecodeOpcode["vcolornorm"]     = 247 //VCOLORNORM X,Y	: X = COLOR_NORMALIZE(Y)				[MODEF,MODEF]
	//- Matrix math -------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["madd"]           = 250 //X,Y										[MATRIX,MATRIX]
	self.DecodeOpcode["msub"]           = 251 //X,Y										[MATRIX,MATRIX]
	self.DecodeOpcode["mmul"]           = 252 //X,Y										[MATRIX,MATRIX]
	self.DecodeOpcode["mrot"]           = 253 //X -> ROT(Y)									[MATRIX,MATRIX]
	self.DecodeOpcode["mscale"]         = 254 //X -> SCALE(Y)								[MATRIX,MATRIX]
	self.DecodeOpcode["mperspective"]   = 255 //X -> PERSP(Y)								[MATRIX,MATRIX]
	self.DecodeOpcode["mtrans"]         = 256 //X -> TRANS(Y)								[MATRIX,MATRIX]
	self.DecodeOpcode["mlookat"]        = 257 //X -> LOOKAT(Y)								[MATRIX,MATRIX]
	//- Misc math ---------------------------------------------------------------------------------------------------------
	self.DecodeOpcode["mident"]         = 260 //MIDENT X		: Load identity matrix into X				[MATRIX]
	self.DecodeOpcode["mload"]          = 261 //MLOAD X		: Load matrix X into view matrix			[MATRIX]
	self.DecodeOpcode["mread"]          = 262 //MREAD X		: Write view matrix into matrix X			[MATRIX]
	self.DecodeOpcode["dt"]             = 263 //DT X		: X -> Frame DeltaTime					[F]
	self.DecodeOpcode["ddframe"]        = 264 //DDFRAME X		: Draw bordered frame					[-BORDERINFO-]
	//Bordered frames info:
	//X points to array of 2f's:
	//[PosX;PosY][Width;Height][HighlightPointer;ShadowPointer][FacePointer;BorderSize]
	//---------------------------------------------------------------------------------------------------------------------
end

function ENT:InitializeASMOpcodes()
	self.OpcodeCount = {}
	self.OpcodeCount[0] = 0
	for i=1,270 do
		if ((i >= 1) && (i <= 9)) then
			self.OpcodeCount[i] = 1
		elseif (i >= 10) && (i <= 19) then	
			self.OpcodeCount[i] = 2
		elseif (i >= 20) && (i <= 29) then
			self.OpcodeCount[i] = 1
		elseif (i >= 30) && (i <= 39) then
			self.OpcodeCount[i] = 1
		elseif (i >= 40) && (i <= 49) then
			self.OpcodeCount[i] = 0
		elseif (i >= 50) && (i <= 59) then
			self.OpcodeCount[i] = 2
		elseif (i >= 60) && (i <= 69) then
			self.OpcodeCount[i] = 2
		elseif (i >= 70) && (i <= 79) then
			self.OpcodeCount[i] = 1
		elseif (i >= 80) && (i <= 89) then
			self.OpcodeCount[i] = 2
		elseif (i >= 90) && (i <= 99) then
			self.OpcodeCount[i] = 1
		elseif (i >= 100) && (i <= 109) then
			self.OpcodeCount[i] = 1
		elseif (i >= 110) && (i <= 119) then
			self.OpcodeCount[i] = 0
		elseif (i >= 120) && (i <= 129) then
			self.OpcodeCount[i] = 1

		//GPU OPCODES
		elseif (i >= 200) && (i <= 209) then
			self.OpcodeCount[i] = 0
		elseif (i >= 210) && (i <= 219) then
			self.OpcodeCount[i] = 1
		elseif (i >= 220) && (i <= 229) then
			self.OpcodeCount[i] = 2
		elseif (i >= 230) && (i <= 249) then
			self.OpcodeCount[i] = 2
		elseif (i >= 240) && (i <= 249) then
			self.OpcodeCount[i] = 2
		elseif (i >= 250) && (i <= 259) then
			self.OpcodeCount[i] = 2
		elseif (i >= 260) && (i <= 269) then
			self.OpcodeCount[i] = 1
		end
	end
end

function ENT:InitializeOpcodeTable()
	self.OpcodeTable = {}

	self.OpcodeTable[0] = function (Param1,Param2)	//END
		self:Interrupt(2,0)
	end
	self.OpcodeTable[1] = function (Param1,Param2)	//JNE
		if (self.CMPR ~= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[2] = function (Param1,Param2)	//JMP
		self.IP = Param1
	end
	self.OpcodeTable[3] = function (Param1,Param2)	//JG
		if (self.CMPR > 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[4] = function (Param1,Param2)	//JGE
		if (self.CMPR >= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[5] = function (Param1,Param2)	//JL
		if (self.CMPR < 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[6] = function (Param1,Param2)	//JLE
		if (self.CMPR <= 0) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[7] = function (Param1,Param2)	//JE
		if (self.CMPR == 0) then
			self.IP = Param1
		end
	end
	//============================================================
	self.OpcodeTable[8] = function (Param1,Param2)	//CPUID
		if (Param1 == 0) then 			//CPU REVISION/VERSION
			self.EAX = self:CPUID_Version()	//= 3.00 BETA 2
		elseif (Param1 == 1) then		//AMOUNT OF RAM
			self.EAX = 65536		//= 64KB
		elseif (Param1 == 2) then		//TYPE (0 - ZCPU; 1 - ZGPU)
			self.EAX = 0			//= ZCPU
		end
	end
	//============================================================
	self.OpcodeTable[9] = function (Param1,Param2)	//PUSH
		self:Push(Param1)
	end
	//------------------------------------------------------------
	self.OpcodeTable[10] = function (Param1,Param2)	//ADD
		return Param1 + Param2
	end
	self.OpcodeTable[11] = function (Param1,Param2)	//SUB
		return Param1 - Param2
	end
	self.OpcodeTable[12] = function (Param1,Param2)	//MUL
		return Param1 * Param2
	end
	self.OpcodeTable[13] = function (Param1,Param2)	//DIV
		if (math.abs(Param2) < 1e-12) then
			self:Interrupt(3,0)
		else
			return Param1 / Param2
		end
	end
	self.OpcodeTable[14] = function (Param1,Param2) //MOV
		return Param2
	end
	self.OpcodeTable[15] = function (Param1,Param2)	//CMP
		self.CMPR = Param1 - Param2
	end
	self.OpcodeTable[16] = function (Param1,Param2)	//RD
		if (self.Memory[Param2]) then
			return self.Memory[Param2]
		else
			return 0
		end
	end
	self.OpcodeTable[17] = function (Param1,Param2)	//WD
		self.Memory[Param1] = Param2
	end
	self.OpcodeTable[18] = function (Param1,Param2)	//MIN
		if (Param2 < Param1) then
			return Param2
		else
			return Param1
		end
	end
	self.OpcodeTable[19] = function (Param1,Param2)	//MAX
		if (Param2 > Param1) then
			return Param2
		else
			return Param1
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[20] = function (Param1,Param2)	//INC
		return Param1 + 1		
	end
	self.OpcodeTable[21] = function (Param1,Param2)	//DEC
		return Param1 - 1
	end
	self.OpcodeTable[22] = function (Param1,Param2)	//NEG
		return -Param1
	end
	self.OpcodeTable[23] = function (Param1,Param2)	//RAND
		return math.random()
	end
	self.OpcodeTable[24] = function (Param1,Param2)	//LOOP
		if (self.ECX ~= 0) then
			self.IP = Param1
			self.ECX = self.ECX-1
		end
	end
	self.OpcodeTable[25] = function (Param1,Param2)	//LOOPA
		if (self.EAX ~= 0) then
			self.IP = Param1
			self.EAX = self.EAX-1
		end
	end
	self.OpcodeTable[26] = function (Param1,Param2)	//LOOPB
		if (self.EBX ~= 0) then
			self.IP = Param1
			self.EBX = self.EBX-1
		end
	end
	self.OpcodeTable[27] = function (Param1,Param2)	//LOOPD
		if (self.EDX ~= 0) then
			self.IP = Param1
			self.EDX = self.EDX-1
		end
	end
	self.OpcodeTable[28] = function (Param1,Param2)	//SPG
		local page = math.floor(Param1 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 0
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = self.CurrentPage.RunLevel
		else
			if (self.CurrentPage.RunLevel <= Page[page].RunLevel) then
				self.Page[page].Read  = 1
				self.Page[page].Write = 0
			else
				self:Interrupt(11,page)
			end
		end
	end
	self.OpcodeTable[29] = function (Param1,Param2)	//CPG
		local page = math.floor(Param1 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 1
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = self.CurrentPage.RunLevel
		else
			if (self.CurrentPage.RunLevel <= Page[page].RunLevel) then
				self.Page[page].Read  = 1
				self.Page[page].Write = 1
			else
				self:Interrupt(11,page)
			end
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[30] = function (Param1,Param2)	//POP
		return self:Pop()
	end
	self.OpcodeTable[31] = function (Param1,Param2)	//CALL
		if self:Push(self.IP) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[32] = function (Param1,Param2)	//BNOT
		return BinaryNot(Param1)
	end
	self.OpcodeTable[33] = function (Param1,Param2)	//FINT
		return math.floor(Param1)
	end
	self.OpcodeTable[34] = function (Param1,Param2)	//RND
		return math.Round(Param1)
	end
	self.OpcodeTable[35] = function (Param1,Param2)	//FLOOR
		return Param1 - math.floor(Param1)
	end
	self.OpcodeTable[36] = function (Param1,Param2)	//INV
		if (math.abs(Param1) < 1e-12) then
			self:Interrupt(3,0)
		else
			return 1 / Param1
		end
	end
	self.OpcodeTable[37] = function (Param1,Param2)	//HALT
		self.HaltPort = math.floor(Param1)
	end
	self.OpcodeTable[38] = function (Param1,Param2)	//FSHL
		return math.floor(Param1 * 2)
	end
	self.OpcodeTable[39] = function (Param1,Param2)	//FSHR
		return math.floor(Param1 / 2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[40] = function (Param1,Param2)	//RET
		local newIP = self:Pop()
		self.IP = newIP
	end
	self.OpcodeTable[41] = function (Param1,Param2)	//IRET
		if (self.EF == 1) then
			local newCS = self:Pop()
			self.CS = newCS
			local newIP = self:Pop()
			self.IP = newIP
		else
			self:Pop() //XEIP
			local newIP = self:Pop()
			self.IP = newIP
		end
		Wire_TriggerOutput(self.Entity, "Error", 0)
	end
	self.OpcodeTable[42] = function (Param1,Param2)	//STI
		self.NextIF = 1
	end
	self.OpcodeTable[43] = function (Param1,Param2)	//CLI
		self.IF = 0
	end
	self.OpcodeTable[44] = function (Param1,Param2)	//STP
		self.PF = 1
	end
	self.OpcodeTable[45] = function (Param1,Param2)	//CLP
		self.PF = 0
	end
	self.OpcodeTable[46] = function (Param1,Param2)	//STD
		self.Debug = true
	end
	self.OpcodeTable[47] = function (Param1,Param2)	//RETF
		local newIP = self:Pop()
		local newCS = self:Pop()

		self.IP = newIP
		if (newCS) then
			self.CS = newCS
		end
	end
	self.OpcodeTable[48] = function (Param1,Param2)	//STE
		self.EF = 1
	end
	self.OpcodeTable[49] = function (Param1,Param2)	//CLE
		self.EF = 0
	end
	//------------------------------------------------------------
	self.OpcodeTable[50] = function (Param1,Param2)	//AND
		if (Param1 > 0) && (Param2 > 0) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[51] = function (Param1,Param2)	//OR
		if (Param1 > 0) || (Param2 > 0) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[52] = function (Param1,Param2)	//XOR
		if ((Param1 > 0) && (Param2 <= 0)) ||
		   ((Param1 <= 0) && (Param2 > 0)) then
			return 1
		else
			return 0
		end
	end
	self.OpcodeTable[53] = function (Param1,Param2)	//FSIN
		return math.sin(Param2)
	end
	self.OpcodeTable[54] = function (Param1,Param2)	//FCOS
		return math.cos(Param2)
	end
	self.OpcodeTable[55] = function (Param1,Param2)	//FTAN
		return math.tan(Param2)
	end
	self.OpcodeTable[56] = function (Param1,Param2)	//FASIN
		return math.asin(Param2)
	end
	self.OpcodeTable[57] = function (Param1,Param2)	//FACOS
		return math.acos(Param2)
	end
	self.OpcodeTable[58] = function (Param1,Param2)	//FATAN
		return math.atan(Param2)
	end
	self.OpcodeTable[59] = function (Param1,Param2)	//MOD
		return math.fmod(Param1,Param2)
	end
	//------------------------------------------------------------
	self.OpcodeTable[60] = function (Param1,Param2)	//BIT
		local bits = self:IntegerToBinary(Param1)
		self.CMPR = bits[math.floor(math.Clamp(Param2,0,self.IPREC-1)+1)]
	end
	self.OpcodeTable[61] = function (Param1,Param2)	//SBIT
		local bits = self:IntegerToBinary(math.floor(Param1))
		bits[math.floor(math.Clamp(Param2,0,self.IPREC-1)+1)] = 1
		return self:BinaryToInteger(bits)
	end
	self.OpcodeTable[62] = function (Param1,Param2)	//CBIT
		local bits = IntegerToBinary(math.floor(Param1))
		bits[math.floor(math.Clamp(Param2,0,self.IPREC-1)+1)] = 0
		return self:BinaryToInteger(bits)
	end
	self.OpcodeTable[63] = function (Param1,Param2)	//TBIT
		local bits = self:IntegerToBinary(math.floor(Param1))
		bits[math.floor(math.Clamp(Param2,0,self.IPREC-1)+1)] = 1-bits[math.floor(math.Clamp(Param2,0,self.IPREC-1)+1)]
		return self:BinaryToInteger(bits)
	end
	self.OpcodeTable[64] = function(Param1,Param2) 	//BAND
		return self:BinaryAnd(Param1,Param2)
	end
	self.OpcodeTable[65] = function(Param1,Param2)	//BOR
		return self:BinaryOr(Param1,Param2)
	end
	self.OpcodeTable[66] = function(Param1,Param2) 	//BXOR
		return self:BinaryXor(Param1,Param2)
	end
	self.OpcodeTable[67] = function(Param1,Param2)	//BSHL
		return self:BinarySHL(Param1,Param2)
	end
	self.OpcodeTable[68] = function(Param1,Param2)	//BSHR
		return self:BinarySHR(Param1,Param2)
	end
	self.OpcodeTable[69] = function (Param1,Param2)	//JMPF
		self.CS = Param2
		self.IP = Param1
	end
	//------------------------------------------------------------
	self.OpcodeTable[70] = function (Param1,Param2)	//NMIINT
		self.NMIInterrupt(math.floor(Param1))	
	end
	self.OpcodeTable[71] = function (Param1,Param2)	//CNE
		if (self.CMPR ~= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[72] = function (Param1,Param2)	//CJMP
		if self:Push(self.IP) then
			self.IP = Param1
		end
	end
	self.OpcodeTable[73] = function (Param1,Param2)	//CG
		if (self.CMPR > 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[74] = function (Param1,Param2)	//CGE
		if (self.CMPR >= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[75] = function (Param1,Param2)	//CL
		if (self.CMPR < 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[76] = function (Param1,Param2)	//CLE
		if (self.CMPR <= 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[77] = function (Param1,Param2)	//CE
		if (self.CMPR == 0) then
			if self:Push(self.IP) then
				self.IP = Param1
			end
		end
	end
	self.OpcodeTable[78] = function (Param1,Param2)	//MCOPY
		if (Param1 == 0) then return end
		for i = 1,math.Clamp(Param1,0,8192) do
			local val
			val = self:ReadCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1])
			if (val == nil) then return end
			if (self:WriteCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2],val) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
	end
	self.OpcodeTable[79] = function (Param1,Param2)	//MXCHG
		if (Param1 == 0) then return end
		for i = 1,math.Clamp(Param1,0,8192) do
			local val
			val1 = self:ReadCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1])
			val2 = self:ReadCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2])
			if (val1 == nil) || (val2 == nil) then return end
			if (self:WriteCell(self.EDI+self[self.PrecompileData[self.XEIP].Segment2],val1) == false) || (self:WriteCell(self.ESI+self[self.PrecompileData[self.XEIP].Segment1],val2) == false) then return end
			self.EDI = self.EDI + 1
			self.ESI = self.ESI + 1
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[80] = function (Param1,Param2)	//FPWR
		return Param1^Param2
	end
	self.OpcodeTable[81] = function (Param1,Param2)	//XCHG
		self.PrecompileData[self.XEIP].WriteBack2(Param1)
		return Param2
	end
	self.OpcodeTable[82] = function (Param1,Param2)	//FLOG
		return math.log(Param2)
	end
	self.OpcodeTable[83] = function (Param1,Param2)	//FLOG10
		return math.log10(Param2)
	end
	self.OpcodeTable[84] = function (Param1,Param2)	//IN
		return self:ReadPort(Param2)
	end
	self.OpcodeTable[85] = function (Param1,Param2)	//OUT
		self:WritePort(Param1,Param2)
	end
	self.OpcodeTable[86] = function (Param1,Param2)	//FABS
		return math.abs(Param2)
	end
	self.OpcodeTable[87] = function (Param1,Param2)	//FSGN
		if (Param2 > 0) then
			return 1
		elseif (Param2 < 0) then
			return -1
		else
			return 0
		end
	end
	self.OpcodeTable[88] = function (Param1,Param2)	//FEXP
		return math.exp(Param2)
	end
	self.OpcodeTable[89] = function (Param1,Param2)	//CALLF
		if self:Push(self.CS) && self:Push(self.IP)  then
			self.IP = Param1
			self.CS = Param2
		end
	end
	//------------------------------------------------------------
	self.OpcodeTable[90] = function (Param1,Param2) //FPI
		return 3.141592653589793
	end
	self.OpcodeTable[91] = function (Param1,Param2) //FE
		return 2.718281828459045
	end
	self.OpcodeTable[92] = function (Param1,Param2)	//INT
		self:Interrupt(Param1,0)
	end
	self.OpcodeTable[93] = function (Param1,Param2)	//TPG
		local tadd = Param1*128
		self.CMPR = 0
		while (tadd < Param1*128+128) do
			local val = self:ReadCell(tadd)
			if (val == nil) then
				self.CMPR = tadd
				tadd = Param1*128+128
			end
			tadd = tadd + 1
		end
	end
	self.OpcodeTable[94] = function (Param1,Param2)	//FCEIL
		return math.ceil(Param1)
	end
	self.OpcodeTable[95] = function (Param1,Param2) //ERPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.ROMMemory[tadd] = 0
				tadd = tadd + 1
			end
		else
			self:Interrupt(12,0)
		end
	end
	self.OpcodeTable[96] = function (Param1,Param2)	//WRPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.ROMMemory[tadd] = self.Memory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12,0)
		end
	end
	self.OpcodeTable[97] = function (Param1,Param2) //RDPG
		if (Param1 >= 0) && (Param1 < 512) then
			local tadd = Param1*128
			while (tadd < Param1*128+128) do
				self.Memory[tadd] = self.ROMMemory[tadd]
				tadd = tadd + 1
			end
		else
			self:Interrupt(12,0)
		end
	end
	self.OpcodeTable[98] = function (Param1,Param2)	//TIMER
		return self.TIMER
	end
	self.OpcodeTable[99] = function (Param1,Param2)	//LIDTR
		self.IDTR = Param1
	end
	self.OpcodeTable[100] = function (Param1,Param2)	//STATESTORE
		self:WriteCell(Param1 + 00,self.IP)

		self:WriteCell(Param1 + 01,self.EAX)
		self:WriteCell(Param1 + 02,self.EBX)
		self:WriteCell(Param1 + 03,self.ECX)
		self:WriteCell(Param1 + 04,self.EDX)

		self:WriteCell(Param1 + 05,self.ESI)
		self:WriteCell(Param1 + 06,self.EDI)
		self:WriteCell(Param1 + 07,self.ESP)
		self:WriteCell(Param1 + 08,self.EBP)

		self:WriteCell(Param1 + 09,self.CS)
		self:WriteCell(Param1 + 10,self.SS)
		self:WriteCell(Param1 + 11,self.DS)
		self:WriteCell(Param1 + 12,self.ES)
		self:WriteCell(Param1 + 13,self.GS)
		self:WriteCell(Param1 + 14,self.FS)
	
		self:WriteCell(Param1 + 15,self.CMPR)
	end
	//------------------------------------------------------------
	self.OpcodeTable[101] = function (Param1,Param2)	//JNER
		if (self.CMPR ~= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[102] = function (Param1,Param2)	//JMPR
		self.IP = self.IP + Param1
	end
	self.OpcodeTable[103] = function (Param1,Param2)	//JGR
		if (self.CMPR > 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[104] = function (Param1,Param2)	//JGER
		if (self.CMPR >= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[105] = function (Param1,Param2)	//JLR
		if (self.CMPR < 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[106] = function (Param1,Param2)	//JLER
		if (self.CMPR <= 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[107] = function (Param1,Param2)	//JER
		if (self.CMPR == 0) then
			self.IP = self.IP + Param1
		end
	end
	self.OpcodeTable[108] = function (Param1,Param2)	//LNEG
		return 1-math.Clamp(Param1,0,1)
	end
	self.OpcodeTable[109] = function (Param1,Param2) 	//STATERESTORE
		//self.IP = 	self:ReadCell(Param1 + 00)
				self:ReadCell(Param1 + 00)

		self.EAX = 	self:ReadCell(Param1 + 01)
		self.EBX = 	self:ReadCell(Param1 + 02)
		self.ECX = 	self:ReadCell(Param1 + 03)
		self.EDX = 	self:ReadCell(Param1 + 04)

		self.ESI = 	self:ReadCell(Param1 + 05)
		self.EDI = 	self:ReadCell(Param1 + 06)
		self.ESP = 	self:ReadCell(Param1 + 07)
		self.EBP = 	self:ReadCell(Param1 + 08)

		self.CS	= 	self:ReadCell(Param1 + 09)
		self.SS = 	self:ReadCell(Param1 + 10)
		self.DS = 	self:ReadCell(Param1 + 11)
		self.ES = 	self:ReadCell(Param1 + 12)
		self.GS = 	self:ReadCell(Param1 + 13)
		self.FS = 	self:ReadCell(Param1 + 14)

		self.CMPR = 	self:ReadCell(Param1 + 15)
	end
	//------------------------------------------------------------
	self.OpcodeTable[110] = function (Param1,Param2)	//NMIRET
		local newval

		//Interrupt data:
		newval = self:Pop() //Interrupt return CS
		newval = self:Pop() //Interrupt return EIP

		newval = self:Pop() if (newval) then self.IP = newval else return end
		newval = self:Pop() if (newval) then self.CMPR = newval else return end

		newval = self:Pop() if (newval) then self.EAX = newval else return end
		newval = self:Pop() if (newval) then self.EBX = newval else return end
		newval = self:Pop() if (newval) then self.ECX = newval else return end
		newval = self:Pop() if (newval) then self.EDX = newval else return end
		newval = self:Pop() if (newval) then self.EBP = newval else return end
		newval = self:Pop() if (newval) then else return end //ESP - not now
		newval = self:Pop() if (newval) then self.ESI = newval else return end
		newval = self:Pop() if (newval) then self.EDI = newval else return end

		newval = self:Pop() if (newval) then self.CS = newval else return end
		newval = self:Pop() if (newval) then else return end //SS - not now
		newval = self:Pop() if (newval) then self.DS = newval else return end
		newval = self:Pop() if (newval) then self.FS = newval else return end
		newval = self:Pop() if (newval) then self.GS = newval else return end
		newval = self:Pop() if (newval) then self.ES = newval else return end
		newval = self:Pop() if (newval) then self.KS = newval else return end
		newval = self:Pop() if (newval) then self.LS = newval else return end
	end
	self.OpcodeTable[111] = function (Param1,Param2)	//IDLE
		self.Idle = true
	end
	self.OpcodeTable[112] = function (Param1,Param2)	//NOP
	end
	self.OpcodeTable[113] = function (Param1,Param2)	//RLADD
		self.EAX = self.LADD
	end
	//------------------------------------------------------------
	self.OpcodeTable[120] = function (Param1,Param2)	//CPUGET
		if (self.CPUVariable[Param2]) then
			return self[self.CPUVariable[Param2]]
		else
			return 0
		end
	end
	self.OpcodeTable[121] = function (Param1,Param2)	//CPUSET
		if (self.CPUVariable[Param1]) then
			self[self.CPUVariable[Param1]] = Param2
		end
	end
	self.OpcodeTable[122] = function (Param1,Param2)	//SPP
		local page = math.floor(Param1 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 1
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = self.CurrentPage.RunLevel
		end

		if (self.CurrentPage.RunLevel <= Page[page].RunLevel) then
			if (Param2 == 0) then
				self.Page[page].Read  = 1
			elseif (Param2 == 1) then
				self.Page[page].Write = 1
			elseif (Param2 == 2) then
				self.Page[page].Execute = 1
			elseif (Param2 == 3) then
				self.Page[page].RunLevel = 1
			end
		else
			self:Interrupt(11,page)
		end
		
	end
	self.OpcodeTable[123] = function (Param1,Param2)	//CPP
		local page = math.floor(Param1 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 1
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = self.CurrentPage.RunLevel
		end

		if (self.CurrentPage.RunLevel <= Page[page].RunLevel) then
			if (Param2 == 0) then
				self.Page[page].Read  = 0
			elseif (Param2 == 1) then
				self.Page[page].Write = 0
			elseif (Param2 == 2) then
				self.Page[page].Execute = 0
			elseif (Param2 == 3) then
				self.Page[page].RunLevel = 0
			end
		else
			self:Interrupt(11,page)
		end
		
	end
	self.OpcodeTable[124] = function (Param1,Param2)	//SRL
		local page = math.floor(Param1 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 1
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = Param2
		end

		if (self.CurrentPage.RunLevel <= Page[page].RunLevel) then
			self.Page[page].RunLevel = Param2
		else
			self:Interrupt(11,page)
		end
		
	end
	self.OpcodeTable[125] = function (Param1,Param2)	//GRL
		local page = math.floor(Param2 / 128)
		if (not self.Page[page]) then
			self.Page[page] = {}
			self.Page[page].Read  = 1
			self.Page[page].Write = 1
			self.Page[page].Execute = 1
			self.Page[page].RunLevel = self.CurrentPage.RunLevel
		end

		return self.Page[page].RunLevel
		
	end
	self.OpcodeTable[126] = function (Param1,Param2)	//LEA
		if (self.PrecompileData[self.XEIP].EffectiveAddress2) then
			return self.PrecompileData[self.XEIP].EffectiveAddress2()
		else
			return Param2
		end
	end
	//------------------------------------------------------------
end

function ENT:InitializeOpcodeRunlevels()
	self.OpcodeRunlevel = {}

	for i=0,130 do
		self.OpcodeRunLevel[i] = 1
	end

	//Priviliegied opcodes:
	self.OpcodeRunLevel[16]  = 0	//RD
	self.OpcodeRunLevel[17]  = 0	//WD
	self.OpcodeRunLevel[42]  = 0	//STI
	self.OpcodeRunLevel[43]  = 0	//CLI
	self.OpcodeRunLevel[44]  = 0	//STP
	self.OpcodeRunLevel[45]  = 0	//CLP
	self.OpcodeRunLevel[48]  = 0	//STE
	self.OpcodeRunLevel[49]  = 0	//CLE
	self.OpcodeRunLevel[70]  = 0	//NMIINT
	self.OpcodeRunLevel[95]  = 0	//ERPG
	self.OpcodeRunLevel[96]  = 0	//WRPG
	self.OpcodeRunLevel[97]  = 0	//RRPG
	self.OpcodeRunLevel[99]  = 0	//LIDTR
	self.OpcodeRunLevel[110] = 0	//NMIRET
	self.OpcodeRunLevel[111] = 0	//IDLE
	self.OpcodeRunLevel[121] = 0	//CPUSET
	//fixme: add cpp spp srl
end