/datum/martial_combo/krav_maga/leg_sweep
	name = "Подножка"
	explaination_text = "Выбивает ноги жертвы, в результате чего она падает и не может двигаться в течении короткого времени."

/datum/martial_combo/krav_maga/leg_sweep/perform_combo(mob/living/carbon/human/user, mob/living/target, datum/martial_art/MA)
	if(target.stat || target.IsWeakened())
		return FALSE
	target.visible_message("<span class='warning'>[user] выбивает ногу [target]!</span>", \
					  	"<span class='userdanger'>[user] выбил вам ногу!</span>")
	playsound(get_turf(user), 'sound/effects/hit_kick.ogg', 50, 1, -1)
	target.apply_damage(5, BRUTE)
	target.Weaken(2)
	add_attack_logs(user, target, "Melee attacked with martial-art [src] :  Leg Sweep", ATKLOG_ALL)
	return MARTIAL_COMBO_DONE_CLEAR_COMBOS
