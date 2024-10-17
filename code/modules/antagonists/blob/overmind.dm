GLOBAL_LIST_EMPTY(overminds)


/mob/camera/blob
	name = "Blob Overmind"
	real_name = "Blob Overmind"
	desc = "The overmind. It controls the blob."
	icon = 'icons/mob/blob.dmi'
	icon_state = "marker"
	nightvision = 8
	sight = SEE_TURFS|SEE_MOBS|SEE_OBJS
	invisibility = INVISIBILITY_OBSERVER
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	see_invisible = SEE_INVISIBLE_LIVING
	pass_flags = PASSBLOB
	faction = list(ROLE_BLOB)
	mouse_opacity = MOUSE_OPACITY_ICON
	move_on_shuttle = TRUE
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	pass_flags = PASSBLOB
	faction = list(ROLE_BLOB)
	// Vivid blue green, would be cool to make this change with strain
	lighting_cutoff_red = 0
	lighting_cutoff_green = 35
	lighting_cutoff_blue = 20
	hud_type = /datum/hud/blob_overmind
	var/obj/structure/blob/special/core/blob_core = null // The blob overmind's core
	var/blob_points = 0
	var/max_blob_points = OVERMIND_MAX_POINTS_DEFAULT
	var/last_attack = 0
	var/datum/blobstrain/reagent/blobstrain
	var/list/blob_mobs = list()
	/// A list of all blob structures
	var/list/all_blobs = list()
	var/list/resource_blobs = list()
	var/list/factory_blobs = list()
	var/list/node_blobs = list()
	var/free_strain_rerolls = OVERMIND_STARTING_REROLLS
	var/last_reroll_time = 0 //time since we last rerolled, used to give free rerolls
	var/nodes_required = TRUE //if the blob needs nodes to place resource and factory blobs
	var/list/blobs_legit = list()
	var/max_count = 0 //The biggest it got before death
	var/rerolling = FALSE
	/// The list of strains the blob can reroll for.
	var/list/strain_choices
	var/split_used = FALSE
	var/is_offspring = FALSE


/mob/camera/blob/Initialize(mapload, starting_points = OVERMIND_STARTING_POINTS)
	ADD_TRAIT(src, TRAIT_BLOB_ALLY, INNATE_TRAIT)
	blob_points = starting_points
	GLOB.overminds += src
	var/new_name = "[initial(name)] ([rand(1, 999)])"
	name = new_name
	real_name = new_name
	last_attack = world.time
	var/datum/blobstrain/BS = pick(GLOB.valid_blobstrains)
	set_strain(BS)
	color = blobstrain.complementary_color
	if(blob_core)
		blob_core.update_appearance()
	. = ..()
	START_PROCESSING(SSobj, src)
	GLOB.blob_telepathy_mobs |= src



/mob/camera/blob/proc/set_strain(datum/blobstrain/new_strain)
	if (!ispath(new_strain))
		return FALSE

	var/had_strain = FALSE
	if (istype(blobstrain))
		blobstrain.on_lose()
		qdel(blobstrain)
		had_strain = TRUE

	blobstrain = new new_strain(src)
	blobstrain.on_gain()

	if (had_strain)
		to_chat(src, span_notice("Your strain is now: <b><font color=\"[blobstrain.color]\">[blobstrain.name]</b></font>!"))
		to_chat(src, span_notice("The <b><font color=\"[blobstrain.color]\">[blobstrain.name]</b></font> strain [blobstrain.description]"))
		if(blobstrain.effectdesc)
			to_chat(src, span_notice("The <b><font color=\"[blobstrain.color]\">[blobstrain.name]</b></font> strain [blobstrain.effectdesc]"))
	SEND_SIGNAL(src, COMSIG_BLOB_SELECTED_STRAIN, blobstrain)

/mob/camera/blob/can_z_move(direction, turf/start, turf/destination, z_move_flags = NONE, mob/living/rider)
	if(placed) // The blob can't expand vertically (yet)
		return FALSE
	. = ..()
	if(!.)
		return
	var/turf/target_turf = .
	if(!is_valid_turf(target_turf)) // Allows unplaced blobs to travel through station z-levels
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(src, span_warning("Your destination is invalid. Move somewhere else and try again."))
		return null

/mob/camera/blob/proc/is_valid_turf(turf/tile)
	var/area/area = get_area(tile)
	if((area && !(area.area_flags & BLOBS_ALLOWED)) || !tile || !is_station_level(tile.z) || isgroundlessturf(tile))
		return FALSE
	return TRUE

