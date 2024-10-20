/datum/antagonist/blob_minion
	name = "\improper Blob Minion"
	roundend_category = "blobs"
	job_rank = ROLE_BLOB
	special_role = SPECIAL_ROLE_BLOB_MINION
	wiki_page_name = "Blob"
	russian_wiki_name = "Блоб"
	show_in_roundend = FALSE
	show_in_orbit = FALSE
	/// The blob core that this minion is attached to
	var/datum/weakref/overmind

/datum/antagonist/blob_minion/can_be_owned(datum/mind/new_owner)
	. = ..() && isminion(new_owner?.current)

/datum/antagonist/blob_minion/New(mob/camera/blob/overmind)
	. = ..()
	src.overmind = WEAKREF(overmind)

/datum/antagonist/blob_minion/add_owner_to_gamemode()
	var/datum/game_mode/mode = SSticker.mode
	if(mode)
		mode.blobs["minions"] |= owner

/datum/antagonist/blob_minion/remove_owner_from_gamemode()
	var/datum/game_mode/mode = SSticker.mode
	if(mode)
		mode.blobs["minions"] -= owner


/datum/antagonist/blob_minion/roundend_report_header()
	return


/datum/antagonist/blob_minion/on_gain()
	. = ..()
	give_objectives()
	
/datum/antagonist/blob_minion/give_objectives()
	var/datum/objective/blob_minion/objective = new
	objective.owner = owner
	objective.overmind = overmind
	objectives += objective

/datum/antagonist/blob_minion/blobernaut
	name = "\improper Blobernaut"


/datum/antagonist/blob_minion/blobernaut/greet()
	. = ..()
	var/mob/camera/blob/blob = overmind
	var/datum/blobstrain/blobstrain = blob.blobstrain
	. += span_dangerbigger("Вы блобернаут! Вы должны помогать всем формам блоба в их миссии по уничтожению всего!")
	. += span_info("You are powerful, hard to kill, and slowly regenerate near nodes and cores, [span_cultlarge("but will slowly die if not near the blob")] or if the factory that made you is killed.")
	. += span_info("You can communicate with other blobbernauts and overminds <b>telepathically</b> by attempting to speak normally")
	. += span_info("Your overmind's blob reagent is: <b><font color=\"[blobstrain.color]\">[blobstrain.name]</b></font>!")
	. += span_info("The <b><font color=\"[blobstrain.color]\">[blobstrain.name]</b></font> reagent [blobstrain.shortdesc ? "[blobstrain.shortdesc]" : "[blobstrain.description]"]")

/datum/objective/blob_minion
	name = "protect the blob core"
	explanation_text = "Protect the blob core at all costs."
	var/datum/weakref/overmind

/datum/objective/blob_minion/check_completion()
	var/mob/camera/blob/resolved_overmind = overmind.resolve()
	if(!resolved_overmind)
		return FALSE
	return resolved_overmind.stat != DEAD

/**
 * Takes any datum `source` and checks it for blob_minion datum.
 */
/proc/isblobminion(datum/source)
	if(!source)
		return FALSE

	if(istype(source, /datum/mind))
		var/datum/mind/our_mind = source
		return our_mind.has_antag_datum(/datum/antagonist/blob_minion)

	if(!ismob(source))
		return FALSE

	var/mob/mind_holder = source
	if(!mind_holder.mind)
		return FALSE

	return mind_holder.mind.has_antag_datum(/datum/antagonist/blob_minion)
