/datum/affiliate/gorlex
	name = AFFIL_GORLEX
	affil_info = list("Группировка специализирующаяся на налетах.",
					"Основная специализация - массовые убийства.",
					"Стандартные цели:",
					"Убить важных корпоративных крыс",
					"Убить рядовых корпоративных крыс",
					"Умереть героем")
	slogan = "Давайте, вошли и вышли, приключение на 20 минут."
	hij_desc = "Вы - наёмный солдат Gorlex Marauders, засланный на станцию NT с особой целью:\n\
			активировать системы самоуничтожения станции. \n\
			Вам предоставлен обширный арсенал для закупки всего необходимого, однако ваши средства ограничены. \n\
			Вам установлен особый имплант, помогающий идентифицировать солдат Gorlex Maraduers - пользуйтесь этим;\n\
			Вам предоставлен код от системы самоуничтожения станции, а также система отслеживания диска ядерной аутентификации;\n\
			Каждый наёмник Gorlex Maraduers будет обязан помочь вам;\n\
			Возможны помехи от агентов других корпораций - действуйте на свое усмотрение."
	icon_state = "gorlex"
	hij_obj = /datum/objective/nuclear/traitor
	normal_objectives = 5
	can_take_bonus_objectives = FALSE
	escape_type = /datum/objective/die

/datum/affiliate/gorlex/finalize_affiliate(datum/mind/owner)
	. = ..()
	var/datum/atom_hud/antag/gorlhud = GLOB.huds[ANTAG_HUD_AFFIL_GORLEX]
	gorlhud.join_hud(owner.current)
	set_antag_hud(owner.current, "hudaffilgorlex")

/datum/affiliate/gorlex/get_weight(mob/living/carbon/human/H)
	var/gorlexes = 0
	for (var/datum/antagonist/traitor/traitor in GLOB.antagonists)
		gorlexes += traitor?.affiliate?.type == /datum/affiliate/gorlex

	if(gorlexes > 2)
		return 0

	switch (H.dna.species.type)
		if(/datum/species/human)
			return 1

		if(/datum/species/nucleation)
			return 1

		if(/datum/species/machine)
			return 0.2

		if(/datum/species/slime)
			return 0.2

	return 0

/datum/affiliate/mi13/give_default_objective()
	traitor.add_objective(pickweight(list(
		/datum/objective/assassinate/headofstaff = 30,
		/datum/objective/assassinate/procedure = 20,
		/datum/objective/assassinate = 45,
		/datum/objective/destroy = 5,
	)))

/datum/affiliate/gorlex/give_bonus_objectives()
	return
