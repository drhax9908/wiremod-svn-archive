
AddCSLuaFile( "autorun/client/cl_modelplug.lua" )


ModelPlugInfo = {}


function ModelPlug_Register(category)
	if (not ModelPlugInfo[category]) then
		local catinfo = {}

	    local packs = file.Find("WireModelPacks/*.txt")
	    for _,filename in pairs(packs) do
        	//resource.AddFile("data/WireModelPacks/" .. filename)
			
	        local packtbl = util.KeyValuesToTable(file.Read("WireModelPacks/" .. filename) or {})

	        for name,entry in pairs(packtbl) do
				local categorytable = string.Explode(",", entry.categories or "none") or { "none" }
				
				for _,cat in pairs(categorytable) do
					if (cat == category) then
					    catinfo[name] = entry.model or ""

						//if (entry.model) then
						//    resource.AddFile(entry.model)
						//end

						//if (entry.files) then
						//    for _,extrafilename in pairs(entry.files) do
						//	    resource.AddFile(extrafilename)
						//    end
						//end

						break
					end
				end
	        end
	    end

	    ModelPlugInfo[category] = catinfo
	end
end