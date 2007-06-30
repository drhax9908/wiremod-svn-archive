if (SERVER) then return end

AdvDupeClient={}

include( "autorun/shared/dupeshare.lua" )

AdvDupeClient.version = 1.74
local MAXUPLOADLENGTH = 200



//
//	Upload functions
//
function AdvDupeClient.UpLoadFile( pl, filepath )
	
	if (AdvDupeClient.sending) then return end
	if !file.Exists(filepath)then print("File not found") return end
	
	local filename = dupeshare.GetFileFromFilename(filepath)
	
	//load from file
	local temp = file.Read(filepath)
	
	AdvDupeClient.temp2 = dupeshare.Compress(temp, true)
	
	//this is where we send the data to the serer
	local len = string.len(AdvDupeClient.temp2)
	local last = math.ceil(len / MAXUPLOADLENGTH)
	
	pl:ConCommand("DupeRecieveFileContentStart "..tostring(last).." \""..string.gsub(filename,".txt","").."\"")
	
	AdvDupeClient.SetPercentText( "Uploading" )
	
	timer.Simple( 0.2, AdvDupeClient.SendSaveDataToServer, len, 1, last )
	
	AdvDupeClient.sending = true
end

local PiecesPerSend = 4
local SendDelay = 0.25
function AdvDupeClient.SendSaveDataToServer(len, offset, last)
	
	for i = 1,PiecesPerSend do
		if (offset <= last) then
			Msg("sending string: "..tostring(offset * MAXUPLOADLENGTH).." / "..len.." piece: "..offset.." / "..last.."\n")
			if ( AdvDupeClient.PercentText == "Uploading" ) then
				AdvDupeClient.UpdatePercent( math.ceil(offset / last * 100) )
			end
			
			local str = ""
			if (offset == last) then
				local pos = (len - ((last - 1) * MAXUPLOADLENGTH))
				str = string.Right(AdvDupeClient.temp2, pos)
				Msg("last str len: "..tostring(string.len(str)).."\n")
				AdvDupeClient.UpdatePercent( 100 )
				timer.Simple(.2, AdvDupeClient.UpdatePercent, -1)
			else
				str = string.Right(string.Left(AdvDupeClient.temp2, (offset * MAXUPLOADLENGTH)),MAXUPLOADLENGTH)
			end
			LocalPlayer():ConCommand("_DFC "..tostring(offset).." \""..str.."\"")
		end
		offset = offset + 1
	end
	
	if (offset <= last) then
		timer.Simple( SendDelay, AdvDupeClient.SendSaveDataToServer, len, offset, last )
	else
		timer.Simple( 1, 
			function()
				LocalPlayer():ConCommand("DupeRecieveFileContentFinish")  
				AdvDupeClient.temp2 = ""
			end
		)
	end
	
end

local function SendFinished( um )
	AdvDupeClient.sending = false
	AdvDuplicator_UpdateControlPanel()
end
usermessage.Hook("AdvDupeClientSendFinished", SendFinished)

local function SendFinishedFailed( um )
	if (SendDelay < .5) then
		SendDelaqqqqy = SendDelay + 0.05
		Msg("AdvDupe: increasing SendDelay to "..SendDelay.."\n")
	elseif (PiecesPerSend > 1) then
		PiecesPerSend = PiecesPerSend - 1
		Msg("AdvDupe: decreasing PiecesPerSend to "..PiecesPerSend.."\n")
	else
		Msg("AdvDupeERROR: SendDelay and PiecesPerSend maxed to .5 and 1, there's a problem if it's failed this many times.\n")
	end
	AdvDupeClient.sending = false
	AdvDuplicator_UpdateControlPanel()
end
usermessage.Hook("AdvDupeClientSendFinishedFailed", SendFinishedFailed)



