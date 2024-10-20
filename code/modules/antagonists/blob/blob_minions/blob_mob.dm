/// Root of shared behaviour for mobs spawned by blobs, is abstract and should not be spawned
/mob/living/simple_animal/hostile/blob_minion
	name = "Blob Error"
	desc = "A nonfunctional fungal creature created by bad code or celestial mistake. Point and laugh."
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_head"
	unique_name = TRUE
	pass_flags = PASSBLOB
	status_flags = NONE //No throwing blobspores into deep space to despawn, or throwing blobbernaughts, which are bigger than you.
	faction = list(ROLE_BLOB)
	bubble_icon = "blob"
	speak_emote = null
	stat_attack = UNCONSCIOUS
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	sight = SEE_TURFS|SEE_MOBS|SEE_OBJS
	nightvision = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	can_buckle_to = FALSE
	universal_speak = TRUE //So mobs can understand them when a blob uses Blob Broadcast
	sentience_type = SENTIENCE_OTHER
	gold_core_spawnable = NO_SPAWN
	can_be_on_fire = TRUE
	fire_damage = 3
	tts_seed = "Earth"
	tts_atom_say_effect = SOUND_EFFECT_NONE


/mob/living/simple_animal/hostile/blob_minion/ComponentInitialize()
	AddComponent( \
		/datum/component/animal_temperature, \
		minbodytemp = 0, \
		maxbodytemp = INFINITY, \
	)
	AddComponent(/datum/component/blob_minion, on_strain_changed = CALLBACK(src, PROC_REF(on_strain_updated)))

/mob/living/simple_animal/hostile/blob_minion/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_BLOB_ALLY, TRAIT_MUTE), INNATE_TRAIT)

/// Called when our blob overmind changes their variant, update some of our mob properties
/mob/living/simple_animal/hostile/blob_minion/proc/on_strain_updated(mob/camera/blob/overmind, datum/blobstrain/new_strain)
	return

/// Associates this mob with a specific blob factory node
/mob/living/simple_animal/hostile/blob_minion/proc/link_to_factory(obj/structure/blob/special/factory/factory)
	RegisterSignal(factory, COMSIG_QDELETING, PROC_REF(on_factory_destroyed))

/// Called when our factory is destroyed
/mob/living/simple_animal/hostile/blob_minion/proc/on_factory_destroyed()
	SIGNAL_HANDLER
	to_chat(src, span_userdanger("Your factory was destroyed! You feel yourself dying!"))
