
if SERVER then
	AddCSLuaFile("wire_expression2_editor.lua")
	return
end

local Editor = {}

// overwritten commands

function Editor:Init()
	self.Title = ""
	self.subTitle = ""
	self.LastClick = 0
	self.GuiClick = 0
	self.SimpleGUI = false
	self.Location = ""

	// colors
	self.colors = {}
	self.colors.col_FL = Color( 65, 105, 225, 255 ) //Royal Blue
	self.colors.col_FR = Color( 25, 25, 112, 255 ) //Midnight Blue
	self.colors.tmp_FL = Color( 65, 105, 225, 255 )
	self.colors.tmp_FR = Color( 25, 25, 112, 255 )
	self.colors.tmp_Dark = 255

	self.C = {}
	self.Components = {}

	surface.CreateFont( "default", 11, 300, false, false, "E2SmallFont" )
	self.logo = surface.GetTextureID("vgui/e2logo")

	self:InitComponents()
	
	local width, height = math.min(surface.ScreenWidth()-200, 780), math.min(surface.ScreenHeight()-200, 580)
	self:SetPos((surface.ScreenWidth() - width) / 2, (surface.ScreenHeight() - height) / 2)
	self:SetSize(width, height)
	
	//  This turns off the engine drawing 
	self:SetPaintBackgroundEnabled(false) 
 	self:SetPaintBorderEnabled(false) 
	
	self:SetV(false)
end

function Editor:Paint()
	local w,h = self:GetSize()
	if(self.SimpleGUI) then
		draw.RoundedBox(4, 0, 0, w, h, self.colors.col_FL)
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( 0, 22, w, 1 )
	else
		local dif = {(self.colors.col_FR.r-self.colors.col_FL.r)/w, (self.colors.col_FR.g-self.colors.col_FL.g)/w, (self.colors.col_FR.b-self.colors.col_FL.b)/w }
		draw.RoundedBox(4, 0, 0, 10, h, self.colors.col_FL)
		draw.RoundedBox(4, w-15, 0, 15, h, self.colors.col_FR)
	
		for i = 5 , w-9, 5 do
			surface.SetDrawColor(math.floor(self.colors.col_FL.r + dif[1]*i), math.floor(self.colors.col_FL.g + dif[2]*i), math.floor(self.colors.col_FL.b + dif[3]*i), self.colors.col_FL.a)
			surface.DrawRect( i, 0, 5, h )
		end
	end
	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	surface.SetDrawColor( 0, 0, 0, 150 )
 	surface.DrawRect( 0, 22, w, 1 )
	surface.SetDrawColor( 255, 255, 255, 255 )
	
	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	return true
end

function Editor:PaintOver()
	local w,h = self:GetSize()

	draw.RoundedBox( 4, 0, 0, 118, 21, self.colors.col_FL )
	surface.SetFont("DefaultBold")
	surface.SetTextColor( 255, 255, 255, 255 )
	surface.SetTextPos( 10, 6 )
	surface.DrawText(self.Title .. self.subTitle)
	if(self.E2) then
	surface.SetTexture(logo) 
	surface.SetDrawColor( 255, 255, 255, 128 )
	surface.DrawTexturedRect( w-148, h-158, 128, 128)
	end
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTextPos(0,0)
	surface.SetFont("Default")
	return true
end

function Editor:PerformLayout()
	local w,h = self:GetSize()

	for i=1, #self.Components do
		local c = self.Components[i]
		local c_x,c_y,c_w,c_h = c.x,c.y,c.w,c.h
		if(c.x<0) then c_x = w+c.x end
		if(c.y<0) then c_y = h+c.y end
		if(c.w<0) then c_w = w+c.w-c_x end
		if(c.h<0) then c_h = h+c.h-c_y end
		c.panel:SetPos(c_x,c_y)
		c.panel:SetSize(c_w,c_h)
	end
end