//
//	Download functions
//
local function ClientRecieveSaveStart( um )
	Msg("=========  ClientRecieveSaveStart  ==========\n")
	AdvDupeClient.temp = {}
	AdvDupeClient.temp.pieces = {}
	
	AdvDupeClient.temp.numofpieces	= um:ReadShort()
	AdvDupeClient.temp.filename		= um:ReadString()
	AdvDupeClient.temp.dir			= AdvDupeClient.CLcdir
	
	AdvDupeClient.temp.recievedpieces = 0
	AdvDupeClient.downloading = true
	AdvDuplicator_UpdateControlPanel()
	
	Msg("NumToRecieve= "..AdvDupeClient.temp.numofpieces.."\n==========\n")
	AdvDupeClient.SetPercentText( "Downloading" )
end
usermessage.Hook("AdvDupeRecieveSaveStart", ClientRecieveSaveStart)

local function ClientRecieveSaveData( um )
	local piece	= um:ReadShort()
	local temp	= um:ReadString()
	AdvDupeClient.temp.recievedpieces = AdvDupeClient.temp.recievedpieces + 1
	
	Msg("getting file data, piece: "..piece.." of "..AdvDupeClient.temp.numofpieces.."\n")
	if ( AdvDupeClient.PercentText == "Downloading" ) then
		AdvDupeClient.UpdatePercent( math.ceil( piece / AdvDupeClient.temp.numofpieces ) )
	end
	
	AdvDupeClient.temp.pieces[piece] = temp
	
	if (AdvDupeClient.temp.recievedpieces >= AdvDupeClient.temp.numofpieces) then
		Msg("recieved last piece\n")
		AdvDupeClient.UpdatePercent( 100 )
		timer.Simple(.2, AdvDupeClient.UpdatePercent, -1)
		//LocalPlayer():ConCommand("adv_duplicator_clientsavefile")
		AdvDupeClient.ClientSaveRecievedFile()
	end
end
usermessage.Hook("AdvDupeRecieveSaveData", ClientRecieveSaveData)

function AdvDupeClient.ClientSaveRecievedFile()
	
	local filepath, filename = dupeshare.FileNoOverWriteCheck( AdvDupeClient.temp.dir, AdvDupeClient.temp.filename )
	
	//reassemble the pieces
	local temp = table.concat(AdvDupeClient.temp.pieces)
	
	temp = dupeshare.DeCompress(temp, false)
	
	file.Write(filepath, temp)
	
	AdvDupeClient.Error( "Your file: \""..filepath.."\" was downloaded form the server", false, true )
	Msg("Your file: \""..filepath.."\" was downloaded form the server\n")
	
	
	LocalPlayer():ConCommand("adv_duplicator_updatelist")
	
end
//concommand.Add( "adv_duplicator_clientsavefile", ClientSaveFile )

local function DownloadFinished( um )
	AdvDupeClient.downloading = false
	AdvDuplicator_UpdateControlPanel()
end
usermessage.Hook("AdvDupeClientDownloadFinished", DownloadFinished)




	
local function FileOptsCommand(pl, cmd, args)
	if ( !pl:IsValid() ) or ( !pl:IsPlayer() ) or ( !args[1] ) then return end
	
	local action = args[1]
	local filename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename_cl" ))..".txt"
	//local filename2 = pl:GetInfo( "adv_duplicator_open_cl2" )
	local dir	= AdvDupeClient.CLcdir
	local dir2	= AdvDupeClient.CLcdir2
	
	AdvDupeClient.FileOpts(action, filename, dir, dir2)
	
end
concommand.Add("adv_duplicator_cl_fileopts", FileOptsCommand)

