/******************************************************************************\
  Expression 2 Text Editor for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

AddCSLuaFile("texteditor.lua")

if SERVER then return end

local EDITOR = {}

surface.CreateFont("Courier New", 16, 400, false, false, "Expression2EditorFont")
surface.CreateFont("Courier New", 16, 700, false, false, "Expression2EditorFontBold")

function EDITOR:Init()
	self:SetCursor("beam")

	surface.SetFont("Expression2EditorFont")
	self.FontWidth, self.FontHeight = surface.GetTextSize(" ")

	self.Rows = {""}
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Size = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}

	self.Blink = RealTime()

	self.ScrollBar = vgui.Create("DVScrollBar", self)
	self.ScrollBar:SetUp(1, 1)
	
	self.TextEntry = vgui.Create("TextEntry", self)
	self.TextEntry:SetMultiline(true)
	self.TextEntry:SetSize(0, 0)
	
	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus() end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged() end
	self.TextEntry.OnKeyCodeTyped = function (self, code) self.Parent:_OnKeyCodeTyped(code) end
	
	self.TextEntry.Parent = self
	
	self.LastClick = 0
end

function EDITOR:RequestFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:OnGetFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:CursorToCaret()
	local x, y = self:CursorPos()
	
	x = x - (self.FontWidth * 3 + 6)
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	
	local line = math.floor(y / self.FontHeight)
	local char = math.floor(x / self.FontWidth)
	
	line = line + self.Scroll[1]
	char = char + self.Scroll[2]
	
	if line > #self.Rows then line = #self.Rows end
	local length = string.len(self.Rows[line])
	if char > length + 1 then char = length + 1 end
	
	return { line, char }
end

function EDITOR:OnMousePressed(code)
	if code == MOUSE_LEFT then
		if((CurTime() - self.LastClick) < 1 and self.tmp and self:CursorToCaret()[1] == self.Caret[1] and self:CursorToCaret()[2] == self.Caret[2]) then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.tmp = false
			return
		end
		
		self.tmp = true
		
		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true
		
		self.Caret = self:CursorToCaret()
		if !input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT) then
			self.Start = self:CursorToCaret()
		end
	end
end

function EDITOR:OnMouseReleased(code)
	if !self.MouseDown then return end
	
	if code == MOUSE_LEFT then
		self.MouseDown = nil
		if(!self.tmp) then return end
		self.Caret = self:CursorToCaret()
	end
end

function EDITOR:SetText(text)
	self.Rows = string.Explode("\n", text)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
	end
	
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:GetValue()
	return string.Implode("\n", self.Rows)
end


function EDITOR:NextChar()
	if !self.char then return end
	
	self.str = self.str .. self.char
	self.pos = self.pos + 1
	
	if self.pos <= string.len(self.line) then
		self.char = string.sub(self.line, self.pos, self.pos)
	else
		self.char = nil
	end
end

function EDITOR:SyntaxColorLine(row)
	local cols = {}
	self.line = self.Rows[row]
	self.pos = 0
	self.char = ""
	self.str = ""

	colors = {
		["directive"] = { Color(240, 240, 160, 255), false},
		["number"] =    { Color(240, 160, 160, 255), false},
		["function"] =  { Color(160, 160, 240, 255), false},
		["notfound"] =  { Color(240,  96,  96, 255), false},
		["variable"] =  { Color(160, 240, 160, 255), false},
		["string"] =    { Color(128, 128, 128, 255), false},
		["ifelse"] =    { Color(160, 240, 240, 255), false},
		["operator"] =  { Color(224, 224, 224, 255), false},
		["comment"] =   { Color(128, 128, 128, 255), false},
	}
	
	self:NextChar()
	
	if self.char == "@" then
		cols = {{self.line, colors["directive"]}}
	else
		while self.char do
			token = ""
			self.str = ""
			
			while self.char and self.char == " " do self:NextChar() end
			if !self.char then break end
			
			if self.char >= "0" and self.char <= "9" then
				while self.char and (self.char >= "0" and self.char <= "9" or self.char == ".") do self:NextChar() end
				
				token = "number"
			elseif self.char >= "a" and self.char <= "z" then
				while self.char and (self.char >= "a" and self.char <= "z" or
									 self.char >= "A" and self.char <= "Z" or
									 self.char >= "0" and self.char <= "9" or self.char == "_") do self:NextChar() end
				
				local sstr = string.Trim(self.str)
				if sstr == "if" or sstr == "elseif" or sstr == "else" then
					token = "ifelse"
				elseif funclist[sstr] then
					token = "function"
				else
					token = "notfound"
				end
			elseif self.char >= "A" and self.char <= "Z" then
				while self.char and (self.char >= "a" and self.char <= "z" or
									 self.char >= "A" and self.char <= "Z" or
									 self.char >= "0" and self.char <= "9" or self.char == "_") do self:NextChar() end
				
				token = "variable"
			elseif self.char == "\"" then
				self:NextChar()
				while self.char and self.char != "\"" do
					if self.char == "\\" then self:NextChar() end
					self:NextChar()
				end
				self:NextChar()
				
				token = "string"
			elseif self.char == "#" then
				self:NextChar()
				while self.char do self:NextChar() end
				
				token = "comment"
			else
				self:NextChar()
				
				token = "operator"
			end
			
			color = colors[token]
			if #cols > 1 and color == cols[#cols][2] then
				cols[#cols][1] = cols[#cols][1] .. self.str
			else
				cols[#cols + 1] = {self.str, color}
			end
		end
	end
	
	return cols
end

function EDITOR:PaintLine(row)
	if row > #self.Rows then return end

	if !self.PaintRows[row] then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end
	
	local width, height = self.FontWidth, self.FontHeight
	
	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		surface.SetDrawColor(48, 48, 48, 255)
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end
	
	if self:HasSelection() then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]
		
		surface.SetDrawColor(0, 0, 160, 255)
		local length = string.len(self.Rows[row]) - self.Scroll[2] + 1
		
		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if char < 0 then char = 0 end
		if endchar < 0 then endchar = 0 end
		
		if row == line and line == endline then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif row == line then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif row == endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif row > line and row < endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end
	
	draw.SimpleText(tostring(row), "Expression2EditorFont", width * 3, (row - self.Scroll[1]) * height, Color(128, 128, 128, 255), TEXT_ALIGN_RIGHT)
	
	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if offset < 0 then
			if string.len(cell[1]) > -offset then
				line = string.sub(cell[1], -offset + 1)
				offset = string.len(line)
				
				if cell[2][2] then
					draw.SimpleText(line, "Expression2EditorFontBold", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				else
					draw.SimpleText(line, "Expression2EditorFont", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				end
			else
				offset = offset + string.len(cell[1])
			end
		else
			if cell[2][2] then
				draw.SimpleText(cell[1], "Expression2EditorFontBold", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			else
				draw.SimpleText(cell[1], "Expression2EditorFont", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			end
			
			offset = offset + string.len(cell[1])
		end
	end
	
	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		if (RealTime() - self.Blink) % 0.8 < 0.4 then
			if self.Caret[2] - self.Scroll[2] >= 0 then
				surface.SetDrawColor(240, 240, 240, 255)
				surface.DrawRect((self.Caret[2] - self.Scroll[2]) * width + width * 3 + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
			end
		end
	end
end

function EDITOR:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)
	
	self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:Paint()
	if !input.IsMouseDown(MOUSE_LEFT) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if !self.PaintRows then
		self.PaintRows = {}
	end

	if self.MouseDown then
		self.Caret = self:CursorToCaret()
	end
	
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())
	
	surface.SetDrawColor(32, 32, 32, 255)
	surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())
	
	self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)
	
	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end
	
	return true
end


function EDITOR:SetCaret(caret)
	self.Caret = self:CopyPosition(caret)
	self.Start = self:CopyPosition(caret)
	self:ScrollCaret()
end


function EDITOR:CopyPosition(caret)
	return { caret[1], caret[2] }
end

function EDITOR:MovePosition(caret, offset)
	local caret = { caret[1], caret[2] }

	if offset > 0 then
		while true do
			local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
			if offset < length then
				caret[2] = caret[2] + offset
				break
			elseif caret[1] == #self.Rows then
				caret[2] = caret[2] + length - 1
				break
			else
				offset = offset - length
				caret[1] = caret[1] + 1
				caret[2] = 1
			end
		end
	elseif offset < 0 then
		offset = -offset
		
		while true do
			if offset < caret[2] then
				caret[2] = caret[2] - offset
				break
			elseif caret[1] == 1 then
				caret[2] = 1
				break
			else
				offset = offset - caret[2]
				caret[1] = caret[1] - 1
				caret[2] = string.len(self.Rows[caret[1]]) + 1
			end
		end
	end
	
	return caret
end


function EDITOR:HasSelection()
	return self.Caret[1] != self.Start[1] || self.Caret[2] != self.Start[2]
end

function EDITOR:Selection()
	return { { self.Caret[1], self.Caret[2] }, { self.Start[1], self.Start[2] } }
end

function EDITOR:MakeSelection(selection)
	local start, stop = selection[1], selection[2]

	if start[1] < stop[1] or start[1] == stop[1] and start[2] < stop[2] then
		return start, stop
	else
		return stop, start
	end
end


function EDITOR:GetArea(selection)
	local start, stop = self:MakeSelection(selection)

	if start[1] == stop[1] then
		return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string.sub(self.Rows[start[1]], start[2])
		
		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end
		
		return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
end

function EDITOR:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)
	
	local buffer = self:GetArea(selection)
	
	if start[1] != stop[1] or start[2] != stop[2] then
		// clear selection
		self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false
		
		for i=start[1]+1,stop[1] do
			table.remove(self.Rows, start[1] + 1)
			table.remove(self.PaintRows, start[1] + 1)
			self.PaintRows = {} // TODO: fix for cache errors
		end
		
		// add empty row at end of file (TODO!)
		if self.Rows[#self.Rows] != "" then
			self.Rows[#self.Rows + 1] = ""
			self.PaintRows[#self.Rows + 1] = false
		end
	end
	
	if !text or text == "" then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
		
		self.PaintRows = {}
	
		self:OnTextChanged()
	
		if isredo then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		elseif isundo then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		else
			self.Redo = {}
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start) }
			return start
		end
	end
	
	// insert text
	local rows = string.Explode("\n", text)
	
	local remainder = string.sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false
	
	for i=2,#rows do
		table.insert(self.Rows, start[1] + i - 1, rows[i])
		table.insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end

	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }
	
	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false
	
	// add empty row at end of file (TODO!)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
		self.PaintRows[#self.Rows + 1] = false
		self.PaintRows = {} // TODO: fix for cache errors
	end
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
	self.PaintRows = {}
	
	self:OnTextChanged()
	
	if isredo then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	elseif isundo then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	else
		self.Redo = {}
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop) }
		return stop
	end
end


function EDITOR:GetSelection()
	return self:GetArea(self:Selection())
end

function EDITOR:SetSelection(text)
	self:SetCaret(self:SetArea(self:Selection(), text))
end

function EDITOR:OnTextChanged()
end

function EDITOR:_OnLoseFocus()
	if self.TabFocus then
		self:RequestFocus()
		self.TabFocus = nil
	end
end

function EDITOR:_OnTextChanged()
	local ctrlv = false
	local text = self.TextEntry:GetValue()
	self.TextEntry:SetText("")

	if (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and not (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
		-- ctrl+[shift+]key
		if input.IsKeyDown(KEY_V) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if text == "" then return end
	if not ctrlv then
		if text == "\n" then return end
		if text == "}" and GetConVarNumber('wire_expression2_autoindent') then
			local row = self.Rows[self.Caret[1]]
			if string.find("{" .. row .. "}", "^%b{}.*$") then 
				self.Rows[self.Caret[1]] = unindent(row)
			end
		end
	end
	
	self:SetSelection(text)
end

function EDITOR:OnMouseWheeled(delta)
	self.Scroll[1] = self.Scroll[1] - 4 * delta
	if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	if self.Scroll[1] > #self.Rows then self.Scroll[1] = #self.Rows end
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:OnShortcut()
end

function EDITOR:ScrollCaret()
	if self.Caret[1] - self.Scroll[1] < 2 then
		self.Scroll[1] = self.Caret[1] - 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end

	if self.Caret[1] - self.Scroll[1] > self.Size[1] - 2 then
		self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end
	
	if self.Caret[2] - self.Scroll[2] < 4 then
		self.Scroll[2] = self.Caret[2] - 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end
	
	if self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4 then
		self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end
	
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:FindFunction(self,reversed,searchterm,MatchCase)
	//local reversed = self:GetParent().Reversed
	//local searchterm = self:GetParent().String:GetValue()
	if searchterm=="" then return end
	//local oldself = self
	//self = self:GetParent():GetParent()
	if !MatchCase then
		searchterm = string.lower(searchterm)
	end
	local Num,Row = 1,1
	local find = false
	local currentrow = Row
	if !reversed then
		if self.Caret[1] < self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] < self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num+1
		end
		for i=Row, #self.Rows do
			local row = self.Rows[i]
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = i
			Num=1
			if find then break end
		end
	else
		if self.Caret[1] > self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] > self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num-1
		end
		searchterm = string.reverse(searchterm)
		Num=#self.Rows[Row] - Num +2
		for i=1, Row do
			local now = Row-i+1
			local row = self.Rows[now]
			row = string.reverse(row)
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = now
			Num=1
			if find then
				find = #self.Rows[now] - (find - 2) - #searchterm
				break
			end
		end
	end
	if find then
		self.Caret[1] = currentrow
		self.Caret[2] = find+#searchterm
		self.Start[1] = currentrow
		self.Start[2] = find
		self:ScrollCaret()
	/*
	else
		if self.eof && type(self.eof)=="Panel" && self.eof:IsValid() then
			self.eof:Close()
		end
		self.eof = vgui.Create("DFrame", oldself)
		local popup = self.eof
		popup:SetSize(200,100)
		popup:Center()
		popup:SetTitle("End of file")
		popup:MakePopup()
		popup.Text = vgui.Create("DLabel", popup)
		popup.Text:SetPos(20,20)
		popup.Text:SetSize(200,20)
		popup.Text:SetText("File end has been reached")
	//*/
	end
