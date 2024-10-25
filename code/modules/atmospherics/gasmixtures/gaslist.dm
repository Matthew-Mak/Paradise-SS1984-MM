/datum/gaslist
	var/list/gases = list()
	var/amount = 0

/datum/gaslist/proc/get_gas(id)
	if(isgas(id))
		return id

	if(!(id in gases))
		if(id in GLOB.special_gases)
			var/type = GLOB.special_gases[id]
			gases[id] = new type(id, 0)
		else
			gases[id] = new /datum/gas(id, 0)

	return gases[id]

/datum/gaslist/proc/update_gas(id)
	var/datum/gas/gas = get_gas(id)
	if(gas.check())
		gases -= gas
		qdel(gas)

/datum/gaslist/proc/get(id)
	if(!(id in gases))
		return 0

	var/datum/gas/gas = get_gas(id)
	update_gas(gas)
	return gas.amount

/datum/gaslist/proc/add(id, amount = 0)
	var/datum/gas/gas = get_gas(id)
	gas.add(amount)
	src.amount += amount
	update_gas(gas)

/datum/gaslist/proc/_set(id, amount = 0)
	var/datum/gas/gas = get_gas(id)
	src.amount -= get(id)
	gas._set(amount)
	src.amount += amount
	update_gas(gas)

/datum/gaslist/proc/gas_heatcap(id)
	var/datum/gas/gas = get_gas(id)
	return gas.heatcap()

/datum/gaslist/proc/heatcap()
	var/result = 0
	for(var/id in gases)
		var/datum/gas/gas = get_gas(id)
		result += gas.heatcap()

	return result

/datum/gaslist/proc/amount()
	return amount

/datum/gaslist/proc/copy()
	var/datum/gaslist/new_gaslist = new
	for(var/id in gases)
		new_gaslist.add(id, get(id))

	return new_gaslist

/datum/gaslist/proc/merge(datum/gaslist/giver)
	for(var/id in giver.gases)
		add(id, giver.get(id))

/datum/gaslist/proc/remove(amount)
	var/datum/gaslist/removed = new
	for(var/id in gases)
		var/transfer = QUANTIZE((get(id) / src.amount) * amount)
		removed.add(id, transfer)
		add(id, -transfer)

	return removed

/datum/gaslist/proc/remove_ratio(ratio)
	var/datum/gaslist/removed = new
	for(var/id in gases)
		var/transfer = QUANTIZE(get(id) * ratio)
		removed.add(id, transfer)
		add(id, -transfer)

	return removed

/datum/gaslist/proc/gases_with(datum/gaslist/gaslist2)
	var/ids = list()
	for(var/id in gases)
		ids += id

	for(var/id in gaslist2.gases)
		if(!(id in ids))
			ids += id

	return ids

/datum/gaslist/proc/delta_gaslist(datum/gaslist/gaslist, datum/gaslist/gaslist2, atmos_adjacent_turfs = 4)
	var/datum/gaslist/deltas = new
	for(var/id in gases_with(gaslist2))
		deltas.add(id, (gaslist.get(id) - gaslist2.get(id)) / (atmos_adjacent_turfs + 1))

	return deltas

/datum/gaslist/proc/delta_gaslist_total(datum/gaslist/gaslist2)
	var/datum/gaslist/deltas = new
	for(var/id in gases_with(gaslist2))
		deltas.add(id, get(id) - gaslist2.get(id))

	return deltas

/datum/gaslist/proc/isequal(datum/gaslist/gaslist2, eps = 0.0001)
	for(var/id in gases_with(gaslist2))
		if(abs(get(id) - gaslist2.get(id)) > eps)
			return 0

	return 1

/proc/to_gaslist(list/just_list)
	var/datum/gaslist/gases = new
	for(var/id in just_list)
		gases._set(id, just_list[id])

	return gases

/datum/gaslist/proc/breath(mob/living/breather)
	var/datum/gaslist/rest = new
	for(var/id in gases)
		var/datum/gas/gas = get_gas(id)
		var/used = gas.on_breath(breather)
		rest.add(id, gas.amount - used)
		gas.amount -= used

/datum/gaslist/proc/on_touch(mob/living/target)
	for(var/id in gases)
		var/datum/gas/gas = get_gas(id)
		add(id, -gas.on_touch(target))