function AdvDupeClient.FileOpts(action, filename, dir, dir2)
	if ( !action ) or ( !filename ) or ( !dir ) then return end
	
	local file1 = dir.."/"..filename
	Msg("action= "..action.."  filename= "..filename.."  dir= "..dir.."  dir2= "..(dir2 or "none").."\n")
	
	if (action == "delete") then
		
		file.Delete(file1)
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	elseif (action == "copy") then
		
		local file2 = dir2.."/"..filename
		if file.Exists(file2) then
			local filename2 = ""
			file2, filename2 = dupeshare.FileNoOverWriteCheck(dir2, filename)
			AdvDupeClient.Error("File Exists at Destination, Renamed to: "..filename2)
		end
		file.Write(file2, file.Read(file1))
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	elseif action == "move" then
		
		AdvDupeClient.FileOpts("copy", filename, dir, dir2)
		AdvDupeClient.FileOpts("delete", filename, dir)
		
	elseif (action == "makedir") then
		
		if file.Exists(file1) and file.IsDir(file1) then 
			AdvDupeClient.Error("Folder Already Exists!")
			return
		end
		
		file.CreateDir(file1)
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	elseif action == "rename" then
		
		AdvDupeClient.FileOpts("duplicate", filename, dir, dir2)
		AdvDupeClient.FileOpts("delete", filename, dir)
		
	elseif action == "duplicate" then
		
		local file2 = dir.."/"..dir2 //using dir2 to hold the new filename
		if file.Exists(file2) then
			local filename2 = ""
			file2, filename2 = dupeshare.FileNoOverWriteCheck(dir, dir2)
			AdvDupeClient.Error("File Exists With That Name Already, Renamed as: "..filename2)
		end
		file.Write(file2, file.Read(file1))
		LocalPlayer():ConCommand("adv_duplicator_updatelist")
		
	else
		AdvDupeClient.Error( "FileOpts: Unknown Action!")
	end
	
end





//simple error msg display
function AdvDupeClient.Error( errormsg, NoSound, NotError )
	if !errormsg then return end
	if (NotError) then
		GAMEMODE:AddNotify( "AdvDupe: "..tostring(errormsg), NOTIFY_GENERIC, 10 );
	else
		GAMEMODE:AddNotify( "AdvDupe-ERROR: "..tostring(errormsg), NOTIFY_ERROR, 10 );
	end
	if (!NoSound) then
		if (NotError) then
			surface.PlaySound( "buttons/button10.wav" )
		else
			surface.PlaySound("ambient/water/drip"..math.random(1, 4)..".wav")
		end
	end
end

local function AdvDupeCLError( um )
	AdvDupeClient.Error( um:ReadString(), um:ReadBool() )
end
usermessage.Hook("AdvDupeCLError", AdvDupeCLError)

local function AdvDupeCLInfo( um )
	AdvDupeClient.Error( um:ReadString(), um:ReadBool(), true )
end
usermessage.Hook("AdvDupeCLInfo", AdvDupeCLInfo)




local function SetPasting( um )
	AdvDupeClient.Pasting = um:ReadBool()
