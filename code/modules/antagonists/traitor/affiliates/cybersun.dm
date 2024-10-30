GLOBAL_LIST_INIT(cybersun_theft_objectives_weights, list(
	/datum/theft_objective/highrisk/antique_laser_gun = 1.3,
	/datum/theft_objective/highrisk/captains_jetpack = 1.2,
	/datum/theft_objective/highrisk/captains_rapier = 0.6,
	/datum/theft_objective/highrisk/hoslaser = 1.3,
	/datum/theft_objective/highrisk/hand_tele = 2,
	/datum/theft_objective/highrisk/ai = 2,
	/datum/theft_objective/highrisk/defib = 1.2,
	/datum/theft_objective/highrisk/magboots = 1.1,
	/datum/theft_objective/highrisk/combatrcd = 1.3,
	/datum/theft_objective/highrisk/blueprints = 0.7,
	/datum/theft_objective/highrisk/capmedal = 0.4,
	/datum/theft_objective/highrisk/nukedisc = 0.5,
	/datum/theft_objective/highrisk/reactive = 1.5,
	/datum/theft_objective/highrisk/documents = 0.4,
	/datum/theft_objective/highrisk/hypospray = 1.2,
	/datum/theft_objective/highrisk/ablative = 1.1,
	/datum/theft_objective/highrisk/krav = 1.1,
	/datum/theft_objective/highrisk/supermatter_sliver = 0.6,
	/datum/theft_objective/highrisk/plutonium_core = 0.6,
))

/datum/affiliate/cybersun
	name = AFFIL_CYBERSUN
	affil_info = list("Одна из ведущих корпораций занимающихся передовыми исследованиями.",
					"Стандартные цели:",
					"Украсть технологии",
					"Украсть определенное количество ценных вещей",
					"Убить определенное количество членов экипажа",
					"Угнать мех или под",
					"Завербовать нового агента вколов ему модифицированный имплант \"Mindslave\".")
	slogan = "Сложно быть во всём лучшими, но у нас получается."
	hij_desc = "Вы - наёмный агент Cybersun Industries, засланный на станцию NT с особой целью:\n\
				Взломать искусственный интеллект станции специальным, предоставленным вам, устройством. \n\
				После взлома, искусственный интеллект попытается уничтожить станцию. \n\
				Ваша задача ему с этим помочь;\n\
				Ваше выживание опционально;\n\
				Возможны помехи от агентов других корпораций - действуйте на свое усмотрение."
	icon_state = "cybersun"
	hij_obj = /datum/objective/make_ai_malf
	normal_objectives = 4
	objectives = list(list(/datum/objective/download_data = 70, /datum/objective/steal/ai = 10, /datum/objective/new_mini_traitor = 20),
						/datum/objective/escape,
						)

/datum/affiliate/cybersun/finalize_affiliate()
	. = ..()
	for(var/path in subtypesof(/datum/uplink_item/implants))
		add_discount_item(path, 0.8)

	add_discount_item(/datum/uplink_item/device_tools/hacked_module, 2/3)

/datum/affiliate/cybersun/proc/gen_default_objective()
	if(prob(40))
		if(length(active_ais()) && prob(100 / length(GLOB.player_list)))
			return /datum/objective/destroy

		else if(prob(5))
			return /datum/objective/debrain

		else if(prob(15))
			return /datum/objective/protect

		else if(prob(10))
			return /datum/objective/mecha_or_pod_hijack

		else
			return /datum/objective/maroon

	else
		return /datum/objective/steal

/datum/affiliate/cybersun/give_default_objective()
	var/obj_type = gen_default_objective()
	if(obj_type != /datum/objective/steal)
		traitor.add_objective(obj_type)
		return

	var/target_type = gen_steal_objective(GLOB.cybersun_theft_objectives_weights)
	if(target_type)
		traitor.add_objective(/datum/objective/steal, target_override = target_type)
	else
		traitor.add_objective(/datum/objective/steal)
