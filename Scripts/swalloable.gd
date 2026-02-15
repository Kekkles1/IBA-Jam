extends RigidBody2D

@export var contains_milk: bool = false
@export var is_savory: bool = false
@export var level_texture: Texture2D

@export var collision_radius: float = 24.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var cs: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if level_texture != null:
		sprite.texture = level_texture

	_apply_collision_and_visual()

# Call this when you tweak values in the editor too
func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_apply_collision_and_visual()

func _apply_collision_and_visual() -> void:
	if cs.shape != null:
		cs.shape = cs.shape.duplicate(true)

	var circle := cs.shape as CircleShape2D
	if circle == null:
		return

	circle.radius = collision_radius
	_sync_sprite_to_circle(circle.radius)

func _sync_sprite_to_circle(radius: float) -> void:
	if sprite.texture == null:
		return

	# texture size in pixels
	var tex_size: Vector2 = sprite.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	# assume the sprite image is roughly a circle that fills the texture
	var tex_radius: float = min(tex_size.x, tex_size.y) * 0.5

	# scale sprite so its visual radius equals collision radius
	var s: float = radius / tex_radius
	sprite.scale = Vector2(s, s)
