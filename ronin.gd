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
    cam.position = Vector3(5.0,5.7,8.8)
    cam.fov = 42.0
    add_child(cam)
    cam.look_at(Vector3(0,1.3,0))
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

func create_hero() -> void:
    hero = Node3D.new()
    hero.name = "CustomCyberSamurai"
    add_child(hero)
    block(hero,"Torso",Vector3(0,1.73,0),Vector3(.85,1,.45),ARMOR)
    block(hero,"Breastplate",Vector3(0,1.83,-.25),Vector3(.80,.73,.12),STEEL)
    block(hero,"Reactor",Vector3(0,1.83,-.33),Vector3(.09,.54,.04),CYAN,true)
    block(hero,"Belt",Vector3(0,1.2,0),Vector3(.84,.15,.54),BLACK)
    block(hero,"Neck",Vector3(0,2.39,0),Vector3(.25,.22,.21),Color("#b77e68"))
    var head := MeshInstance3D.new()
    var headmesh := CapsuleMesh.new()
    headmesh.radius = .245
    headmesh.height = .48
    head.mesh = headmesh
    head.position = Vector3(0,2.7,-.02)
    head.material_override = material(Color("#ad7864"))
    hero.add_child(head)
    block(hero,"Hair",Vector3(0,2.95,-.02),Vector3(.45,.10,.49),BLACK)
    block(hero,"Visor",Vector3(0,2.70,-.265),Vector3(.45,.10,.05),BLACK)
    block(hero,"Eyes",Vector3(0,2.69,-.294),Vector3(.40,.025,.025),CYAN,true)
    # Optional user portrait: add assets/face.png locally.
    if ResourceLoader.exists("res://assets/face.png"):
        var face := Sprite3D.new()
        face.texture = load("res://assets/face.png")
        face.pixel_size = .00165
        face.position = Vector3(0,2.68,-.27)
        face.shaded = false
        hero.add_child(face)
    l_arm = Node3D.new(); l_arm.position = Vector3(-.58,2.09,0); hero.add_child(l_arm)
    r_arm = Node3D.new(); r_arm.position = Vector3(.58,2.09,0); hero.add_child(r_arm)
    for arm in [l_arm,r_arm]:
        block(arm,"Upper",Vector3(0,-.34,0),Vector3(.26,.68,.29),ARMOR)
        block(arm,"Forearm",Vector3(0,-.76,-.06),Vector3(.29,.43,.31),STEEL)
        block(arm,"Neon",Vector3(0,-.76,-.23),Vector3(.06,.26,.03),CYAN,true)
    l_leg = Node3D.new(); l_leg.position = Vector3(-.23,1.15,0); hero.add_child(l_leg)
    r_leg = Node3D.new(); r_leg.position = Vector3(.23,1.15,0); hero.add_child(r_leg)
    for leg in [l_leg,r_leg]:
        block(leg,"Thigh",Vector3(0,-.28,0),Vector3(.34,.65,.42),ARMOR)
        block(leg,"Shin",Vector3(0,-.75,-.02),Vector3(.30,.47,.37),STEEL)
        block(leg,"Boot",Vector3(0,-1.03,-.12),Vector3(.34,.20,.52),BLACK)
        block(leg,"LED",Vector3(0,-.75,-.22),Vector3(.10,.25,.03),PINK,true)
    for s in [-1.0,1.0]:
        block(hero,"Shoulder",Vector3(s*.51,2.10,0),Vector3(.40,.23,.60),STEEL)
        block(hero,"ShoulderLight",Vector3(s*.51,2.21,-.30),Vector3(.34,.025,.025),CYAN,true)
    var katana := Node3D.new()
    katana.position = Vector3(.56,1.27,0)
    katana.rotation_degrees.z = 22
    hero.add_child(katana)
    block(katana,"Scabbard",Vector3(0,-.48,0),Vector3(.09,1.0,.09),BLACK)
    block(katana,"NeonBlade",Vector3(0,-.48,-.053),Vector3(.018,.96,.03),PINK,true)
    block(katana,"Guard",Vector3(0,.06,0),Vector3(.23,.045,.20),STEEL)
    block(katana,"Grip",Vector3(0,.25,0),Vector3(.08,.31,.09),BLACK)

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
    var swing := sin(stride) * min(active*2.0,1.0)
    l_leg.rotation.x = swing*.60
    r_leg.rotation.x = -swing*.60
    l_arm.rotation.x = -swing*.48
    r_arm.rotation.x = swing*.48
    hero.position.y = .08 + abs(sin(stride))*.045*active
    label_speed.text = "VELOCITY   %.1f M/S" % speed
