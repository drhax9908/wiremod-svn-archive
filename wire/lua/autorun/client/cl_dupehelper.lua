if (CLIENT) then

	duplicatorclient={}
	
	include( "autorun/shared/dupeshare.lua" )
	
	function duplicatorclient.UpLoadFile( pl, filepath )
		
		if (duplicatorclient.sending) then return end
		if !file.Exists(filepath)then print("File not found") return end
		
		local filename = dupeshare.GetFileFromFilename(filepath)
		
		//load from file
		local temp = file.Read(filepath)
		
		//shitty string protection/compression
		//duplicatorclient.temp2 = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(temp,"\t\t\"__name\"\t\t","|mn"),"\t\t\"__type\"\t\t","|mt"),"\t\t\t\"V\"\t\t","|mv|"),"\t\t\t\"DupeInfo\"","|mD"),"\"Number\"\n","|mN"),"\"String\"\n","|mS"),"\"Angle\"\n","|mA"),"\"Vector\"\n","|mV"),"\"Bool\"\n","|mB"),"\"Class\"","|mC"),"\"material\"","|mm"),"\"prop_physics\"","|mp"),"\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n","|VI"),"\"models","|wm"),"\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t","|NC"),"\"nocollide\"\n","|nc"),"\"HeadEntID\"\n","|HE"),"\n\t}\n\t\"holdangle\"\n\t{\n","|ha"),"\t\t\"Y\"\t\t\"","|qY"),"\t\t\"z\"\t\t\"","|qz"),"\t\t\"x\"\t\t\"","|qx"),"\t\t\"A\"\t\t\"","|qA"),"\t\t\"B\"\t\t\"","|qB"),"\t\t\"g\"\t\t\"","|qg"),"\t\t\"r\"\t\t\"","|qr"),"\t\t\"p\"\t\t\"","|qp"),"\"HoldAngle\"\n","|HA"),"\n","|n"),"\t\t\t\t","|4t"),"\t\t\t","|3t"),"\t\t","|2t"),"\t","|t"),"name","|N"),"\"","|Q")
		
		duplicatorclient.temp2 = dupeshare.Compress(temp, true)
		
		//this is where we send the data to the serer
		local len = string.len(duplicatorclient.temp2)
		local last = math.ceil(len / 250)
		
		pl:ConCommand("DupeRecieveFileContentStart "..tostring(last).." \""..string.gsub(filename,".txt","").."\"")
		
		timer.Simple( 0.2, duplicatorclient.SendSaveDataToServer, len, 1, last )
		
		duplicatorclient.sending = true
	end
	
	
	function duplicatorclient.SendSaveDataToServer(len, offset, last)
		
		if (offset <= last) then
			Msg("sending string: "..tostring(offset * 250).." / "..len.." piece: "..offset.." / "..last.."\n")
			
			local str = ""
			if (offset == last) then
				local pos = (len - ((last - 1) * 250))
				str = string.Right(duplicatorclient.temp2, pos)
				Msg("last str len: "..tostring(string.len(str)).."\n")
			else
				str = string.Right(string.Left(duplicatorclient.temp2, (offset * 250)),250)
			end
			LocalPlayer():ConCommand("_DFC "..tostring(offset).." \""..str.."\"")
		end
		
		if (offset + 1) <= last then
			//send slowly or the server will boot player or just crash
			timer.Simple( 0.1, duplicatorclient.SendSaveDataToServer, len, (offset + 1), last )
		else
			timer.Simple( 0.5, 
				function()
					LocalPlayer():ConCommand("DupeRecieveFileContentFinish")  
					duplicatorclient.temp2 = ""
				end
			)
		end
		
	end
	
	local function SendFinished( um )
		duplicatorclient.sending = false
	end
	usermessage.Hook("ClientSendFinished", SendFinished)
	
	
	local function ClientRecieveSaveStart( um )
		Msg("=========  ClientRecieveSaveStart  ==========\n")
		duplicatorclient.temp = {}
		duplicatorclient.temp.piece = {}
		
		duplicatorclient.temp.numofpieces	= um:ReadShort()
		duplicatorclient.temp.filename		= um:ReadString()
		duplicatorclient.temp.dir			= um:ReadString()
		
		duplicatorclient.temp.recievedpieces = 0
		
		Msg("NumToRecieve= "..duplicatorclient.temp.numofpieces.."\n==========\n")
	end
	usermessage.Hook("RecieveSaveStart", ClientRecieveSaveStart)
	
	local function ClientRecieveSaveData( um )
		local piece	= um:ReadShort()
		local temp	= um:ReadString()
		duplicatorclient.temp.recievedpieces = duplicatorclient.temp.recievedpieces + 1
		
		Msg("getting file data, piece: "..piece.." of "..duplicatorclient.temp.numofpieces.."\n")
		
		duplicatorclient.temp.piece[piece] = temp
		
		if (duplicatorclient.temp.recievedpieces >= duplicatorclient.temp.numofpieces) then
			Msg("recieved last piece\n")
			LocalPlayer():ConCommand("adv_duplicator_clientsavefile")
		end
	end
	usermessage.Hook("RecieveSaveData", ClientRecieveSaveData)
	
	local function ClientSaveFile()
		
		local filepath, filename = duplicatorclient.FileNoOverWriteCheck( duplicatorclient.temp.dir, duplicatorclient.temp.filename )
		
		//reassemble the pieces
		local temp = ""
		for k, v in pairs(duplicatorclient.temp.piece) do
			temp = temp .. v
		end
		
		//temp = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(temp,"|mn","\t\t\"__name\"\t\t"),"|mt","\t\t\"__type\"\t\t"),"|mv|","\t\t\t\"V\"\t\t"),"|mD","\t\t\t\"DupeInfo\""),"|mN","\"Number\"\n"),"|mS","\"String\"\n"),"|mA","\"Angle\"\n"),"|mV","\"Vector\"\n"),"|mB","\"Bool\"\n"),"|mC","\"Class\""),"|mm","\"material\""),"|mp","\"prop_physics\""),"|VI","\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n"),"|wm","\"models"),"|NC","\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t"),"|nc","\"nocollide\"\n"),"|HE","\"HeadEntID\"\n"),"|ha","\n\t}\n\t\"holdangle\"\n\t{\n"),"|qY","\t\t\"Y\"\t\t\""),"|qz","\t\t\"z\"\t\t\""),"|qx","\t\t\"x\"\t\t\""),"|qA","\t\t\"A\"\t\t\""),"|qB","\t\t\"B\"\t\t\""),"|qg","\t\t\"g\"\t\t\""),"|qr","\t\t\"r\"\t\t\""),"|qp","\t\t\"p\"\t\t\""),"|HA","\"HoldAngle\"\n"),"|4","\t\t\t\t"),"|3","\t\t\t"),"|N","name")
		
		temp = dupeshare.DeCompress(temp, false)
		
		file.Write(filepath, temp)
		
		Msg("Your file: \""..filepath.."\" was saved form the server\n")
		Msg("Your file: \""..filename.."\" was saved form the server\n")
		
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	end
	concommand.Add( "adv_duplicator_clientsavefile", ClientSaveFile )
	
	
	
	
	/*---------------------------------------------------------
	functions for clients from server side duplicator.lua
	---------------------------------------------------------*/
	/*---------------------------------------------------------
	Name: duplicatorclient.PrepareTableToSave( table )
	Desc: Converts a table in to a lot tables to protect 
		vectors, angles, bools, numbers, and indexes
		from being horribly raped by TableToKeyValues
	---------------------------------------------------------*/
	function duplicatorclient.PrepareTableToSave( t, done)
		
		local done = done or {}
		local tbl = {}
		
		for k, v in pairs ( t ) do
			if ( type( v ) == "table" and !done[ v ] ) then
				done[ v ] = true
				tbl[ k ] = duplicatorclient.PrepareTableToSave ( v, done )
				tbl[k].__name = k
			else
				if ( type(v) == "Vector" ) then
					local x, y, z = v.x, v.y, v.z
					if y == 0 then y = nil end
					if z == 0 then z = nil end
					tbl[k] = { __type = "Vector", x = x, y = y, z = z, __name = k }
				elseif ( type(v) == "Angle" ) then
					local p,y,r = v.pitch, v.yaw, v.roll
					if p == 0 then p = nil end
					if y == 0 then y = nil end
					if r == 0 then r = nil end
					tbl[k] = { __type = "Angle", p = p, y = y, r = r, __name = k }
				elseif ( type(v) == "boolean" ) then
					tbl[k] = { __type = "Bool", v = tostring( v ), __name = k }
				elseif ( type(v) == "number" ) then
					tbl[k] = { __type = "Number", v = tostring( v ), __name = k }
				else
					tbl[k] = { __type = "String", v = tostring( v ), __name = k }
				end
			end
		end
		
		return tbl
	end
	
	/*---------------------------------------------------------
	   Name: duplicatorclient.RebuildTableFromLoad( table )
	   Desc: Removes the protection added by PrepareTableToSave
			after table is loaded with KeyValuesToTable
	---------------------------------------------------------*/
	function duplicatorclient.RebuildTableFromLoad( t, done )
		
		local done = done or {}
		local tbl = {}
		
		for k, v in pairs ( t ) do
			if ( type( v ) == "table" and !done[ v ] ) then
				done[ v ] = true
				if ( v.__type ) then
					if ( v.__type == "Vector" ) then
						tbl[ v.__name ] = Vector( v.x, v.y, v.z )
					elseif ( v.__type == "Angle" ) then
						tbl[ v.__name ] = Angle( v.p, v.y, v.r )
					elseif ( v.__type == "Bool" ) then
						tbl[ v.__name ] = util.tobool( v.v )
					elseif ( v.__type == "Number" ) then
						tbl[ v.__name ] = tonumber( v.v )
					elseif ( v.__type == "String" ) then
						tbl[ v.__name ] = tostring( v.v )
					end
				else
					tbl[ v.__name ] = duplicatorclient.RebuildTableFromLoad ( v, done )
				end
			else
				if k != "__name" then //don't add the table names to output
					tbl[ k ] = v
				end
			end
		end
		
		return tbl
		
	end
	
	/*---------------------------------------------------------
	   Name: duplicatorclient.FileNoOverWriteCheck( dir, filename )
	   Desc: Check if dir and filename exist and if so renames
			returns filepath (dir.."/"..filename..".txt")
	---------------------------------------------------------*/
	function duplicatorclient.FileNoOverWriteCheck( dir, filename )
		
		if !file.Exists(dir) then 
			file.CreateDir(dir)
		elseif !file.IsDir(dir) then
			local x = 0
			while x ~= nil do
				x = x + 1
				if not file.Exists(dir.."_"..tostring(x)) then
					dir = dir.."_"..tostring(x)
					file.CreateDir(dir)
					x = nil
				end
			end
		end
		
		if file.Exists(dir .. "/" .. filename .. ".txt") then
			local x = 0
			while x ~= nil do
				x = x + 1
				if not file.Exists(dir.."/"..filename.."_"..tostring(x)..".txt") then
					filename = filename.."_"..tostring(x)
					x = nil
				end
			end
		end
		
		local filepath = dir .. "/" .. filename .. ".txt"
		
		return filepath, filename, dir
	end
	
	
	
	Msg("--- Wire duplicator client module installed! ---\n")
	
end
