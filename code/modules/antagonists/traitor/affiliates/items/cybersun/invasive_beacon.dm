/obj/item/invasive_beacon
	name = "Invasive Beacon"
	desc = "Сложное черное устройство. На боку едва заметная надпись \"Cybersun Industries\"."
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "invasive_beacon"
	item_state = "beacon"
	lefthand_file = 'icons/obj/affiliates_l.dmi'
	righthand_file = 'icons/obj/affiliates_r.dmi'
	origin_tech = "programming=6;magnets=3;syndicate=1"
	w_class = WEIGHT_CLASS_TINY

/obj/item/invasive_beacon/attack(mob/living/target, mob/living/user, def_zone)
	return

/obj/item/invasive_beacon/afterattack(atom/target, mob/user, proximity, params)
	if(!user.Adjacent(target))
		user.balloon_alert(user, "слишком далеко")
		return

	var/obj/mecha/mecha = target
	var/obj/spacepod/pod = target

	if(istype(mecha))
		do_sparks(5, 1, mecha)
		mecha.dna = null
		mecha.operation_req_access = list()
		mecha.internals_req_access = list()

		user.visible_message(span_warning("[user] hacked [mecha] using [src]."), span_info("You hacked [mecha] using [src]."))

		if(mecha.occupant)
			to_chat(mecha.occupant, span_danger("You were thrown out of [mecha]."))

			mecha.occupant.forceMove(get_turf(mecha))
			mecha.occupant.Knockdown(6 SECONDS)
			mecha.occupant.electrocute_act(30, mecha)
			mecha.occupant.throw_at(pick(orange(3)))
			mecha.occupant = null

	else if(istype(pod))
		do_sparks(5, 1, pod)
		pod.unlocked = TRUE
		user.visible_message(span_warning("[user] hacked [pod] using [src]."), span_info("You hacked [pod] using [src]."))

		if(pod.pilot) // It is not ejecting passangers
			var/mob/living/victim = pod.pilot
			to_chat(victim, span_danger("You were thrown out of [pod]."))

			pod.eject_pilot()
			victim.Knockdown(6 SECONDS)
			victim.electrocute_act(30, pod)
			victim.throw_at(pick(orange(3)))
	else
		user.balloon_alert(user, "невозможно взломать")
		return
