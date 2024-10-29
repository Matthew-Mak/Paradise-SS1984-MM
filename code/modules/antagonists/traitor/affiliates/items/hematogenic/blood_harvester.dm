#define BLOOD_HARVEST_VOLUME 200
#define BLOOD_HARVEST_TIME 10 SECONDS

/obj/item/blood_harvester
	name = "Blood harvester"
	desc = "Большой шприц для быстрого сбора больших объемов крови. На боку едва заметная гравировка \"Hematogenic Industries\""
	icon = 'icons/obj/affiliates.dmi'
	icon_state = "blood_harvester"
	item_state = "blood1_used"
	lefthand_file = 'icons/obj/affiliates_l.dmi'
	righthand_file = 'icons/obj/affiliates_r.dmi'
	w_class = WEIGHT_CLASS_TINY
	origin_tech = "biotech=5;syndicate=1"
	reagents = new(BLOOD_HARVEST_VOLUME)
	/// If TRUE, there is blood inside.
	var/used = FALSE
	/// The mind of the one whose blood is harvested.
	var/datum/mind/target
	/// Name of target at the moment of harvesting.
	var/target_name

/obj/item/blood_harvester/attack(mob/living/target, mob/living/user, def_zone)
	return ATTACK_CHAIN_BLOCKED

/obj/item/blood_harvester/proc/can_harvest(mob/living/carbon/human/target, mob/user)
	. = FALSE
	if(!istype(target))
		user.balloon_alert(src, "неподходящая цель")
		return

	if(HAS_TRAIT(target, TRAIT_NO_BLOOD) || HAS_TRAIT(target, TRAIT_EXOTIC_BLOOD))
		user.balloon_alert(target, "кровь не обнаружена!")
		return

	if(target.blood_volume < BLOOD_HARVEST_VOLUME)
		user.balloon_alert(target, "недостаточно крови!")
		return

	if(!target.mind)
		user.balloon_alert(target, "разум не обнаружен!")
		return

	return TRUE

/obj/item/blood_harvester/proc/inject_blood(mob/living/carbon/human/user, atom/target)
	if(!target.reagents)
		return

	var/mob/living/L
	if(isliving(target))
		L = target
		if(!L.can_inject(user, TRUE))
			return

	if(!L && !target.is_injectable(user)) //only checks on non-living mobs, due to how can_inject() handles
		to_chat(user, span_warning("Вы не можете заполнить [target]!"))
		return

	if(target.reagents.total_volume >= target.reagents.maximum_volume)
		to_chat(user, span_notice("В [target] нет места."))
		return

	if(L) //living mob
		if(L != user)
			L.visible_message(span_danger("[user] is trying to inject [L]!"), \
									span_userdanger("[user] is trying to inject you!"))
			if(!do_after(user, BLOOD_HARVEST_TIME, L, NONE))
				return

			if(!reagents.total_volume)
				return

			if(L.reagents.total_volume >= L.reagents.maximum_volume)
				return

			L.visible_message(span_danger("[user] injects [L] with [src]!"), \
							span_userdanger("You injects [L] with the [src]!"))
	else
		to_chat(user, span_notice("You injects [target] with the [src]."))

	add_attack_logs(user, target, "Injected bood from [name], transfered [min(BLOOD_HARVEST_VOLUME, target.reagents.maximum_volume - target.reagents.total_volume)] units", reagents.harmless_helper() ? ATKLOG_ALMOSTALL : null)
	var/fraction = min(BLOOD_HARVEST_VOLUME / reagents.total_volume, 1)
	if(L)
		reagents.reaction(L, REAGENT_INGEST, fraction)

	reagents.trans_to(target, BLOOD_HARVEST_VOLUME)
	if(istype(target, /obj/item/reagent_containers/food))
		var/obj/item/reagent_containers/food/F = target
		F.log_eating = TRUE

	clear_blood()

/obj/item/blood_harvester/proc/drink_blood(mob/living/carbon/human/user) // Only for vampires.
	if(isvampire(user))
		clear_blood()
		user.adjust_nutrition(BLOOD_HARVEST_VOLUME)
		user.visible_message(span_warning("[user] пьет кровь из [src]."), span_info("Вы пьете кровь из [src]. Она насыщает вас, но не более."))
		return TRUE
	else
		return FALSE

/obj/item/blood_harvester/afterattack(atom/target, mob/user, proximity, params)
	if(used)
		if(user != target || !isvampire(user))
			inject_blood(user, target)
			return

		var/new_gender = tgui_alert(user, "Вколоть или выпить?", "Выбор действия", list("Выпить", "Вколоть"))
		if(new_gender == "Вколоть")
			inject_blood(user, target)
			return

		if(!drink_blood(user))
			to_chat(user, span_warning("Вы не вампир."))

		return

	if(!can_harvest(target, user))
		return

	target.visible_message(span_warning("[user] started collecting [target]'s blood using [src]!"), span_danger("[user] started collecting your blood using [src]!"))
	if(do_after(user, BLOOD_HARVEST_TIME, target = target, max_interact_count = 1))
		harvest(user, target)

/obj/item/blood_harvester/proc/harvest(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!can_harvest(target, user))
		return

	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	target.visible_message(span_warning("[user] collected [target]'s blood using [src]!"), span_danger("[user] collected your blood using [src]!"))
	target.emote("scream")
	for (var/i = 0; i < 3; ++i)
		if(prob(60))
			continue

		var/obj/item/organ/external/bodypart = pick(target.bodyparts)
		bodypart.internal_bleeding() // no blood collection from metafriends.

	target.transfer_blood_to(src, BLOOD_HARVEST_VOLUME)
	src.target = target.mind
	target_name = target.name
	used = TRUE
	item_state = "blood1_ful"
	update_icon(UPDATE_ICON_STATE)

/obj/item/blood_harvester/update_icon_state()
 	icon_state = initial(icon_state) + (used ? "_used" : "")

/obj/item/blood_harvester/proc/clear_blood()
	target = null
	target_name = null
	used = FALSE
	reagents.clear_reagents()
	item_state = "blood1_used"
	update_icon(UPDATE_ICON_STATE)

/obj/item/blood_harvester/attack_self(mob/user)
	. = ..()
	if(!used)
		user.balloon_alert(src, "уже пусто")
		return

	var/new_gender = tgui_alert(user, "Очистить сборщик крови?", "Подтверждение", list("Продолжить", "Отмена"))
	if(new_gender != "Продолжить")
		return

	clear_blood()
	playsound(src, 'sound/goonstation/items/hypo.ogg', 80)
	user.visible_message(span_info("[user] cleared blood at [src]."), span_info("You cleared blood at [src]."))

/obj/item/blood_harvester/examine(mob/user)
	. = ..()

	if(!used)
		. += span_info("Кровь не собрана.")
		return

	if(user?.mind.has_antag_datum(/datum/antagonist/traitor))
		. += span_info("Собрана кровь с отпечатком души [target_name].")
	else
		. += span_info("Кровь собрана.")

#undef BLOOD_HARVEST_VOLUME
#undef BLOOD_HARVEST_TIME