end

function EDITOR:ReplaceNextFunction(self,ToRep,RepWith,MatchCase)
	local oldcoords = {self.Caret[1],self.Caret[2],self.Start[1],self.Start[2]}
	if ToRep == "" then return end
	self:FindFunction(self,false,ToRep,MatchCase)
	if oldcoords[1]!=self.Caret[1] or oldcoords[2]!=self.Caret[2] or oldcoords[3]!=self.Start[1] or oldcoords[4]!=self.Start[2] then
		self:SetArea(self:Selection(),RepWith)
		self.Caret[2]=self.Caret[2]-(#ToRep-#RepWith)
		self:ScrollCaret()
	end
end

function EDITOR:ReplaceAllFunction(self,ToRep,RepWith,MatchCase)
	if ToRep == "" then return end
	if MatchCase then
		local text = string.gsub(self:GetValue(),ToRep,RepWith)
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},text)
		self:ScrollCaret()
		return
	end
	local originaltext = self:GetValue()
	local text = string.lower(originaltext)
	ToRep = string.lower(ToRep)
	local offset = #ToRep-#RepWith
	local totaloffset = 0
	local curpos = 1
	local chardiff = #ToRep
	local success = false
	repeat
		local find = string.find(text,ToRep,curpos,true)
		if find then
			success = true
			originaltext = string.sub(originaltext,1,find+totaloffset-1)..RepWith..string.sub(originaltext,find+totaloffset+#ToRep)
			totaloffset=totaloffset-offset
			curpos = find+chardiff
		end
	until !find
	if success then
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},originaltext)
		self:ScrollCaret()
	end
