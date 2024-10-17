/mob/camera/blob

/mob/camera/blob/New()
	var/new_name = "[initial(name)] ([rand(1, 999)])"
	name = new_name
	real_name = new_name
	last_attack = world.time
	..()
	START_PROCESSING(SSobj, src)

/mob/camera/blob/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/mob/camera/blob/process()
	if(!blob_core)
		qdel(src)

/mob/camera/blob/Login()
	..()
	sync_mind()
	update_health_hud()
	sync_lighting_plane_alpha()

/mob/camera/blob/update_health_hud()
	if(blob_core && hud_used)
		hud_used.blobhealthdisplay.maptext = "<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#e36600'>[round(blob_core.obj_integrity)]</font></div>"

/mob/camera/blob/memory()
	SSticker.mode.update_blob_objective()
	..()

/mob/camera/blob/say(message)
	if(!message)
		return

	if(client)
		if(check_mute(client.ckey, MUTE_IC))
			to_chat(src, "You cannot send IC messages (muted).")
			return
		if(client.handle_spam_prevention(message, MUTE_IC))
			return

	if(stat)
		return

	blob_talk(message)


/mob/camera/blob/proc/blob_talk(message)
	add_say_logs(src, message, language = "BLOB")

	message = trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))

	if(!message)
		return

	var/rendered = "<i><span class='blob[blobstrain.id]'>Blob Telepathy,</span> <span class='name'>[name](<span class='blob[blobstrain.id]'>[blobstrain.name]</span>)</span> states, <span class='blob[blobstrain.id]'>\"[message]\"</span></i>"
	for(var/mob/M in GLOB.mob_list)
		if(isovermind(M) || isblobbernaut(M) || isblobinfected(M.mind))
			M.show_message(rendered, 2)
		else if(isobserver(M) && !isnewplayer(M))
			var/rendered_ghost = "<i><span class='blob[blobstrain.id]'>Blob Telepathy,</span> \
			<span class='name'>[name](<span class='blob[blobstrain.id]'>[blobstrain.name]</span>)</span> \
			<a href='byond://?src=[M.UID()];follow=[UID()]'>(F)</a> states, <span class='blob[blob_reagent_datum.id]'>\"[message]\"</span></i>"
			M.show_message(rendered_ghost, 2)


/mob/camera/blob/blob_act(obj/structure/blob/B)
	return

/mob/camera/blob/get_status_tab_items()
	. = ..()
	if(blob_core)
		. += "Core Health[blob_core.obj_integrity]"
		. += "Power Stored: [blob_points]/[max_blob_points]"
		. += "Blobs to Win: [GLOB.blobs.len]/[SSticker?.mode.blob_win_count]"
	if(free_strain_rerolls)
		. += "You have [free_strain_rerolls] Free Strain Reroll\s Remaining"

/mob/camera/blob/proc/can_attack()
	return (world.time > (last_attack + CLICK_CD_RANGE))

/mob/camera/blob/proc/select_reagent()
	var/list/possible_reagents = list()
	var/datum/antagonist/blob_overmind/overmind_datum = mind?.has_antag_datum(/datum/antagonist/blob_overmind)
	if(!overmind_datum)
		for(var/type in subtypesof(/datum/reagent/blob))
			possible_reagents.Add(new type)
		blob_reagent_datum = pick(possible_reagents)
	else
		blob_reagent_datum = overmind_datum.reagent
	if(blob_core)
		blob_core.adjustcolors(blob_reagent_datum.color)

	color = blob_reagent_datum.complementary_color
