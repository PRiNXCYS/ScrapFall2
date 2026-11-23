## Day -> dusk -> night -> dawn -> day. Flags entered_night / entered_day are true for one step only.
class_name DayCycle
extends RefCounted

enum Phase { DAY, DUSK, NIGHT, DAWN }

const DAY_SECONDS := 150.0
const DUSK_SECONDS := 5.0
const NIGHT_SECONDS := 90.0
const DAWN_SECONDS := 5.0

var phase := Phase.DAY
var t := 0.0
var nights := 0  # nights started so far
var entered_night := false
var entered_day := false


func length(p: Phase) -> float:
	return [DAY_SECONDS, DUSK_SECONDS, NIGHT_SECONDS, DAWN_SECONDS][p]


func step(dt: float) -> void:
	entered_night = false
	entered_day = false
	t += dt
	while t >= length(phase):
		t -= length(phase)
		phase = ((phase + 1) % 4) as Phase
		if phase == Phase.NIGHT:
			entered_night = true
			nights += 1
		elif phase == Phase.DAY:
			entered_day = true


## Ends the night early (all waves cleared): jump straight to dawn.
func skip_to_dawn() -> void:
	if phase == Phase.NIGHT:
		phase = Phase.DAWN
		t = 0.0


## Sun strength: 1.1 by day, 0.15 at night, eased through dusk and dawn.
func light_energy() -> float:
	var k := t / length(phase)
	match phase:
		Phase.DAY: return 1.1
		Phase.NIGHT: return 0.15
		Phase.DUSK: return lerpf(1.1, 0.15, smoothstep(0.0, 1.0, k))
		_: return lerpf(0.15, 1.1, smoothstep(0.0, 1.0, k))
