/obj/item/laser_eyes_injector
	name = "laser eyes injector"
	desc = "Инжектор позволяющий вам стрелять лазерами из глаз после исспользования."
	icon = 'icons/obj/hypo.dmi'
	icon_state = "dnainjector"
	var/used = FALSE

/obj/item/laser_eyes_injector/update_icon_state()
	. = ..()
	icon_state = "dnainjector[used ? "0" : ""]"

/obj/item/laser_eyes_injector/update_name(updates = ALL)
	. = ..()
	name = used ? "used [initial(name)]" : initial(name)

/obj/item/laser_eyes_injector/attack(mob/M, mob/user)
	if(used)
		to_chat(user, span_warning("Этот инжектор уже использован!"))
		return FALSE
	if(!M.dna) //You know what would be nice? If the mob you're injecting has DNA, and so doesn't cause runtimes.
		return FALSE
	if(ishuman(M)) // Would've done this via species instead of type, but the basic mob doesn't have a species, go figure.
		var/mob/living/carbon/human/H = M
		if(NO_DNA in H.dna.species.species_traits)
			return FALSE
	else
		return FALSE
	if(!used)
		M.AddSpell(new /obj/effect/proc_holder/spell/lasereyes)
		used = TRUE
		update_appearance(UPDATE_NAME|UPDATE_ICON)
	else
		to_chat(user, span_notice("Этот инжектор уже исспользован."))


/obj/effect/proc_holder/spell/lasereyes
	name = "Лазеры из глаз"
	desc = "Переключатель позволяющий активировать и деактивировать способность стрелять лазерами из глаз."
	clothes_req = FALSE
	base_cooldown = 1 SECONDS
	cooldown_min = 1 SECONDS
	action_icon_state = "lazer_hulk"

/obj/effect/proc_holder/spell/lasereyes/create_new_targeting()
	return new /datum/spell_targeting/self

/obj/effect/proc_holder/spell/lasereyes/cast(list/targets, mob/user = usr)
	if (HAS_TRAIT(user, TRAIT_LASEREYES))
		REMOVE_TRAIT(user, TRAIT_LASEREYES, "laser_eyes_injector")
		to_chat(user, span_warning("Легкое жжение в области ваших глаз прошло."))
	else
		ADD_TRAIT(user, TRAIT_LASEREYES, "laser_eyes_injector")
		to_chat(user, span_warning("Вы чувствуете легкое жжение в области ваших глаз."))
