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
ENT.firstConfig = true

wire_text_screen_lastCreated = nil

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
			
	self.clock = true
	self.currentLine = 0
	self.currentText = ""
	self.currentTextnum = 0
	--holds the last created screen (possible fuckup if two screens created by different players at almost the same time.)
	wire_text_screen_lastCreated = self.Entity
end

function ENT:Setup(textTable, chrPl, textJust, tRed, tGreen, tBlue, numInputs, defaultOn)
	self.textTable = textTable
	self.textTable[0] = ""
	self.maxLineLen = math.abs(chrPl)
	self.maxLines = math.abs(chrPl) / 2
	self.chrPerLine = math.abs(chrPl)
	self.numInputs = math.abs(numInputs)
	self.textJust = textJust
	self.tRed = tRed
	self.tGreen = tGreen
	self.tBlue = tBlue
	self.currentLine = 0
	valInputs = {}
	self.Val = {}
	for n=1, numInputs do
		table.insert(self.Val, 0)
		table.insert(valInputs, "Value "..n)
	end
	--inputTable = {"Clk", "Text", "String"}
	inputTable = {"Clk", "Text"}
	table.Add(inputTable, valInputs)
	self.Inputs = Wire_CreateInputs(self.Entity, inputTable)
	--Msg("defaulon = "..tostring(defaultOn).."\n")
	self.defaultOn = defaultOn
	
	--timer.Simple (0.5, sendUmConfig, self.Entity, chrPl, textJust, tRed, tGreen, tBlue)
	if !self.firstConfig then
		umTextScreenSendConfig(self.Entity, nil, true, chrPl, textJust, tRed, tGreen, tBlue)
	end
end

--sends config to client(s), includes colour, justification etc. can be used to send to a specific player (sendAll = false) or all players (sendAll = true)
function umTextScreenSendConfig(ent, player, sendAll, chrPl, textJust, tRed, tGreen, tBlue)
	local sendPlayer = player
	if sendAll then
		sendPlayer = RecipientFilter()
		sendPlayer:AddAllPlayers()
	end
	umsg.Start("umsgScreenConfig", sendPlayer)
		umsg.Entity(ent)
		umsg.Short(chrPl)
		umsg.Short(textJust)
		umsg.Short(tRed)
		umsg.Short(tGreen)
		umsg.Short(tBlue)
		umsg.Bool(true)
	umsg.End() 
	ent:WriteLine()
end

--Called by a client when the entity is created client side to request config data
function clientTextScreenConfigRequest(player, commandName, args)
	local ent = wire_text_screen_lastCreated
	umTextScreenSendConfig(ent, player, false, ent.chrPerLine, ent.textJust, ent.tRed, ent.tGreen, ent.tBlue)
	if (ent.defaultOn == 1) then	
		ent:TriggerInput("Clk", 1)	--make text on by default
		ent:TriggerInput("Text", 1)
		ent.defaultOn = 0
	end
end
concommand.Add("cTextScreenConfig", clientTextScreenConfigRequest)

--Sends text to clients for drawing
function umTextScreenSendText(ent, text)
	local allPlayers = RecipientFilter()
	allPlayers:AddAllPlayers()
	umsg.Start("umsgTextScreenSetText", allPlayers)
		umsg.Entity(ent)
		umsg.String(text)
	umsg.End()
end

function ENT:Use()
end

--wire input routine
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
	elseif (string.sub(iname, 1, 6) == "Value ") then
		self.Val[tonumber(string.sub(iname, 7, -1))] = math.abs(value)
		self:WriteLine()
	--elseif (iname == "String") then
	--	print ("string = '"..value.."'\n")
	end
end

--format text and send it to the client(s)
function ENT:WriteLine()
	if (self.clock && (self.currentLine <= self.maxLines)) then
		local compstring = ""
		local outString = ""
		local intoText = false
		local basestring = self.textTable[self.currentTextnum]
		if (!basestring) then return false end
		
		for k,inp in ipairs(self.Val) do
			local nString = string.format("%G", inp)
			--print ("ns = "..nString.."\n")
			basestring = string.gsub(basestring, "<"..k..">", nString)
		end
		
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
		--self:SetLine(self.currentLine, outString)
		umTextScreenSendText(self.Entity, outString)
	end
end

