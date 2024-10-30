/obj/effect/proc_holder/spell/charge
	name = "Charge"
	desc = "Это заклинание можно использовать для подзарядки различных предметов, находящихся в ваших руках, от магических артефактов до электрических компонентов. Изобретательный волшебник может даже использовать его для обновления перезарядки заклинаний своего товарища по магии."
	school = "transmutation"
	base_cooldown = 1 MINUTES
	clothes_req = FALSE
	human_req = FALSE
	invocation = "DIRI CEL"
	invocation_type = "whisper"
	cooldown_min = 40 SECONDS //50 deciseconds reduction per rank
	action_icon_state = "charge"


/obj/effect/proc_holder/spell/charge/create_new_targeting()
	return new /datum/spell_targeting/self


/obj/effect/proc_holder/spell/charge/cast(list/targets, mob/user = usr)
	var/charge_result = NONE
	var/atom/charge_target_name


	var/mob/living/living = targets[1]

	if(living.pulling)
		charge_target_name = living.pulling.name
		charge_result = living.pulling.magic_charge_act(living)

	if(!(charge_result & RECHARGE_SUCCESSFUL))
		var/list/hand_items = list(living.get_active_hand(), living.get_inactive_hand())

		for(var/obj/item in hand_items)
			charge_target_name = item.name
			charge_result = item.magic_charge_act(living)

			if(charge_result & RECHARGE_SUCCESSFUL)
				break


	if(!(charge_result & RECHARGE_SUCCESSFUL))
		to_chat(user, span_notice("Вы чувствуете, как к вашим рукам приливает магическая сила, но это ощущение быстро исчезает..."))
		return

	if(charge_result & RECHARGE_BURNOUT)
		to_chat(user, span_caution("[charge_target_name] не реагирует на заклинание..."))
		return

	to_chat(user, span_notice("[charge_target_name] внезапно становится очень тёплым!"))
