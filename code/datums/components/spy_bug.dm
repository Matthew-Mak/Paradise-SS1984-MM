/datum/component/spy_bug
	var/obj/item/spy_bug/bug

/datum/component/spy_bug/Initialize(...)
	. = ..()
	var/atom/par = parent
	for(var/obj/item/spy_bug/spy_bug in par.contents)
		bug = spy_bug

/datum/component/spy_bug/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_CLICK_ALT, PROC_REF(on_altclick))
	RegisterSignal(parent, COMSIG_PREQDELETED, PROC_REF(deleted_handler))

/datum/component/spy_bug/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)
	UnregisterSignal(parent, COMSIG_CLICK_ALT)
	UnregisterSignal(parent, COMSIG_PREQDELETED)

/datum/component/spy_bug/proc/on_examine(datum/source, mob/living/carbon/human/user, list/examine_list)
	SIGNAL_HANDLER

	if(!istype(user))
		return

	examine_list += span_warning("Вы видите небольшое устройство с микрофоном и камерой.")

/datum/component/spy_bug/proc/on_altclick(datum/source, mob/living/carbon/human/user)
	SIGNAL_HANDLER

	if(!istype(user))
		return

	if(!user.Adjacent(parent))
		return

	if(user.stat)
		return

	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return

	bug.unhook(user)

/datum/component/spy_bug/proc/deleted_handler()
	bug.unhook()