end
usermessage.Hook("AdvDupeSetPasting", SetPasting)






	//HUD progress bar stuff
	//kinda based on wired HUD indicators (TheApathic), but most everything was replaced to make it work as a single centered progress bar
	//TODO: this is a mess, needs clean up
	AdvDupeClient.Factor = 0
	surface.SetFont("Default")
	local pwidth, pheight = surface.GetTextSize("NoColliding: 100%")
	pheight = pheight + 16
	local halfpwidth = pwidth / 2
	local halfpheight = pheight / 2
	local bw1 = halfpwidth + 6
	local bw2 = pwidth + 12
	local fh1 = 3
	local fh2 = pheight - 6
	local bcolor = Color(150, 150, 255, 190)
	local fcolor = Color(150, 255, 150, 240)
	local txtcolor = Color(0, 0, 0, 255)
	
	local function DrawProgressBar()
		if (AdvDupeClient.Done) and (AdvDupeClient.Done > -1) then
			local w1 = AdvDupeClient.hudx - math.floor(AdvDupeClient.Factor * halfpwidth) - 4
			local w2 = math.floor(AdvDupeClient.Factor * pwidth) + 8
			draw.RoundedBox(6, (AdvDupeClient.hudx - bw1), AdvDupeClient.hudy, bw2, pheight, bcolor)
			draw.RoundedBox(4, w1, (AdvDupeClient.hudy + fh1), w2, fh2, fcolor)
			local txt
			if ( AdvDupeClient.PercentText == "Copying..." ) then
				txt = AdvDupeClient.PercentText
			else
				txt = AdvDupeClient.PercentText..": "..AdvDupeClient.Done.."%"
			end
			draw.SimpleText(txt, "Default", AdvDupeClient.hudx, (AdvDupeClient.hudy + halfpheight), txtcolor, 1, 1)
		end
	end
	hook.Add("HUDPaint", "AdvDupeProgressBar", DrawProgressBar)
	
	
	function AdvDupeClient.UpdatePercent( Percent )
		AdvDupeClient.Done = Percent
		AdvDupeClient.Factor = AdvDupeClient.Done / 100
	end
	
	local function UpdatePercent( um )
		AdvDupeClient.UpdatePercent( um:ReadShort() )
	end
	usermessage.Hook("AdvDupe_Update_Percent", UpdatePercent)
	
	function AdvDupeClient.SetPercentText( PercentText )
		AdvDupeClient.PercentText = PercentText
		AdvDupeClient.Done = 0
		AdvDupeClient.Factor = 0
		
		AdvDupeClient.hudx = ScrW() / 2
		AdvDupeClient.hudy = ScrH() / 1.8
		
		surface.SetFont("Default")
		pwidth, pheight = surface.GetTextSize(AdvDupeClient.PercentText..": 100%")
		pheight = pheight + 16
		halfpwidth = pwidth / 2
		halfpheight = pheight / 2
		bw1 = halfpwidth + 6
		bw2 = pwidth + 12
		fh2 = pheight - 6
	end
	
	local function StartPercent( um ) 
		AdvDupeClient.SetPercentText( um:ReadString() )
	end
	usermessage.Hook("AdvDupe_Start_Percent", StartPercent)
	





AdvDupeClient.res = {}
//vgui code partly adapted from Night-Eagle's HUD Module
AdvDupeClient.res.Basic = [[
"basic.res"
{
	"basic"
	{
		"ControlName"		"Frame"
		"fieldName"		"basic"
		"xpos"		"475"
		"ypos"		"355"
		"zpos"		"290"
		"wide"		"400"
		"tall"		"66"
		"autoResize"		"0"
		"pinCorner"		"0"
		"visible"		"1"
		"enabled"		"1"
		"tabPosition"		"0"
		"settitlebarvisible"		"1"
		"title"		"%TITLE%"
		"sizable"		"0"
	}
	"frame_topGrip"
	{
		"ControlName"		"Panel"
		"fieldName"		"frame_topGrip"
		"xpos"		"8"
		"ypos"		"0"
		"wide"		"384"
		"tall"		"5"
		"autoResize"		"0"
		"pinCorner"		"0"
		"visible"		"0"
		"enabled"		"1"
		"tabPosition"		"0"
	}
}
]]

function AdvDupeClient.res.gengui(caption)
	return string.gsub(AdvDupeClient.res.Basic,"%%TITLE%%",caption)
end

AdvDupeClient.gui = {}

