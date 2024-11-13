// Fish flopping

#define PAUSE_BETWEEN_PHASES 15
#define PAUSE_BETWEEN_FLOPS 2
#define FLOP_COUNT 2
#define FLOP_DEGREE 20
#define FLOP_SINGLE_MOVE_TIME 1.5
#define JUMP_X_DISTANCE 5
#define JUMP_Y_DISTANCE 6
/// This animation should be applied to actual parent atom instead of vc_object.
/proc/flop_animation(atom/movable/animation_target)
	var/pause_between = PAUSE_BETWEEN_PHASES + rand(1, 5) //randomized a bit so fish are not in sync
	animate(animation_target, time = pause_between, loop = -1)
	//move nose down and up
	for(var/_ in 1 to FLOP_COUNT)
		var/matrix/up_matrix = matrix()
		up_matrix.Turn(FLOP_DEGREE)
		var/matrix/down_matrix = matrix()
		down_matrix.Turn(-FLOP_DEGREE)
		animate(transform = down_matrix, time = FLOP_SINGLE_MOVE_TIME, loop = -1)
		animate(transform = up_matrix, time = FLOP_SINGLE_MOVE_TIME, loop = -1)
		animate(transform = matrix(), time = FLOP_SINGLE_MOVE_TIME, loop = -1, easing = BOUNCE_EASING | EASE_IN)
		animate(time = PAUSE_BETWEEN_FLOPS, loop = -1)
	//bounce up and down
	animate(time = pause_between, loop = -1, flags = ANIMATION_PARALLEL)
	var/jumping_right = FALSE
	var/up_time = 3 * FLOP_SINGLE_MOVE_TIME / 2
	for(var/_ in 1 to FLOP_COUNT)
		jumping_right = !jumping_right
		var/x_step = jumping_right ? JUMP_X_DISTANCE/2 : -JUMP_X_DISTANCE/2
		animate(time = up_time, pixel_y = JUMP_Y_DISTANCE , pixel_x=x_step, loop = -1, flags= ANIMATION_RELATIVE, easing = BOUNCE_EASING | EASE_IN)
		animate(time = up_time, pixel_y = -JUMP_Y_DISTANCE, pixel_x=x_step, loop = -1, flags= ANIMATION_RELATIVE, easing = BOUNCE_EASING | EASE_OUT)
		animate(time = PAUSE_BETWEEN_FLOPS, loop = -1)
#undef PAUSE_BETWEEN_PHASES
#undef PAUSE_BETWEEN_FLOPS
#undef FLOP_COUNT
#undef FLOP_DEGREE
#undef FLOP_SINGLE_MOVE_TIME
#undef JUMP_X_DISTANCE
#undef JUMP_Y_DISTANCE

// actual fish

/obj/item/lavaland_fish
	name = "generic lavaland fish"
	ru_names = list(
		NOMINATIVE = "рыба",
		ACCUSATIVE = "рыбу"
	)
	desc = "Вау, она такая... невпечатляющая!"
	icon = 'icons/obj/lavaland/lava_fishing.dmi'
	icon_state = "ash_crab"
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	throwforce = 5
	force = 1
	attack_verb = list("slapped", "humiliated", "hit", "rubbed")
	hitsound = 'sound/effects/snap.ogg'

	/// If this fish should do the flopping animation
	var/do_flop_animation = TRUE
	var/flopping = FALSE

	/// Favourite bait. Using this will add more chance to catch this fish
	var/favorite_bait = null

	/// List of items you get after butchering it
	var/list/butcher_loot = list()

/obj/item/lavaland_fish/Initialize(mapload)
	. = ..()
	if(do_flop_animation)
		RegisterSignal(src, COMSIG_ATOM_TEMPORARY_ANIMATION_START, PROC_REF(on_temp_animation))
	START_PROCESSING(SSobj, src)

/obj/item/lavaland_fish/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/lavaland_fish/attackby(obj/item/I, mob/living/user, params)
	user.changeNext_move(CLICK_CD_MELEE)
	var/sharpness = is_sharp(I)
	if(sharpness && user.a_intent == INTENT_HARM)
		to_chat(user, "<span class='notice'>Вы начинаете разделывать [declent_ru(ACCUSATIVE)]...</span>")
		playsound(loc, 'sound/weapons/slice.ogg', 50, 1, -1)
		if(do_after(user, 6 SECONDS, src,) && Adjacent(I))
			harvest(user)
	return ..()

/obj/item/lavaland_fish/proc/harvest(mob/user)
	if(QDELETED(src))
		return
	for(var/path in butcher_loot)
		for(var/i in 1 to butcher_loot[path])
			new path(loc)
		butcher_loot.Remove(path)
	visible_message(span_notice("[user] успешно разделывает [declent_ru(ACCUSATIVE)]!"))
	playsound(src.loc, 'sound/goonstation/effects/gib.ogg', 50, 1)
	gibs(loc)
	qdel(src)

/// Starts flopping animation
/obj/item/lavaland_fish/proc/start_flopping()
	if(flopping)  //Requires update_transform/animate_wrappers to be less restrictive.
		return
	flopping = TRUE
	flop_animation(src)

/// Stops flopping animation
/obj/item/lavaland_fish/proc/stop_flopping()
	if(flopping)
		flopping = FALSE
		animate(src, transform = matrix()) //stop animation

/// Refreshes flopping animation after temporary animation finishes
/obj/item/lavaland_fish/proc/on_temp_animation(datum/source, animation_duration)
	if(animation_duration > 0)
		addtimer(CALLBACK(src, PROC_REF(refresh_flopping)), animation_duration)

/obj/item/lavaland_fish/proc/refresh_flopping()
	if(flopping)
		flop_animation(src)

/obj/item/lavaland_fish/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	start_flopping()

/obj/item/lavaland_fish/shoreline
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/lavaland_fish/deep_water
	w_class = WEIGHT_CLASS_BULKY

