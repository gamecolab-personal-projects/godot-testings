extends Node3D

@onready var skel = $Skeleton3D
@onready var t_brazo_der = $KeyPoints/Target_BrazoDer
@onready var p_brazo_der = $KeyPoints/Pole_BrazoDer
@onready var m_golpe = $KeyPoints/Marker_Golpe

# Helpers de perímetro
@onready var h_forward = $KeyPoints/Helper_Forward
@onready var h_back = $KeyPoints/Helper_Back
@onready var h_right = $KeyPoints/Helper_Right
@onready var h_left = $KeyPoints/Helper_Left

var lanzando = false
var guardia_pos: Vector3
var guardia_pole: Vector3
var rotacion_original_torso: Vector3

func _ready():
	t_brazo_der.set_as_top_level(true)
	p_brazo_der.set_as_top_level(true)
	
	await get_tree().process_frame
	rotacion_original_torso = skel.rotation # Guardamos la pose natural
	configurar_y_guardar_guardia()

func configurar_y_guardar_guardia():
	var centro = skel.global_position
	var v_der = (h_right.global_position - h_left.global_position)
	var v_fwd = (h_forward.global_position - h_back.global_position)
	
	guardia_pos = centro + (v_der * 0.4) + (v_fwd * 0.3)
	guardia_pos.y = centro.y + 1.2
	guardia_pole = centro + (v_der * 0.6) - (v_fwd * 0.1)
	guardia_pole.y = centro.y + 1.1
	
	t_brazo_der.global_position = guardia_pos
	p_brazo_der.global_position = guardia_pole

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not lanzando:
			ejecutar_ataque_con_cuerpo()

func ejecutar_ataque_con_cuerpo():
	lanzando = true
	var pos_impacto = m_golpe.global_position
	var v_der_norm = (h_right.global_position - h_left.global_position).normalized()
	
	var tween = create_tween()
	
	# --- FASE 1: IMPACTO (Brazo + Rotación de Torso) ---
	tween.parallel().tween_property(t_brazo_der, "global_position", pos_impacto, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(p_brazo_der, "global_position", pos_impacto + (v_der_norm * 0.5), 0.1)
	
	# Rotamos el torso: Inclinación hacia adelante (X) y giro hacia la izquierda (Y) para adelantar el hombro derecho
	var rot_golpe = rotacion_original_torso + Vector3(deg_to_rad(10), deg_to_rad(15), 0)
	tween.parallel().tween_property(skel, "rotation", rot_golpe, 0.1).set_trans(Tween.TRANS_SINE)
	
	# --- FASE 2: ESPERA ---
	tween.chain().tween_interval(2.0)
	
	# --- FASE 3: RETORNO ---
	tween.chain().parallel().tween_property(t_brazo_der, "global_position", guardia_pos, 0.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(p_brazo_der, "global_position", guardia_pole, 0.4)
	tween.parallel().tween_property(skel, "rotation", rotacion_original_torso, 0.4).set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func(): lanzando = false)
