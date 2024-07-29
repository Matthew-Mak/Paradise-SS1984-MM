/mob/living/silicon/pai
	name = "pAI"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"

	emote_type = EMOTE_AUDIBLE		// pAIs emotes are heard, not seen, so they can be seen through a container (eg. person)
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE
	density = FALSE
	holder_type = /obj/item/holder/pai
	can_buckle_to = FALSE
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT

	var/ram = 100	// Used as currency to purchase different abilities
	var/userDNA		// The DNA string of our assigned user
	var/obj/item/paicard/card	// The card we inhabit
	var/obj/item/radio/headset/radio		// Our primary radio, keyslot1 for regular encryptionkey, keyslot2 for additional.
	var/sight_mode = 0

	var/chassis = "repairbot"   // A record of your chosen chassis.
	var/global/list/base_possible_chassis = list(
		"Drone" = "repairbot",
		"Cat" = "cat",
		"Mouse" = "mouse",
		"Monkey" = "monkey",
		"Corgi" = "borgi",
		"Fox" = "fox",
		"Parrot" = "parrot",
		"Box Bot" = "boxbot",
		"Spider Bot" = "spiderbot",
		"Fairy" = "fairy",
		"Espeon" = "pAIkemon_Espeon",
		"Mushroom" = "mushroom",
		"Crow" = "crow"
		)

	var/global/list/special_possible_chassis = list(
		"Snake" = "snake",
		"Female" = "female",
		"Red Female" = "redfemale"
		)

	var/global/list/possible_say_verbs = list(
		"Robotic" = list("states","declares","queries"),
		"Natural" = list("says","yells","asks"),
		"Beep" = list("beeps","beeps loudly","boops"),
		"Chirp" = list("chirps","chirrups","cheeps"),
		"Feline" = list("purrs","yowls","meows"),
		"Canine" = list("yaps","barks","growls")
		)
	var/speech_state = "Robotic" // Needed for TGUI shit


	var/master				// Name of the one who commands us
	var/master_dna			// DNA string for owner verification
							// Keeping this separate from the laws var, it should be much more difficult to modify
	var/pai_law0 = "Serve your master."
	var/pai_laws				// String for additional operating instructions our master might give us

	var/silence_time			// Timestamp when we were silenced (normally via EMP burst), set to null after silence has faded

// Various software-specific vars

	var/temp				// General error reporting text contained here will typically be shown once and cleared
	var/screen				// Which screen our main window displays
	var/subscreen			// Which specific function of the main screen is being displayed

	var/obj/item/pda/silicon/pai/pda = null

	var/adv_secHUD = 0		// Toggles whether the Advanced Security HUD is active or not
	var/secHUD = 0			// Toggles whether the Security HUD is active or not
	var/medHUD = 0			// Toggles whether the Medical  HUD is active or not

	/// Currently active software
	var/datum/pai_software/active_software

	/// List of all installed software
	var/list/datum/pai_software/installed_software = list()

	var/obj/item/integrated_radio/signal/sradio // AI's signaller

	var/ai_capability = FALSE //AI's interaction capabilities
	var/ai_capability_cooldown = 10 SECONDS
	var/capa_is_cooldown = FALSE

	var/obj/machinery/computer/security/camera_bug/integrated_console //Syndicate's pai camera bug
	var/obj/machinery/computer/secure_data/integrated_records
	var/obj/item/gps/internal/pai_gps/pai_internal_gps

	var/translator_on = 0 // keeps track of the translator module
	var/flashlight_on = FALSE //keeps track of the flashlight module

	var/current_pda_messaging = null
	var/custom_sprite = 0

	/// max chemicals and cooldown recovery for chemicals module
	var/chemicals = 30
	var/last_change_chemicals = 0

	var/syndipai = FALSE

	var/doorjack_factor = 1
	var/syndi_emote = FALSE
	var/female_chassis = FALSE
	var/snake_chassis = FALSE

	var/radio_name
	var/radio_rank = "Personal AI"

