
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

local hudindicators = {}
// Default HUD x/y
local hudx = 22
local hudy = 200
local nextupdate = 0
// Y Offset constant 
local offsety = 32
// Text Height Constant
local dtextheight = draw.GetFontHeight("Default")
// So we don't need to calculate this every frame w/ Percent Bar style
local pbarheight = dtextheight + 16

// Copied from wirelib.lua (table.MakeSortedKeys() should be made shared :P)
local function MakeSortedKeys(tbl)
	local result = {}
	
	for k,_ in pairs(tbl) do table.insert(result, k) end
	table.sort(result)

	return result
end

local function DrawHUDIndicators()
	if (!LocalPlayer():Alive()) then return end
	
	local currenty = hudy
	
	// Now draw HUD Indicators
	for _, index in ipairs(MakeSortedKeys(hudindicators)) do
		if (hudindicators[index]) then // Is this necessary?
			local ent = ents.GetByIndex(index)
		
			if (ent && ent:IsValid()) then
				local indinfo = hudindicators[index]
				if (!indinfo.HideHUD) then
					local txt = indinfo.FullText or ""
				
					if (indinfo.Style == 0) then // Basic
						draw.WordBox(8, hudx, currenty, txt, "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
					elseif (indinfo.Style == 1) then // Gradient
						local r, g, b, a = ent:GetColor()
						local textcolor = Color(255, 255, 255, 255)
						if (r >= 192 && g >= 192 && b >= 192) then
							// Draw dark text for very bright Indicator colors
							textcolor = Color(32, 32, 32, 255)
						end
						
						draw.WordBox(8, hudx, currenty, txt, "Default", Color(r, g, b, 160), textcolor)
					elseif (indinfo.Style == 2) then // Percent Bar
						surface.SetFont("Default")
						local pbarwidth, h = surface.GetTextSize(txt)
						pbarwidth = math.max(pbarwidth + 16, 100) // The extra 16 pixels is a "buffer" to make it look better
						local startx = hudx
						local w1 = math.floor(indinfo.Factor * pbarwidth)						
						local w2 = math.ceil(pbarwidth - w1)
						if (indinfo.Factor > 0) then // Draw only if we have a factor
							local BColor = indinfo.BColor
							surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
							surface.DrawRect(startx, currenty, w1, pbarheight)
							startx = w1 + hudx
						end
						
						if (indinfo.Factor < 1) then
							local AColor = indinfo.AColor
							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							surface.DrawRect(startx, currenty, w2, pbarheight)
						end
						
						// Center the description (+ value if applicable) on the percent bar
						draw.SimpleText(txt, "Default", hudx + (pbarwidth / 2), currenty + (pbarheight / 2), Color(255, 255, 255, 255), 1, 1)
					end
					
					// Go to next "line"
					currenty = currenty + offsety
				end
			else
				// Clear this from the table so we don't check again
				hudindicators[index] = nil
			end
		end
	end
end
hook.Add("HUDPaint", "DrawHUDIndicators", DrawHUDIndicators)

local function HUDFormatDescription( eindex )
	// This is placed here so we don't have to update
	// the description more often than is necessary
	local indinfo = hudindicators[eindex]
	if (indinfo.ShowValue == 0) then // No Value
		hudindicators[eindex].FullText = indinfo.Description
	elseif (indinfo.ShowValue == 1) then // Percent
		hudindicators[eindex].FullText = indinfo.Description.." ("..string.format("%.1f", ((indinfo.Factor or 0) * 100)).."%)"
	elseif (indinfo.ShowValue == 2) then // Value
		// Round to up to 2 places
		hudindicators[eindex].FullText = indinfo.Description.." ("..string.format("%g", math.Round((indinfo.Value or 0) * 100) / 100)..")"
	end
end

// UserMessage stuff
local function HUDIndicatorRegister( um )
	local eindex = um:ReadShort()
	if (!hudindicators[eindex]) then // First-time register
		hudindicators[eindex] = {}
	end
	hudindicators[eindex].Description = um:ReadString()
	hudindicators[eindex].ShowValue = um:ReadShort()
	hudindicators[eindex].Style = um:ReadShort()
	if (!hudindicators[eindex].Factor) then // First-time register
		hudindicators[eindex].Factor = 0
		hudindicators[eindex].Value = 0
		hudindicators[eindex].HideHUD = false
	end
	HUDFormatDescription( eindex )
end
usermessage.Hook("HUDIndicatorRegister", HUDIndicatorRegister)

local function HUDIndicatorUnRegister( um )
	local eindex = um:ReadShort()
	hudindicators[eindex] = nil
end
usermessage.Hook("HUDIndicatorUnRegister", HUDIndicatorUnRegister)

local function HUDIndicatorFactor( um )
	local eindex = um:ReadShort()
	// HUDIndicatorRegister *should* be called before this,
	// I don't know why it isn't (TheApathetic)
	if (!hudindicators[eindex]) then
		hudindicators[eindex] = {}
	end
	hudindicators[eindex].Factor = um:ReadFloat()
	hudindicators[eindex].Value = um:ReadFloat()
	HUDFormatDescription( eindex )
end
usermessage.Hook("HUDIndicatorFactor", HUDIndicatorFactor)

local function HUDIndicatorHideHUD( um )
	local eindex = um:ReadShort()
	hudindicators[eindex].HideHUD = um:ReadBool()
end
usermessage.Hook("HUDIndicatorHideHUD", HUDIndicatorHideHUD)

local function HUDIndicatorStylePercent( um )
	local eindex = um:ReadShort()
	local ainfo = string.Explode("|", um:ReadString())
	local binfo = string.Explode("|", um:ReadString())
	hudindicators[eindex].AColor = { r = ainfo[1], g = ainfo[2], b = ainfo[3]}
	hudindicators[eindex].BColor = { r = binfo[1], g = binfo[2], b = binfo[3]}
end
usermessage.Hook("HUDIndicatorStylePercent", HUDIndicatorStylePercent)

// Check for CVar updates every 1/5 seconds
local function CVarCheck()
	if (CurTime() < nextupdate) then return end
	
	nextupdate = CurTime() + 0.20
	// Keep x/y within range (the 50 and 100 are arbitrary and may change)
	hudx = math.Clamp(GetConVarNumber("wire_hudindicator_hudx") or 22, 0, ScrW() - 50)
	hudy = math.Clamp(GetConVarNumber("wire_hudindicator_hudy") or 200, 0, ScrH() - 100)
end
hook.Add("Think", "WireIndicatorCVarCheck", CVarCheck)