//Bot Construction

//Cleanbot assembly
/obj/item/bucket_sensor
	name = "Proxy bucket"
	desc = "Это ведро, к которому прикреплён сенсор."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "bucket_proxy"
	force = 3
	throwforce = 5
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	var/created_name = "Cleanbot"
	var/robot_arm = /obj/item/robot_parts/l_arm


/obj/item/bucket_sensor/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	add_fingerprint(user)
	if(!istype(I, /obj/item/robot_parts/l_arm) && !istype(I, /obj/item/robot_parts/r_arm))
		balloon_alert(user, "для завершения сборки нужна робо-рука")
		return ATTACK_CHAIN_PROCEED

	if(!isturf(loc))
		balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
		return ATTACK_CHAIN_PROCEED

	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()

	balloon_alert(user, "вы завершили сборку")
	to_chat(user, span_notice("Вы завершили сборку чистобота."))
	var/mob/living/simple_animal/bot/cleanbot/new_bot = new(loc)
	transfer_fingerprints_to(new_bot)
	I.transfer_fingerprints_to(new_bot)
	new_bot.add_fingerprint(user)
	new_bot.name = created_name
	new_bot.robot_arm = I.type
	qdel(src)
	qdel(I)
	return ATTACK_CHAIN_BLOCKED_ALL



//Edbot Assembly

/obj/item/ed209_assembly
	name = "\improper ED-209 assembly"
	desc = "Заготовка для чего-то серьёзного."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "ed209_frame"
	item_state = "ed209_frame"
	var/build_step = 0
	var/created_name = "\improper ED-209 Security Robot" //To preserve the name if it's a unique securitron I guess
	var/lasercolor = ""
	var/new_name = ""


/obj/item/ed209_assembly/update_name(updates = ALL)
	. = ..()
	switch(build_step)
		if(1,2)
			name = "legs/frame assembly"
		if(3)
			name = "vest/legs/frame assembly"
		if(4)
			name = "shielded frame assembly"
		if(5)
			name = "covered and shielded frame assembly"
		if(6)
			name = "covered, shielded and sensored frame assembly"
		if(7)
			name = "wired ED-209 assembly"
		if(8)
			name = new_name
		if(9)
			name = "armed [name]"


/obj/item/ed209_assembly/update_icon_state()
	switch(build_step)
		if(1)
			item_state = "ed209_leg"
			icon_state = "ed209_leg"
		if(2)
			item_state = "ed209_legs"
			icon_state = "ed209_legs"
		if(3,4)
			item_state = "[lasercolor]ed209_shell"
			icon_state = "[lasercolor]ed209_shell"
		if(5)
			item_state = "[lasercolor]ed209_hat"
			icon_state = "[lasercolor]ed209_hat"
		if(6,7)
			item_state = "[lasercolor]ed209_prox"
			icon_state = "[lasercolor]ed209_prox"
		if(8,9)
			item_state = "[lasercolor]ed209_taser"
			icon_state = "[lasercolor]ed209_taser"



