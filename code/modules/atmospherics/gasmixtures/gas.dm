/datum/gas
	var/id = "no_id"
	var/amount = 0

/datum/gas/New(id = "no_id", amount = 0)
	. = ..()
	src.id = id
	src.amount = amount

/datum/gas/proc/specific_heatcap()
	. = HEAT_CAP_DEFAULT
	if(id in GLOB.gastype_specific_heatcup_by_id)
		return GLOB.gastype_specific_heatcup_by_id[id]

/datum/gas/proc/heatcap()
	return specific_heatcap() * amount

/datum/gas/proc/add(amount)
	src.amount += amount

/datum/gas/proc/_set(amount)
	src.amount = amount

/datum/gas/proc/get()
	return amount

/proc/get_specific_heatcap(id)
	. = HEAT_CAP_DEFAULT
	if(id in GLOB.gastype_specific_heatcup_by_id)
		return GLOB.gastype_specific_heatcup_by_id[id]

/datum/gas/proc/check()
	amount = QUANTIZE(amount)
	if(!amount)
		return TRUE

/datum/gas/proc/on_breath(mob/living/carbon/human/breather)
	if(!istype(breather))
		return

	if(!(id in GLOB.chemical_reagents_list))
		return

	if(amount >= 0.1)
		breather.reagents.add_reagent(id, amount)
		return

	if(!prob(100 * amount / 0.1))
		return

	var/datum/reagent/R = GLOB.chemical_reagents_list[id]
	var/datum/reagent/reagent = new R.type
	reagent.volume = amount

	var/is_in = breather.reagents.has_reagent(id)

	if(!is_in)
		reagent.on_mob_add(breather)

	reagent.on_mob_life(breather)

	if(!is_in)
		reagent.on_mob_delete(breather)

/datum/gas/proc/on_touch(mob/living/carbon/human/target)
	. = 0
	if(!istype(target))
		return

	if(!(id in GLOB.chemical_reagents_list))
		return

	var/datum/reagent/R = GLOB.chemical_reagents_list[id]
	var/datum/reagent/reagent = new R.type
	reagent.reaction_mob(target, REAGENT_TOUCH, amount * GASES_TOUCH_PERCENTAGE)
	return amount * GASES_TOUCH_PERCENTAGE

/datum/gas/not_reagent/on_breath(mob/living/breather)
	return 0;

/datum/gas/not_reagent/plasma

/datum/gas/not_reagent/oxygen

/datum/gas/not_reagent/nitrogen

/datum/gas/not_reagent/cdo

/datum/gas/not_reagent/n2o

/datum/gas/not_reagent/agent_b