/mob/camera/blob/process()
	if(!free_strain_rerolls && (last_reroll_time + BLOB_POWER_REROLL_FREE_TIME < world.time))
		to_chat(src, span_boldnotice("You have gained another free strain re-roll."))
		free_strain_rerolls = TRUE

/// Create a blob spore and link it to us
/mob/camera/blob/proc/create_spore(turf/spore_turf, spore_type = /mob/living/simple_animal/hostile/blob_minion/spore/minion)
	var/mob/living/simple_animal/hostile/blob_minion/spore/spore = new spore_type(spore_turf)
	assume_direct_control(spore)
	return spore

/// Give our new minion the properties of a minion
/mob/camera/blob/proc/assume_direct_control(mob/living/minion)
	minion.AddComponent(/datum/component/blob_minion, src)

/// Add something to our list of mobs and wait for it to die
/mob/camera/blob/proc/register_new_minion(mob/living/minion)
	blob_mobs |= minion
	if (!istype(minion, /mob/living/basic/blob_minion/blobbernaut))
		RegisterSignal(minion, COMSIG_LIVING_DEATH, PROC_REF(on_minion_death))

/// When a spore (or zombie) dies then we do this
/mob/camera/blob/proc/on_minion_death(mob/living/spore)
	SIGNAL_HANDLER
	blobstrain.on_sporedeath(spore)


/mob/camera/blob/Destroy()
	QDEL_NULL(blobstrain)
	for(var/BL in GLOB.blobs)
		var/obj/structure/blob/B = BL
		if(B && B.overmind == src)
			B.overmind = null
			B.update_appearance() //reset anything that was ours
	for(var/obj/structure/blob/blob_structure as anything in all_blobs)
		blob_structure.overmind = null
	all_blobs = null
	resource_blobs = null
	factory_blobs = null
	node_blobs = null
	blob_mobs = null
	GLOB.overminds -= src
	QDEL_LIST_ASSOC_VAL(strain_choices)

	STOP_PROCESSING(SSobj, src)
	GLOB.blob_telepathy_mobs -= src

	return ..()

/mob/camera/blob/proc/can_attack()
	return (world.time > (last_attack + CLICK_CD_RANGE))

/mob/camera/blob/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE)
	if(world.time < last_movement)
		return
	last_movement = world.time + 0.5 // cap to 20fps

	var/obj/structure/blob/B = locate() in range(OVERMIND_MAX_CAMERA_STRAY, newloc)
	if(B)
		loc = newloc
	else
		return FALSE

/mob/camera/blob/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	update_health_hud()
	add_points(0)

/mob/camera/blob/examine(mob/user)
	. = ..()
	if(blobstrain)
		. += "Its strain is <font color=\"[blobstrain.color]\">[blobstrain.name]</font>."

/mob/camera/blob/update_health_hud()
	if(!blob_core)
		return FALSE
	var/current_health = round((blob_core.obj_integrity / blob_core.max_integrity) * 100)
	hud_used.blobhealthdisplay.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#82ed00'>[current_health]%</font></div>")
	for(var/mob/living/basic/blob_minion/blobbernaut/blobbernaut in blob_mobs)
		var/datum/hud/using_hud = blobbernaut.hud_used
		if(!using_hud?.blobpwrdisplay)
			continue
		using_hud.blobpwrdisplay.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#82ed00'>[current_health]%</font></div>")

/mob/camera/blob/proc/add_points(points)
	blob_points = clamp(blob_points + points, 0, max_blob_points)
	hud_used.blobpwrdisplay.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#e36600'>[round(blob_points)]</font></div>")

/mob/camera/blob/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	list/message_mods = list(),
)
	if (!message)
		return

	if (src.client)
		if(GLOB.admin_mutes_assoc[ckey] & MUTE_IC)
			to_chat(src, span_boldwarning("You cannot send IC messages (muted)."))
			return
		if (!(ignore_spam || forced) && src.client.handle_spam_prevention(message, MUTE_IC))
			return

	if (stat)
		return

	blob_talk_overmind(message)

/mob/camera/blob/proc/blob_talk_overmind(message)

	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))

	if (!message)
		return

	add_say_logs(src, message, language = "BLOB")

	var/message_a = say_quote(message)
	var/rendered = span_big(span_blob("<b>\[Blob Telepathy\] <span class='name'>[name]</span>(<font color=\"[blobstrain.color]\">[blobstrain.name]</font>)</b> [message_a]"))
	relay_to_list_and_observers(rendered, GLOB.blob_telepathy_mobs, src)


/mob/camera/blob/mind_initialize()
	. = ..()
	var/datum/antagonist/blob/blob = mind.has_antag_datum(/datum/antagonist/blob)
	if(!blob)
		mind.add_antag_datum(/datum/antagonist/blob)
