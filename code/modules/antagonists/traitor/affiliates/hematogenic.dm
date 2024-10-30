GLOBAL_LIST_INIT(hematogenic_theft_objectives_weights, list(
	/datum/theft_objective/highrisk/defib = 3,
	/datum/theft_objective/highrisk/hypospray = 3,
))

/datum/affiliate/hematogenic
	name = AFFIL_HEMATOGENIC
	affil_info = list("Фармацевтическая мега корпорация подозревающаяся в связях с вампирами.",
					"Стандартные цели:",
					"Собрать образцы крови полной различной духовной энергии",
					"Украсть передовые медицинские технологии",
					"Сделать одного из членов экипажа вампиром",
					"Украсть что-то ценное или убить кого-то")
	slogan = "Мы с тобой одной крови."
	hij_desc = "Вы - опытный наёмный агент Hematogenic Industries.\n\
				Основатель Hematogenic Industries высоко оценил ваши прошлые заслуги, а потому, дал вам возможность купить инжектор наполненный его собственной кровью... \n\
				Вас предупредили, что после инъекции вы будете продолжительное время испытывать сильный голод. \n\
				Ваша задача - утолить этот голод.\n\
				Возможны помехи от агентов других корпораций - действуйте на свое усмотрение."
	icon_state = "hematogenic"
	hij_obj = /datum/objective/blood/ascend
	normal_objectives = 2
	objectives = list(list(/datum/objective/harvest_blood = 80, /datum/objective/new_mini_vampire = 20),
					/datum/objective/escape
					)

/datum/affiliate/hematogenic/get_weight(mob/living/carbon/human/H)
	return (!ismachineperson(H) && H.mind?.assigned_role != JOB_TITLE_CHAPLAIN) * 2

/datum/affiliate/hematogenic/proc/gen_default_objective()
	if(prob(60))
		if(length(active_ais()) && prob(100 / length(GLOB.player_list)))
			return /datum/objective/destroy

		else if(prob(5))
			return /datum/objective/debrain

		else if(prob(10))
			return /datum/objective/protect

		else
			return /datum/objective/maroon

	else
		return /datum/objective/steal

/datum/affiliate/hematogenic/give_default_objective()
	var/obj_type = gen_default_objective()
	if(obj_type != /datum/objective/steal)
		traitor.add_objective(obj_type)
		return

	var/target_type = gen_steal_objective(GLOB.hematogenic_theft_objectives_weights)
	if(target_type)
		traitor.add_objective(/datum/objective/steal, target_override = target_type)
	else
		traitor.add_objective(/datum/objective/steal)
