
Msg("=== Loading Wire Model Packs ===\n")

CreateConVar("cl_showmodeltextbox", "0")

ModelPlugInfo = {}

for _,filename in pairs( file.Find("WireModelPacks/*.txt") ) do
	local packtbl = util.KeyValuesToTable(file.Read("WireModelPacks/" .. filename) or {})
	for name,entry in pairs(packtbl) do
		local categorytable = string.Explode(",", entry.categories or "none") or { "none" }
		for _,cat in pairs(categorytable) do
			list.Set( "Wire_"..cat.."_Models", entry.model, {} )
		end
	end
	MsgN("\tLoaded: "..filename)
end



//
//	Add some more options to the stools
//

//screens
list.Set( "WireScreenModels", "models/props_lab/monitor01b.mdl", {} )
list.Set( "WireScreenModels", "models/props/cs_office/TV_plasma.mdl", {} )
list.Set( "WireScreenModels", "models/props/cs_office/computer_monitor.mdl", {} )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorbig.mdl", {} )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorsmall.mdl", {} )

//sounds
local WireSounds = {
	Warning = "common/warning.wav",
	Talk = "common/talk.wav",
	Button = "buttons/button15.wav",
	Denied = "buttons/weapon_cant_buy.wav",
	Zap = "ambient/energy/zap2.wav",
	["Oh No"] = "vo/npc/male01/ohno.wav",
	Yeah = "vo/npc/male01/yeah02.wav",
	["apc alarm"] = "ambient/alarms/apc_alarm_loop1.wav",
	["Coast Siren"] = "coast.siren_citizen",
	["Bunker Siren"] = "coast.bunker_siren1",
	["Alarm Bell"] = "d1_canals.Floodgate_AlarmBellLoop",
	["Engine Start"] = "ATV_engine_start",
	["Engine Stop"] = "ATV_engine_stop",
	["Zombie Breathe"] = "NPC_PoisonZombie.Moan1",
	["Idle Zombies"] = "Zombie.Idle",
	["Turret Alert"] = "NPC_FloorTurret.Alert",
	["Helicopter Rotor"] = "NPC_CombineGunship.RotorSound",
	Heartbeat = "k_lab.teleport_heartbeat",
	Breathing = "k_lab.teleport_breathing",
}
for k,v in pairs(WireSounds) do
	list.Set("WireSounds",k,{wire_soundemitter_sound=v});
end


//some extra wheels that wired wheels have
local wastelandwheels = {
	"models/props_wasteland/wheel01a.mdl",
	"models/props_wasteland/wheel02a.mdl",
	"models/props_wasteland/wheel03a.mdl",
	"models/props_wasteland/wheel03b.mdl"
}
for k,v in pairs(wastelandwheels) do
	if file.Exists("../"..v) then
	list.Set( "WheelModels", v, { wheel_rx = 90, wheel_ry = 0, wheel_rz = 90} )
	end
end


//Cheeze's Buttons Pack or Wire Model Pack 1
MsgN("\tAdding Cheeze's Buttons Pack")
local CheezesButtons = {
	"models/cheeze/buttons/button_0.mdl",
	"models/cheeze/buttons/button_1.mdl",
	"models/cheeze/buttons/button_2.mdl",
	"models/cheeze/buttons/button_3.mdl",
	"models/cheeze/buttons/button_4.mdl",
	"models/cheeze/buttons/button_5.mdl",
	"models/cheeze/buttons/button_6.mdl",
	"models/cheeze/buttons/button_7.mdl",
	"models/cheeze/buttons/button_8.mdl",
	"models/cheeze/buttons/button_9.mdl",
	"models/cheeze/buttons/button_arm.mdl",
	"models/cheeze/buttons/button_clear.mdl",
	"models/cheeze/buttons/button_enter.mdl",
	"models/cheeze/buttons/button_fire.mdl",
	"models/cheeze/buttons/button_minus.mdl",
	"models/cheeze/buttons/button_muffin.mdl",
	"models/cheeze/buttons/button_plus.mdl",
	"models/cheeze/buttons/button_reset.mdl",
	"models/cheeze/buttons/button_set.mdl",
	"models/cheeze/buttons/button_start.mdl",
	"models/cheeze/buttons/button_stop.mdl",
	//more buttons
	"models/props_citizen_tech/Firetrap_button01a.mdl",
	"models/props_lab/freightelevatorbutton.mdl",
	"models/props_combine/CombineButton.mdl"
}
for k,v in pairs(CheezesButtons) do
	if file.Exists("../"..v) then
		list.Set( "ButtonModels", v, {} )
	end
end


//PHX Final Pack
--Removed, PHX2 has this info now


//Thrusters
//Jaanus Thruster Pack
MsgN("\tJaanus' Thruster Pack")
local JaanusThrusters = {
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/jaanus/thruster_flat.mdl",
	"models/jaanus/thruster_invisi.mdl",
	"models/jaanus/thruster_shoop.mdl",
	"models/jaanus/thruster_smile.mdl",
	"models/jaanus/thruster_muff.mdl",
	"models/jaanus/thruster_rocket.mdl",
	"models/jaanus/thruster_megaphn.mdl",
	"models/jaanus/thruster_stun.mdl"
}
for k,v in pairs(JaanusThrusters) do
	if file.Exists("../"..v) then
		list.Set( "ThrusterModels", v, {} )
	end
end
