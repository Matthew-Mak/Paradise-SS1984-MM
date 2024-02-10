#define NO_SUCCESS 0
#define CORRECT_MECHA 1
#define SOME_CORRECT_MODULES 2
#define ALL_CORRECT_MODULES 3
#define DIFFICULTY_EASY		1
#define DIFFICULTY_NORMAL	2
#define DIFFICULTY_HARD		3
#define CATS_BY_STAGE list("number" = list("first", "second", "third"), "first" = list("working", "medical", "security"), "second" = list("working_medical", "medical_security"), "third" = list("working_medical_security"))

/obj/machinery/computer/roboquest
	name = "Robotics Request Console"
	desc = "Console used for receiving requests for construction of exosuits."
	icon_screen = "robo_ntos_roboquest"
	icon_keyboard = "rd_key"
	light_color = LIGHT_COLOR_FADEDPURPLE
	var/print_delayed = FALSE
	var/style = "ntos_roboquest"
	var/canSend = FALSE
	var/canCheck = FALSE
	var/check_timer
	var/success
	var/checkMessage = ""
	var/points = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 0)
	req_access = list(ACCESS_ROBOTICS)
	circuit = /obj/item/circuitboard/roboquest
	var/obj/item/card/id/currentID
	var/obj/machinery/roboquest_pad/pad
	var/difficulty
	var/list/shop_items = list()

/obj/machinery/computer/roboquest/Initialize(mapload)
	..()
	generate_roboshop()
	var/mapping_pad = locate(/obj/machinery/roboquest_pad) in range(2, src)
	if(mapping_pad)
		pad = mapping_pad
		pad.console = src
		canCheck = TRUE

/obj/machinery/computer/roboquest/New()
	generate_roboshop()
	. = ..()

/obj/machinery/computer/roboquest/Destroy()
	for(var/obj/item/I in contents)
		I.forceMove(get_turf(src))
	if(pad)
		pad.console=null
		pad = null
	currentID = null
	. = ..()

/obj/machinery/computer/roboquest/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/card/id))
		currentID = O
		user.drop_item_ground(O)
		O.forceMove(src)
		SStgui.try_update_ui(user, src)
	if(istype(O, /obj/item/multitool))
		var/obj/item/multitool/M = O
		if(M.buffer)
			add_fingerprint(user)
			if(istype(M.buffer, /obj/machinery/roboquest_pad))
				pad = M.buffer
				if(pad.console)
					pad.console.pad = null
				pad.console = src
				canCheck = TRUE
				M.buffer = null

/obj/machinery/computer/roboquest/emag_act(mob/user)
	if(!emagged)
		emagged = TRUE
		playsound(src, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)


/obj/machinery/computer/roboquest/proc/check_pad()
	var/obj/mecha/M
	var/needed_mech = currentID.robo_bounty.choosen_mech
	var/list/needed_modules = currentID.robo_bounty.choosen_modules
	var/amount = 0
	if(locate(/obj/mecha) in get_turf(pad))
		M = (locate(/obj/mecha) in get_turf(pad))
		if(M.type == needed_mech)
			for(var/i in (needed_modules))
				for(var/obj/item/mecha_parts/mecha_equipment/weapon in M.equipment)
					if(i == weapon.type)
						amount++
			if(amount == currentID.robo_bounty.modules_amount)
				success = ALL_CORRECT_MODULES
				canSend = TRUE
				return	amount
			if(amount == 0)
				success = CORRECT_MECHA
				canSend = TRUE
				return amount
			success = SOME_CORRECT_MODULES
			canSend = TRUE
			return	amount
	success = NO_SUCCESS
	canSend = FALSE

/obj/machinery/computer/roboquest/proc/generate_roboshop()
	var/list/newshop = list()
	for(var/path in subtypesof(/datum/roboshop_item))
		var/datum/roboshop_item/item = new path
		var/category
		for(var/cat in item.cost)
			if(item.cost[cat])
				if(category)
					category += "_[cat]"
				else
					category = cat
		var/icon/combined = icon('icons/misc/robo_ui2.dmi', category)
		combined.Blend(item.tgui_icon, ICON_OVERLAY)
		var/newitem = list("name" = item.name, "desc" = item.desc, "cost" = item.cost, "icon" = icon2base64(combined), "path" = path, "emagOnly" = item.emag_only)
		newshop[category] += list(newitem)
	shop_items = newshop

