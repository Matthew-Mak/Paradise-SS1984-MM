/obj/structure/blob/storage
	name = "storage blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_resource"
	max_integrity = BLOB_STORAGE_MAX_HP
	fire_resist = BLOB_STORAGE_FIRE_RESIST
	point_return = BLOB_REFUND_STORAGE_COST 

/obj/structure/blob/storage/obj_destruction(damage_flag)
	if(overmind)
		overmind.max_blob_points -= 50
	..()

/obj/structure/blob/storage/proc/update_max_blob_points(new_point_increase)
	if(overmind)
		overmind.max_blob_points += new_point_increase