end

function EDITOR:FindWindow()
	// Does a find box already exist? Kill it
	if self.FW && type(self.FW)=="Panel" && self.FW:IsValid() then
		self.FW:Close()
	end

	// Create the frame, make it highlight the line and show cursor
	FW = vgui.Create("DFrame",self)
	self.FW = FW
	FW.OldThink = FW.Think
	FW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FW.OldClose = FW.Close
	FW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FW.Reversed = false
	FW:SetSize(250,100)
	FW:ShowCloseButton(true)
	FW:SetTitle("Search")
	FW:MakePopup()
	FW:Center()

	// Search Textbox
	FW.String = vgui.Create("DTextEntry",FW)
	FW.String:SetPos(10,30)
	FW.String:SetSize(230,20)
	FW.String:RequestFocus()
	FW.String.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			self:GetParent().Next.DoClick(self:GetParent().Next)
		end
	end

	// Forward Checkbox
	FW.Forw = vgui.Create("DCheckBox",FW)
	FW.Forw:SetPos(115,55)
	FW.Forw:SetValue(true)
	FW.Forw.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Back:SetValue(self:GetChecked())
			self:GetParent().Reversed = false
			self:SetValue(!self:GetChecked())
		end
	end

	// Backward Checkbox
	FW.Back = vgui.Create("DCheckBox",FW)
	FW.Back:SetPos(115,75)
	FW.Back:SetValue(false)
	FW.Back.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Forw:SetValue(self:GetChecked())
			self:GetParent().Reversed = true
			self:SetValue(!self:GetChecked())
		end
	end

	// Case Sensitive Checkbox
	FW.Case = vgui.Create("DCheckBoxLabel",FW)
	FW.Case:SetPos(10,75)
	FW.Case:SetValue(false)
	FW.Case:SetText("Case Sensitive")
	FW.Case:SizeToContents()

	// Checkbox Labels
	local Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Forw:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Forward")
	Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Back:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Backward")

	// Cancel Button
	FW.CloseB = vgui.Create("DButton",FW)
	FW.CloseB:SetText("Cancel")
	FW.CloseB:SetPos(190,75)
	FW.CloseB:SetSize(50,20)
	FW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end

	// Find Button
	FW.Next = vgui.Create("DButton",FW)
	FW.Next:SetText("Find")
	FW.Next:SetPos(190,52)
	FW.Next:SetSize(50,20)
	FW.Next.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:FindFunction(self,self.FW.Reversed,self.FW.String:GetValue(),self.FW.Case:GetChecked())
	end
