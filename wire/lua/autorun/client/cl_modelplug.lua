
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
	Msg("= Loaded Pack : "..filename.." =\n")
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
list.Set( "WheelModels", "models/props_wasteland/wheel01a.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 90} )
list.Set( "WheelModels", "models/props_wasteland/wheel02a.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 90} )
list.Set( "WheelModels", "models/props_wasteland/wheel03a.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 90} )
list.Set( "WheelModels", "models/props_wasteland/wheel03b.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 90} )


//Add some of the model packs too
//Doing it in wire so almost every server will have it :)

//Cheeze's Buttons Pack or Wire Model Pack 1
Msg("Adding Cheeze's Buttons Pack to list\n")
list.Set( "ButtonModels", "models/cheeze/buttons/button_0.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_1.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_2.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_3.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_4.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_5.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_6.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_7.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_8.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_9.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_arm.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_clear.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_enter.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_fire.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_minus.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_muffin.mdl", {} ) //muffin! lol
list.Set( "ButtonModels", "models/cheeze/buttons/button_plus.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_reset.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_set.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_start.mdl", {} )
list.Set( "ButtonModels", "models/cheeze/buttons/button_stop.mdl", {} )

//Wire Model Pack 1 or Jaanus Thruster Pack
list.Set( "ThrusterModels", "models/jaanus/thruster_flat.mdl", {} )


//PHX Final Pack
// I assume that if you have wire you have PHX model pack too, if you don't, then comment out these lines
Msg("Adding PHX Pack to list\n")
//PHX Wheels
list.Set( "WheelModels", "models/props_phx/facepunch_logo.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/facepunch_barrel.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/oildrum001.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/oildrum001_explosive.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/chrome_tire.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/breakable_tire.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gibs/tire1_gib.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/normal_tire.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/mechanics/medgear.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/mechanics/biggear.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/bevel9.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/bevel12.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/bevel24.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/bevel36.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/spur9.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/spur12.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/spur24.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/gears/spur36.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/smallwheel.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/747wheel.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/trucktire.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/trucktire2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/metal_wheel1.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/metal_wheel2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/wooden_wheel1.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/wooden_wheel2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/metal_plate_curve360.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/metal_plate_curve360x2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/wood/wood_curve360x1.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/wood/wood_curve360x2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/windows/window_curve360x1.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/construct/windows/window_curve360x2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/trains/wheel_medium.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/trains/medium_wheel_2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/trains/double_wheels.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/trains/double_wheels2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/drugster_back.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/drugster_front.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/wheels/monster_truck.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/misc/propeller2x_small.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/misc/propeller3x_small.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/misc/paddle_small.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
list.Set( "WheelModels", "models/props_phx/misc/paddle_small2.mdl", { wheel_rx = 90, 	wheel_ry = 0, 	wheel_rz = 0} )
//Buttons
list.Set( "ButtonModels", "models/props_phx/rt_screen.mdl", {} )
//Thrusters
list.Set( "ThrusterModels", "models/props_junk/garbage_metalcan001a.mdl", {} )


//Jaanus Thruster Pack
// uncomment to enable
/*Msg("Jaanus Thruster Pack\n")
list.Set( "ThrusterModels", "models/jaanus/thruster_invisi.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_shoop.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_smile.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_muff.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_rocket.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_megaphn.mdl", {} )
list.Set( "ThrusterModels", "models/jaanus/thruster_stun.mdl", {} )*/

//more buttons
list.Set( "ButtonModels", "models//props_citizen_tech/Firetrap_button01a.mdl", {} )
list.Set( "ButtonModels", "models//props_lab/freightelevatorbutton.mdl", {} )
list.Set( "ButtonModels", "models/props_combine/CombineButton.mdl", {} )
