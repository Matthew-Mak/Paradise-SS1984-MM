/datum/martial_combo/krav_maga/lung_punch
	name = "Удар под Дых"
	explaination_text = "Наносит сильный удар под дых, сдавливая лёгкие, отчего жертва временно не может дышать."

/datum/martial_combo/krav_maga/lung_punch/perform_combo(mob/living/carbon/human/user, mob/living/target, datum/martial_art/MA)
	target.visible_message("<span class='warning'>[user] бь[pluralize_ru(user.gender,"ет","ют")] [target] в солнечное сплетение!</span>", \
				  	"<span class='userdanger'>[user] бь[pluralize_ru(user.gender,"ет","ют")] тебя в солнечное сплетение! Вы не можете дышать!</span>")
	playsound(get_turf(user), 'sound/effects/hit_punch.ogg', 50, 1, -1)
	target.AdjustLoseBreath(5)
	target.adjustOxyLoss(10)
	add_attack_logs(user, target, "Melee attacked with martial-art [src] :  Lung Punch", ATKLOG_ALL)
	return MARTIAL_COMBO_DONE_CLEAR_COMBOS
