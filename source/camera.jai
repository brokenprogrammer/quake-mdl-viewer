Camera :: struct
{
	FLY_SPEED :: 25.0;
	ROTATION_SPEED :: 0.3;
	ROTATION_SMOOTHING :: 0.3;

	position : Vector3;
	euler_angles : Vector3;
	rotation : Quaternion;
	rotation_input : Vector2;
	fov := 60.0;
	transform := Matrix4_Identity;
	view_matrix := Matrix4_Identity;
	projection_matrix := Matrix4_Identity;
	view_projection_matrix := Matrix4_Identity;
}

update_flying_camera :: (using camera : *Camera, delta_time : float)
{
	mouse_delta : Vector2;
	move_input  : Vector3;
	move_speed  : float;

	// Some very @Hack code to make android one finger drag to orbt, two fingers drag to free look.
	// There is an ugly snap when you stop free looking as we instantly teleport to the position we would be
	// in orbit with the free look angle.
	android_grabbing := false;
	orbitting := false;
	#if OS == .ANDROID {
		orbitting = android_num_pointers < 2;

		// Invert the delta and scale it on android so dragging feels how you expect.
		scale_factor := ifx orbitting  0.5 else 0.25;
		mouse_delta_x = xx (cast(float) mouse_delta_x * scale_factor);
		mouse_delta_y = xx (cast(float) mouse_delta_y * scale_factor);

		if orbitting mouse_delta_y *= -1;
		else         mouse_delta_x *= -1;

		android_grabbing = !getrect.is_grabbing();
	}

	if g_control_camera || android_grabbing {
		move_speed = FLY_SPEED;
		mouse_delta = xy (xx mouse_delta_x, xx mouse_delta_y);
		if is_key_down (.SHIFT) then move_speed *= 10;
		move_speed *= delta_time;
		move_input.x = cast (float) is_key_down (xx #char "D")
			- cast (float) is_key_down (xx #char "A");
		move_input.y = cast (float) is_key_down (xx #char "E")
			- cast (float) is_key_down (xx #char "Q");
		move_input.z = cast (float) is_key_down (xx #char "S")
			- cast (float) is_key_down (xx #char "W");
		move_input = rotate (unit_vector (move_input), rotation);
	}
	position += move_input * move_speed;

	rotation_input = lerp (rotation_input, mouse_delta, ROTATION_SMOOTHING);
	delta := rotation_input * ROTATION_SPEED;
	euler_angles.x += delta.x * PI / 180.0;
	euler_angles.y += delta.y * PI / 180.0;
	euler_angles.y = clamp (euler_angles.y, -80.0  * PI / 180.0, 80.0 * PI / 180.0);
	yaw : Quaternion;
	// I am not sure why I need to invert the axis of rotation...
	set_from_axis_and_angle (*yaw, 0, -1, 0, euler_angles.x);
	pitch : Quaternion;
	set_from_axis_and_angle (*pitch, -1, 0, 0, euler_angles.y);
	rotation = yaw * pitch;

	// @Hack orbit camera movment.
	if orbitting {
		ORBIT_DISTANCE :: 2.5;
		FOCUS :: Vector3.{0, 1, 0};
		offset := rotate (.{0, 0, ORBIT_DISTANCE}, rotation); // -z is forward!
		position = FOCUS + offset;
	}

	transform = make_translation_matrix4 (position) * rotation_matrix (Matrix4, rotation);
	view_matrix = inverse (transform);
	vx, vy, vw, vh := get_dimensions (g_window, false);
	aspect_ratio := vw / cast (float) vh;
	projection_matrix = make_projection_matrix (fov * PI / 180.0, aspect_ratio, 0.1, 1000.0);
	view_projection_matrix = projection_matrix * view_matrix;
}