/obj/item/ed209_assembly/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	switch(build_step)
		if(0, 1)
			add_fingerprint(user)
			if(!istype(I, /obj/item/robot_parts/l_leg) && !istype(I, /obj/item/robot_parts/r_leg))
				balloon_alert(user, "вам нужна робо-нога для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			qdel(I)
			build_step++
			balloon_alert(user, "вы прикрепили робо-ногу к заготовке")
			update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)
			return ATTACK_CHAIN_PROCEED_SUCCESS

		if(2)
			add_fingerprint(user)
			var/newcolor = ""
			if(istype(I, /obj/item/clothing/suit/redtag))
				newcolor = "r"
			else if(istype(I, /obj/item/clothing/suit/bluetag))
				newcolor = "b"
			if(!newcolor && !istype(I, /obj/item/clothing/suit/armor/vest))
				balloon_alert(user, "вам нужен защитный жилет для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			lasercolor = newcolor
			build_step++
			balloon_alert(user, "вы прикрепили жилет к заготовке")
			update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)
			qdel(I)
			return ATTACK_CHAIN_PROCEED_SUCCESS

		if(4)
			add_fingerprint(user)
			switch(lasercolor)
				if("b")
					if(!istype(I, /obj/item/clothing/head/helmet/bluetaghelm))
						balloon_alert(user, "вам нужен синий шлем для лазертага для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
				if("r")
					if(!istype(I, /obj/item/clothing/head/helmet/redtaghelm))
						balloon_alert(user, "вам нужен красный шлем для лазертага для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
				if("")
					if(!istype(I, /obj/item/clothing/head/helmet))
						balloon_alert(user, "вам нужен стандартный шлем СБ для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			build_step++
			balloon_alert(user, "вы прикрепили шлем к заготовке")
			update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(5)
			add_fingerprint(user)
			if(!isprox(I))
				balloon_alert(user, "вам нужен датчик движения для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			qdel(I)
			build_step++
			balloon_alert(user, "вы прикрепили датчик движения к заготовке")
			update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(6)
			add_fingerprint(user)
			var/obj/item/stack/cable_coil/coil = I
			if(!iscoil(I) || coil.get_amount() < 1)
				balloon_alert(user, "вам нужны провода для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			coil.play_tool_sound(src)
			balloon_alert(user, "вы начинаете прокладывать проводку в заготовке")
			if(!do_after(user, 4 SECONDS * I.toolspeed, src, category = DA_CAT_TOOL) || build_step != 6 || QDELETED(coil) || !coil.use(1))
				return ATTACK_CHAIN_PROCEED
			build_step++
			balloon_alert(user, "вы проложили проводку в заготовке")
			update_appearance(UPDATE_NAME)
			return ATTACK_CHAIN_PROCEED_SUCCESS

		if(7)
			add_fingerprint(user)
			new_name = ""
			switch(lasercolor)
				if("b")
					if(!istype(I, /obj/item/gun/energy/laser/tag/blue))
						balloon_alert(user, "вам нужен синий лазертаг-карабин для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
					new_name = "bluetag ED-209 assembly"
				if("r")
					if(!istype(I, /obj/item/gun/energy/laser/tag/red))
						balloon_alert(user, "вам нужен красный лазертаг-карабин для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
					new_name = "redtag ED-209 assembly"
				if("")
					if(!istype(I, /obj/item/gun/energy/gun/advtaser))
						balloon_alert(user, "вам нужен гибридный тазер для продолжения сборки")
						return ATTACK_CHAIN_PROCEED
					new_name = "taser ED-209 assembly"
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			build_step++
			balloon_alert(user, "вы установили вооружение в заготовку")
			update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(9)
			add_fingerprint(user)
			if(!istype(I, /obj/item/stock_parts/cell))
				balloon_alert(user, "вам нужна батарея для завершения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!isturf(loc))
				balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы завершили сборку")
			to_chat(user, span_notice("Вы завершили сборку ED-209."))
			var/mob/living/simple_animal/bot/ed209/new_bot = new(loc, created_name, lasercolor)
			transfer_fingerprints_to(new_bot)
			I.transfer_fingerprints_to(new_bot)
			new_bot.add_fingerprint(user)
			qdel(I)
			qdel(src)
			return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


/obj/item/ed209_assembly/welder_act(mob/living/user, obj/item/I)
	if(build_step != 3)
		return FALSE
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return .
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	build_step++
	balloon_alert(user, "вы приварили броню к заготовке")
	update_appearance(UPDATE_NAME|UPDATE_ICON_STATE)


/obj/item/ed209_assembly/screwdriver_act(mob/living/user, obj/item/I)
	if(build_step != 8)
		return FALSE
	. = TRUE
	balloon_alert(user, "вы начинаете устанавливать орудие в заготовку")
	if(!I.use_tool(src, user, 4 SECONDS, volume = I.tool_volume) || build_step != 8)
		return .
	build_step++
	update_appearance(UPDATE_NAME)
	balloon_alert(user, "вы установили орудие в заготовку")


//Floorbot assemblies
/obj/item/toolbox_tiles
	desc = "Это ящик для инструментов, из которого торчат плитки пола."
	name = "tiles and toolbox"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "toolbox_tiles"
	force = 3
	throwforce = 10
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	var/created_name = "Floorbot"
	var/toolbox = /obj/item/storage/toolbox/mechanical
	var/toolbox_color = "" //Blank for blue, r for red, y for yellow, etc.

/obj/item/toolbox_tiles/sensor
	desc = "Это ящик для инструментов, из которого торчат плитки пола. К нему прикреплён датчик движения."
	name = "tiles, toolbox and sensor arrangement"
	icon_state = "toolbox_tiles_sensor"


/obj/item/storage/toolbox/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM || !istype(I, /obj/item/stack/tile/plasteel))
		return ..()

	. = ATTACK_CHAIN_PROCEED

	add_fingerprint(user)
	var/obj/item/stack/tile/plasteel/plasteel = I
	if(istype(I, /obj/item/storage/toolbox/green/memetic))
		balloon_alert(user, "хорошая попытка...")
		return .

	if(length(contents))
		balloon_alert(user, "нельзя начать сборку, пока в ящике что-то есть")
		return .

	if(!plasteel.use(10))
		balloon_alert(user, "нужно 10 листов пластали, чтобы начать сборку")
		return .

	. |= ATTACK_CHAIN_BLOCKED_ALL

	hide_from_all_viewers()

	var/obj/item/toolbox_tiles/assembly = new(drop_location())
	assembly.toolbox = type
	switch(assembly.toolbox)
		if(/obj/item/storage/toolbox/mechanical/old)
			assembly.toolbox_color = "ob"
		if(/obj/item/storage/toolbox/emergency)
			assembly.toolbox_color = "r"
		if(/obj/item/storage/toolbox/emergency/old)
			assembly.toolbox_color = "or"
		if(/obj/item/storage/toolbox/electrical)
			assembly.toolbox_color = "y"
		if(/obj/item/storage/toolbox/green)
			assembly.toolbox_color = "g"
		if(/obj/item/storage/toolbox/syndicate)
			assembly.toolbox_color = "s"
		if(/obj/item/storage/toolbox/fakesyndi)
			assembly.toolbox_color = "s"
	assembly.update_icon(UPDATE_ICON_STATE)
	transfer_fingerprints_to(assembly)
	assembly.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(assembly)
	balloon_alert(user, "вы укрепили ящик листами пластали")
	qdel(src)


/obj/item/toolbox_tiles/update_icon_state()
	icon_state = "[toolbox_color]toolbox_tiles"


/obj/item/toolbox_tiles/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	add_fingerprint(user)
	if(!isprox(I))
		balloon_alert(user, "вам нужен датчик движения для продолжения сборки")
		return ATTACK_CHAIN_PROCEED

	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()
	var/obj/item/toolbox_tiles/sensor/assembly = new(drop_location())
	assembly.created_name = created_name
	assembly.toolbox_color = toolbox_color
	assembly.update_icon(UPDATE_ICON_STATE)
	I.transfer_fingerprints_to(assembly)
	transfer_fingerprints_to(assembly)
	assembly.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(assembly)
	balloon_alert(user, "вы прикрепили датчик движения к заготовке")
	qdel(I)
	qdel(src)
	return ATTACK_CHAIN_BLOCKED_ALL



/obj/item/toolbox_tiles/sensor/update_icon_state()
	icon_state = "[toolbox_color]toolbox_tiles_sensor"


/obj/item/toolbox_tiles/sensor/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	add_fingerprint(user)
	if(!istype(I, /obj/item/robot_parts/l_arm) && !istype(I, /obj/item/robot_parts/r_arm))
		balloon_alert(user, "для завершения сборки нужна робо-рука")
		return ATTACK_CHAIN_PROCEED

	if(!isturf(loc))
		balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
		return ATTACK_CHAIN_PROCEED

	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()

	var/mob/living/simple_animal/bot/floorbot/new_bot = new(loc, toolbox_color)
	I.transfer_fingerprints_to(new_bot)
	transfer_fingerprints_to(new_bot)
	new_bot.add_fingerprint(user)
	new_bot.name = created_name
	new_bot.robot_arm = I.type
	balloon_alert(user, "вы завершили сборку")
	to_chat(user, span_notice("Вы завершили сборку ремонтного бота."))
	qdel(I)
	qdel(src)
	return ATTACK_CHAIN_BLOCKED_ALL


/obj/item/storage/firstaid/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM || (!istype(I, /obj/item/robot_parts/l_arm) && !istype(I, /obj/item/robot_parts/r_arm)))
		return ..()

	. = ATTACK_CHAIN_PROCEED

	add_fingerprint(user)
	if(length(contents))
		balloon_alert(user, "нельзя начать сборку, пока в аптечке что-то есть")
		return .

	. |= ATTACK_CHAIN_BLOCKED_ALL

	hide_from_all_viewers()

	var/obj/item/firstaid_arm_assembly/assembly = new(drop_location(), med_bot_skin)
	assembly.req_access = req_access
	assembly.syndicate_aligned = syndicate_aligned
	assembly.treatment_oxy = treatment_oxy
	assembly.treatment_brute = treatment_brute
	assembly.treatment_fire = treatment_fire
	assembly.treatment_tox = treatment_tox
	assembly.treatment_virus = treatment_virus
	assembly.robot_arm = I.type
	transfer_fingerprints_to(assembly)
	I.transfer_fingerprints_to(assembly)
	assembly.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(assembly)
	balloon_alert(user, "вы прикрепили робо-руку к аптечке")
	qdel(I)
	qdel(src)


/obj/item/firstaid_arm_assembly
	name = "incomplete medibot assembly."
	desc = "Аптечка первой помощи с прикрепленной роботизированной рукой."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "firstaid_arm"
	w_class = WEIGHT_CLASS_NORMAL
	req_access = list(ACCESS_MEDICAL, ACCESS_ROBOTICS)
	var/build_step = 0
	var/created_name = "Medibot" //To preserve the name if it's a unique medbot I guess
	var/skin = null //Same as medbot, set to tox or ointment for the respective kits.
	var/syndicate_aligned = FALSE
	var/treatment_brute = "salglu_solution"
	var/treatment_oxy = "salbutamol"
	var/treatment_fire = "salglu_solution"
	var/treatment_tox = "charcoal"
	var/treatment_virus = "spaceacillin"
	var/robot_arm = /obj/item/robot_parts/l_arm


/obj/item/firstaid_arm_assembly/Initialize(mapload, new_skin)
	. = ..()
	if(new_skin)
		skin = new_skin
	update_icon(UPDATE_OVERLAYS)


/obj/item/firstaid_arm_assembly/update_overlays()
	. = ..()
	if(skin)
		. += image('icons/obj/aibots.dmi', "kit_skin_[skin]")
	if(build_step > 0)
		. += image('icons/obj/aibots.dmi', "na_scanner")


/obj/item/firstaid_arm_assembly/update_name(updates = ALL)
	. = ..()
	if(build_step == 1)
		name = "First aid/robot arm/health analyzer assembly"


/obj/item/firstaid_arm_assembly/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	switch(build_step)
		if(0)
			add_fingerprint(user)
			if(!istype(I, /obj/item/healthanalyzer))
				balloon_alert(user, "вам нужен анализатор здоровья для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы прикрепили анализатор здоровья к заготовке")
			build_step++
			update_appearance(UPDATE_NAME|UPDATE_OVERLAYS)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(1)
			add_fingerprint(user)
			if(!isprox(I))
				balloon_alert(user, "вам нужен датчик движения для завершения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!isturf(loc))
				balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы завершили сборку")
			to_chat(user, span_notice("Вы завершили сборку медбота."))
			var/mob/living/simple_animal/bot/medbot/new_bot
			if(syndicate_aligned)
				// syndicate medibots are a special case that have so many unique vars on them,
				// it's not worth passing them through construction phases
				new_bot = new /mob/living/simple_animal/bot/medbot/syndicate(loc)
			else
				new_bot = new /mob/living/simple_animal/bot/medbot(loc, skin)
				new_bot.name = created_name
				new_bot.bot_core.req_access = req_access
				new_bot.treatment_oxy = treatment_oxy
				new_bot.treatment_brute = treatment_brute
				new_bot.treatment_fire = treatment_fire
				new_bot.treatment_tox = treatment_tox
				new_bot.treatment_virus = treatment_virus
				new_bot.robot_arm = robot_arm
			transfer_fingerprints_to(new_bot)
			I.transfer_fingerprints_to(new_bot)
			new_bot.add_fingerprint(user)
			qdel(I)
			qdel(src)
			return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


//Secbot Assembly
/obj/item/secbot_assembly
	name = "incomplete securitron assembly"
	desc = "Замудрённая конструкция, состоящая из датчика движения, шлема и сигнального устройства."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "helmet_signaler"
	item_state = "helmet"
	var/created_name = "Securitron" //To preserve the name if it's a unique securitron I guess
	var/build_step = 0
	var/robot_arm = /obj/item/robot_parts/l_arm


/obj/item/secbot_assembly/update_name(updates = ALL)
	. = ..()
	switch(build_step)
		if(2)
			name = "helmet/signaler/prox sensor assembly"
		if(3)
			name = "helmet/signaler/prox sensor/robot arm assembly"


/obj/item/secbot_assembly/update_overlays()
	. = ..()
	switch(build_step)
		if(1)
			. += "hs_hole"
		if(2)
			. += "hs_eye"
		if(3)
			. += "hs_arm"


/obj/item/clothing/head/helmet/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM || !issignaler(I))
		return ..()

	. = ATTACK_CHAIN_PROCEED
	add_fingerprint(user)
	var/obj/item/assembly/signaler/signaler = I
	if(signaler.secured)
		balloon_alert(user, "сигнальное устройство не должно быть закреплено")
		return ATTACK_CHAIN_PROCEED

	. |= ATTACK_CHAIN_BLOCKED_ALL

	var/obj/item/secbot_assembly/assembly = new(drop_location())
	I.transfer_fingerprints_to(assembly)
	transfer_fingerprints_to(assembly)
	assembly.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(assembly)
	balloon_alert(user, "вы прикрепили сигнальное устройство к шлему")
	qdel(I)
	qdel(src)


/obj/item/secbot_assembly/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(is_pen(I))
		var/new_name = rename_interactive(user, I, prompt = "Введите новое имя для робота")
		if(!isnull(new_name))
			created_name = new_name
			add_game_logs("[key_name(user)] has renamed a robot to [new_name]", user)
		return ATTACK_CHAIN_PROCEED_SUCCESS

	switch(build_step)
		if(1)
			add_fingerprint(user)
			if(!isprox(I))
				balloon_alert(user, "вам нужен датчик движения для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы прикрепили датчик движения к заготовке")
			build_step++
			update_appearance(UPDATE_NAME|UPDATE_OVERLAYS)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(2)
			add_fingerprint(user)
			if(!istype(I, /obj/item/robot_parts/l_arm) && !istype(I, /obj/item/robot_parts/r_arm))
				balloon_alert(user, "вам нужна робо-рука для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы прикрепили робо-руку к заготовке")
			build_step++
			robot_arm = I.type
			update_appearance(UPDATE_NAME|UPDATE_OVERLAYS)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(3)
			add_fingerprint(user)
			if(!istype(I, /obj/item/melee/baton/security))
				balloon_alert(user, "вам нужна оглушающая дубинка для завершения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!isturf(loc))
				balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы завершили сборку")
			to_chat(user, span_notice("Вы завершили сборку охранного бота."))
			var/mob/living/simple_animal/bot/secbot/new_bot = new(loc)
			new_bot.name = created_name
			new_bot.robot_arm = robot_arm
			transfer_fingerprints_to(new_bot)
			I.transfer_fingerprints_to(new_bot)
			new_bot.add_fingerprint(user)
			qdel(I)
			qdel(src)
			return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


/obj/item/secbot_assembly/screwdriver_act(mob/living/user, obj/item/I)
	if(build_step != 0 && build_step != 2 && build_step != 3)
		return FALSE
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	var/atom/drop_loc = drop_location()
	switch(build_step)
		if(0)
			var/obj/item/assembly/signaler/signaler = new(drop_loc)
			transfer_fingerprints_to(signaler)
			signaler.add_fingerprint(user)
			var/obj/item/clothing/head/helmet/helmet = new(drop_loc)
			transfer_fingerprints_to(helmet)
			helmet.add_fingerprint(user)
			balloon_alert(user, "вы отсоединили сигнальное устройство от шлема")
			to_chat(user, span_notice("You have disconnected the signaler from the helmet."))
			qdel(src)
		if(2)
			var/obj/item/assembly/prox_sensor/sensor = new(drop_loc)
			transfer_fingerprints_to(sensor)
			sensor.add_fingerprint(user)
			build_step--
			balloon_alert(user, "вы отсоединили датчик движения от заготовки")
			update_appearance(UPDATE_NAME|UPDATE_OVERLAYS)
		if(3)
			var/obj/item/robot_parts/new_arm = new robot_arm(drop_loc)
			transfer_fingerprints_to(new_arm)
			new_arm.add_fingerprint(user)
			build_step--
			balloon_alert(user, "вы отсоединили робо-руку от заготовки")
			update_appearance(UPDATE_NAME|UPDATE_OVERLAYS)


/obj/item/secbot_assembly/wrench_act(mob/living/user, obj/item/I)
	if(build_step != 3)
		return FALSE
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	balloon_alert(user, "вы создали дополнительные слоты для вооружения в заготовке")
	var/obj/item/griefsky_assembly/destroyer_of_the_worlds = new(drop_location())
	transfer_fingerprints_to(destroyer_of_the_worlds)
	destroyer_of_the_worlds.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(destroyer_of_the_worlds)
	qdel(src)


/obj/item/secbot_assembly/welder_act(mob/living/user, obj/item/I)
	if(build_step != 0 && build_step != 1)
		return FALSE
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return .
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	if(build_step == 1)
		build_step = 0
		balloon_alert(user, "вы заварили лишние отверстия в заготовке")
	else
		build_step = 1
		balloon_alert(user, "вы вырезали дополнительные отверстия в заготовке")
	update_appearance(UPDATE_OVERLAYS)


//General Griefsky

/obj/item/griefsky_assembly
	name = "\improper General Griefsky assembly"
	desc = "Причудливая конструкция. Выглядит мощно."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "griefsky_assembly"
	item_state = "griefsky_assembly"
	var/build_step = 0
	var/toy_step = 0


/obj/item/griefsky_assembly/update_name(updates = ALL)
	. = ..()
	name = toy_step > 0 ? "\improper Genewul Giftskee assembly" : "\improper General Griefsky assembly"


/obj/item/griefsky_assembly/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	add_fingerprint(user)
	var/energy_sword = istype(I, /obj/item/melee/energy/sword)
	var/toy_sword = istype(I, /obj/item/toy/sword)
	if(!energy_sword && !toy_sword)
		if(build_step == 0 && toy_step == 0)
			balloon_alert(user, "вам нужен лазерный меч для продолжения сборки")
			return ATTACK_CHAIN_PROCEED
		if(build_step > 0)
			balloon_alert(user, "вам нужен лазерный меч для продолжения сборки")
			return ATTACK_CHAIN_PROCEED
		if(toy_step > 0)
			balloon_alert(user, "вам нужен игрушечный лазерный меч для продолжения сборки")
			return ATTACK_CHAIN_PROCEED
		return ATTACK_CHAIN_PROCEED

	if(energy_sword)
		if(toy_step > 0)
			balloon_alert(user, "этот лазерный меч не подойдёт")
			return ATTACK_CHAIN_PROCEED
		if(build_step == 3)
			if(!isturf(loc))
				balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы завершили сборку")
			to_chat(user, span_notice("Вы завершили сборку Генерала Грифски."))
			var/mob/living/simple_animal/bot/secbot/griefsky/destroyer_of_the_worlds = new(loc)
			transfer_fingerprints_to(destroyer_of_the_worlds)
			I.transfer_fingerprints_to(destroyer_of_the_worlds)
			destroyer_of_the_worlds.add_fingerprint(user)
			qdel(I)
			qdel(src)
			return ATTACK_CHAIN_BLOCKED_ALL
		if(!user.drop_transfer_item_to_loc(I, src))
			return ..()
		build_step++
		I.transfer_fingerprints_to(src)
		update_appearance(UPDATE_NAME)
		balloon_alert(user, "вы прикрепили лазерный меч к заготовке")
		qdel(I)
		return ATTACK_CHAIN_BLOCKED_ALL

	if(build_step > 0)
		balloon_alert(user, "здесь нужен настоящий лазерный меч")
		return ATTACK_CHAIN_PROCEED
	if(toy_step == 3)
		if(!isturf(loc))
			balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
			return ATTACK_CHAIN_PROCEED
		if(!user.drop_transfer_item_to_loc(I, src))
			return ..()
		balloon_alert(user, "вы завершили сборку")
		to_chat(user, span_notice("Вы завершили сборку Генерала Грифски."))
		var/mob/living/simple_animal/bot/secbot/griefsky/toy/destroyer_of_the_pinatas = new(loc)
		transfer_fingerprints_to(destroyer_of_the_pinatas)
		I.transfer_fingerprints_to(destroyer_of_the_pinatas)
		destroyer_of_the_pinatas.add_fingerprint(user)
		qdel(I)
		qdel(src)
		return ATTACK_CHAIN_BLOCKED_ALL
	if(!user.drop_transfer_item_to_loc(I, src))
		return ..()
	toy_step++
	I.transfer_fingerprints_to(src)
	update_appearance(UPDATE_NAME)
	balloon_alert(user, "вы прикрепили игрушечный лазерный меч к заготовке")
	qdel(I)
	return ATTACK_CHAIN_BLOCKED_ALL


/obj/item/griefsky_assembly/screwdriver_act(mob/living/user, obj/item/I)
	if(build_step == 0 && toy_step == 0)
		return FALSE
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	var/obj/item/sword
	if(build_step)
		sword = new /obj/item/melee/energy/sword(drop_location())
		balloon_alert(user, "вы отсоединили лазерный меч от заготовки")
		build_step--
	else if(toy_step)
		sword = new /obj/item/toy/sword(drop_location())
		balloon_alert(user, "вы отсоединили игрушечный лазерный меч от заготовки")
		toy_step--
	transfer_fingerprints_to(sword)
	sword.add_fingerprint(user)
	update_appearance(UPDATE_NAME)


/obj/item/storage/box/clown/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM || (!istype(I, /obj/item/robot_parts/l_arm) && !istype(I, /obj/item/robot_parts/r_arm)))
		return ..()

	. = ATTACK_CHAIN_PROCEED

	add_fingerprint(user)
	if(length(contents))
		balloon_alert(user, "нельзя начать сборку, пока в коробке что-то есть")
		return .

	. |= ATTACK_CHAIN_BLOCKED_ALL

	hide_from_all_viewers()

	var/obj/item/honkbot_arm_assembly/assembly = new(drop_location())
	assembly.robot_arm = I.type
	transfer_fingerprints_to(assembly)
	I.transfer_fingerprints_to(assembly)
	assembly.add_fingerprint(user)
	if(loc == user)
		user.temporarily_remove_item_from_inventory(src, force = TRUE)
		user.put_in_hands(assembly)
	balloon_alert(user, "вы прикрепили робо-руку к коробке")
	qdel(I)
	qdel(src)


/obj/item/honkbot_arm_assembly
	name = "incomplete honkbot assembly"
	desc = "Клоунская коробка с прикрепленной роботизированной рукой."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "honkbot_arm"
	w_class = WEIGHT_CLASS_NORMAL
	req_access = list(ACCESS_CLOWN, ACCESS_ROBOTICS, ACCESS_MIME)
	var/build_step = 0
	var/created_name = "Honkbot" //To preserve the name if it's a unique medbot I guess
	var/robot_arm = /obj/item/robot_parts/l_arm


/obj/item/honkbot_arm_assembly/attackby(obj/item/I, mob/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	switch(build_step)
		if(0)
			add_fingerprint(user)
			if(!isprox(I))
				balloon_alert(user, "вам нужен датчик движения для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы прикрепили датчик движения к заготовке")
			build_step++
			update_appearance(UPDATE_ICON_STATE)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(1)
			add_fingerprint(user)
			if(!istype(I, /obj/item/bikehorn))
				balloon_alert(user, "вам нужен велосипедный гудок для продолжения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы прикрепили велосипедный гудок к заготовке")
			build_step++
			update_appearance(UPDATE_ICON_STATE|UPDATE_DESC)
			qdel(I)
			return ATTACK_CHAIN_BLOCKED_ALL

		if(2)
			add_fingerprint(user)
			if(!istype(I, /obj/item/instrument/trombone))
				balloon_alert(user, "вам нужен тромбон для завершения сборки")
				return ATTACK_CHAIN_PROCEED
			if(!isturf(loc))
				balloon_alert(user, "вы не можете завершить сборку [ismob(loc) ? "в инвентаре" : "здесь"]")
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			balloon_alert(user, "вы завершили сборку")
			to_chat(user, span_notice("Вы завершили сборку хонкобота."))
			var/mob/living/simple_animal/bot/honkbot/new_bot = new(loc)
			new_bot.robot_arm = robot_arm
			transfer_fingerprints_to(new_bot)
			I.transfer_fingerprints_to(new_bot)
			new_bot.add_fingerprint(user)
			qdel(I)
			qdel(src)
			return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


/obj/item/honkbot_arm_assembly/update_icon_state()
	icon_state = build_step == 1 ? "honkbot_proxy" : "honkbot_arm"


/obj/item/honkbot_arm_assembly/update_desc(updates = ALL)
	. = ..()
	if(build_step == 2)
		desc = "Клоунская коробка с прикреплённой роботизированной рукой и велосипедным гудком. Ему не хватает лишь тромбона."
		return .
	desc = initial(desc)