function AdvDupeClient.SaveGUI( pl, command, args )
	if (!AdvDupeClient.Copied) then return end
	
	LocalPlayer():ConCommand("adv_duplicator_hideghost 1")
	
	if !AdvDupeClient.gui.save or !AdvDupeClient.gui.save.frame then
		AdvDupeClient.gui.save = {}
		AdvDupeClient.gui.save.frame = vgui.Create( "Frame" )
		AdvDupeClient.gui.save.frame:SetName( "basic" )
		AdvDupeClient.gui.save.frame:LoadControlsFromString(AdvDupeClient.res.gengui("Save to File"))
		AdvDupeClient.gui.save.frame:SetName("AdvDuplicatorSave")
		AdvDupeClient.gui.save.frame:SetSize(320,135)
		AdvDupeClient.gui.save.frame:SetPos(400,250)
		
		
		AdvDupeClient.gui.save.lblFile = vgui.Create("Label",AdvDupeClient.gui.save.frame,"lblFile")
		AdvDupeClient.gui.save.lblFile:SetPos(6,25)
		AdvDupeClient.gui.save.lblFile:SetSize(185,25)
		AdvDupeClient.gui.save.lblFile:SetText("Filename:")
		
		AdvDupeClient.gui.save.lblDesc = vgui.Create("Label",AdvDupeClient.gui.save.frame,"lblDesc")
		AdvDupeClient.gui.save.lblDesc:SetPos(6,65)
		AdvDupeClient.gui.save.lblDesc:SetSize(185,25)
		AdvDupeClient.gui.save.lblDesc:SetText("Description:")
		
		AdvDupeClient.gui.save.btnSave = vgui.Create("Button",AdvDupeClient.gui.save.frame,"btnSave")
		AdvDupeClient.gui.save.btnSave:SetPos(184,110)
		AdvDupeClient.gui.save.btnSave:SetSize(110,20)
		AdvDupeClient.gui.save.btnSave:SetText("Save")
		AdvDupeClient.gui.save.btnSave:SetCommand("Save")
		
		AdvDupeClient.gui.save.txtFile = vgui.Create("TextEntry",AdvDupeClient.gui.save.frame,"txtFile")
		AdvDupeClient.gui.save.txtFile:SetPos(6,45)
		AdvDupeClient.gui.save.txtFile:SetSize(290,20)
		
		
		AdvDupeClient.gui.save.txtDesc = vgui.Create("TextEntry",AdvDupeClient.gui.save.frame,"txtDesc")
		AdvDupeClient.gui.save.txtDesc:SetPos(6,85)
		AdvDupeClient.gui.save.txtDesc:SetSize(290,20)
		
		function AdvDupeClient.gui.save.frame:ActionSignal(key,value)
			if key == "Save" then
				local filename	= AdvDupeClient.gui.save.txtFile:GetValue()
				local desc		= AdvDupeClient.gui.save.txtDesc:GetValue()
				
				LocalPlayer():ConCommand("adv_duplicator_save \""..filename.."\" \""..desc.."\"")
				
				AdvDupeClient.gui.save.frame:SetVisible(false)
			end
		end
	end
	
	AdvDupeClient.gui.save.txtFile:SetText("")
	AdvDupeClient.gui.save.txtDesc:SetText("")
	
	AdvDupeClient.gui.save.frame:SetKeyBoardInputEnabled( true )
	AdvDupeClient.gui.save.frame:SetMouseInputEnabled( true )
	AdvDupeClient.gui.save.frame:SetVisible( true )
end
concommand.Add( "adv_duplicator_save_gui", AdvDupeClient.SaveGUI )

