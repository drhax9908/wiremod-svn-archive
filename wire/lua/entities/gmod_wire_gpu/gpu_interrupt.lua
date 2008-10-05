//INTERRUPTS TABLE
//Value | Meaning				
//---------------------------------------------------------------------
//2	| End of program
//3	| Division by zero
//4	| Unknown opcode
//5	| Internal processor error
//6	| Stack error (overflow/underflow)
//7	| Memory read/write fault
//13	| General processor fault
//15	| Address space violation
//------|---------------------------------------------------------------
//16	| Pants integrity violation
//17	|
//18	|
//19	|
//20	|
//21	|
//22	|
//23	| String read error
//24	|
//25	|
//----------------------------------------------------------------------

function ENT:InitializeErrors()
	self.ErrorText = {}
	self.ErrorText[2]  = "Unexpected end\n   of program"
	self.ErrorText[3]  = "Division by\n   zero"
	self.ErrorText[4]  = "Unknown opcode"
	self.ErrorText[5]  = "Internal\n   processor error"
	self.ErrorText[6]  = "Stack error\n   (overflow/underflow)"
	self.ErrorText[7]  = "Memory read/\n  write fault"
	self.ErrorText[13] = "General \n  processor fault"
	self.ErrorText[15] = "Address space \n  violation"
	self.ErrorText[23] = "String read \n  error"
end

function ENT:Interrupt(intnumber,intparam)
	if (self.INTR == 1) then return end
	self.INTR = 1
	self.HandleError = 1
	if (not self.EntryPoint[3]) then
		self:OutputError(intnumber,intparam)
	end
end