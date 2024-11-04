GLOBAL_LIST_INIT(mi13_theft_objectives_weights, list(
	/datum/theft_objective/highrisk/blueprints = 2,
	/datum/theft_objective/highrisk/documents = 2,
))

/datum/affiliate/mi13
	name = AFFIL_MI13
	affil_info = list("Агенство специализирующееся на добыче и продаже секретной информации и разработок.",
					"Стандартные цели:",
					"Украсть секретные документы",
					"Украсть определенное количество ценных вещей",
					"Убить определенное количество членов экипажа",
					"Обменяться секретными документами с другим агентом",
					"Выглядеть стильно")
	slogan = "Да, я Бонд. Джеймс Бонд."
	icon_state = "mi13"
	normal_objectives = 5

/proc/is_MI13_agent(mob/living/user)
	var/datum/antagonist/traitor/traitor = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	return istype(traitor?.affiliate, /datum/affiliate/mi13)

/datum/affiliate/mi13/finalize_affiliate(datum/mind/owner)
	. = ..()
	var/datum/antagonist/traitor/traitor = owner.has_antag_datum(/datum/antagonist/traitor)
	traitor.assign_exchange_role(SSticker.mode.exchange_red)
	uplink.get_intelligence_data = TRUE

/datum/affiliate/mi13/give_bonus_objectives()
	traitor.add_objective(/datum/objective/steal)
	traitor.add_objective(/datum/objective/steal)

/datum/affiliate/mi13/proc/gen_default_objective()
	if(prob(40))
		if(length(active_ais()) && prob(100 / length(GLOB.player_list)))
			return /datum/objective/destroy

		else if(prob(5))
			return /datum/objective/debrain

		else if(prob(15))
			return /datum/objective/protect

		else
			return pickweight(list(/datum/objective/maroon = 40, /datum/objective/maroon/agent = 60))

	else
		return /datum/objective/steal

/datum/affiliate/mi13/give_default_objective()
	var/obj_type = gen_default_objective()
	if(obj_type != /datum/objective/steal)
		traitor.add_objective(obj_type)
		return

	var/target_type = gen_steal_objective(GLOB.mi13_theft_objectives_weights)
	if(target_type)
		traitor.add_objective(/datum/objective/steal, target_override = target_type)
	else
		traitor.add_objective(/datum/objective/steal)