end

function EDITOR:FindAndReplaceWindow()
	// Does a find box already exist? Kill it
	if self.FRW && type(self.FRW)=="Panel" && self.FRW:IsValid() then
		self.FRW:Close()
	end

	// Create the frame, make it highlight the line and show cursor
	FRW = vgui.Create("DFrame",self)
	self.FRW = FRW
	FRW.OldThink = FRW.Think
	FRW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FRW.OldClose = FRW.Close
	FRW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FRW:SetSize(250,142)
	FRW:ShowCloseButton(true)
	FRW:SetTitle("Replace")
	FRW:MakePopup()
	FRW:Center()

	// ToReplace Textentry
	FRW.ToRep = vgui.Create("DTextEntry",FRW)
	FRW.ToRep:SetPos(10,30)
	FRW.ToRep:SetSize(230,20)
	FRW.ToRep:RequestFocus()
	FRW.ToRep.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			//self:GetParent().Replace.DoClick(self:GetParent().Next)
			self:GetParent().RepWith:RequestFocus()
		end
	end

	// ReplaceWith Textentry
	FRW.RepWith = vgui.Create("DTextEntry",FRW)
	FRW.RepWith:SetPos(10,64)
	FRW.RepWith:SetSize(230,20)

	// Text Labels
	local Label = vgui.Create("DLabel",FRW)
	Label:SetPos(12,50)
	Label:SetText("Replace With:")
	Label:SizeToContents()

	// Case Sensitive Checkbox
	FRW.Case = vgui.Create("DCheckBoxLabel",FRW)
	FRW.Case:SetPos(10,117)
	FRW.Case:SetValue(false)
	FRW.Case:SetText("Case Sensitive")
	FRW.Case:SizeToContents()

	// Cancel Button
	FRW.CloseB = vgui.Create("DButton",FRW)
	FRW.CloseB:SetText("Cancel")
	FRW.CloseB:SetPos(190,115)
	FRW.CloseB:SetSize(50,20)
	FRW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end

	// Replace Button
	FRW.Replace = vgui.Create("DButton",FRW)
	FRW.Replace:SetText("Replace")
	FRW.Replace:SetPos(190,90)
	FRW.Replace:SetSize(50,21)
	FRW.Replace.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceNextFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
	end

	// Replace All Button
	FRW.ReplaceAll = vgui.Create("DButton",FRW)
	FRW.ReplaceAll:SetText("Replace All")
	FRW.ReplaceAll:SetPos(127,90)
	FRW.ReplaceAll:SetSize(60,21)
	FRW.ReplaceAll.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceAllFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
	end

