/obj/item/clothing/gloves/ring/gadget
	origin_tech = "magnets=3;combat=3;syndicate=2"
	var/changing = FALSE
	var/op_time = 2 SECONDS
	var/op_time_upgaded = 1 SECONDS
	var/op_cd_time = 5 SECONDS
	var/op_cd_time_upgaded = 3 SECONDS
	var/breaking = FALSE
	COOLDOWN_DECLARE(operation_cooldown)
	var/old_mclick_override

/obj/item/clothing/gloves/ring/gadget/attack_self(mob/user)
	. = ..()

	if(changing)
		user.balloon_alert(user, "подождите")
		return

	changing = TRUE

	// only types that we can meet in the game
	var/list/possible = list("iron ring", "silver ring", "gold ring", "plasma ring", "uranium ring")
	var/list/obj/item/clothing/gloves/ring/choices = list()
	for(var/obj/item/clothing/gloves/ring/ring as anything in typesof(/obj/item/clothing/gloves/ring))
		if(ring.type == type)
			continue

		if(!(ring.name in possible))
			continue

		ring.stud = stud
		choices[ring] = image(icon = ring.icon, icon_state = ring.icon_state)

	var/obj/item/clothing/gloves/ring/selected_chameleon = show_radial_menu(usr, loc, choices, require_near = TRUE)
	if(!selected_chameleon)
		return

	name = selected_chameleon.name
	icon_state = selected_chameleon.icon_state
	material = selected_chameleon.material
	ring_color = selected_chameleon.ring_color

	user.visible_message(span_warning("[user] изменяет внешний вид кольца!"), span_notice("[selected_chameleon] selected."))
	playsound(loc, 'sound/items/screwdriver2.ogg', 50, 1)
	to_chat(user, span_notice("Смена маскировки..."))
	update_icon(UPDATE_ICON_STATE)
	changing = FALSE

/obj/item/clothing/gloves/ring/gadget/Touch(atom/A, proximity)
	. = FALSE
	var/mob/living/carbon/human/user = loc

	if(user.a_intent != INTENT_DISARM)
		return

	if(get_dist(user, A) > 1)
		return

	if(user.incapacitated())
		return

	var/obj/item/clothing/gloves/ring/gadget/ring = user.gloves

	if(ring.breaking)
		return

	if(!istype(A, /obj/structure/window))
		return

	if(!COOLDOWN_FINISHED(ring, operation_cooldown))
		user.balloon_alert(user, "перезарядка")
		return

	ring.breaking = TRUE
	if(do_after(user, ring.stud ? ring.op_time_upgaded : ring.op_time))
		COOLDOWN_START(ring, operation_cooldown, ring.stud ? ring.op_cd_time_upgaded : ring.op_cd_time)

		ring.visible_message(span_warning("BANG"))
		playsound(ring, 'sound/effects/bang.ogg', 100, TRUE)

		for(var/mob/living/M in range(A, 3))
			if(M.check_ear_prot() == HEARING_PROTECTION_NONE)
				M.Deaf(6 SECONDS)

		for(var/obj/structure/grille/grille in A.loc)
			grille.obj_break()

		for(var/obj/structure/window/window in range(A, 2))
			window.take_damage(window.max_integrity * rand(20, 60) / 100)

		var/obj/structure/window/window = A
		window.deconstruct()
		ring.breaking = FALSE
		return TRUE

	ring.breaking = FALSE
