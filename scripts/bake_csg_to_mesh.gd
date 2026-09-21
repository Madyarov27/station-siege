@tool
extends EditorScript
# Converts every plain (Union-operation) CSGBox3D in the currently open scene,
# with no child nodes of its own, into a static MeshInstance3D +
# StaticBody3D/CollisionShape3D pair.
#
# HOW TO RUN:
# 1. Save/commit your current work in git first (safety net).
# 2. Open the scene you want to convert so it's the active tab.
# 3. Open this file in the Script editor.
# 4. File > Run (or the play-button icon top-right of the Script editor).
# 5. Check the Output panel for the summary + any skipped nodes.
# 6. Save the scene (Ctrl+S) ONLY after visually confirming nothing looks wrong.
#
# Recommend trying this on spawnroom.tscn (only 6 CSG boxes) first, since it's
# much lower-risk to check by eye than the full node_3d.tscn map.
#
# Skipped and reported (left untouched) instead of converted:
#   - CSGBox3D with a non-Union operation (Subtraction/Intersection)
#   - CSGBox3D that has child nodes of its own

var _converted_count := 0
var _skipped_count := 0


func _run() -> void:
	var scene_root := get_scene()
	if scene_root == null:
		push_error("No scene is open/focused. Open the target scene first.")
		return

	_converted_count = 0
	_skipped_count = 0
	_convert(scene_root, scene_root)
	print("bake_csg_to_mesh: converted %d, skipped %d. Now save the scene (Ctrl+S) — but check it looks right first." % [_converted_count, _skipped_count])


func _convert(node: Node, scene_root: Node) -> void:
	# Snapshot children first since we'll be adding/removing nodes as we go.
	var children := node.get_children()
	for child in children:
		if child is CSGBox3D:
			var csg := child as CSGBox3D

			if csg.operation != CSGShape3D.OPERATION_UNION:
				_skipped_count += 1
				print("Skipped (non-union operation): ", csg.get_path())
				continue

			if csg.get_child_count() > 0:
				_skipped_count += 1
				print("Skipped (has child nodes, would be deleted): ", csg.get_path())
				continue

			var parent := csg.get_parent()
			var xform := csg.transform
			var box_size := csg.size

			# Visual replacement.
			var mesh_instance := MeshInstance3D.new()
			var box_mesh := BoxMesh.new()
			box_mesh.size = box_size
			mesh_instance.mesh = box_mesh
			mesh_instance.transform = xform
			mesh_instance.name = csg.name + "_Mesh"
			mesh_instance.visible = csg.visible
			mesh_instance.layers = csg.layers
			if csg.material:
				mesh_instance.material_override = csg.material

			parent.add_child(mesh_instance)
			mesh_instance.owner = scene_root

			# Collision replacement (only if the original CSG box had collision on).
			if csg.use_collision:
				var static_body := StaticBody3D.new()
				static_body.transform = xform
				static_body.name = csg.name + "_Body"
				static_body.collision_layer = csg.collision_layer
				static_body.collision_mask = csg.collision_mask
				parent.add_child(static_body)
				static_body.owner = scene_root

				var collision_shape := CollisionShape3D.new()
				var box_shape := BoxShape3D.new()
				box_shape.size = box_size
				collision_shape.shape = box_shape
				static_body.add_child(collision_shape)
				collision_shape.owner = scene_root

			parent.remove_child(csg)
			csg.queue_free()
			_converted_count += 1
		else:
			_convert(child, scene_root)