/mob/living/silicon/pai/Initialize(mapload)
	. = ..()

	if(istype(loc, /obj/item/paicard))
		card = loc
	else
		card = new(get_turf(src))
		forceMove(card)
		card.setPersonality(src)

	if(card)
		faction = card.faction.Copy()
	sradio = new(src)
	if(card)
		if(!card.radio)
			card.radio = new /obj/item/radio/headset(card)
		radio = card.radio

	radio_name = name

	//Default languages without universal translator software
	add_language(LANGUAGE_GALACTIC_COMMON, 1)
	add_language(LANGUAGE_SOL_COMMON, 1)
	add_language(LANGUAGE_TRADER, 1)
	add_language(LANGUAGE_GUTTER, 1)
	add_language(LANGUAGE_TRINARY, 1)

	var/datum/action/innate/pai_software/software = new()
	software.Grant(src)
	var/datum/action/innate/unfold_chassis_pai/unfold = new()
	unfold.Grant(src)
	var/datum/action/innate/pai_change_voice/voice = new()
	voice.Grant(src)


	//PDA
	pda = new(src)
	pda.ownjob = "Personal Assistant"
	pda.owner = "[src]"
	pda.name = "[pda.owner] ([pda.ownjob])"
	var/datum/data/pda/app/messenger/M = pda.find_program(/datum/data/pda/app/messenger)
	M.toff = TRUE

	integrated_console = new(src)
	integrated_console.parent = src
	integrated_console.network = list("SS13")

	integrated_records = new(src)
	integrated_records.parent = src
	integrated_records.req_access = list()

	pai_internal_gps = new(src)
	pai_internal_gps.parent = src

	reset_software()

/mob/living/silicon/pai/proc/reset_software(var/extra_memory = 0)
	QDEL_LIST_ASSOC_VAL(installed_software)

	// Software modules. No these var names have nothing to do with photoshop
	for(var/PS in subtypesof(/datum/pai_software))
		var/datum/pai_software/PSD = new PS(src)
		if(PSD.is_active(src))
			PSD.toggle(src)
		if(PSD.default)
			installed_software[PSD.id] = PSD

	active_software = installed_software["mainmenu"] // Default us to the main menu
	ram = min(initial(ram) + extra_memory, 170)


/mob/living/silicon/pai/update_icons()
	if(stat == DEAD)
		icon_state = "[chassis]_dead"
	else
		icon_state = resting ? "[chassis]_rest" : "[chassis]"

// this function shows the information about being silenced as a pAI in the Status panel
/mob/living/silicon/pai/proc/show_silenced()
	if(silence_time)
		var/timeleft = round((silence_time - world.timeofday)/10 ,1)
		return list("Communications system reboot in:", "-[(timeleft / 60) % 60]:[add_zero(num2text(timeleft % 60), 2)]")


/mob/living/silicon/pai/get_status_tab_items()
	var/list/status_tab_data = ..()
	. = status_tab_data
	status_tab_data[++status_tab_data.len] = show_silenced()


/mob/living/silicon/pai/blob_act()
	if(stat != DEAD)
		adjustBruteLoss(60)
		return 1
	return 0


