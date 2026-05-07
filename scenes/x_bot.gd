extends Node3D

@onready var skel = $Skeleton3D
@onready var t_brazo_der = $KeyPoints/Target_BrazoDer
@onready var p_brazo_der = $KeyPoints/Pole_BrazoDer
@onready var t_brazo_izq = $KeyPoints/Target_BrazoIzq
@onready var p_brazo_izq = $KeyPoints/Pole_BrazoIzq
@onready var t_pierna_der = $KeyPoints/Target_PiernaDer
@onready var p_pierna_der = $KeyPoints/Pole_PiernaDer
@onready var t_pierna_izq = $KeyPoints/Target_PiernaIzq
@onready var p_pierna_izq = $KeyPoints/Pole_PiernaIzq

# Helpers de Perímetro
@onready var h_forward = $KeyPoints/Helper_Forward
@onready var h_back = $KeyPoints/Helper_Back
@onready var h_right = $KeyPoints/Helper_Right
@onready var h_left = $KeyPoints/Helper_Left

# Poses Visuales (Fantasmas)
@onready var pose_g_r_hand = $Pose_Guardia/RightHand
@onready var pose_g_r_elbow = $Pose_Guardia/RightElbow
@onready var pose_g_l_hand = $Pose_Guardia/LeftHand
@onready var pose_g_l_elbow = $Pose_Guardia/LeftElbow

@onready var pose_b_r_hand = $Pose_Bloqueo/RightHand
@onready var pose_b_r_elbow = $Pose_Bloqueo/RightElbow
@onready var pose_b_l_hand = $Pose_Bloqueo/LeftHand
@onready var pose_b_l_elbow = $Pose_Bloqueo/LeftElbow

@onready var pose_p_r_hand = $Pose_Punch/RightHand
@onready var pose_p_r_elbow = $Pose_Punch/RightElbow
@onready var pose_p_l_hand = $Pose_Punch/LeftHand
@onready var pose_p_l_elbow = $Pose_Punch/LeftElbow

# --- CONFIGURACIÓN DESDE EL INSPECTOR ---
@export_group("Locomoción")
@export var velocidad_movimiento: float = 4.0
@export var amplitud_zancada: float = 1.05
@export var umbral_paso: float = 0.65

@export_group("Personalidad Idle")
@export var amplitud_respiracion: float = 0.015
@export var velocidad_respiracion: float = 1.5

@export_group("Física y Balanceo")
@export var intensidad_rebote: float = 0.06
@export var inclinacion_torso_deg: float = 12.0
@export var balanceo_cadera_deg: float = 3.0
@export var amplitud_braceo: float = 0.25

# --- ESTADO INTERNO ---
var lanzando = false
var bloqueando = false
var pie_dando_paso = false
var walk_time = 0.0
var idle_time = 0.0
var current_move_dir = Vector3.ZERO
var rotacion_original_torso: Vector3
var posicion_original_skel: Vector3

func _ready():
	# Inicializar independencia de extremidades
	for t in [t_brazo_der, t_brazo_izq, t_pierna_der, t_pierna_izq]:
		t.set_as_top_level(true)
	
	# Los codos siguen al cuerpo
	for p in [p_brazo_der, p_brazo_izq, p_pierna_der, p_pierna_izq]:
		p.set_as_top_level(false)
	
	await get_tree().process_frame
	rotacion_original_torso = skel.rotation
	posicion_original_skel = skel.position
	
	# Posición inicial de pies
	t_pierna_der.global_position = $KeyPoints/Target_PiernaDer.global_position
	t_pierna_izq.global_position = $KeyPoints/Target_PiernaIzq.global_position
	
	actualizar_posicion_guardia()

func _physics_process(delta):
	var move_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move_dir.z += 1
	if Input.is_key_pressed(KEY_S): move_dir.z -= 1
	if Input.is_key_pressed(KEY_A): move_dir.x += 1
	if Input.is_key_pressed(KEY_D): move_dir.x -= 1
	
	current_move_dir = move_dir
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
		var direction = (transform.basis * Vector3(move_dir.x, 0, move_dir.z)).normalized()
		global_position += direction * velocidad_movimiento * delta
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
		
		# Avanzar el ciclo de caminata
		walk_time += delta * velocidad_movimiento * 3.0
	else:
		# Frenado MUCHO más rápido del ciclo de braceo
		walk_time = lerp(walk_time, 0.0, 12.0 * delta)
	
	# Inclinación dinámica de compensación
	var target_tilt = rotacion_original_torso.x
	var target_sway = 0.0
	var total_y_offset = 0.0
	
	if move_dir != Vector3.ZERO and not bloqueando:
		target_tilt -= deg_to_rad(inclinacion_torso_deg) 
		# Rebote de caminata
		total_y_offset = -abs(sin(walk_time)) * intensidad_rebote
		target_sway = sin(walk_time) * deg_to_rad(balanceo_cadera_deg)
	else:
		# Respiración (solo si estamos quietos)
		total_y_offset = sin(Time.get_ticks_msec() * 0.001 * velocidad_respiracion) * amplitud_respiracion * 0.4
	
	if not bloqueando and not lanzando:
		skel.rotation.x = lerp_angle(skel.rotation.x, target_tilt, 5.0 * delta)
		skel.rotation.z = lerp_angle(skel.rotation.z, target_sway, 5.0 * delta)
		skel.position.y = lerp(skel.position.y, posicion_original_skel.y + total_y_offset, 10.0 * delta)
	
	var d_actual = (transform.basis * Vector3(move_dir.x, 0, move_dir.z)).normalized()
	intentar_dar_paso(d_actual)