function AdvDupeClient.MakeDir( pl, command, args )
	if !args or !args[1] then return end
	
	LocalPlayer():ConCommand("adv_duplicator_hideghost 1")
	
	if !AdvDupeClient.gui.makedir or !AdvDupeClient.gui.makedir.frame then
		AdvDupeClient.gui.makedir = {}
		AdvDupeClient.gui.makedir.frame = vgui.Create( "Frame" )
		AdvDupeClient.gui.makedir.frame:SetName( "basic" )
		AdvDupeClient.gui.makedir.frame:LoadControlsFromString(AdvDupeClient.res.gengui("Make Dir"))
		AdvDupeClient.gui.makedir.frame:SetName("AdvDuplicatorMakeDirSS")
		AdvDupeClient.gui.makedir.frame:SetSize(320,135)
		AdvDupeClient.gui.makedir.frame:SetPos(400,250)
		
		AdvDupeClient.gui.makedir.btnMakeDir = vgui.Create("Button",AdvDupeClient.gui.makedir.frame,"btnMakeDir")
		AdvDupeClient.gui.makedir.btnMakeDir:SetPos(184,110)
		AdvDupeClient.gui.makedir.btnMakeDir:SetSize(110,20)
		AdvDupeClient.gui.makedir.btnMakeDir:SetText("Make Folder")
		
		AdvDupeClient.gui.makedir.lblDir = vgui.Create("Label",AdvDupeClient.gui.makedir.frame,"lblDir")
		AdvDupeClient.gui.makedir.lblDir:SetPos(6,25)
		AdvDupeClient.gui.makedir.lblDir:SetSize(185,25)
		
		AdvDupeClient.gui.makedir.txtDir = vgui.Create("TextEntry",AdvDupeClient.gui.makedir.frame,"txtDir")
		AdvDupeClient.gui.makedir.txtDir:SetPos(6,45)
		AdvDupeClient.gui.makedir.txtDir:SetSize(289,20)
		
		if (dupeshare.UsePWSys) and (!SinglePlayer()) then 
			AdvDupeClient.gui.makedir.lblPass = vgui.Create("Label",AdvDupeClient.gui.makedir.frame,"lblPass")
			AdvDupeClient.gui.makedir.lblPass:SetPos(6,65)
			AdvDupeClient.gui.makedir.lblPass:SetSize(185,25)
			AdvDupeClient.gui.makedir.lblPass:SetText("Password:")
			
			AdvDupeClient.gui.makedir.txtPass = vgui.Create("TextEntry",AdvDupeClient.gui.makedir.frame,"txtPass")
			AdvDupeClient.gui.makedir.txtPass:SetPos(6,85)
			AdvDupeClient.gui.makedir.txtPass:SetSize(189,20)
		end
		
		function AdvDupeClient.gui.makedir.frame:ActionSignal(key,value)
			if key == "MakeDirServer" then
				local dir = tostring(AdvDupeClient.gui.makedir.txtDir:GetValue())
				
				if (dupeshare.UsePWSys) and (!SinglePlayer()) then
					local pass	= AdvDupeClient.gui.makedir.txtPass:GetValue()
					LocalPlayer():ConCommand("adv_duplicator_makedir \""..dir.."\" \""..pass.."\"")
				else
					LocalPlayer():ConCommand("adv_duplicator_makedir \""..dir.."\"")
				end
				
				AdvDupeClient.gui.makedir.frame:SetVisible(false)
			elseif key == "MakeDirClient" then
				local newdir = dupeshare.ReplaceBadChar( AdvDupeClient.gui.makedir.txtDir:GetValue() )
				local dir	= AdvDupeClient.CLcdir
				
				AdvDupeClient.FileOpts("makedir", newdir, dir)
				
				AdvDupeClient.gui.makedir.frame:SetVisible(false)
			end
		end
	end
	
	AdvDupeClient.gui.makedir.txtDir:SetText("")
	if (dupeshare.UsePWSys) and (!SinglePlayer()) then 
		AdvDupeClient.gui.makedir.txtPass:SetText("")
	end
	
	if args[1] == "client" then
		AdvDupeClient.gui.makedir.btnMakeDir:SetCommand("MakeDirClient")
		AdvDupeClient.gui.makedir.lblDir:SetText("Name for new folder in \""..string.gsub(AdvDupeClient.CLcdir, dupeshare.BaseDir, "").."\"")
	else
		AdvDupeClient.gui.makedir.btnMakeDir:SetCommand("MakeDirServer")
		AdvDupeClient.gui.makedir.lblDir:SetText("Name for new folder in \""..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "").."\"")
	end
	
	AdvDupeClient.gui.makedir.frame:SetKeyBoardInputEnabled( true )
	AdvDupeClient.gui.makedir.frame:SetMouseInputEnabled( true )
	AdvDupeClient.gui.makedir.frame:SetVisible( true )
end
concommand.Add( "adv_duplicator_makedir_gui", AdvDupeClient.MakeDir )

