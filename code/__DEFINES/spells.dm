/// Spell target defines
#define SPELL_TARGET_CLOSEST 1
#define SPELL_TARGET_RANDOM 2
/// Spell target selection
#define SPELL_SELECTION_RANGE "range"
#define SPELL_SELECTION_VIEW "view"
/// Smoke spell defines
#define SMOKE_NONE		0
#define SMOKE_HARMLESS	1
#define SMOKE_COUGHING	2
#define SMOKE_SLEEPING	3

// smoke paths
#define SMOKE_TYPE_DEFAULT		/obj/effect/particle_effect/smoke
#define SMOKE_TYPE_SLEEPING		/obj/effect/particle_effect/smoke/sleeping
#define SMOKE_TYPE_SOLID		/obj/effect/particle_effect/smoke/solid
#define SMOKE_TYPE_BAD			/obj/effect/particle_effect/smoke/bad

/// Recharge spell defines
#define RECHARGE_SUCCESSFUL     (1<<0)
#define RECHARGE_BURNOUT        (1<<1)