func _process(delta):
	if not lanzando:
		actualizar_posicion_guardia(delta)

func actualizar_posicion_guardia(delta = 1.0):
	var t_pos_der: Vector3; var t_pol_der: Vector3
	var t_pos_izq: Vector3; var t_pol_izq: Vector3
	
	if bloqueando:
		t_pos_der = pose_b_r_hand.global_position
		t_pol_der = pose_b_r_elbow.global_position
		t_pos_izq = pose_b_l_hand.global_position
		t_pol_izq = pose_b_l_elbow.global_position
		skel.rotation.x = lerp_angle(skel.rotation.x, rotacion_original_torso.x + deg_to_rad(8), 10.0 * delta)
	else:
		t_pos_der = pose_g_r_hand.global_position
		t_pol_der = pose_g_r_elbow.global_position
		t_pos_izq = pose_g_l_hand.global_position
		t_pol_izq = pose_g_l_elbow.global_position
		
		# APLICAR RESPIRACIÓN A LAS MANOS (Solo si estamos casi parados)
		if current_move_dir.length() < 0.1:
			var breath_hands = sin(Time.get_ticks_msec() * 0.001 * velocidad_respiracion) * amplitud_respiracion
			t_pos_der.y += breath_hands
			t_pos_izq.y += breath_hands
		
		# APLICAR BRACEO PROCEDIMENTAL (Manos y Codos)
		var v_fwd = (h_forward.global_position - h_back.global_position).normalized()
		var swing = sin(walk_time) * amplitud_braceo
		
		t_pos_der += v_fwd * swing
		t_pol_der += v_fwd * (swing * 0.8) - v_fwd * 0.1 + Vector3(0, -0.15, 0)
		
		t_pos_izq -= v_fwd * swing
		# Corregimos el signo: movemos atrás en horizontal y ABAJO en vertical
		t_pol_izq -= (v_fwd * (swing * 0.8) + v_fwd * 0.1)
		t_pol_izq += Vector3(0, -0.2, 0) # Más bajo que el derecho como pediste
		
		# La verticalidad se gestiona en _physics_process
		pass

	var s = 15.0 * delta
	t_brazo_der.global_position = t_brazo_der.global_position.lerp(t_pos_der, s)
	p_brazo_der.global_position = p_brazo_der.global_position.lerp(t_pol_der, s)
	t_brazo_izq.global_position = t_brazo_izq.global_position.lerp(t_pos_izq, s)
	p_brazo_izq.global_position = p_brazo_izq.global_position.lerp(t_pol_izq, s)

func intentar_dar_paso(dir):
	if pie_dando_paso: return 
	
	# Centro de referencia
	var centro_base = global_position - (dir * 0.1)
	centro_base.y = 0
	
	# Zancada equilibrada para compensar el avance
	var offset_paso = dir * amplitud_zancada 
	
	var ideal_der = centro_base + (transform.basis * Vector3(-0.18, 0, 0)) + offset_paso
	var ideal_izq = centro_base + (transform.basis * Vector3(0.18, 0, 0)) + offset_paso
	
	var d_der = t_pierna_der.global_position.distance_to(ideal_der)
	var d_izq = t_pierna_izq.global_position.distance_to(ideal_izq)
	
	# Umbral dinámico: si nos movemos usamos umbral_paso, si paramos usamos 0.15
	var umbral = umbral_paso if dir.length() > 0.1 else 0.15
	
	if d_der > umbral and d_der >= d_izq:
		animar_paso(t_pierna_der, ideal_der)
	elif d_izq > umbral:
		animar_paso(t_pierna_izq, ideal_izq)

func animar_paso(target, destino):
	pie_dando_paso = true
	var tween = create_tween()
	var medio = target.global_position.lerp(destino, 0.5) + Vector3(0, 0.15, 0)
	
	# Paso un poco más pausado para que se vea la amplitud (0.12s + 0.08s)
	tween.tween_property(target, "global_position", medio, 0.12).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(target, "global_position", destino, 0.08).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func(): pie_dando_paso = false)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not lanzando and not bloqueando:
			ejecutar_ataque_con_cuerpo()
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		bloqueando = event.pressed

func ejecutar_ataque_con_cuerpo():
	lanzando = true
	var tween = create_tween()
	tween.parallel().tween_property(t_brazo_der, "global_position", pose_p_r_hand.global_position, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(p_brazo_der, "global_position", pose_p_r_elbow.global_position, 0.1)
	tween.parallel().tween_property(t_brazo_izq, "global_position", pose_p_l_hand.global_position, 0.1)
	tween.parallel().tween_property(p_brazo_izq, "global_position", pose_p_l_elbow.global_position, 0.1)
	var rot_g = rotacion_original_torso + Vector3(deg_to_rad(10), deg_to_rad(15), 0)
	tween.parallel().tween_property(skel, "rotation", rot_g, 0.1)
	tween.chain().tween_interval(0.2)
	tween.finished.connect(func(): lanzando = false)
