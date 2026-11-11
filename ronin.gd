extends Node3D
## Android cyberpunk treadmill: fixed hero, moving procedural checkerboard.
const CYAN := Color("#16e7e4")
const PINK := Color("#ff38ba")
const ARMOR := Color("#192a3d")
const STEEL := Color("#43576a")
const BLACK := Color("#0c1323")
var floor_mat: ShaderMaterial
var hero: Node3D
var l_leg: Node3D
var r_leg: Node3D
var l_arm: Node3D
var r_arm: Node3D
var travel := Vector2.ZERO
var move := Vector2.ZERO
var facing := Vector2(0,1)
var stride := 0.0
var joystick_id := -1
var joystick_start := Vector2.ZERO
var knob := Vector2.ZERO
var sprint := false
var label_speed: Label
var hud: Control

func material(c: Color, glowing: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.32
    m.metallic = 0.45
    if glowing:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 3.0
    return m

func block(root: Node3D, name: String, pos: Vector3, size: Vector3, c: Color, glow: bool = false) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = mesh
    node.position = pos
    node.material_override = material(c,glow)
    root.add_child(node)

func _ready() -> void:
    var environment := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#080d1b")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#7184ab")
    e.ambient_light_energy = 0.8
    environment.environment = e
    add_child(environment)
    var cam := Camera3D.new()
    cam.position = Vector3(3.1,4.2,-7.7)
    cam.fov = 42.0
    add_child(cam)
    cam.look_at(Vector3(0,1.52,0))
    cam.current = true
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-25,0)
    sun.light_energy = 1.7
    add_child(sun)
    var neon := OmniLight3D.new()
    neon.position = Vector3(-2,4,-1)
    neon.omni_range = 12
    neon.light_energy = 4
    neon.light_color = PINK
    add_child(neon)
    var plane := MeshInstance3D.new()
    var p := PlaneMesh.new()
    p.size = Vector2(140,140)
    plane.mesh = p
    floor_mat = ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec2 scroll = vec2(0.0);