function Editor:OnMousePressed(mousecode)
	if(mousecode != 107) then return end // do nothing if mouseclick is other than left-click
	if(!self.pressed) then
		self.pressed 		= true 
		self.p_x, self.p_y 	= self:GetPos()
		self.p_w, self.p_h 	= self:GetSize()
		self.p_mx 			= gui.MouseX()
		self.p_my 			= gui.MouseY()
		self.p_mode 		= self:getMode()
		if(self.p_mode == "drag") then
			if(self.GuiClick>CurTime()-1) then 
				self:fullscreen() 
				self.pressed = false
				self.GuiClick = 0
			else
				self.GuiClick = CurTime()
			end
		end
	end
end

function Editor:OnMouseReleased(mousecode)
	if(mousecode != 107) then return end // do nothing if mouseclick is other than left-click
	self.pressed = false
end

function Editor:Think()
	if(self.fs) then return end
	if(self.pressed) then
		if(!input.IsMouseDown()) then	// needs this if you let go of the mouse outside the panel
			self.pressed = false
		end
		local movedX = gui.MouseX()-self.p_mx
		local movedY = gui.MouseY()-self.p_my
		if(self.p_mode == "drag") then
			local x = self.p_x + movedX
			local y = self.p_y + movedY
			if(x<10 and x>-10) then x = 0 end
			if(y<10 and y>-10) then y = 0 end
			if(x+self.p_w<surface.ScreenWidth()+10 and x+self.p_w>surface.ScreenWidth()-10) then x = surface.ScreenWidth()-self.p_w end
			if(y+self.p_h<surface.ScreenHeight()+10 and y+self.p_h>surface.ScreenHeight()-10) then y = surface.ScreenHeight()-self.p_h end
			self:SetPos(x,y)
		end
		if(self.p_mode == "sizeBR") then
			local w = self.p_w + movedX
			local h = self.p_h + movedY
			if(self.p_x+w<surface.ScreenWidth()+10 and self.p_x+w>surface.ScreenWidth()-10) then w = surface.ScreenWidth()-self.p_x end
			if(self.p_y+h<surface.ScreenHeight()+10 and self.p_y+h>surface.ScreenHeight()-10) then h = surface.ScreenHeight()-self.p_y end
			if(w<400) then w = 400 end
			if(h<400) then h = 400 end
			self:SetSize(w,h)
		end
		if(self.p_mode == "sizeR") then
			local w = self.p_w + movedX
			if(w<400) then w = 400 end
			self:SetWide(w)
		end
		if(self.p_mode == "sizeB") then
			local h = self.p_h + movedY
			if(h<400) then h = 400 end
			self:SetTall(h)
		end
	end
	if(!self.pressed) then
		local cursor = "arrow"
		local mode = self:getMode()
		if(mode == "sizeBR") then cursor = "sizenwse" end
		if(mode == "sizeR") then cursor = "sizewe" end
		if(mode == "sizeB") then cursor = "sizens" end
		if(cursor != self.cursor) then 
			self.cursor = cursor
			self:SetCursor(self.cursor)
		end
	end
	
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	
	if w < 400 then w = 400 end
	if h < 400 then h = 400 end
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	if x + w > surface.ScreenWidth() then x = surface.ScreenWidth() - w end
	if y + h > surface.ScreenHeight() then y = surface.ScreenHeight() - h end

	self:SetPos(x, y)
	self:SetSize(w, h)
end

// special functions

function Editor:fullscreen()
	if(self.fs) then
		self:SetPos(self.preX,self.preY)
		self:SetSize(self.preW,self.preH)
		self.fs = false
	else
		self.preX,self.preY = self:GetPos()
		self.preW,self.preH = self:GetSize()
		self:SetPos(0, 0)
		self:SetSize(surface.ScreenWidth(), surface.ScreenHeight())
		self.fs = true
	end
end

function Editor:getMode()
	local x, y 			= self:GetPos()
	local w, h 			= self:GetSize()
	local ix 			= gui.MouseX() - x
	local iy 			= gui.MouseY() - y
	
	if(ix<0 or ix>w or iy<0 or iy>h) then return end // if the mouse is outside the box
	if(iy<22) then 
		return "drag" 
	end
	if(iy>h-10) then
		if(ix>w-20) then return "sizeBR" end
	return "sizeB" end
	if(ix>w-10) then 
		if(iy>h-20) then return "sizeBR" end
	return "sizeR" end
