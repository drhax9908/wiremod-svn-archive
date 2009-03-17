/******************************************************************************\
  Expression 2 Tool Screen for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

AddCSLuaFile("E2toolscreen.lua")
resource.AddFile("materials/expression 2/cog.vmt")
resource.AddFile("materials/expression 2/cog.vtf")

surface.CreateFont("Arial", 40, 1000, true, false, "Expression2ToolScreenFont")
surface.CreateFont("Arial", 30, 1000, true, false, "Expression2ToolScreenSubFont")

local percent = nil
local name = "Unnamed"

function Expression2SetName(n)
	name = n
	if !name then
		name = "Unnamed"
		return
	end
	
	surface.SetFont("Expression2ToolScreenSubFont")
	local ww = surface.GetTextSize("...")
	
	local w, h = surface.GetTextSize(name)
	if w < 240 then return end
	
	while true do
		local w, h = surface.GetTextSize(name)
		if w < 240 - ww then break end
		name = string.sub(name, 1, -2)
	end
	
	name = string.Trim(name) .. "..."
end

function Expression2SetProgress(p)
	percent = p
end

function DrawTextOutline(text, font, x, y, color, xalign, yalign, bordercolor, border)
	for i=0,8 do
		draw.SimpleText(text, font, x + border * math.sin(i * math.pi / 4), y + border * math.cos(i * math.pi / 4), bordercolor, xalign, yalign)
	end
	
	draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

hook.Add("InitPostEntity", "Expression2ToolScreenInitialize", function()
	for _,weapon in pairs(weapons.GetList()) do
		if weapon.Classname == "gmod_tool" then
			SWEP = weapon
			break
		end
	end

	local ViewModelDrawn = SWEP.ViewModelDrawn
	local ToolGunMaterial = Material("models/weapons/v_toolgun/screen")
	local ExpressionRT = GetRenderTarget("GModToolgunScreen", 256, 256)
	
	local CogColor = Color(150, 34, 34, 255)
	local CogTexture = surface.GetTextureID("expression 2/cog")
	if CogTexture == surface.GetTextureID("texturemissing") then CogTexture = nil end
	
	local function Expression2ViewModelDrawn(self)
		local ToolGunRT = render.GetRenderTarget()

		ToolGunMaterial:SetMaterialTexture("$basetexture", ExpressionRT)

		render.SetRenderTarget(ExpressionRT)
		render.SetViewPort(0, 0, 256, 256)
		cam.Start2D()

		surface.SetDrawColor(32, 32, 32, 255)
		surface.DrawRect(0, 0, 256, 256)
		
		if CogTexture then
			if percent then
				ToColor = Color(34, 150, 34, 255)
			else
				ToColor = Color(150, 34, 34, 255)
			end
			
			CogDelta = 750 * FrameTime()
			
			CogColor.r = CogColor.r + math.max(-CogDelta, math.min(CogDelta, ToColor.r - CogColor.r))
			CogColor.g = CogColor.g + math.max(-CogDelta, math.min(CogDelta, ToColor.g - CogColor.g))
			CogColor.b = CogColor.b + math.max(-CogDelta, math.min(CogDelta, ToColor.b - CogColor.b))	
		
			surface.SetTexture(CogTexture)
			surface.SetDrawColor(CogColor.r, CogColor.g, CogColor.b, 255)
			surface.DrawTexturedRectRotated(256, 256, 455, 455, RealTime() * 10)
			surface.DrawTexturedRectRotated(30, 30, 227.5, 227.5, RealTime() * -20 + 12.5)
		end

		surface.SetFont("Expression2ToolScreenFont")
		local w, h = surface.GetTextSize(" ")
		surface.SetFont("Expression2ToolScreenSubFont")
		local w2, h2 = surface.GetTextSize(" ")
		
		if percent then
			surface.SetFont("Expression2ToolScreenFont")
			local w, h = surface.GetTextSize("Uploading")
			DrawTextOutline("Uploading", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
			draw.RoundedBox(4, 128 - w/2 - 2, 128 + h / 2 - 0, (w*percent)/100 + 4, h2 - 4, Color(0, 0, 0, 255))
			draw.RoundedBox(2, 128 - w/2 + 2, 128 + h / 2 + 4, (w*percent)/100 - 4, h2 - 12, Color(224, 224, 224, 255))
		elseif name then
			DrawTextOutline("Expression 2", "Expression2ToolScreenFont", 128, 128, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
			DrawTextOutline(name, "Expression2ToolScreenSubFont", 128, 128 + (h+h2) / 2 - 4, Color(224, 224, 224, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, 255), 4)
		end
		
		cam.End2D()
		render.SetRenderTarget(ToolGunRT)
	end
	
	function SWEP:ViewModelDrawn()
		if gmod_toolmode:GetString() == "wire_expression2" then
			Expression2ViewModelDrawn(self)
		else
			ViewModelDrawn(self)
		end
	end
end)
