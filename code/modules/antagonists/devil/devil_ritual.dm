/datum/ritual/devil
	allowed_special_role = list(ROLE_DEVIL)
	cooldown_after_cast = null
	disaster_prob = 0
	fail_chance = 0

/datum/ritual/devil/imp
	name = "Imp summoning ritual"
	required_things = list(
		/obj/item/wirecutters = 3,
        /obj/item/organ/internal/kidneys = 2,
        /obj/item/organ/internal/heart = 1,
        /obj/effect/decal/cleanable/vomit = 2
	)

/datum/ritual/devil/imp/del_things()
    for(var/obj/obj in used_things) // no type ignore for future.
        qdel(obj)

    return

/datum/ritual/devil/imp/do_ritual(mob/living/carbon/human/invoker)
	var/datum/antagonist/devil/devil = invoker.mind?.has_antag_datum(/datum/antagonist/devil)

    var/list/candidates = SSghost_spawns.poll_candidates("Вы хотите сыграть за беса?", ROLE_DEMON, TRUE)

	if(!LAZYLEN(candidates))
		return RITUAL_FAILED_ON_PROCEED 

	var/mob/mob = pick(candidates)
    var/mob/living/simple_animal/imp/imp = new(get_turf(ritual_object))

	imp.key = mob.key
	imp.universal_speak = TRUE
	imp.sentience_act()
	imp.master_commander = invoker

	imp.mind.store_memory("Я подчиняюсь призывателю [imp.master_commander.name], также известному как [devil.info.truename].")

	return RITUAL_SUCCESSFUL

/datum/ritual/devil/sacrifice
	name = "Sacrifice ritual"
	ritual_should_del_things = FALSE
	required_things = list(
		/mob/living/carbon/human = 1
	)

/datum/ritual/devil/sacrifice/check_contents(mob/living/carbon/human/invoker)
    . = ..()

    if(!.)
        return FALSE

    var/mob/living/carbon/human/human = locate() in used_things

    if(!human.mind?.hasSoul)
        ritual_object.balloon_alert("цель без души!")
        return FALSE

    var/datum/objective/devil/sacrifice/sacrifice = locate() in invoker.mind?.objectives

    if(!LAZYIN(sacrifice?.target_minds, human.mind))
        ritual_object.balloon_alert("не имеет ценности!")
        return FALSE

    var/datum/antagonist/devil/devil = invoker.mind?.has_antag_datum(/datum/antagonist/devil)

    if(locate(human.mind) in devil.soulsOwned)
        return FALSE // Error occured / Admin changed hasSoul.

    return TRUE

/datum/ritual/devil/sacrifice/do_ritual(mob/living/carbon/human/invoker)
	var/mob/living/carbon/human/human = locate() in used_things
	var/datum/antagonist/devil/devil = invoker.mind?.has_antag_datum(/datum/antagonist/devil)
    
	devil?.add_soul(human.mind)

	return RITUAL_SUCCESSFUL
