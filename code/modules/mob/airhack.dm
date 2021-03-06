/mob
	var/datum/gas_mixture/air_contents = new
	var/obj/machinery/atmospherics/portables_connector/connected_port
	var/obj/item/weapon/tank/holding
	var/volume = 1000
	var/destroyed = 0
	var/start_pressure = ONE_ATMOSPHERE
	var/maximum_pressure = 90 * ONE_ATMOSPHERE
	var/inflatable = 1
	
/mob/living
	inflatable= 0
	
/mob/New()
	..()
	air_contents.volume = volume
	air_contents.temperature = T20C
	return 1
	
/mob/Destroy()
	qdel_null(air_contents)
	qdel_null(holding)
	. = ..()
	
/mob/Life()
	if(!connected_port) //only react when pipe_network will ont it do it for you
		//Allow for reactions
		air_contents.react()
	. = ..()
	
/mob/proc/StandardAirMix()
	return list(
		"oxygen" = O2STANDARD * MolesForPressure(),
		"nitrogen" = N2STANDARD *  MolesForPressure())
		
/mob/proc/MolesForPressure(var/target_pressure = start_pressure)
	return (target_pressure * air_contents.volume) / (R_IDEAL_GAS_EQUATION * air_contents.temperature)

/mob/proc/connect(obj/machinery/atmospherics/portables_connector/new_port)
	//Make sure not already connected to something else
	if(connected_port || !new_port || new_port.connected_device)
		return 0

	//Make sure are close enough for a valid connection
	if(new_port.loc != loc)
		return 0

	//Perform the connection
	connected_port = new_port
	connected_port.connected_device = src
	connected_port.on = 1 //Activate port updates
	buckled = 1 //Prevent movement
	anchored = 1

	//Actually enforce the air sharing
	var/datum/pipe_network/network = connected_port.return_network(src)
	if(network && !network.gases.Find(air_contents))
		network.gases += air_contents
		network.update = 1
	return 1

/mob/proc/disconnect()
	if(!connected_port)
		return 0
	var/datum/pipe_network/network = connected_port.return_network(src)
	if(network)
		network.gases -= air_contents
	buckled = 0
	anchored = 0
	connected_port.connected_device = null
	connected_port = null
	return 1

/mob/proc/update_connected_network()
	if(!connected_port)
		return
	var/datum/pipe_network/network = connected_port.return_network(src)
	if (network)
		network.update = 1

/mob/proc/Airattackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(src.inflatable == 0)
		return 0
	if (istype(W, /obj/item/weapon/wrench))
		if(connected_port)
			disconnect()
			user << "<span class='notice'>You disconnect \the [src] from the port.</span>"
			update_icon()
			playsound(src, W.usesound, 50, 1)
			return 1
		else
			var/obj/machinery/atmospherics/portables_connector/possible_port = locate(/obj/machinery/atmospherics/portables_connector/) in loc
			if(possible_port)
				if(connect(possible_port))
					user << "<span class='notice'>You connect \the [src] to the port.</span>"
					update_icon()
					playsound(src, W.usesound, 50, 1)
					return 1
				else
					user << "<span class='notice'>\The [src] failed to connect to the port.</span>"
					return 0
			else
				return 0
	else if ((istype(W, /obj/item/device/analyzer)) && Adjacent(user))
		var/obj/item/device/analyzer/A = W
		A.analyze_gases(src, user)
		return 1
	return 0

/mob/proc/atmosanalyze(var/mob/user)
	return atmosanalyzer_scan(src, src.air_contents, user)