end

function Editor:addComponent(panel,x,y,w,h)
	local t = #self.Components+1
	self.Components[t] = {}
	self.Components[t].panel = panel
	self.Components[t].x = x
	self.Components[t].y = y
	self.Components[t].w = w
	self.Components[t].h = h
	return self.Components[t]
end

// initialization commands

function Editor:InitComponents()
	self.Components = {}
	self.C = {}
	
	// addComponent( panel, x, y, w, h )     
	// if x, y, w, h is minus, it will stay relative to right or buttom border
	self.C['Close'] 	= self:addComponent(vgui.Create( "DSysButton", self )				, -22,   4,  18,  18)	// Close button
	self.C['Inf'] 		= self:addComponent(vgui.Create( "DSysButton", self )				, -42,   4,  18,  18)	// Info button
	self.C['Sav'] 		= self:addComponent(vgui.Create( "Button", self )					, 191,  30,  20,  20)	// Save button
	self.C['Dir'] 		= self:addComponent(vgui.Create( "Label", self )		     		, 220,  30, -70,  20)	// Directory line
	self.C['SaE'] 		= self:addComponent(vgui.Create( "Button", self )					, -70,  30, -10,  20)	// Save & Exit button
	self.C['Browser']	= self:addComponent(vgui.Create( "wire_expression2_browser", self )	,  10,  30, 157, -10)	// Expression browser
	self.C['Editor'] 	= self:addComponent(vgui.Create( "Expression2Editor", self )		, 170,  53, -10, -33)	// Expression editor
	self.C['Val']		= self:addComponent(vgui.Create( "Label", self )					, 170, -30, -10,  20)	// Validation line
	self.C['Btoggle']	= self:addComponent(vgui.Create( "Button", self )					, 170,  30,  20,  20)	// Toggle Browser being shown
	self.C['ConBut'] 	= self:addComponent(vgui.Create( "Button", self )					, -62,   4,  18,  18)	// Control panel open/close
	self.C['Control']	= self:addComponent(vgui.Create( "Panel", self )					,-210,  52, 200, 150)	// Control Panel
	self.C['Credit'] 	= self:addComponent(vgui.Create( "TextEntry", self )				,-160,  52, 150,  60)	// Credit box
	
	// extra component options
 	self.C['Close'].panel:SetType( "close" ) 
 	self.C['Close'].panel:SetDrawBorder( false ) 
 	self.C['Close'].panel:SetDrawBackground( false ) 
	self.C['Close'].panel.DoClick = function ( button ) self:Close() end 
	self.C['Credit'].panel:SetText("\t\tCREDITS\n\n\tEditor by: \tSyranide and Shandolum")
	self.C['Credit'].panel:SetMultiline(true)
	self.C['Credit'].panel:SetVisible(false)
	self.C['Inf'].panel:SetType( "question" ) 
 	self.C['Inf'].panel:SetDrawBorder( false ) 
 	self.C['Inf'].panel:SetDrawBackground( false ) 
	self.C['Inf'].panel.OnCursorEntered = function() self.C['Credit'].panel:SetVisible(true) end
	self.C['Inf'].panel.OnCursorExited = function() self.C['Credit'].panel:SetVisible(false) end
	self.C['Sav'].panel:SetText("")
	self.C['Sav'].panel.Icon = surface.GetTextureID( "vgui/spawnmenu/save" )
	self.C['Sav'].panel.Paint = function(button) 
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetTexture(button.Icon) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['Sav'].panel.DoClick = function( button ) self:SaveFile( chosenfile ) end
	self.C['SaE'].panel:SetText("")
	self.C['SaE'].panel.Font = "E2SmallFont"
	self.C['SaE'].panel.Paint = function(button) 
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetFont(button.Font)
		surface.SetTextPos( 3, 4 )
		surface.SetTextColor( 255, 255, 255, 255 )
		if(self.chip) then surface.DrawText("Upload & Exit")
		else surface.DrawText(" Save & Exit") end
	end
	self.C['SaE'].panel.DoClick = function( button ) self:SaveFile( chosenfile, true ) end
	self.C['Browser'].panel.OnFileClick = function(panel)
		if(panel.sDir and panel.sDir == panel.File.FileDir and CurTime()-LastClick < 1) then
			self:LoadFile(panel.sDir)
		else
			panel.sDir = panel.File.FileDir
			LastClick = CurTime()
		end
	end
	self.C['Browser'].panel:AddRightClick( self.C['Browser'].panel.filemenu, "Save To" , function() 
		self:SaveFile( self.C['Browser'].panel.File.FileDir)
	end )
	self.C['Editor'].panel.OnShortcut = function(_, code)
		if code == KEY_S then
			self:SaveFile(chosenfile)
			self:Validate()
		elseif code == KEY_SPACE then
			self:Validate(true)
		end
	end
	self.C['Editor'].panel:RequestFocus()
	self.C['Val'].panel:SetText( "   Click to validate..." )
	self.C['Val'].panel.OnMousePressed = function(panel) self:Validate(true) end
	self.C['Btoggle'].panel:SetText("<")
	self.C['Btoggle'].panel.Paint = function(button) 
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
	end
	self.C['Btoggle'].panel.DoClick = function(button)
		if(button.hide) then 
			button.hide = false
			button:SetText("<")
		else
			button.hide = true
			button:SetText(">")
		end
		button.toggle = true
	end
	self.C['Btoggle'].panel.anispeed = 10
	self.C['Btoggle'].panel.Think = function(button)
		if(!button.toggle) then return end
		if(button.hide and self.C['Btoggle'].x > 10) then 
			self.C['Btoggle'].x 	= self.C['Btoggle'].x-button.anispeed
			self.C['Sav'].x 		= self.C['Sav'].x-button.anispeed
			self.C['Dir'].x 		= self.C['Dir'].x-button.anispeed
			self.C['Editor'].x 		= self.C['Editor'].x-button.anispeed
			self.C['Val'].x 		= self.C['Val'].x-button.anispeed
			self.C['Browser'].w 	= self.C['Browser'].w-button.anispeed
		elseif(!button.hide and self.C['Btoggle'].x < 170) then
			self.C['Btoggle'].x 	= self.C['Btoggle'].x+button.anispeed
			self.C['Sav'].x 		= self.C['Sav'].x+button.anispeed
			self.C['Dir'].x 		= self.C['Dir'].x+button.anispeed
			self.C['Editor'].x 		= self.C['Editor'].x+button.anispeed
			self.C['Val'].x 		= self.C['Val'].x+button.anispeed
			self.C['Browser'].w 	= self.C['Browser'].w+button.anispeed
		end
		
		if(self.C['Browser'].panel:IsVisible() and self.C['Browser'].w <= 0) then self.C['Browser'].panel:SetVisible(false)
		elseif(!self.C['Browser'].panel:IsVisible() and self.C['Browser'].w > 0) then self.C['Browser'].panel:SetVisible(true) end
		self:InvalidateLayout()
		if(button.hide) then
			if(self.C['Btoggle'].x > 10 or self.C['Sav'].x > 30 or self.C['Dir'].x > 50 or self.C['Val'].x < 170 or self.C['Browser'].w > 0) then return end
			button.toggle = false
		else
			if(self.C['Btoggle'].x < 170 or self.C['Sav'].x < 190 or self.C['Dir'].x < 210 or self.C['Val'].x < 170 or self.C['Browser'].w < 150) then return end
			button.toggle = false
		end
	
	end
	self.C['ConBut'].panel.Icon = surface.GetTextureID( "gui/silkicons/wrench" )
	self.C['ConBut'].panel:SetText("")
	self.C['ConBut'].panel.Paint = function(button)
		local w,h = button:GetSize()
		surface.SetTexture(button.Icon) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['ConBut'].panel.DoClick = function() self.C['Control'].panel:SetVisible(!self.C['Control'].panel:IsVisible()) end
	self:InitControlPanel(self.C['Control'].panel)	//making it seperate for better overview
	self.C['Control'].panel:SetVisible(false)
	self:Validate()