/obj/machinery/computer/roboquest/proc/clear_checkMessage()
	checkMessage = ""

/obj/machinery/computer/roboquest/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)

/obj/machinery/computer/roboquest/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = TRUE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "RoboQuest", name, 800, 475, master_ui, state)
		ui.open()

/obj/machinery/computer/roboquest/ui_data(mob/user)
	var/list/data = list()
	if(istype(currentID))
		data["hasID"] = TRUE
		data["name"] = currentID.registered_name
		data["points"] = points
		if(currentID.robo_bounty)
			data["questInfo"] = currentID.robo_bounty.questinfo
			data["hasTask"] = TRUE
		else
			data["questInfo"] = "None"
			data["hasTask"] = FALSE
	else
		data["hasID"] = FALSE
		data["name"] = FALSE
		data["points"] = FALSE
		data["questInfo"] = FALSE
		data["hasTask"] = FALSE
	data["canCheck"] = canCheck
	data["canSend"] = canSend
	data["checkMessage"] = checkMessage
	data["style"] = style
	data["cooldown"] = currentID?.bounty_penalty ? time2text((currentID.bounty_penalty-world.time), "mm:ss") : FALSE
	return data

/obj/machinery/computer/roboquest/ui_static_data(mob/user)
	var/list/data = list()
	data["cats"] = CATS_BY_STAGE
	data["shopItems"] = shop_items
	return data

/obj/machinery/computer/roboquest/ui_act(action, list/params)
	switch(action)
		if("RemoveID")
			currentID.forceMove(get_turf(src))
			currentID = null
			SStgui.update_uis(src)
		if("GetTask")
			var/list/difficulties = list("Easy" = DIFFICULTY_EASY, "Medium" = DIFFICULTY_NORMAL, "Hard" = DIFFICULTY_HARD)
			difficulty = tgui_input_list(usr, "Select event type.", "Select", difficulties)
			if(!difficulty)
				return
			pick_mecha(difficulties[difficulty])
		if("RemoveTask")
			currentID.robo_bounty = null
			addtimer(CALLBACK(src, PROC_REF(cooldown_end), currentID), 5 MINUTES)
			currentID.bounty_penalty = world.time + 5 MINUTES
		if("Check")
			if(!pad)
				checkMessage = "Привязанный пад не обнаружен"
			else
				var/amount = check_pad()
				switch(success)
					if(NO_SUCCESS)
						checkMessage = "Мех отсутствует или не соответствует заказу"
					if(CORRECT_MECHA)
						checkMessage = "Мех соответствует заказу, но не имеет заказанных модулей. Награда Будет сильно урезана"
					if(SOME_CORRECT_MODULES)
						checkMessage = "Мех соответствует заказу, но имеет лишь [amount]/[currentID.robo_bounty.modules_amount] модулей. Награда будет слегка урезана."
					if(ALL_CORRECT_MODULES)
						checkMessage = "Мех и модули полностью соответствуют заказу. Награда будет максимальной."
			check_timer = null
			check_timer = addtimer(CALLBACK(src, PROC_REF(clear_checkMessage)), 15 SECONDS)
		if("SendMech")
			check_pad()
			if(canSend)
				flick("sqpad-beam", pad)
				pad.teleport()
				checkMessage = "Вы отправили меха с оценкой успеха [success] из трех"
				check_timer = null
				check_timer = addtimer(CALLBACK(src, PROC_REF(clear_checkMessage)), 15 SECONDS)
				points["robo"] += success
				currentID.robo_bounty = null
				success = 0
		if("ChangeStyle")
			switch(style)
				if("ntos_roboquest")
					style = "ntos_roboblue"
				if("ntos_roboblue")
					style = "ntos_terminal"
				if("ntos_terminal")
					if(emagged)
						style = "syndicate"
					else
						style = "ntos_roboquest"
				if("syndicate")
					style = "ntos_roboquest"
			icon_screen = "robo_[style]"
			SStgui.update_uis(src)
			update_icon()
		if("buyItem")
			var/path = params["item"]
			new path(get_turf(src))
		if("printOrder")
			if(print_delayed)
				return FALSE
			var/datum/roboquest/quest = currentID?.robo_bounty
			if(!istype(quest))
				return FALSE
			print_delayed = TRUE
			print_task(quest)
			addtimer(VARSET_CALLBACK(src, print_delayed, FALSE), 10 SECONDS)

