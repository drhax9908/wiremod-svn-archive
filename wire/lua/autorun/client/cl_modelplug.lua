
ModelPlugInfo = {}


function ModelPlug_AddToCPanel(panel, category, toolname, label, type, textbox_label)
	if (not ModelPlugInfo[category]) then
		local catinfo = {}

	    local packs = file.Find("WireModelPacks/*.txt")
	    for _,filename in pairs(packs) do
	        local packtbl = util.KeyValuesToTable(file.Read("WireModelPacks/" .. filename) or {})

	        for name,entry in pairs(packtbl) do
				local categorytable = string.Explode(",", entry.categories or "none") or { "none" }

				for _,cat in pairs(categorytable) do
					if (cat == category) then
					    catinfo[name] = entry.model or ""
					    default = default or entry.model

						break
					end
				end
	        end
	    end

	    ModelPlugInfo[category] = catinfo
	end

	if (table.Count(ModelPlugInfo[category]) > 1) then
		local type = type or "ComboBox"
		local Models = {
			Label = label or "Model:",
			MenuButton = "0",

			Options = {}
		}

		for name,model in pairs(ModelPlugInfo[category]) do
		    Models.Options[name] = { [toolname .. "_model"] = model }
		end

		panel:AddControl(type, Models)
	end

	if (textbox_label) then
		panel:AddControl("TextBox", {
			Label = textbox_label,
			Command = toolname .. "_model",
			MaxLength = "200"
		})
	end
end