end

function Editor:InitControlPanel(frame)
	
	local ColorPanel = vgui.Create( "Panel" , frame)
	ColorPanel:SetPos(0,0)
	ColorPanel:SetSize(200,130)
	ColorPanel.Paint = function(panel)
		local w,h = panel:GetSize()
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect(0, 0, w, h)
	end
 
	local SimpleColors = vgui.Create( "Label", ColorPanel)
	SimpleColors:SetPos(10,10)
	SimpleColors:SetSize(180,20)
	SimpleColors:SetText("Simple Colors = off")
	SimpleColors.OnMousePressed = function(check)
		if(self.SimpleGUI) then 
			self.SimpleGUI = false
			check:SetText("Simple Colors = off")
		else
			self.SimpleGUI = true
			check:SetText("Simple Colors = on")
		end
		self:InvalidateLayout()
	end
	local FLColor = vgui.Create( "DColorCircle" , ColorPanel)
	FLColor:SetPos(30,35)
	FLColor:SetSize(64,64)
	FLColor.SetFrameColor = function(panel) 
		self.colors.tmp_FL = panel:GetRGB()
		self:CalculateColor()
	end
	FLColor.TranslateValues = function(panel, x, y ) return self:TranslateValues(panel, x, y ) end
	local FRColor = vgui.Create( "DColorCircle" , ColorPanel)
	FRColor:SetPos(120,35)
	FRColor:SetSize(64,64)
	FRColor.SetFrameColor = function(panel) 
		self.colors.tmp_FR = panel:GetRGB()
		self:CalculateColor()
	end
	FRColor.TranslateValues = function(panel, x, y ) return self:TranslateValues(panel, x, y ) end
	local DarknessColor = vgui.Create( "DSlider" , ColorPanel)
	DarknessColor:SetPos(10,100)
	DarknessColor:SetSize(180,30)
	DarknessColor.TranslateValues = function(panel, x, y )
		self.colors.tmp_Dark = 255-math.floor(x*255)
		self:CalculateColor()
		return x, 0.5
	end
	DarknessColor:SetSlideX(0)