end


-- removes the first 0-4 spaces from a string and returns it
function unindent(line)
	local i = line:find("[^ ]")
	if i == nil or i > 5 then i = 5 end
	return line:sub(i)
end

function EDITOR:_OnKeyCodeTyped(code)
	self.Blink = RealTime()
	
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	
	if control then
		if code == KEY_A then
			self.Caret = {#self.Rows, string.len(self.Rows[#self.Rows]) + 1}
			self.Start = {1, 1}
			self:ScrollCaret()
		elseif code == KEY_Z then
			if #self.Undo > 0 then
				local undo = self.Undo[#self.Undo]
				self.Undo[#self.Undo] = nil
				
				self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]))
			end
		elseif code == KEY_Y then
			if #self.Redo > 0 then
				local redo = self.Redo[#self.Redo]
				self.Redo[#self.Redo] = nil
				
				self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]))
			end
		elseif code == KEY_X then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		elseif code == KEY_C then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
			end
		elseif code == KEY_V then
			//if self.clipboard then
			//	self:SetSelection(self.clipboard)
			//end
		elseif code == KEY_F then
			self:FindWindow()
		elseif code == KEY_H then
			self:FindAndReplaceWindow()
		elseif code == KEY_UP then
			self.Scroll[1] = self.Scroll[1] - 1
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
		elseif code == KEY_DOWN then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif code == KEY_LEFT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:getWordStart(self:MovePosition(self.Caret, -2))
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:getWordEnd(self:MovePosition(self.Caret, 1))
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		--[[ -- old code that scrolls on ctrl-left/right:
		elseif code == KEY_LEFT then
			self.Scroll[2] = self.Scroll[2] - 1
			if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
		elseif code == KEY_RIGHT then
			self.Scroll[2] = self.Scroll[2] + 1
		]]
		elseif code == KEY_HOME then
			self.Caret[1] = 1
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			self.Caret[1] = #self.Rows
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		end
		
	else
	
		if code == KEY_ENTER then
			local row = self.Rows[self.Caret[1]]
			local diff = string.len(row) - string.len(string.TrimRight(string.reverse(row)))
			local tabs = string.rep("    ", math.floor(diff / 4))
			if GetConVarNumber('wire_expression2_autoindent') and (string.find("{" .. row .. "}", "^%b{}.*$") == nil) then tabs = tabs .. "    " end
			self:SetSelection("\n" .. tabs)
		elseif code == KEY_UP then
			if self.Caret[1] > 1 then
				self.Caret[1] = self.Caret[1] - 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_DOWN then
			if self.Caret[1] < #self.Rows then
				self.Caret[1] = self.Caret[1] + 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_LEFT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, -1)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, 1)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEUP then
			self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
			if self.Caret[1] < 1 then self.Caret[1] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
			if self.Caret[1] > #self.Rows then self.Caret[1] = #self.Rows end
			if self.Caret[1] == #self.Rows then self.Caret[2] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_HOME then
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			local length = string.len(self.Rows[self.Caret[1]])
			self.Caret[2] = length + 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_BACKSPACE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
				end
			end
		elseif code == KEY_DELETE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1 then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		end
	end
	
	if (!control and code == KEY_TAB) or (control and (code == KEY_I or code == KEY_O)) then
		if code == KEY_O then shift = not shift end
		if self:HasSelection() then
			-- TAB with a selection --
			-- remember scroll position
			local tab_scroll = self:CopyPosition(self.Scroll)
			
			-- normalize selection, so it spans whole lines
			local tab_start, tab_caret = self:MakeSelection(self:Selection())
			tab_start[2] = 1
			
			if (tab_caret[2] ~= 1) then
				tab_caret[1] = tab_caret[1] + 1
				tab_caret[2] = 1
			end
			
			-- remember selection
			self.Caret = self:CopyPosition(tab_caret)
			self.Start = self:CopyPosition(tab_start)
			-- (temporarily) adjust selection, so there is no empty line at its end.
			if (self.Caret[2] == 1) then
				self.Caret = self:MovePosition(self.Caret, -1)
			end
			if shift then
				-- shift-TAB with a selection --
				local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
				
				-- makes sure that the first line is outdented
				self:SetSelection(unindent(tmp))
			else
				-- plain TAB with a selection --
				self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
			end
			-- restore selection
			self.Caret = self:CopyPosition(tab_caret)
			self.Start = self:CopyPosition(tab_start)
			-- restore scroll position
			self.Scroll = self:CopyPosition(tab_scroll)
			-- trigger scroll bar update (TODO: find a better way)
			self:ScrollCaret()
			-- signal that we want our focus back after (since TAB normally switches focus)
			self.TabFocus = true
		else
			-- TAB without a selection --
			-- TODO: shift-tab without a selection
			local count = (self.Caret[2] + 2) % 4 + 1
			self:SetSelection(string.rep(" ", count))
			self.TabFocus = true
		end
	end
	
	if control then
		self:OnShortcut(code)
	end
