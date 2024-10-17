/datum/antagonist/blob
	name = "\improper Blob"
	roundend_category = "blobs"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS
	show_to_ghosts = TRUE
	show_in_antagpanel = FALSE
	job_rank = ROLE_BLOB
	ui_name = "AntagInfoBlob"
	stinger_sound = 'sound/ambience/antag/blobalert.ogg'
	/// Action to release a blob infection
	var/datum/action/innate/blobpop/pop_action
	/// Initial points for a human blob
	var/starting_points_human_blob = OVERMIND_STARTING_POINTS
	/// Has the blob already popped inside of the round? This is here to prevent blobs from "respawning"
	var/has_already_popped = FALSE

/datum/antagonist/blob/roundend_report()
	var/basic_report = ..()
	//Display max blobpoints for blebs that lost
	if(isovermind(owner.current)) //embarrasing if not
		var/mob/camera/blob/overmind = owner.current
		if(!overmind.victory_in_progress) //if it won this doesn't really matter
			var/point_report = "<br><b>[owner.name]</b> took over [overmind.max_count] tiles at the height of its growth."
			return basic_report+point_report
	return basic_report

/datum/antagonist/blob/greet()
	. = ..()
	owner.announce_objectives()
	if(!isovermind(owner.current))
		to_chat(owner.current, span_notice("Use the pop ability to place your blob core! It is recommended you do this away from anyone else, as you'll be taking on the entire crew!"))
	else
		has_already_popped = TRUE

/datum/antagonist/blob/on_gain()
	create_objectives()
	. = ..()

/datum/antagonist/blob/remove_innate_effects()
	QDEL_NULL(pop_action)
	return ..()

/datum/antagonist/blob/get_preview_icon()
	var/datum/blobstrain/reagent/reactive_spines/reactive_spines = /datum/blobstrain/reagent/reactive_spines

	var/icon/icon = icon('icons/mob/nonhuman-player/blob.dmi', "blob_core")
	icon.Blend(initial(reactive_spines.color), ICON_MULTIPLY)
	icon.Blend(icon('icons/mob/nonhuman-player/blob.dmi', "blob_core_overlay"), ICON_OVERLAY)
	icon.Scale(ANTAGONIST_PREVIEW_ICON_SIZE, ANTAGONIST_PREVIEW_ICON_SIZE)

	return icon


/datum/antagonist/blob/ui_data(mob/user)
	var/list/data = list()

	data["objectives"] = get_objectives()

	if(!isovermind(user))
		return data
	var/mob/camera/blob/blob = user
	var/datum/blobstrain/reagent/blobstrain = blob.blobstrain

	if(!blobstrain)
		return data

	data["color"] = blobstrain.color
	data["description"] = blobstrain.description
	data["effects"] = blobstrain.effectdesc
	data["name"] = blobstrain.name

	return data

/datum/antagonist/blob/proc/create_objectives()
	var/datum/objective/blob_takeover/main = new
	main.owner = owner
	objectives += main

/datum/antagonist/blob/apply_innate_effects(mob/living/mob_override)
	if(isovermind(owner.current) || has_already_popped)
		return FALSE
	if(!pop_action)
		pop_action = new
	pop_action.Grant(owner.current)

/datum/objective/blob_takeover
	explanation_text = "Reach critical mass!"

//Non-overminds get this on blob antag assignment
/datum/action/innate/blobpop
	name = "Pop"
	desc = "Unleash the blob!"
	button_icon = 'icons/mob/blob.dmi'
	button_icon_state = "blob"

	/// The time taken before this ability is automatically activated.
	var/autoplace_time = OVERMIND_STARTING_AUTO_PLACE_TIME

/datum/action/innate/blobpop/Grant(Target)
	. = ..()
	if(owner)
		addtimer(CALLBACK(src, PROC_REF(Activate), TRUE), autoplace_time, TIMER_UNIQUE|TIMER_OVERRIDE)
		to_chat(owner, span_boldannounce("You will automatically pop and place your blob core in [DisplayTimeText(autoplace_time)]."))


/datum/antagonist/blob/antag_listing_status()
	. = ..()
	if(owner?.current)
		var/mob/camera/blob/blob_cam = owner.current
		if(istype(blob_cam))
			. += "(Progress: [length(blob_cam.blobs_legit)]/[blob_cam.blobwincount])"