varying vec2 v_pos;
void vertex() { v_pos = VERTEX.xz; }
void fragment() {
  vec2 q = (v_pos + scroll) * 0.8;
  vec2 tile = floor(q);
  float chk = mod(tile.x + tile.y,2.0);
  vec3 col = mix(vec3(0.018,0.026,0.061),vec3(0.06,0.10,0.16),chk);
  vec2 edge = abs(fract(q)-0.5);
  float border = smoothstep(0.47,0.50,max(edge.x,edge.y));
  col = mix(col,vec3(0.03,0.29,0.36),border*0.40);
  ALBEDO = col;
}
"""
    floor_mat.shader = shader
    plane.material_override = floor_mat
    add_child(plane)
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.79
    torus.outer_radius = 0.85
    ring.mesh = torus
    ring.position.y = 0.05
    ring.material_override = material(CYAN,true)
    add_child(ring)
    create_hero()
    create_hud()

var rig_root: Node3D
var l_knee: Node3D
var r_knee: Node3D
var l_elbow: Node3D
var r_elbow: Node3D
var head_joint: Node3D

func create_hero() -> void:
    hero = Node3D.new()
    hero.name = "CyberRonin"
    add_child(hero)
    var packed: PackedScene = load("res://assets/ronin_v2.glb")
    if packed == null:
        push_error("The real 3D avatar could not be imported")
        return
    rig_root = packed.instantiate() as Node3D
    hero.add_child(rig_root)
    l_leg = rig_root.find_child("HipL", true, false) as Node3D
    r_leg = rig_root.find_child("HipR", true, false) as Node3D
    l_arm = rig_root.find_child("ShoulderL", true, false) as Node3D
    r_arm = rig_root.find_child("ShoulderR", true, false) as Node3D
    l_knee = rig_root.find_child("KneeL", true, false) as Node3D
    r_knee = rig_root.find_child("KneeR", true, false) as Node3D
    l_elbow = rig_root.find_child("ElbowL", true, false) as Node3D
    r_elbow = rig_root.find_child("ElbowR", true, false) as Node3D
    head_joint = rig_root.find_child("Neck_Head", true, false) as Node3D
    for limb in [l_leg, r_leg, l_arm, r_arm, l_knee, r_knee, l_elbow, r_elbow]:
        if limb == null:
            push_error("Rig hierarchy missing a joint after glTF import")
            break

func create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(hud)
    var title := Label.new()
    title.text = "NEON // RONIN"
    title.position = Vector2(30,32)
    title.add_theme_font_size_override("font_size",38)
    title.add_theme_color_override("font_color",CYAN)
    hud.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "SECTOR 07  //  INFINITE TREADMILL"
    subtitle.position = Vector2(32,90)
    subtitle.add_theme_color_override("font_color",Color("#b3cce5"))
    hud.add_child(subtitle)
    label_speed = Label.new()
    label_speed.position = Vector2(32,139)
    label_speed.add_theme_font_size_override("font_size",21)
    label_speed.add_theme_color_override("font_color",PINK)
    hud.add_child(label_speed)
    var sprint_btn := Button.new()
    sprint_btn.text = "SPRINT ⚡"
    sprint_btn.position = Vector2(525,1040)
    sprint_btn.custom_minimum_size = Vector2(155,90)
    sprint_btn.toggle_mode = true
    sprint_btn.toggled.connect(func(v: bool): sprint = v)
    hud.add_child(sprint_btn)
    var instructions := Label.new()
    instructions.text = "DRAG LEFT AREA TO WALK  /  WASD + SHIFT"
    instructions.position = Vector2(26,1190)
    instructions.add_theme_color_override("font_color",Color("#9fa7c9"))
    hud.add_child(instructions)
    hud.draw.connect(_draw_joystick)

func _draw_joystick() -> void:
    var origin := Vector2(126,1080)
    hud.draw_circle(origin,94,Color(0.03,0.35,0.42,.32))
    hud.draw_arc(origin,94,0,TAU,64,CYAN,4)
    hud.draw_circle(origin+knob,33,Color(0.04,0.82,0.83,.66))

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x*0.60 and joystick_id == -1:
            joystick_id = event.index
            joystick_start = event.position
        elif not event.pressed and event.index == joystick_id:
            joystick_id = -1
            move = Vector2.ZERO
            knob = Vector2.ZERO
            hud.queue_redraw()
    elif event is InputEventScreenDrag and event.index == joystick_id:
        knob = (event.position-joystick_start).limit_length(94)
        move = knob/94.0
        hud.queue_redraw()

func _process(dt: float) -> void:
    var keyboard := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
    var v := keyboard if keyboard.length() > .08 else move
    var active := v.length()
    var running := sprint or Input.is_key_pressed(KEY_SHIFT)
    var speed := active * (5.0 if running else 2.5)
    if active > .08:
        facing = v.normalized()
        travel += v * speed * dt
        stride += dt * (10.0 if running else 7.0) * active
        hero.rotation.y = lerp_angle(hero.rotation.y,atan2(facing.x,-facing.y),min(1.0,7*dt))
    else:
        stride += dt * .9
    floor_mat.set_shader_parameter("scroll",travel)
    var swing: float = sin(stride) * minf(active * 2.0, 1.0)
    if l_leg != null and r_leg != null:
        l_leg.rotation.x = swing * .48
        r_leg.rotation.x = -swing * .48
    if l_arm != null and r_arm != null:
        l_arm.rotation.x = -swing * .38
        r_arm.rotation.x = swing * .38
    if l_knee != null and r_knee != null:
        l_knee.rotation.x = maxf(0.0,-swing) * .38
        r_knee.rotation.x = maxf(0.0,swing) * .38
    if l_elbow != null and r_elbow != null:
        l_elbow.rotation.x = -.18 - maxf(0.0,swing) * .19
        r_elbow.rotation.x = -.18 - maxf(0.0,-swing) * .19
    if head_joint != null:
        head_joint.rotation.z = sin(stride*.32) * .015
    hero.position.y = .08 + abs(sin(stride))*.045*active
    label_speed.text = "VELOCITY   %.1f M/S" % speed
