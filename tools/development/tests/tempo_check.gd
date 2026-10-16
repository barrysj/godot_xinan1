extends Node
var integrated := 0.0
var tween_value := 0.0
func _ready() -> void:
	_run.call_deferred()
func _process(delta: float) -> void:
	integrated += delta
func _run() -> void:
	await get_tree().create_timer(0.5,true,false,true).timeout
	var start := Time.get_ticks_usec()
	var before := integrated
	var tween := create_tween()
	tween.tween_method(func(v): tween_value = v,0.0,1.0,10.0)
	await get_tree().create_timer(3.0,true,false,true).timeout
	var real_seconds := (Time.get_ticks_usec()-start)/1000000.0
	var ratio := (integrated-before)/real_seconds
	var tween_ratio := tween_value*10.0/real_seconds
	var ok := is_equal_approx(Engine.time_scale,0.8) and absf(ratio-0.8)<0.08 and absf(tween_ratio-0.8)<0.08
	print("TEMPO_CHECK delta_ratio=",ratio," tween_ratio=",tween_ratio," failures=",0 if ok else 1)
	get_tree().quit(0 if ok else 1)