/obj/machinery/computer/roboquest/proc/print_task(datum/roboquest/quest)
	playsound(loc, 'sound/goonstation/machines/printer_thermal.ogg', 50, 1)
	var/obj/item/paper/paper = new(get_turf(src))
	paper.header = "<p><img style='display: block; margin-left: auto; margin-right: auto;' src='ntlogo.png' width='220' height='135' /></p><hr noshade size='4'>"
	paper.info = "<center> <h2> Mecha request form </h2> </center>"
	paper.info += "<ul> <h3> Mecha info:</h3>"
	paper.info += "<li> Mecha type: [quest.name]</li><br>"
	paper.info += "<li> Report: [quest.desc]</li><br>"
	paper.info += "<h3>Requested modules:</h3>"
	for(var/i in quest.questinfo["modules"])
		paper.info += "<li> [i["name"]]</li><br>"
	paper.info += "<br><b> Initial reward:</b> [quest.reward] point(s)"
	paper.info += "<p><b>Mecha request accepted by:</b> [currentID.registered_name] - [currentID.rank] at [station_time_timestamp()].</p></ul>"
	paper.info += "<hr><center><small><i>The request has been approved and certified by NAS Trurl.</i></small></center>"
	var/obj/item/stamp/centcom/stamp = new()
	paper.stamp(stamp)
	paper.update_icon()
	paper.name = "NT-CC-RND-[rand(10, 51)] \"Mecha request form\" "

/obj/machinery/computer/roboquest/proc/cooldown_end(obj/item/card/id/penaltycard)
	penaltycard.bounty_penalty = null

/obj/machinery/computer/roboquest/proc/pick_mecha(difficulty)
	currentID.robo_bounty = new /datum/roboquest(difficulty)



/obj/machinery/roboquest_pad
	name = "Robotics Request Quantum Pad"
	desc = "A bluespace quantum-linked telepad linked to a orbital long-range matter transmitter."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "sqpad-idle"
	idle_power_usage = 500
	var/obj/machinery/computer/roboquest/console

/obj/machinery/roboquest_pad/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/circuitboard/roboquest_pad(null)
	component_parts += new /obj/item/stack/ore/bluespace_crystal/artificial(null)
	component_parts += new /obj/item/stack/cable_coil(null, 1)
	RefreshParts()

/obj/machinery/roboquest_pad/Destroy()
	if(console)
		console.canSend = FALSE
		console.pad = null
		console = null
	. = ..()

/obj/machinery/roboquest_pad/crowbar_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	default_deconstruction_crowbar(user, I)

/obj/machinery/roboquest_pad/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	default_deconstruction_screwdriver(user, "pad-idle-o", "qpad-idle", I)

/obj/machinery/roboquest_pad/proc/teleport()
	do_sparks(5, 1, get_turf(src))
	var/obj/mecha/M = (locate(/obj/mecha) in get_turf(src))
	if(istype(M))
		qdel(M)

/obj/machinery/roboquest_pad/New()
	RegisterSignal(src, COMSIG_MOVABLE_UNCROSSED, PROC_REF(ismechgone))
	. = ..()

/obj/machinery/roboquest_pad/proc/ismechgone(datum/source, atom/movable/exiting)
	if(ismecha(exiting) && console)
		console.canSend = FALSE

/obj/machinery/roboquest_pad/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(!I.multitool_check_buffer(user))
		return
	var/obj/item/multitool/M = I
	M.set_multitool_buffer(user, src)

#undef NO_SUCCESS
#undef CORRECT_MECHA
#undef SOME_CORRECT_MODULES
#undef ALL_CORRECT_MODULES
#undef DIFFICULTY_EASY
#undef DIFFICULTY_NORMAL
#undef DIFFICULTY_HARD
#undef CATS_BY_STAGE