end

function Editor:CalculateColor()
	self.colors.col_FL.r = math.floor(self.colors.tmp_FL.r*self.colors.tmp_Dark/255)
	self.colors.col_FL.g = math.floor(self.colors.tmp_FL.g*self.colors.tmp_Dark/255)
	self.colors.col_FL.b = math.floor(self.colors.tmp_FL.b*self.colors.tmp_Dark/255)
	
	self.colors.col_FR.r = math.floor(self.colors.tmp_FR.r*self.colors.tmp_Dark/255)
	self.colors.col_FR.g = math.floor(self.colors.tmp_FR.g*self.colors.tmp_Dark/255)
	self.colors.col_FR.b = math.floor(self.colors.tmp_FR.b*self.colors.tmp_Dark/255)
	
	self:InvalidateLayout()
end

// used with color-circles
function Editor:TranslateValues(panel, x, y )
	x = x - 0.5
	y = y - 0.5
	local angle = math.atan2( x, y )
	local length = math.sqrt( x*x + y*y )
	length = math.Clamp( length, 0, 0.5 )
	x = 0.5 + math.sin( angle ) * length
	y = 0.5 + math.cos( angle ) * length
	panel:SetHue( math.Rad2Deg( angle ) + 270 )
	panel:SetSaturation( length * 2 )
	panel:SetRGB( HSVToColor( panel:GetHue(), panel:GetSaturation(), 1 ) )
	panel:SetFrameColor()
	return x, y
end
// options

function Editor:NewScript()
	self:ChosenFile()
	self:SetCode("@name \n@inputs \n@outputs \n@persist \n\n")
end