end

// Auto-completion

function EDITOR:IsVarLine()
	local first = string.Explode(" ", self.Rows[self.Caret[1]])[1]
	if(first == "@inputs" or first == "@outputs" or first == "@persist") then return true end
	return false
end

function EDITOR:getWordStart(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=0,caret[2] do
		if(!line[caret[2]-i]) then return {caret[1],caret[2]-i+1} end
		if(line[caret[2]-i] >= "a" and line[caret[2]-i] <= "z" or line[caret[2]-i] >= "A" and line[caret[2]-i] <= "Z" or line[caret[2]-i] >= "0" and line[caret[2]-i] <= "9") then else return {caret[1],caret[2]-i+1} end
	end
	return {caret[1],1}
end

function EDITOR:getWordEnd(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=caret[2],#line do
		if(!line[i]) then return {caret[1],i} end
		if(line[i] >= "a" and line[i] <= "z" or line[i] >= "A" and line[i] <= "Z" or line[i] >= "0" and line[i] <= "9") then else return {caret[1],i} end
	end
	return {caret[1],#line+1}
end


/*
local optable = {"+","-","*","/","%","^","=","!",">","<","&","|","?",":",",","(",")","{","}","~"}
local auto = {}
function EDITOR:AutoComplete(char)
	if(char == " ") then
		auto = {}
		return char
	end
	if(char == "\n") then
		if(auto.full and auto.full != "") 
			
		auto = {}
		return char
	end
	if(!auto.word) then
		auto.word = ""		// current word
		auto.last = ""		// saved word (set at end)
		auto.full = ""		// the auto-completed word
		auto.var = ""		// the variable (can be used later)
		auto.posstart = getWordStart()
		auto.posend = getWordEnd()
		auto.func = false	// auto-completion on/off (auto is primarily used with functions)
	end
	auto.word = self:getWord()
	if(char == ":") then
		auto.func = true
		auto.var = auto.last
		auto.word = ""
		auto.full = ""
		return char
	end
	
	
	auto.last = auto.word
end
*/
vgui.Register("Expression2Editor", EDITOR, "Panel");
