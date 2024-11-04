#define FREE_INJECT_TIME 10 SECONDS
#define TARGET_INJECT_TIME 3 SECONDS

/obj/item/hemophagus_extract
	name = "Bloody Injector"
	desc = "Инжектор странной формы, с неестественно двигающейся алой жидкостью внутри. На боку едва заметная гравировка \"Hematogenic Industries\". Конкретно на этом инжекторе установлена блокировка, не позволяющая исспользовать его на случайном гуманойде."
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "hemophagus_extract"
	item_state = "inj_ful"
	lefthand_file = 'icons/obj/affiliates_l.dmi'
	righthand_file = 'icons/obj/affiliates_r.dmi'
	w_class = WEIGHT_CLASS_TINY
	/// The mind of the target into which we must inject the injector according to the objective.
	var/datum/mind/target = null
	/// If TRUE, we can inject it in anybody.
	var/free_inject = FALSE
	/// If true, will make you advanced vampire. (All 4 paths)
	var/advanced = FALSE
	/// If TRUE, the injector is used, so we can't use it again.
	var/used = FALSE
	origin_tech = "biotech=7;syndicate=3"

/obj/item/hemophagus_extract/attack(mob/living/target, mob/living/user, def_zone)
	return ATTACK_CHAIN_BLOCKED

/obj/item/hemophagus_extract/afterattack(atom/target, mob/user, proximity, params)
	if(used)
		return

	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	if(H.stat == DEAD)
		return

	if((src.target && target != src.target) || !free_inject)
		to_chat(user, span_warning("You can't use [src] to [target]!"))
		return

	if(do_after(user, free_inject ? FREE_INJECT_TIME : TARGET_INJECT_TIME, target = target, max_interact_count = 1))
		inject(user, H)

/obj/item/hemophagus_extract/proc/make_vampire(mob/living/user, mob/living/carbon/human/target)
	var/datum/antagonist/vampire/vamp = new()

	vamp.give_objectives = FALSE
	target.mind.add_antag_datum(vamp)
	var/datum/antagonist/vampire/vampire = target.mind.has_antag_datum(/datum/antagonist/vampire)
	vampire.upgrade_tiers -= /obj/effect/proc_holder/spell/vampire/self/specialize
	if(advanced)
		vamp.add_subclass(SUBCLASS_ADVANCED, TRUE)

	vampire.add_objective((!advanced) ? /datum/objective/blood : /datum/objective/blood/ascend)
	used = TRUE
	item_state = "inj_used"
	update_icon(UPDATE_ICON_STATE)
	var/datum/antagonist/traitor/T = user.mind.has_antag_datum(/datum/antagonist/traitor)
	if(!T)
		return
	for(var/datum/objective/new_mini_vampire/objective in T.objectives)
		if(target.mind == objective.target)
			objective.made = TRUE

/obj/item/hemophagus_extract/proc/inject(mob/living/user, mob/living/carbon/human/target)
	if(!target.mind)
		to_chat(user, span_notice("[target] body rejects [src]"))
		return

	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	make_vampire(user, target)
	to_chat(user, span_notice("You inject [target] with [src]"))

/obj/item/hemophagus_extract/examine(mob/user)
	. = ..()
	if(target)
		. += span_info("It is intended for [target]")

/obj/item/hemophagus_extract/self
 	name = "Hemophagus Essence Auto Injector"
 	free_inject = TRUE

/obj/item/hemophagus_extract/self/advanced
	name = "Elder Vampire Essence Auto Injector"
	advanced = TRUE

/obj/item/hemophagus_extract/update_icon_state()
 	icon_state = initial(icon_state) + (used ? "_used" : "")

#undef FREE_INJECT_TIME
#undef TARGET_INJECT_TIME
