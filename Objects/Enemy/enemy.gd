extends Area2D

var shot_resource = preload("res://Assets/Sounds/LaserAttackMini.wav")

@export var health := 2:
	get:
		return health
	set(value):
		health = value
		if health == 0:
			die()
	
@export var speed := 200.0
@export var acceleration := 100.0
@export var weapon_cooldown := 0.5
@export var follow_buffer := 0.6
@export var avoid_force := 1.5

@onready var weapons_range: Area2D = $WeaponsRange
@onready var weapon_timer: Timer = $WeaponTimer
@onready var thrust_plus_x: GPUParticles2D = $ThrustParticles/ThrustPlusX
@onready var thrust_minus_x: GPUParticles2D = $ThrustParticles/ThrustMinusX
@onready var thrust_plus_y: GPUParticles2D = $ThrustParticles/ThrustPlusY
@onready var thrust_minus_y: GPUParticles2D = $ThrustParticles/ThrustMinusY
@onready var death_particles: Node2D = $DeathParticles

var bullet_scene = preload("res://Objects/Weapon/Projectile.tscn")

var target : CharacterBody2D
var velocity := Vector2.ZERO
var is_dead := false
var manager : Node
var detect_radius : float
var bullet_container : Node2D
var tracked_enemies : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_tree().get_nodes_in_group(&"Player")[0]
	bullet_container = get_tree().get_nodes_in_group(&"BulletContainer")[0]
	detect_radius = $WeaponsRange/CollisionShape2D.shape.radius * follow_buffer
	thrust_plus_x.emitting = false
	thrust_plus_y.emitting = false
	thrust_minus_x.emitting = false
	thrust_minus_y.emitting = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	var target_pos = to_local(target.global_position).normalized() * (to_local(target.global_position).length() - detect_radius)
	
	for enemy in tracked_enemies:
		target_pos += (global_position - enemy.global_position).normalized() * avoid_force
	
	velocity = velocity.move_toward(target_pos, delta * acceleration)
	velocity = velocity.limit_length(speed)
	
	visual_update()
	
	global_position += velocity * delta

func visual_update() -> void:
	if !is_zero_approx(velocity.x):
		thrust_plus_x.emitting = true if velocity.x > 0 else false
		thrust_minus_x.emitting = true if velocity.x < 0 else false
	if !is_zero_approx(velocity.y):
		thrust_plus_y.emitting = true if velocity.y > 0 else false
		thrust_minus_y.emitting = true if velocity.y < 0 else false

func hurt(incoming_vector) -> void:
	modulate = Color(100.0, 100.0, 100.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	velocity += incoming_vector * 20.0
	health -= 1

func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group(&"Player"):
		return
	body.hurt(15.0, false)
	die()

func _on_weapons_range_body_entered(body: Node2D) -> void:
	if body != target || is_dead:
		return
	
	weapon_timer.start(weapon_cooldown + (randf() / 2.0))

func _on_weapons_range_body_exited(body: Node2D) -> void:
	if body != target || is_dead:
		return
	
	weapon_timer.stop()

func _on_weapon_timer_timeout() -> void:
	if is_dead:
		return
	var shot = AudioStreamPlayer2D.new()
	shot.stream = shot_resource
	shot.volume_db = -15.0
	shot.finished.connect(shot.queue_free)
	add_child(shot)
	shot.play()
	var bullet = bullet_scene.instantiate()
	bullet_container.add_child(bullet)
	bullet.global_position = global_position
	bullet.look_at(target.global_position)
	weapon_timer.start(weapon_cooldown + (randf() / 2.0))

func die() -> void:
	is_dead = true
	set_deferred("monitorable", false)
	set_deferred("mointoring", false)
	$Sprite2D.hide()
	$ThrustParticles.hide()
	for child in $DeathParticles.get_children():
		child.emitting = true
	$DeathSound.play()
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_proximity_check_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"Enemies") && !tracked_enemies.has(area):
		tracked_enemies.append(area)

func _on_proximity_check_area_exited(area: Area2D) -> void:
	if !tracked_enemies.has(area):
		return
	tracked_enemies.erase(area)
