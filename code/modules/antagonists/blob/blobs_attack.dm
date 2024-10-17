/atom/proc/can_blob_attack()
	return !(HAS_TRAIT(src, TRAIT_MAGICALLY_PHASED))

/mob/living/can_blob_attack()
	. = ..()
	if(!.)
		return
	return !incorporeal_move

/obj/effect/dummy/phased_mob/can_blob_attack()
	return FALSE