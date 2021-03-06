/turf/simulated/floor/attackby(obj/item/C as obj, mob/user as mob)

	if(!C || !user)
		return 0

	if(isliving(user) && istype(C, /obj/item/weapon))
		var/mob/living/L = user
		if(L.a_intent != I_HELP)
			attack_tile(C, L) // Be on help intent if you want to decon something.
			return

	if(flooring)
		if(istype(C, /obj/item/weapon))
			try_deconstruct_tile(C, user)
			return
		else if(istype(C, /obj/item/stack/cable_coil))
			to_chat(user, "<span class='warning'>You must remove the [flooring.descriptor] first.</span>")
			return
		else if(istype(C, /obj/item/stack/tile))
			try_replace_tile(C, user)
			return
	else

		if(istype(C, /obj/item/stack/cable_coil))
			if(broken || burnt)
				to_chat(user, "<span class='warning'>This section is too damaged to support anything. Use a welder to fix the damage.</span>")
				return
			var/obj/item/stack/cable_coil/coil = C
			coil.turf_place(src, user)
			return
		else if(istype(C, /obj/item/stack))
			if(broken || burnt)
				to_chat(user, "<span class='warning'>This section is too damaged to support anything. Use a welder to fix the damage.</span>")
				return
			var/obj/item/stack/S = C
			var/decl/flooring/use_flooring
			for(var/flooring_type in flooring_types)
				var/decl/flooring/F = flooring_types[flooring_type]
				if(!F.build_type)
					continue
				if((S.type == F.build_type) || (S.build_type == F.build_type))
					use_flooring = F
					break
			if(!use_flooring)
				return
			// Do we have enough?
			if(use_flooring.build_cost && S.amount < use_flooring.build_cost)
				to_chat(user, "<span class='warning'>You require at least [use_flooring.build_cost] [S.name] to complete the [use_flooring.descriptor].</span>")
				return
			// Stay still and focus...
			if(use_flooring.build_time && !do_after(user, use_flooring.build_time))
				return
			if(flooring || !S || !user || !use_flooring)
				return
			if(S.use(use_flooring.build_cost))
				set_flooring(use_flooring)
				playsound(src, 'sound/items/Deconstruct.ogg', 80, 1)
				return
		// Repairs.
		else if(istype(C, /obj/item/weapon/weldingtool))
			var/obj/item/weapon/weldingtool/welder = C
			if(welder.isOn() && (is_plating()))
				if(broken || burnt)
					if(welder.remove_fuel(0,user))
						to_chat(user, "<span class='notice'>You fix some dents on the broken plating.</span>")
						playsound(src, welder.usesound, 80, 1)
						icon_state = "plating"
						burnt = null
						broken = null
					else
						to_chat(user, "<span class='warning'>You need more welding fuel to complete this task.</span>")

/turf/simulated/floor/proc/try_deconstruct_tile(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/crowbar))
		if(broken || burnt)
			to_chat(user, "<span class='notice'>You remove the broken [flooring.descriptor].</span>")
			make_plating()
		else if(flooring.flags & TURF_IS_FRAGILE)
			to_chat(user, "<span class='danger'>You forcefully pry off the [flooring.descriptor], destroying them in the process.</span>")
			make_plating()
		else if(flooring.flags & TURF_REMOVE_CROWBAR)
			to_chat(user, "<span class='notice'>You lever off the [flooring.descriptor].</span>")
			make_plating(1)
		else
			return 0
		playsound(src, W.usesound, 80, 1)
		return 1
	else if(istype(W, /obj/item/weapon/screwdriver) && (flooring.flags & TURF_REMOVE_SCREWDRIVER))
		if(broken || burnt)
			return 0
		to_chat(user, "<span class='notice'>You unscrew and remove the [flooring.descriptor].</span>")
		make_plating(1)
		playsound(src, W.usesound, 80, 1)
		return 1
	else if(istype(W, /obj/item/weapon/wrench) && (flooring.flags & TURF_REMOVE_WRENCH))
		to_chat(user, "<span class='notice'>You unwrench and remove the [flooring.descriptor].</span>")
		make_plating(1)
		playsound(src, W.usesound, 80, 1)
		return 1
	else if(istype(W, /obj/item/weapon/shovel) && (flooring.flags & TURF_REMOVE_SHOVEL))
		to_chat(user, "<span class='notice'>You shovel off the [flooring.descriptor].</span>")
		make_plating(1)
		playsound(src, 'sound/items/Deconstruct.ogg', 80, 1)
		return 1
	return 0

/turf/simulated/floor/proc/try_replace_tile(obj/item/stack/tile/T as obj, mob/user as mob)
	if(T.type == flooring.build_type)
		return
	var/obj/item/weapon/W = user.is_holding_item_of_type(/obj/item/weapon)
	if(!try_deconstruct_tile(W, user))
		return
	if(flooring)
		return
	attackby(T, user)