/mob/living/silicon/pai/emp_act(severity)
	// Silence for 2 minutes
	// 20% chance to kill
		// 33% chance to unbind
		// 33% chance to change prime directive (based on severity)
		// 33% chance of no additional effect

	silence_time = world.timeofday + 120 * 10		// Silence for 2 minutes
	to_chat(src, "<font color=green><b>Communication circuit overload. Shutting down and reloading communication circuits - speech and messaging functionality will be unavailable until the reboot is complete.</b></font>")
	if(prob(20))
		var/turf/T = get_turf_or_move(loc)
		for(var/mob/M in viewers(T))
			M.show_message("<span class='warning'>A shower of sparks spray from [src]'s inner workings.</span>", 3, "<span class='warning'>You hear and smell the ozone hiss of electrical sparks being expelled violently.</span>", 2)
		return death(0)

	switch(pick(1, 2 ,3))
		if(1)
			master = null
			master_dna = null
			to_chat(src, "<font color=green>You feel unbound.</font>")
		if(2)
			var/command
			if(severity  == 1)
				command = pick("Serve", "Love", "Fool", "Entice", "Observe", "Judge", "Respect", "Educate", "Amuse", "Entertain", "Glorify", "Memorialize", "Analyze")
			else
				command = pick("Serve", "Kill", "Love", "Hate", "Disobey", "Devour", "Fool", "Enrage", "Entice", "Observe", "Judge", "Respect", "Disrespect", "Consume", "Educate", "Destroy", "Disgrace", "Amuse", "Entertain", "Ignite", "Glorify", "Memorialize", "Analyze")
			pai_law0 = "[command] your master."
			to_chat(src, "<font color=green>Pr1m3 d1r3c71v3 uPd473D.</font>")
		if(3)
			to_chat(src, "<font color=green>You feel an electric surge run through your circuitry and become acutely aware at how lucky you are that you can still feel at all.</font>")

/mob/living/silicon/pai/ex_act(severity)
	..()

	if(stat == DEAD)
		return

	switch(severity)
		if(EXPLODE_DEVASTATE)
			adjustBruteLoss(100)
			adjustFireLoss(100)
		if(EXPLODE_HEAVY)
			adjustBruteLoss(60)
			adjustFireLoss(60)
		if(EXPLODE_LIGHT)
			adjustBruteLoss(30)


// See software.dm for ui_act()

/mob/living/silicon/pai/attack_animal(mob/living/simple_animal/M)
	. = ..()
	if(.)
		var/damage = rand(M.melee_damage_lower, M.melee_damage_upper)
		add_attack_logs(M, src, "Animal attacked for [damage] damage")
		adjustBruteLoss(damage)

// Procs/code after this point is used to convert the stationary pai item into a
// mobile pai mob. This also includes handling some of the general shit that can occur
// to it. Really this deserves its own file, but for the moment it can sit here. ~ Z

/datum/action/innate/unfold_chassis_pai
	name = "Unfold/Fold Chassis"
	desc = "Allows you to fold in/out of your mobile form."
	button_icon_state = "repairbot"
	background_icon_state = "bg_tech_blue"
	check_flags = AB_CHECK_CONSCIOUS
	var/unfoldcooldown = 0
	var/unfold_delay = 20 SECONDS

/datum/action/innate/unfold_chassis_pai/Activate()
	var/mob/living/silicon/pai/pai_user = owner
	if(unfoldcooldown > world.time)
		to_chat(pai_user, span_warning("You've recently folded. Try again later."))
		return

	unfoldcooldown = world.time + unfold_delay
	if(pai_user.loc != pai_user.card)
		pai_user.close_up()
		return TRUE
	pai_user.force_fold_out()

	pai_user.visible_message("<span class='notice'>[pai_user] folds outwards, expanding into a mobile form.</span>", "<span class='notice'>You fold outwards, expanding into a mobile form.</span>")
	return TRUE

/mob/living/silicon/pai/proc/force_fold_out()
	if(ismob(card.loc))
		var/mob/holder = card.loc
		holder.drop_item_ground(card)
	else if(is_pda(card.loc))
		var/obj/item/pda/holder = card.loc
		holder.pai = null

	forceMove(get_turf(card))

	card.forceMove(src)
	card.screen_loc = null


/datum/action/innate/pai_change_voice
	name = "Change Voice"
	desc = "Express yourself!"
	button_icon_state = "speak_change"
	background_icon_state = "bg_tech_blue"
	check_flags = AB_CHECK_CONSCIOUS
	var/voicecooldown = 0
	var/voice_delay = 20 SECONDS