function AdvDupeClient.RenameFile( pl, cmd, args )
	if !args or !args[1] then return end
	
	LocalPlayer():ConCommand("adv_duplicator_hideghost 1")
	
	if !AdvDupeClient.gui.rename or !AdvDupeClient.gui.rename.frame then
		AdvDupeClient.gui.rename = {}
		AdvDupeClient.gui.rename.frame = vgui.Create( "Frame" )
		AdvDupeClient.gui.rename.frame:SetName( "basic" )
		AdvDupeClient.gui.rename.frame:LoadControlsFromString(AdvDupeClient.res.gengui("Rename File"))
		AdvDupeClient.gui.rename.frame:SetName("AdvDuplicatorRename")
		AdvDupeClient.gui.rename.frame:SetSize(320,135)
		AdvDupeClient.gui.rename.frame:SetPos(400,250)
		
		AdvDupeClient.gui.rename.btnRename = vgui.Create("Button",AdvDupeClient.gui.rename.frame,"btnRename")
		AdvDupeClient.gui.rename.btnRename:SetPos(184,110)
		AdvDupeClient.gui.rename.btnRename:SetSize(110,20)
		AdvDupeClient.gui.rename.btnRename:SetText("Rename")
		
		AdvDupeClient.gui.rename.lblNewName = vgui.Create("Label",AdvDupeClient.gui.rename.frame,"lblNewName")
		AdvDupeClient.gui.rename.lblNewName:SetPos(6,25)
		AdvDupeClient.gui.rename.lblNewName:SetSize(185,25)
		
		AdvDupeClient.gui.rename.txtNewName = vgui.Create("TextEntry",AdvDupeClient.gui.rename.frame,"txtNewName")
		AdvDupeClient.gui.rename.txtNewName:SetPos(6,45)
		AdvDupeClient.gui.rename.txtNewName:SetSize(289,20)
		
		function AdvDupeClient.gui.rename.frame:ActionSignal(key,value)
			if key == "RenameServer" then
				local newname = AdvDupeClient.gui.rename.txtNewName:GetValue()
				Msg("newname= "..newname.."\n")
				
				LocalPlayer():ConCommand("adv_duplicator_fileoptsrename \""..newname.."\"")
				
				AdvDupeClient.gui.rename.frame:SetVisible(false)
			elseif key == "RenameClient" then
				local newname	= dupeshare.ReplaceBadChar(dupeshare.GetFileFromFilename(AdvDupeClient.gui.rename.txtNewName:GetValue()))..".txt"
				local filename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename_cl" ))..".txt"
				local dir	= AdvDupeClient.CLcdir
				
				AdvDupeClient.FileOpts("rename", filename, dir, newname)
				
				AdvDupeClient.gui.rename.frame:SetVisible(false)
			end
		end
	end
	
	if args[1] == "client" then
		AdvDupeClient.gui.rename.btnRename:SetCommand("RenameClient")
		
		local oldfilename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename_cl" ))
		AdvDupeClient.gui.rename.lblNewName:SetText("New name for \""..oldfilename..".txt\" in \""..string.gsub(AdvDupeClient.CLcdir, dupeshare.BaseDir, "").."/ ")
		AdvDupeClient.gui.rename.txtNewName:SetText(oldfilename)
	else
		AdvDupeClient.gui.rename.btnRename:SetCommand("RenameServer")
		
		local oldfilename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename" ))
		AdvDupeClient.gui.rename.lblNewName:SetText("New name for \""..oldfilename..".txt\" in \""..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "").."/ ")
		AdvDupeClient.gui.rename.txtNewName:SetText(oldfilename)
	end
	
	AdvDupeClient.gui.rename.frame:SetKeyBoardInputEnabled( true )
	AdvDupeClient.gui.rename.frame:SetMouseInputEnabled( true )
	AdvDupeClient.gui.rename.frame:SetVisible( true )
	
end
concommand.Add( "adv_duplicator_renamefile_gui", AdvDupeClient.RenameFile )

