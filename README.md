# NEON RONIN V2 — Real 3D cyber samurai for Android

Godot 4.7.2 Android API 36; original cyber-futuristic samurai prototype.
**Unlike V1, this uses an actual textured triangulated 3D GLB mesh**, not box primitives or a flat portrait Sprite3D.
Anatomical body geometry, real 3D face geometry with UV-projected photo texture, individual armor plates,
curved head, ears, hair, articulated hips/knees/shoulders/elbows, katana and metallic/emissive PBR materials.

**Build:** The GitHub workflow installs Python, creates assets/ronin_v2.glb with `tools/build_avatar.py`, imports it into Godot, and exports debug APK for ARM64 / Android API 36.
The generated GLB is a build artifact, not checked in, to preserve a reproducible Blender-independent source mesh.

**Control:** drag the left area for directional treadmill movement, press Sprint for faster motion.
Camera starts on the face side.

**PHOTO PRIVACY NOTICE:** This public repository contains `assets/face_albedo.jpg`, a photograph-derived portrait texture provided by the owner to represent their appearance. The texture is built into the generated 3D model and Android APK. Remove or replace the texture before redistributing the project without permission.

**Higgsfield:** It was considered as an optional production-time asset workflow, but the connected free-plan image model rejected the job; this implementation uses open-source procedural geometry and no paid credits.

This is a preliminary *stylized* high-geometry 3D character and a playable demo, not AAA photorealism or a professional motion-captured full-skeletal game.