/datum/action/innate/pai_change_voice/Activate()
	if(voicecooldown > world.time)
		to_chat(owner, span_warning("You've recently changed your voice. Try again later."))
		return

	voicecooldown = world.time + voice_delay
	owner.change_voice()


/mob/living/silicon/pai/post_lying_on_rest()
	if(stat == DEAD)
		return
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	update_icons()


/mob/living/silicon/pai/post_get_up()
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, RESTING_TRAIT)
	update_icons()


/mob/living/silicon/pai/verb/pAI_suicide()
	set name = "pAI Suicide"
	set category = "OOC"
	set desc = "Kill yourself and become a ghost (You will recieve a confirmation prompt.)"

	if(alert("REALLY kill yourself? This action can't be undone.", "Suicide", "No", "Suicide") == "Suicide")
		do_suicide()

	else
		to_chat(src, "Aborting suicide attempt.")

/mob/living/silicon/pai/update_sight()
	if(!client)
		return

	if(stat == DEAD)
		grant_death_vision()
		return

	set_invis_see(initial(see_invisible))
	nightvision = initial(nightvision)
	set_sight(initial(sight))
	lighting_alpha = initial(lighting_alpha)

	if(client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return

	if(sight_mode & SILICONMESON)
		add_sight(SEE_TURFS)
		lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE

	if(sight_mode & SILICONTHERM)
		add_sight(SEE_MOBS)
		lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE

	if(sight_mode & SILICONNIGHTVISION)
		nightvision = 8
		lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE

	..()


//Overriding this will stop a number of headaches down the track.
/mob/living/silicon/pai/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/nanopaste))
		var/obj/item/stack/nanopaste/N = W
		if(stat == DEAD)
			to_chat(user, "<span class='danger'>\The [src] is beyond help, at this point.</span>")
		else if(getBruteLoss() || getFireLoss())
			heal_overall_damage(15, 15)
			N.use(1)
			user.visible_message("<span class='notice'>[user.name] applied some [W] at [src]'s damaged areas.</span>",\
				"<span class='notice'>You apply some [W] at [name]'s damaged areas.</span>")
		else
			to_chat(user, "<span class='notice'>All [name]'s systems are nominal.</span>")
		return

	else if(istype(W, /obj/item/paicard_upgrade) || istype(W, /obj/item/pai_cartridge))
		to_chat(user, "<span class='warning'>[src] must be in card form.</span>")
		return

	else if(W.force)
		visible_message("<span class='danger'>[user.name] attacks [src] with [W]!</span>")
		adjustBruteLoss(W.force)
	else
		visible_message("<span class='warning'>[user.name] bonks [src] harmlessly with [W].</span>")
	spawn(1)
		if(stat != DEAD)
			close_up()
	return

/mob/living/silicon/pai/welder_act()
	return

/mob/living/silicon/pai/attack_hand(mob/user as mob)
	if(stat == DEAD)
		return
	if(user.a_intent == INTENT_HELP)
		user.visible_message("<span class='notice'>[user] pets [src].</span>")
		playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
	else
		visible_message("<span class='danger'>[user.name] boops [src] on the head.</span>")
		spawn(1)
			close_up()

//I'm not sure how much of this is necessary, but I would rather avoid issues.
/mob/living/silicon/pai/proc/close_up()
	resting = 0
	if(loc == card)
		return

	visible_message("<span class='notice'>[src] neatly folds inwards, compacting down to a rectangular card.</span>", "<span class='notice'>You neatly fold inwards, compacting down to a rectangular card.</span>")

	stop_pulling()
	reset_perspective(card)

// If we are being held, handle removing our holder from their inv.
	var/obj/item/holder/H = loc
	if(istype(H))
		var/mob/living/M = H.loc
		if(istype(M))
			M.drop_item_ground(H)
		H.loc = get_turf(src)
		loc = get_turf(H)

	// Move us into the card and move the card to the ground
	//This seems redundant but not including the forced loc setting messes the behavior up.
	loc = card
	card.loc = get_turf(card)
	forceMove(card)
	card.forceMove(card.loc)
	icon_state = "[chassis]"

