/******************************************************************************\
  Expression 2 Text Editor for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

if SERVER then
	AddCSLuaFile("texteditor.lua")
	return
end

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
	self.Rows = string.Explode("\n", string.Trim(text))
	self.Rows[#self.Rows + 1] = ""
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
		end
		
		// add empty row at end of file (TODO!)
		if self.Rows[#self.Rows] != "" then
			self.Rows[#self.Rows + 1] = ""
		end
	end
	
	if !text or text == "" then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
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
	end

	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }
	
	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false
	
	// add empty row at end of file (TODO!)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
	end
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
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


function EDITOR:_OnLoseFocus()
	if self.TabFocus then
		self:RequestFocus()
		self.TabFocus = nil
	end
end

function EDITOR:_OnTextChanged()
	local text = self.TextEntry:GetValue()
	self.TextEntry:SetText("")

	if input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL) then
		if !input.IsKeyDown(KEY_LALT) and !input.IsKeyDown(KEY_RALT) then
			return
		end
	end
	
	if text != "\n" then
		self:SetSelection(text)
	end
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

function EDITOR:_OnKeyCodeTyped(code)
	self.Blink = RealTime()
	
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	
	if control then
	
		if code == KEY_Z then
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
				self:SetSelection()
			end
		elseif code == KEY_C then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
			end
		elseif code == KEY_V then
			if self.clipboard then
				self:SetSelection(self.clipboard)
			end
		elseif code == KEY_UP then
			self.Scroll[1] = self.Scroll[1] - 1
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
		elseif code == KEY_DOWN then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif code == KEY_LEFT then
			self.Scroll[2] = self.Scroll[2] - 1
			if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
		elseif code == KEY_RIGHT then
			self.Scroll[2] = self.Scroll[2] + 1
		end
		
	else
	
		if code == KEY_ENTER then
			self:SetSelection("\n")
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
				if string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer and self.Caret[2] % 4 == 1 then
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
				if string.rep(" ", string.len(buffer)) == buffer and self.Caret[2] % 4 == 1 then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		elseif code == KEY_TAB then
			if self:HasSelection() then
				
			else 
				local count = (self.Caret[2] + 2) % 4 + 1
				self:SetSelection(string.rep(" ", count))
				self.TabFocus = true
			end
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
