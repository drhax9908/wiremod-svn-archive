--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Text Screen"
ENT.initOn = true

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, {"Clk", "Text", "Value A", "Value B", "Value C" })
	self.clock = false	--somehow make text on by default!!
	self.currentLine = 0
	self.currentText = ""
	self.currentTextnum = 0
	self.ValA = 0
	self.ValB = 0
	self.ValC = 0
	
	self:TriggerInput("Clk", 1)	--make text on by default

end

function ENT:Setup(textTable, chrPl, textJust, tRed, tGreen, tBlue)
	self.textTable = textTable
	self.maxLineLen = math.abs(chrPl)
	self.maxLines = math.abs(chrPl) / 2
	self.chrPerLine = math.abs(chrPl)

	local allPlayers = RecipientFilter()
	allPlayers:AddAllPlayers()
	umsg.Start("umsgScreenConfig", allPlayers)
		umsg.Entity(self.Entity)
		umsg.Short(chrPl)
		umsg.Short(textJust)
		umsg.Short(tRed)
		umsg.Short(tGreen)
		umsg.Short(tBlue)
		umsg.Bool(true)
	umsg.End() 
	self:WriteLine()

end

function ENT:Use()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Text") then
		self.currentTextnum = math.abs(value)
		self:WriteLine()
	elseif (iname == "Clk") then
		if (math.abs(value) > 0) then
			self.clock = true
			self:WriteLine()
		else
			self.clock = false
		end
	elseif (iname == "Value A") then
		self.ValA = math.abs(value)
		self:WriteLine()
	elseif (iname == "Value B") then
		self.ValB = math.abs(value)
		self:WriteLine()
	elseif (iname == "Value C") then
		self.ValC = math.abs(value)
		self:WriteLine()
	end
end

function ENT:WriteLine()
	if (self.clock && (self.currentLine <= self.maxLines)) then
		local compstring = ""
		local outString = ""
		local intoText = false
		local basestring = self.textTable[self.currentTextnum + 1]
		if (!basestring) then return false end
		local aval = string.format("%G", self.ValA)
		local bval = string.format("%G", self.ValB)
		local cval = string.format("%G", self.ValC)
		
		basestring = string.gsub(basestring, "<a>", aval)
		basestring = string.gsub(basestring, "<b>", bval)
		basestring = string.gsub(basestring, "<c>", cval)
		basestring = string.gsub(basestring, "<br>", "\n")
		
		compstring = basestring
		local outString = ""
		if (string.len(compstring) > self.maxLineLen) then
			local lastSpace = 0
			local lastBreak = 1
			local numLines = 1
			for chrNum = 1, string.len(compstring) do
				--Msg(string.format("insepecting chr num %d = %s (%d)\n", chrNum, string.sub(compstring, chrNum, chrNum), string.byte(string.sub(compstring, chrNum, chrNum))))
				--if (string.byte(string.sub(compstring, chrNum, chrNum)) == 92) && (string.byte(string.sub(compstring, chrNum + 1, chrNum + 1)) == 110) && (numLines <= self.maxLines) then
				if (string.byte(string.sub(compstring, chrNum, chrNum)) == 10) && (numLines <= self.maxLines) then
					outString = outString..string.Left(string.sub(compstring, lastBreak, chrNum), self.chrPerLine)
					--Msg(string.format("<br> partial out = '%s'\n", outString))
					lastBreak = chrNum + 1
					lastSpace = 0
					numLines = numLines + 1
				end
				if (string.sub(compstring, chrNum, chrNum) == " ") then
					lastSpace = chrNum
				end
				--Msg(string.format("lastspace = %d\n", lastSpace))
				if (chrNum >= lastBreak + self.maxLineLen) && (numLines <= self.maxLines) then	--if we've gone past a line length since the last break and line is still on screen
					--Msg("due for a break\n")
					if (lastSpace > 0) then
						--Msg("breaking\n")
						outString = outString..string.Left(string.sub(compstring, lastBreak, lastSpace), self.chrPerLine).."\n"
						--Msg(string.format("<exp> partial out = '%s'\n", outString))
						lastBreak = lastSpace + 1
						lastSpace = 0
						numLines = numLines + 1
					end
				end
			end
			if (numLines <= self.maxLines) then
				local foff = 0
				--if (lastSpace > 0) then foff = 1 end
				outString = outString..string.Left(string.sub(compstring, lastBreak + foff, string.len(compstring)), self.chrPerLine).."\n"
			end
		else
			outString = compstring
		end
		--Msg("setting line now ("..outString..")\n")
		self:SetLine(self.currentLine, outString)
	end
end

