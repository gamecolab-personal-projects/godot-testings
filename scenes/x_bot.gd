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

# Configuración y Estado
var speed = 4.0
var lanzando = false
var bloqueando = false
var pie_dando_paso = false
var rotacion_original_torso: Vector3

func _ready():
	# Inicializar independencia de extremidades
	for t in [t_brazo_der, t_brazo_izq, t_pierna_der, t_pierna_izq]:
		t.set_as_top_level(true)
	
	# Los codos siguen al cuerpo
	for p in [p_brazo_der, p_brazo_izq, p_pierna_der, p_pierna_izq]:
		p.set_as_top_level(false)
	
	await get_tree().process_frame
	rotacion_original_torso = skel.rotation
	
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
	
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
		var direction = (transform.basis * Vector3(move_dir.x, 0, move_dir.z)).normalized()
		global_position += direction * speed * delta
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	
	# Inclinación dinámica de compensación
	var target_tilt = rotacion_original_torso.x
	if move_dir != Vector3.ZERO and not bloqueando:
		target_tilt -= deg_to_rad(12) # Se echa atrás solo al caminar
	
	if not bloqueando and not lanzando:
		skel.rotation.x = lerp_angle(skel.rotation.x, target_tilt, 5.0 * delta)
	
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
		# La verticalidad se gestiona en _physics_process
		pass

	var s = 15.0 * delta
	t_brazo_der.global_position = t_brazo_der.global_position.lerp(t_pos_der, s)
	p_brazo_der.global_position = p_brazo_der.global_position.lerp(t_pol_der, s)
	t_brazo_izq.global_position = t_brazo_izq.global_position.lerp(t_pos_izq, s)
	p_brazo_izq.global_position = p_brazo_izq.global_position.lerp(t_pol_izq, s)

func intentar_dar_paso(dir):
	if pie_dando_paso: return 
	
	# Retrasamos el centro de los pies MUCHO más respecto al cuerpo
	var centro_base = global_position - (dir * 0.3)
	centro_base.y = 0
	
	# Zancada muy adelantada
	var offset_paso = dir * 0.55 
	
	var ideal_der = centro_base + (transform.basis * Vector3(-0.18, 0, 0)) + offset_paso
	var ideal_izq = centro_base + (transform.basis * Vector3(0.18, 0, 0)) + offset_paso
	
	var d_der = t_pierna_der.global_position.distance_to(ideal_der)
	var d_izq = t_pierna_izq.global_position.distance_to(ideal_izq)
	
	# Umbral de activación (si el pie se queda atrás 0.4m, salta adelante 0.5m)
	if d_der > 0.4 and d_der >= d_izq:
		animar_paso(t_pierna_der, ideal_der)
	elif d_izq > 0.4:
		animar_paso(t_pierna_izq, ideal_izq)

func animar_paso(target, destino):
	pie_dando_paso = true
	var tween = create_tween()
	var medio = target.global_position.lerp(destino, 0.5) + Vector3(0, 0.15, 0)
	tween.tween_property(target, "global_position", medio, 0.1).set_trans(Tween.TRANS_SINE)
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