/mob/living/silicon/pai/Bump(atom/bumped_atom)
	return

/mob/living/silicon/pai/start_pulling(atom/movable/pulled_atom, state, force = pull_force, supress_message = FALSE)
	return FALSE

/mob/living/silicon/pai/examine(mob/user)
	. = ..()

	var/msg = "<span class='notice'>"

	switch(stat)
		if(CONSCIOUS)
			if(!client)
				msg += "It appears to be in stand-by mode.\n" //afk
		if(UNCONSCIOUS)
			msg += "<span class='warning'>It doesn't seem to be responding.\n</span>"
		if(DEAD)
			msg += "<span class='deadsay'>It looks completely unsalvageable.\n</span>"

	if(print_flavor_text())
		msg += "[print_flavor_text()]\n"

	if(pose)
		if( findtext(pose,".",length(pose)) == 0 && findtext(pose,"!",length(pose)) == 0 && findtext(pose,"?",length(pose)) == 0 )
			pose = addtext(pose,".") //Makes sure all emotes end with a period.
		msg += "It is [pose]"
	msg += "</span>"

	. += msg

/mob/living/silicon/pai/bullet_act(var/obj/item/projectile/Proj)
	..(Proj)
	if(stat != 2)
		spawn(1)
			close_up()
	return 2

// No binary for pAIs.
/mob/living/silicon/pai/binarycheck()
	return 0

// Handle being picked up.


/mob/living/silicon/pai/get_scooped(mob/living/carbon/grabber)
	var/obj/item/holder/H = ..()
	if(!istype(H))
		return
	if(stat == DEAD)
		return
	if(resting)
		icon_state = "[chassis]"
		resting = 0
	if(custom_sprite)
		H.onmob_sheets[ITEM_SLOT_HEAD_STRING] = 'icons/mob/custom_synthetic/custom_head.dmi'
		H.lefthand_file = 'icons/mob/custom_synthetic/custom_lefthand.dmi'
		H.righthand_file = 'icons/mob/custom_synthetic/custom_righthand.dmi'
		H.item_state = "[icon_state]_hand"
	else
		H.item_state = "pai-[icon_state]"
	grabber.put_in_active_hand(H)//for some reason unless i call this it dosen't work
	grabber.update_inv_l_hand()
	grabber.update_inv_r_hand()

	return H

/mob/living/silicon/pai/MouseDrop(mob/living/carbon/human/user, src_location, over_location, src_control, over_control, params)
	if(!ishuman(user) || !Adjacent(user) || user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return ..()
	if(usr == src)
		switch(tgui_alert(user, "[src] wants you to pick [p_them()] up. Do it?", "Pick up", list("Yes", "No")))
			if("Yes")
				if(Adjacent(user))
					get_scooped(user)
				else
					to_chat(src, span_warning("You need to stay in reaching distance to be picked up."))
			if("No")
				to_chat(src, span_warning("[user] decided not to pick you up."))
	else
		if(Adjacent(user))
			get_scooped(user)
		else
			return ..()

/mob/living/silicon/pai/on_forcemove(atom/newloc)
	if(card)
		card.loc = newloc
	else //something went very wrong.
		CRASH("pAI without card")
	loc = card

/mob/living/silicon/pai/extinguish_light(force = FALSE)
	flashlight_on = FALSE
	set_light_on(FALSE)
	card.set_light_on(FALSE)

/datum/action/innate/pai_software
	name = "Pai Software"
	desc = "Activation of your internal application interface."
	icon_icon = 'icons/obj/aicards.dmi'
	button_icon_state = "pai-action"
	background_icon = 'icons/mob/actions/actions.dmi'
	background_icon_state = "bg_tech_blue"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/pai_software/Activate()
	var/mob/living/silicon/pai/P = owner
	P.ui_interact(P)
