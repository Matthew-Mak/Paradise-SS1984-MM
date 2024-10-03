/datum/disease/virus
	form = "Вирус"
	carrier_mobtypes = list(/mob/living/simple_animal/mouse)

	/// If TRUE, host not affected by virus, but can spread it (mostly for viruses)
	var/carrier = FALSE
	///method of infection of the virus
	var/spread_flags = NON_CONTAGIOUS
	///affects how often the virus will try to spread. The more the better. In range [0-100]
	var/infectivity = 65
	///affects how well the virus will pass through the protection. The more the better. In range (0-2]
	var/permeability_mod = 1
	/// Virus can contract others, if carrier is dead with this chance. Set to 0, if can't. Must be in [0, 100].
	var/spread_from_dead_prob = 40

/datum/disease/virus/New()
	..()
	additional_info = spread_text()

/**
 * Main virus process, that executed every tick
 *
 * Returns:
 * * TRUE - if process finished the work properlly
 * * FALSE - if don't need to call a child proc
 */
/datum/disease/virus/stage_act()
	if(!affected_mob)
		return FALSE

	if(can_spread())
		spread()

	. = ..()

	if(!. || carrier)
		return FALSE

	for(var/mobtype in carrier_mobtypes)
		if(istype(affected_mob, mobtype))
			return FALSE

	return TRUE

/datum/disease/virus/try_increase_stage()
	if(prob(affected_mob.reagents?.has_reagent("spaceacillin") ? stage_prob/2 : stage_prob))
		stage = min(stage + 1,max_stages)
		if(!discovered && stage >= CEILING(max_stages * discovery_threshold, 1)) // Once we reach a late enough stage, medical HUDs can pick us up even if we regress
			discovered = TRUE
			affected_mob.med_hud_set_status()

/datum/disease/virus/proc/can_spread()
	if(istype(affected_mob.loc, /obj/structure/closet/body_bag/biohazard))
		return FALSE
	if(prob(infectivity) && (affected_mob.stat != DEAD || prob(spread_from_dead_prob)))
		return TRUE
	return FALSE

/datum/disease/virus/Contract(mob/living/M, act_type, is_carrier = FALSE, need_protection_check = FALSE, zone)
	var/datum/disease/virus/V = ..(M, act_type, need_protection_check, zone)
	V.carrier = is_carrier
	return V


/**
 * An attempt to spread the virus to others
 * Arguments:
 * * spread_range - radius of the infection zone. Use 0 to default value.
 * * force_spread_flags - use the spread flag or a combination of them so that even a non-contagious virus can spread in this way
 */
/datum/disease/virus/proc/spread(spread_range = 0, force_spread_flags = null)
	if(!affected_mob)
		return

	if(affected_mob.reagents?.has_reagent("spaceacillin") || (affected_mob.satiety > 0 && prob(affected_mob.satiety/10)))
		return

	var/act_type = force_spread_flags ? force_spread_flags : spread_flags
	if(act_type <= BLOOD)
		return

	if(!spread_range)
		switch(spread_flags)
			if(CONTACT)
				spread_range = CONTACT_SPREAD_RANGE
			if(AIRBORNE)
				spread_range = AIRBORNE_SPREAD_RANGE

	var/turf/T = get_turf(affected_mob)
	if(istype(T))
		for(var/mob/living/C in view(spread_range, T))
			var/turf/V = get_turf(C)
			if(V)
				while(TRUE)
					if(V == T)
						//if we wear bio suit, for example, we won't be able to contract anyone
						if(affected_mob.CheckVirusProtection(src, act_type))
							return
						Contract(C, act_type, need_protection_check = TRUE)
						break
					var/turf/Temp = get_step_towards(V, T)
					if(!V.CanAtmosPass(Temp, vertical = FALSE))
						break
					V = Temp

/datum/disease/virus/proc/spread_text()
	var/list/spread = list()
	if(!spread_flags)
		spread += "Не заразный"
	if(spread_flags & BITES)
		spread += "Распространяемый через укусы"
	if(spread_flags & BLOOD)
		spread += "Распространяемый через кровь"
	if(spread_flags & CONTACT)
		spread += "Контактный"
	if(spread_flags & AIRBORNE)
		spread += "Воздушно-капельный"
	return english_list(spread, "Неизвестен", " и ")

/datum/disease/virus/Copy()
	var/datum/disease/virus/copy = ..()
	var/list/required_vars = list("spread_flags", "infectivity", "permeability_mod")
	for(var/V in required_vars)
		if(istype(vars[V], /list))
			var/list/L = vars[V]
			copy.vars[V] = L.Copy()
		else
			copy.vars[V] = vars[V]
	return copy
