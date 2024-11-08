// Foam
// Similar to smoke, but spreads out more
// metal foams leave behind a foamed metal wall

/obj/effect/particle_effect/foam
	name = "foam"
	icon_state = "foam"
	opacity = FALSE
	anchored = TRUE
	density = FALSE
	layer = OBJ_LAYER + 0.9
	animate_movement = NO_STEPS
	var/amount = 3
	var/metal = FALSE


/obj/effect/particle_effect/foam/Initialize(mapload, metal = FALSE)
	. = ..()

	icon_state = "[metal ? "m":""]foam"

	if(!metal && reagents)
		color = mix_color_from_reagents(reagents.reagent_list)

	src.metal = metal
	playsound(src, 'sound/effects/bubbles2.ogg', 80, TRUE, -3)

	if(!metal)
		var/static/list/loc_connections = list(
			COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		)
		AddElement(/datum/element/connect_loc, loc_connections)

	spawn(3 + metal*3)
		process()
	spawn(120)
		STOP_PROCESSING(SSobj, src)
		sleep(30)

		if(metal)
			var/turf/T = get_turf(src)
			if(isspaceturf(T) && !istype(T, /turf/space/transit))
				T.ChangeTurf(/turf/simulated/floor/plating/metalfoam)
				var/turf/simulated/floor/plating/metalfoam/MF = get_turf(src)
				MF.metal = metal
				MF.update_icon()

			var/obj/structure/foamedmetal/M = new(src.loc)
			M.metal = metal
			M.update_state()

		flick("[icon_state]-disolve", src)
		sleep(5)
		qdel(src)


// on delete, transfer any reagents to the floor
/obj/effect/particle_effect/foam/Destroy()
	if(!metal && reagents)
		reagents.handle_reactions()
		for(var/atom/A in oview(1, src))
			if(A == src)
				continue
			if(reagents.total_volume)
				var/fraction = 5 / reagents.total_volume
				reagents.reaction(A, REAGENT_TOUCH, fraction)
	return ..()

// foam disolves when heated
// except metal foams
/obj/effect/particle_effect/foam/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume, global_overlay = TRUE) //Don't heat the reagents inside
	return

/obj/effect/particle_effect/foam/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume) // overriden to prevent weird behaviors with heating reagents inside
	if(!metal && prob(max(0, exposed_temperature - 475)))
		flick("[icon_state]-disolve", src)

		spawn(5)
			qdel(src)


/obj/effect/particle_effect/foam/proc/on_entered(datum/source, mob/living/carbon/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(!iscarbon(arrived))
		return

	if(!arrived.slip(4 SECONDS))
		return

	if(!reagents)
		return

	for(var/reagent_id in reagents.reagent_list)
		var/amount = arrived.reagents.get_reagent_amount(reagent_id)
		if(amount < 25)
			arrived.reagents.add_reagent(reagent_id, min(round(amount / 2), 15))

	if(reagents.total_volume)
		var/fraction = 5 / reagents.total_volume
		reagents.reaction(arrived, REAGENT_TOUCH, fraction)

/turf/proc/can_spawn_foam()
	if(!isfloorturf(src))
		return FALSE

	for(var/obj/effect/particle_effect/foam/foam in src)
		return FALSE

	return TRUE

// This distribution has too many differences from the usual effect systems.
/atom/proc/do_foam(amount = 5, datum/reagents/reagents, foamtype = NORMAL_FOAM)
	amount = clamp(amount, 1, 85) // 85 - The number of tiles with Manhattan distance is no more than 6 (a.k.a. radius 7).
	var/turf/epicenter = get_turf(src)
	if(!epicenter)
		return

	reagents.remove_reagent("smoke_powder")
	reagents.remove_reagent("fluorosurfactant")
	reagents.remove_reagent("stimulants")

	spawn(0)
		var/created = 0
		var/list/spawning_now
		var/list/turf/possible_turfs = list(epicenter)

		while(amount - created >= possible_turfs.len && possible_turfs.len)
			created += possible_turfs.len
			spawning_now = possible_turfs
			possible_turfs = list()

			for(var/turf/T in spawning_now)
				var/obj/effect/particle_effect/foam/F = new(T, foamtype)
				for(var/dir in GLOB.cardinal)
					var/turf/possible = get_step(T, dir)
					if(!possible)
						continue

					if(!possible.Enter(F))
						continue

					if(possible in possible_turfs)
						continue

					if(possible.can_spawn_foam())
						possible_turfs.Add(possible)

				if(foamtype != NORMAL_FOAM)
					continue

				if(!reagents)
					F.create_reagents(1)
					F.reagents.add_reagent("cleaner", 1)
					F.color = mix_color_from_reagents(F.reagents.reagent_list)
					continue

				F.create_reagents(reagents.total_volume / amount)
				reagents.trans_to(F, reagents.total_volume / amount)
				F.color = mix_color_from_reagents(F.reagents.reagent_list)

			sleep(1)

// wall formed by metal foams
// dense and opaque, but easy to break

/obj/structure/foamedmetal
	name = "foamed metal"
	desc = "A lightweight foamed metal wall."
	icon = 'icons/effects/effects.dmi'
	icon_state = "metalfoam"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	density = TRUE
	opacity = TRUE	// changed in New()
	anchored = TRUE
	max_integrity = 20
	var/metal = MFOAM_ALUMINUM
	obj_flags = BLOCK_Z_IN_DOWN | BLOCK_Z_IN_UP

/obj/structure/foamedmetal/Initialize()
	..()
	air_update_turf(1)

/obj/structure/foamedmetal/Destroy()
	var/turf/T = get_turf(src)
	. = ..()
	T.air_update_turf(TRUE)

/obj/structure/foamedmetal/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	var/turf/T = loc
	. = ..()
	move_update_air(T)

/obj/structure/foamedmetal/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	playsound(src.loc, 'sound/weapons/tap.ogg', 100, TRUE)


/obj/structure/foamedmetal/proc/update_state()
	if(metal == MFOAM_ALUMINUM)
		max_integrity = 20
		obj_integrity = max_integrity
	else
		max_integrity = 50
		obj_integrity = max_integrity
	update_icon(UPDATE_ICON_STATE)


/obj/structure/foamedmetal/update_icon_state()
	icon_state = (metal == MFOAM_ALUMINUM) ? "metalfoam" : "ironfoam"


/obj/structure/foamedmetal/attack_hand(mob/user)
	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	if(prob(75 - metal * 25))
		user.visible_message("<span class='warning'>[user] smashes through [src].</span>", "<span class='notice'>You smash through [src].</span>")
		qdel(src)
	else
		add_fingerprint(user)
		to_chat(user, "<span class='notice'>You hit the metal foam but bounce off it.</span>")
		playsound(loc, 'sound/weapons/tap.ogg', 100, 1)


/obj/structure/foamedmetal/CanAtmosPass(turf/T, vertical)
	return !density