function Editor:Validate(gotoerror)
	if(!self.E2) then return end
	self:ExtractName()
	local errors = wire_expression_validate(self:GetCode())
	if(!errors) then
		self.C['Val'].panel:SetBGColor(0, 128, 0, 180)
		self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
		self.C['Val'].panel:SetText( "   Validation successful" )
	return true end
	if(gotoerror) then
		local parts = string.Explode(" ", errors)
		if(parts[#parts - 4] == "at" and parts[#parts - 3] == "line" and parts[#parts - 1] == "char") then
			self.C['Editor'].panel:SetCaret({tonumber(string.sub(parts[#parts - 2], 1, -2)), tonumber(parts[#parts])})
		end
	end
	self.C['Val'].panel:SetBGColor(128, 0, 0, 180)
	self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
	self.C['Val'].panel:SetText( "   " .. errors )
	return false
end

function Editor:SubTitle(sub)
	if(!sub) then self.subTitle = ""
	else self.subTitle = " - " .. sub end
end

function Editor:SetV(bool)
	if(bool) then
		self:MakePopup()
		self:SetVisible(true)
		self:InvalidateLayout(true)
		self:SetKeyBoardInputEnabled(true)
		self:Validate()
	else
		self:SetVisible(false)
		self:SetKeyBoardInputEnabled()
	end
end

function Editor:ChosenFile(Line)
	chosenfile = Line
	if(Line) then
		self:SubTitle("Editing: " .. Line)
		self.C['Dir'].panel:SetText(Line)
	else
		self:SubTitle()
		self.C['Dir'].panel:SetText("")
	end
end

function Editor:ExtractName()
	if(!self.E2) then return end
	local code = self:GetCode()
	local lines = string.Explode("\n", code)
	for _,line in ipairs(lines) do
		if string.sub(line, 1, 6) == "@name " then
			if string.Trim(string.sub(line, 7)) == "" then
				Expression2SetName(nil)
				return
			else
				Expression2SetName(string.Trim(string.sub(line, 7)))
				return
			end
		end
	end
end

function Editor:SetCode(code)
	self.C['Editor'].panel:SetText(code)
	self:Validate()
	self:ExtractName()
end

function Editor:GetCode()
	return self.C['Editor'].panel:GetValue()
end

function Editor:Open(Line,code)
	if(self:IsVisible() and !Line and !code) then self:Close() end
	self:SetV(true)
	if(code) then 
		self:ChosenFile()
		self:SetCode(code)
		if(Line) then self:SubTitle("Editing: " .. Line) end
	return end
	if(Line) then self:LoadFile(Line) return end
end

function Editor:SaveFile(Line, close)
	self:ExtractName()
	if(close and self.chip) then
		if(!self:Validate(true)) then return end
		wire_expression2_upload()
		self:Close()
	return end
	if(!Line or Line == self.Location .. "/" .. ".txt") then 
		Derma_StringRequest( "Save to New File", "", "filename", 
 		function( strTextOut ) 
			self:SaveFile( self.Location .. "/" .. string.Replace(strTextOut," ","_") .. ".txt", close )
		end ) 
	return end
	file.Write(Line , self:GetCode())
	if(!self.chip) then self:ChosenFile(Line) end
	if(close) then self:Close() end
end

function Editor:LoadFile( Line ) 
	if(!Line or file.IsDir( Line )) then return end
	local str = file.Read(Line)
	if str == nil then
		Error("ERROR LOADING FILE!")
	else
		if(!self.chip) then self:ChosenFile(Line) end
		self:SetCode(str)
	end
end 

function Editor:Close()
	self:ExtractName()
	self:SetV(false)
	self.chip = false
end

function Editor:Setup(nTitle, nLocation, E2)
	self.Title = nTitle
	self.Location = nLocation
	self.C['Browser'].panel:Setup(nLocation)
	if(!E2) then
		self.E2 = false
		self.C['Editor'].panel.SyntaxColorLine = function(self, row) return {{self.Rows[row], { Color(255, 255, 255, 255), false}}} end
		self.C['Editor'].h = -10
		self.C['Val'].panel:SetVisible(false)
	else
		self.E2 = true
		self:NewScript()
	end
	self:InvalidateLayout()
end

vgui.Register( "Expression2EditorFrame" , Editor , "DFrame" )