function AdvDupeClient.ConfirmDelete( pl, cmd, args )
	if !args or !args[1] then return end
	
	LocalPlayer():ConCommand("adv_duplicator_hideghost 1")
	
	if !AdvDupeClient.gui.delete or !AdvDupeClient.gui.delete.frame then
		AdvDupeClient.gui.delete = {}
		AdvDupeClient.gui.delete.frame = vgui.Create( "Frame" )
		AdvDupeClient.gui.delete.frame:SetName( "basic" )
		AdvDupeClient.gui.delete.frame:LoadControlsFromString(AdvDupeClient.res.gengui("Delete File?"))
		AdvDupeClient.gui.delete.frame:SetName("AdvDuplicatorDelete")
		AdvDupeClient.gui.delete.frame:SetSize(320,135)
		AdvDupeClient.gui.delete.frame:SetPos(400,250)
		
		AdvDupeClient.gui.delete.btnDelete = vgui.Create("Button",AdvDupeClient.gui.delete.frame,"btnDelete")
		AdvDupeClient.gui.delete.btnDelete:SetPos(20,110)
		AdvDupeClient.gui.delete.btnDelete:SetSize(110,20)
		AdvDupeClient.gui.delete.btnDelete:SetText("Delete!")
		
		AdvDupeClient.gui.delete.btnCancel = vgui.Create("Button",AdvDupeClient.gui.delete.frame,"btnCancel")
		AdvDupeClient.gui.delete.btnCancel:SetPos(184,110)
		AdvDupeClient.gui.delete.btnCancel:SetSize(110,20)
		AdvDupeClient.gui.delete.btnCancel:SetText("Cancel")
		AdvDupeClient.gui.delete.btnCancel:SetCommand("Cancel")
		
		AdvDupeClient.gui.delete.lblFileName = vgui.Create("Label",AdvDupeClient.gui.delete.frame,"lblFileName")
		AdvDupeClient.gui.delete.lblFileName:SetPos(6,25)
		AdvDupeClient.gui.delete.lblFileName:SetSize(185,25)
		
		function AdvDupeClient.gui.delete.frame:ActionSignal(key,value)
			if key == "DeleteServer" then
				LocalPlayer():ConCommand("adv_duplicator_fileopts delete")
				AdvDupeClient.gui.delete.frame:SetVisible(false)
			elseif key == "DeleteClient" then
				local filename = pl:GetInfo( "adv_duplicator_open_cl" )
				local dir	= AdvDupeClient.CLcdir
				AdvDupeClient.FileOpts("delete", filename, dir)
				AdvDupeClient.gui.delete.frame:SetVisible(false)
			elseif key == "Cancel" then
				AdvDupeClient.gui.delete.frame:SetVisible(false)
			end
		end
	end
	
	if args[1] == "client" then
		AdvDupeClient.gui.delete.btnDelete:SetCommand("DeleteClient")
		
		local oldfilename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename_cl" ))
		AdvDupeClient.gui.delete.lblFileName:SetText("Delete this file \""..oldfilename..".txt\" from \""..string.gsub(AdvDupeClient.CLcdir, dupeshare.BaseDir, "").."/ ?")
	else
		AdvDupeClient.gui.delete.btnDelete:SetCommand("DeleteServer")
		
		local oldfilename = dupeshare.GetFileFromFilename(pl:GetInfo( "adv_duplicator_load_filename" ))
		AdvDupeClient.gui.delete.lblFileName:SetText("Delete this file \""..oldfilename..".txt\" from \""..string.gsub(AdvDupeClient.SScdir, dupeshare.BaseDir, "").."/ ?")
	end
	
	AdvDupeClient.gui.delete.frame:SetKeyBoardInputEnabled( true )
	AdvDupeClient.gui.delete.frame:SetMouseInputEnabled( true )
	AdvDupeClient.gui.delete.frame:SetVisible( true )
	
end
concommand.Add( "adv_duplicator_confirmdelete_gui", AdvDupeClient.ConfirmDelete )


Msg("==== Advanced Duplicator v."..AdvDupeClient.version.." client module installed! ====\n")

