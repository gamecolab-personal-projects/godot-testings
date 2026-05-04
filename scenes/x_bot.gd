extends Node3D

# --- REFERENCIAS ---
@onready var p_izq = $KeyPoints/Target_PiernaIzq
@onready var p_der = $KeyPoints/Target_PiernaDer
@onready var b_izq = $KeyPoints/Target_BrazoIzq
@onready var b_der = $KeyPoints/Target_BrazoDer
@onready var cuello = $KeyPoints/Target_Cuello # Usaremos esto para compensar la mirada

@onready var h_forward = $KeyPoints/Helper_Forward
@onready var h_back = $KeyPoints/Helper_Back
@onready var h_right = $KeyPoints/Helper_Right
@onready var h_left = $KeyPoints/Helper_Left

@onready var skeleton = $Skeleton3D

# --- AJUSTES ---
@export var velocidad = 3.5          # El sigilo suele ser más lento
@export var altura_paso = 0.1
@export var multiplicador_zancada = 1.2
@export var agachado = 0.25          # <--- CUÁNTO baja el cuerpo (0.0 a 0.5)

func _process(_delta):
	var t = Time.get_ticks_msec() / 1000.0 * velocidad
	
	var osc_a = sin(t) * multiplicador_zancada
	var osc_b = sin(t + PI) * multiplicador_zancada
	
	var centro_z = (h_forward.position.z + h_back.position.z) / 2.0
	var radio_paso = abs(h_forward.position.z - h_back.position.z) / 2.0
	var centro_x = (h_left.position.x + h_right.position.x) / 2.0
	
	# --- PIERNAS ---
	p_izq.position.z = centro_z + (osc_a * radio_paso)
	p_izq.position.x = lerp(centro_x, h_left.position.x, 0.3)
	p_izq.position.y = h_left.position.y + pow(max(0, cos(t)), 2.0) * altura_paso
	
	p_der.position.z = centro_z + (osc_b * radio_paso)
	p_der.position.x = lerp(centro_x, h_right.position.x, 0.3)
	p_der.position.y = h_right.position.y + pow(max(0, cos(t + PI)), 2.0) * altura_paso

	# --- CUERPO (EL TRUCO DEL AGACHADO) ---
	# Bajamos el esqueleto una cantidad fija + el balanceo
	var bobbing = -abs(sin(t * 2.0)) * 0.02
	skeleton.position.y = -agachado + bobbing
	
	# --- BRAZOS (Más tensos y bajos) ---
	# Al estar agachado, los brazos suelen ir más pegados al cuerpo
	var altura_base_brazo = 0.7 - (agachado * 0.5) 
	
	b_izq.position.z = centro_z + (osc_b * radio_paso * 0.6)
	b_izq.position.x = h_left.position.x + 0.05 # Más hacia adentro
	b_izq.position.y = h_left.position.y + altura_base_brazo
	
	b_der.position.z = centro_z + (osc_a * radio_paso * 0.6)
	b_der.position.x = h_right.position.x - 0.05
	b_der.position.y = h_right.position.y + altura_base_brazo

	# --- CUELLO (Compensación) ---
	# Si el cuerpo baja, el cuello debería subir un poco o adelantarse 
	# para que no parezca que el robot mira al suelo
	cuello.position.y = 1.0 + (agachado * 0.3)
	cuello.position.z = 0.2 # Lo adelantamos un poco para pose de "acecho"

	# --- DINÁMICA ---
	skeleton.rotation.x = deg_to_rad(agachado * 40.0) # Inclinamos el torso hacia adelante
	skeleton.rotation.y = sin(t) * 0.05
