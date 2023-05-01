extends Area2D


@export var health := 3:
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

var bullet_scene = preload("res://Objects/Weapon/Projectile.tscn")

var target : CharacterBody2D
var target_pos := Vector2.ZERO
var velocity := Vector2.ZERO
var manager : Node
var detect_radius : float
var bullet_container : Node2D
var tracked_enemies : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_tree().get_nodes_in_group(&"Player")[0]
	bullet_container = get_tree().get_nodes_in_group(&"BulletContainer")[0]
	detect_radius = $WeaponsRange/CollisionShape2D.shape.radius * follow_buffer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var target_pos = to_local(target.global_position).normalized() * (to_local(target.global_position).length() - detect_radius)
	
	for enemy in tracked_enemies:
		target_pos += (global_position - enemy.global_position).normalized() * avoid_force
	
	velocity = velocity.move_toward(target_pos, delta * acceleration)
	velocity = velocity.limit_length(speed)
	
	global_position += velocity * delta

func hurt() -> void:
	health -= 1

func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group(&"Player"):
		return
	body.hurt(15.0)
	die()

func _on_weapons_range_body_entered(body: Node2D) -> void:
	if body != target:
		return
	
	weapon_timer.start(weapon_cooldown + (randf() / 2.0))

func _on_weapons_range_body_exited(body: Node2D) -> void:
	if body != target:
		return
	
	weapon_timer.stop()

func _on_weapon_timer_timeout() -> void:
	var bullet = bullet_scene.instantiate()
	bullet_container.add_child(bullet)
	bullet.global_position = global_position
	bullet.look_at(target.global_position)
	weapon_timer.start(weapon_cooldown + (randf() / 2.0))

func die() -> void:
#	manager.cleanup(self)
	queue_free()

func _on_proximity_check_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"Enemies") && !tracked_enemies.has(area):
		tracked_enemies.append(area)

func _on_proximity_check_area_exited(area: Area2D) -> void:
	if !tracked_enemies.has(area):
		return
	tracked_enemies.erase(area)
