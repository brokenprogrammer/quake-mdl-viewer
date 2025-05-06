//light_pos: Vector3_GLfloat = Vector3_GLfloat.{0.0, 0.0, 0.0};
light_transform: *TG_RigidTransform_t;

g_gizmo_shader: GLuint;
g_gizmo_vao, g_gizmo_vbo  : GLuint;
#scope_file

g_shader: GLuint;
g_line_shader: GLuint;
g_cube_shader: GLuint;
g_viz_normal_shader: GLuint;
g_skybox_shader: GLuint;

g_VAO: GLuint;
g_VBO_CurrentFramePos: GLuint;
g_VBO_NextFramePos: GLuint;
g_VBO_CurrentFrameNormals: GLuint;
g_VBO_NextFrameNormals: GLuint;
g_VBO_Texcoords: GLuint;
// g_EBO: GLuint;

g_texture: GLuint;
g_skybox_texture: GLuint;

g_line_vao, g_line_vbo    : GLuint;
g_cube_vao, g_cube_vbo    : GLuint;
g_skybox_vao, g_skybox_vbo: GLuint;

cube_vertices: []float = float.[
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
     0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
     0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
     0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
];

skybox_vertices: []float = float.[
    // positions          
    -1.0,  1.0, -1.0,
    -1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
     1.0,  1.0, -1.0,
    -1.0,  1.0, -1.0,

    -1.0, -1.0,  1.0,
    -1.0, -1.0, -1.0,
    -1.0,  1.0, -1.0,
    -1.0,  1.0, -1.0,
    -1.0,  1.0,  1.0,
    -1.0, -1.0,  1.0,

     1.0, -1.0, -1.0,
     1.0, -1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0, -1.0,
     1.0, -1.0, -1.0,

    -1.0, -1.0,  1.0,
    -1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
     1.0, -1.0,  1.0,
    -1.0, -1.0,  1.0,

    -1.0,  1.0, -1.0,
     1.0,  1.0, -1.0,
     1.0,  1.0,  1.0,
     1.0,  1.0,  1.0,
    -1.0,  1.0,  1.0,
    -1.0,  1.0, -1.0,

    -1.0, -1.0, -1.0,
    -1.0, -1.0,  1.0,
     1.0, -1.0, -1.0,
     1.0, -1.0, -1.0,
    -1.0, -1.0,  1.0,
     1.0, -1.0,  1.0
];

// Used for line rendering
Vertex_Pos_Color :: struct
{
	position : Vector3;
	color : Vector4;
}

create_shader_program :: (vertex_source: string, fragment_source: string, geometry_source := "") -> GLuint, bool {
    check_compile_errors :: (shader: GLuint) -> bool, info_log: string {
        success: s32;
        glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
        if !success {
            info_len: s32;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast(*u8) alloc(info_len,, temp);
            glGetShaderInfoLog(shader, xx info_len, xx *info_len, info_data);

            result: string;
            result.data = info_data;
            result.count = info_len;

            return false, result;
        }

        return true, "";
    }

    check_link_errors :: (program: GLuint) -> bool, info_log: string {
        success : s32;
		glGetProgramiv (program, GL_LINK_STATUS, *success);
		if !success {
			info_len : s32;
			glGetProgramiv (program, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast (*u8) alloc (info_len,, temp);
			glGetProgramInfoLog (program, xx info_len, xx *info_len, info_data);
			
            result : string;
			result.data = info_data;
			result.count = info_len;

			return false, result;
		}

		return true, "";
    }

    has_geometry_shader := geometry_source.count > 0;

    vs := glCreateShader(GL_VERTEX_SHADER);
    defer glDeleteShader(vs);

    shaders := *u8.[   SHADER_PREFIX.data, vertex_source.data ];
    lengths := s32.[xx SHADER_PREFIX.count, cast(s32)vertex_source.count ];
    glShaderSource(vs, 2, shaders.data, lengths.data);
    glCompileShader(vs);

    ok, info_log := check_compile_errors(vs);
    if !ok {
        log_error("Could not compile vertex shader %", info_log);
        return 0, false;
    }

    fs := glCreateShader(GL_FRAGMENT_SHADER);
    defer glDeleteShader(fs);

    shaders[1] =    fragment_source.data;
    lengths[1] = xx fragment_source.count;
    glShaderSource(fs, 2, shaders.data, lengths.data);
    glCompileShader(fs);

    ok, info_log = check_compile_errors(fs);
    if !ok {
        log_error("Could not compile fragment shader %", info_log);
        return 0, false;
    }

    gs := glCreateShader(GL_GEOMETRY_SHADER);
    defer glDeleteShader(gs);

    if (has_geometry_shader) {
        shaders[1] =    geometry_source.data;
        lengths[1] = xx geometry_source.count;
        glShaderSource(gs, 2, shaders.data, lengths.data);
        glCompileShader(gs);

        ok, info_log = check_compile_errors(fs);
        if !ok {
            log_error("Could not compile geometry shader %", info_log);
            return 0, false;
        }
    }

    result := glCreateProgram();
    glAttachShader(result, vs);
    glAttachShader(result, fs);
    if (has_geometry_shader) {
        glAttachShader(result, gs);
    }
    glLinkProgram(result);

    ok, info_log = check_link_errors(result);
	if !ok {
		log_error ("Could not link shader program: %", info_log);
		glDeleteProgram(result);
		return 0, false;
	}

    return result, true;
}

create_skybox :: (image_faces: []string) -> GLuint {
    skybox_texture: GLuint;

    glGenTextures(1, *skybox_texture);
    glBindTexture(GL_TEXTURE_CUBE_MAP, skybox_texture);

    stbi_set_flip_vertically_on_load(xx false);

    w, h, channels: s32;
    for image_faces {
        data := stbi_load(temp_c_string(it), *w, *h, *channels, 0);
        defer stbi_image_free(data);

        if !data {
            log("Failed to load skybox texture '%'.", it, flags=.ERROR);
            return 0;
        }

        format: GLenum;
        if (channels == 1) {
            format = GL_RED;
        } else if (channels == 3) {
            format = GL_RGB;
        } else if (channels == 4) {
            format = GL_RGBA;
        }

        texture_target: u32 = GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(u32) it_index; 
        glTexImage2D(texture_target, 0, xx format, xx w, xx h, 0, xx format, GL_UNSIGNED_BYTE, data);
    }

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

    return skybox_texture;
}

#scope_export

draw_line :: inline (start : Vector3, end : Vector3, color : Vector4)
{
	draw_line (start, end, color, color);
}

// This is maybe the slowest way possible to draw a line!
draw_line :: (start : Vector3, end : Vector3, start_color : Vector4, end_color : Vector4)
{
	data : [2]Vertex_Pos_Color = ---;
	data[0].position = start;
	data[0].color    = start_color;
	data[1].position = end;
	data[1].color    = end_color;

	glBindVertexArray (g_line_vao);
	glBindBuffer (GL_ARRAY_BUFFER, g_line_vbo);
	// Fill the vertex buffer with our two line vertices
	glBufferSubData (GL_ARRAY_BUFFER, 0, size_of (Vertex_Pos_Color) * 2, data.data);
	glUseProgram (g_line_shader);
	glUniformMatrix4fv (glGetUniformLocation (g_line_shader, "u_View_Projection_Matrix"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
	glDrawArrays (GL_LINES, 0, 2);
}

qxdir :: (q: Vector4) -> Vector3 {
    return .{ q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z, (q.x*q.y + q.z*q.w) * 2, (q.z*q.x - q.y*q.w) * 2 };
}
qydir :: (q: Vector4) -> Vector3 {
    return .{ (q.x*q.y - q.z*q.w) * 2, q.w*q.w - q.x*q.x + q.y*q.y - q.z*q.z, (q.y*q.z + q.x*q.w) * 2 };
}
qzdir :: (q: Vector4) -> Vector3 {
    return .{ (q.z*q.x + q.y*q.w) * 2, (q.y*q.z - q.x*q.w) * 2, q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z };
}

get_transform_matrix :: (transform: *TG_RigidTransform_t, static_transform: Matrix4) -> Matrix4 {
    position: TG_Float3;
    orientation: TG_Float4;
    scale: TG_Float3;

    TG_GetRigidTransformPosition(transform, *position);
    TG_GetRigidTransformOrientation(transform, *orientation);
    TG_GetRigidTransformScale(transform, *scale);

    position_vector := Vector3.{position.x, position.y, position.z};
    orientation_vector := Vector4.{orientation.x, orientation.y, orientation.z, orientation.w};
    scale_vector := Vector3.{scale.x, scale.y, scale.z};

    // TODO(Oskar): Continue here
    x_axis := qxdir(orientation_vector) * scale_vector.x;
    y_axis := qydir(orientation_vector) * scale_vector.y;
    z_axis := qzdir(orientation_vector) * scale_vector.z;

    matrix: Matrix4;
    matrix.v[0] = .{x_axis.x, y_axis.x, z_axis.x, position_vector.x};
    matrix.v[1] = .{x_axis.y, y_axis.y, z_axis.y, position_vector.y};
    matrix.v[2] = .{x_axis.z, y_axis.z, z_axis.z, position_vector.z};
    matrix.v[3] = .{0, 0, 0, 1};

    return matrix * static_transform;
}

draw_cube :: (transform: *TG_RigidTransform_t) {
    glBindVertexArray(g_cube_vao);
    glUseProgram(g_cube_shader);

    model_matrix := get_transform_matrix(transform, Matrix4_Identity);

    glUniformMatrix4fv (glGetUniformLocation (g_cube_shader, "u_View_Projection_Matrix"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
	glUniformMatrix4fv (glGetUniformLocation (g_cube_shader, "u_Model_Matrix"), 1, GL_TRUE, *model_matrix.coef[0][0]);
    glDrawArrays(GL_TRIANGLES, 0, 36);
}


init_buffers :: (mdl_model: Model) {
    ok: bool;

    g_shader, ok = create_shader_program (MDL_VERTEX_SHADER, MDL_FRAGMENT_SHADER);
	if !ok
		return;

    g_line_shader, ok = create_shader_program (LINE_VERTEX_SHADER, LINE_FRAGMENT_SHADER);
	if !ok
		return;

    g_cube_shader, ok = create_shader_program (CUBE_VERTEX_SHADER, CUBE_FRAGMENT_SHADER);
	if !ok
		return;

    g_viz_normal_shader, ok = create_shader_program (VIZ_NORMALS_VERTEX_SHADER, VIZ_NORMALS_FRAGMENT_SHADER, VIZ_NORMALS_GEOMETRY_SHADER);
    if !ok
		return;

    g_skybox_shader, ok = create_shader_program(SKYBOX_VERTEX_SHADER, SKYBOX_FRAGMENT_SHADER);
    if !ok
        return;

    g_gizmo_shader, ok = create_shader_program(GIZMO_VERTEX_SHADER, GIZMO_FRAGMENT_SHADER);
    if !ok
        return;

    glGenVertexArrays(1, *g_VAO);
    glGenBuffers(1, *g_VBO_CurrentFramePos);
    glGenBuffers(1, *g_VBO_NextFramePos);
    glGenBuffers(1, *g_VBO_CurrentFrameNormals);
    glGenBuffers(1, *g_VBO_NextFrameNormals);
    glGenBuffers(1, *g_VBO_Texcoords);
    // glGenBuffers(1, *g_EBO);

    glBindVertexArray(g_VAO);

    // Positions VBO (will update per frame)
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(0);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(1);

    // Normals VBO (will update per frame)
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(2);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(3);

    // Texture Coordinates VBO (static)
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector2_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(4, 2, GL_FLOAT, GL_FALSE, 2 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(4);


    // Elements (Triangles) VBO (static)
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(Vector3_GLuint) * mdl_model.indices.count, mdl_model.indices.data, GL_STATIC_DRAW);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Line
    glGenVertexArrays (1, *g_line_vao);
	glBindVertexArray (g_line_vao);
	glGenBuffers (1, *g_line_vbo);
	glBindBuffer (GL_ARRAY_BUFFER, g_line_vbo);
	glBufferData (GL_ARRAY_BUFFER, size_of (Vertex_Pos_Color) * 2, null, GL_DYNAMIC_DRAW);
	glEnableVertexAttribArray (0);
	glVertexAttribPointer (0, 3, GL_FLOAT, GL_FALSE, size_of (Vertex_Pos_Color), cast (*void) 0);
	glEnableVertexAttribArray (1);
	glVertexAttribPointer (1, 4, GL_FLOAT, GL_FALSE, size_of (Vertex_Pos_Color), cast (*void) size_of (Vector3));

	glBindVertexArray (0);
	glBindBuffer (GL_ARRAY_BUFFER, 0);

    // Cube
    glGenVertexArrays(1, *g_cube_vao);
    glBindVertexArray(g_cube_vao);
    glGenBuffers(1, *g_cube_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, g_cube_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(float)*cube_vertices.count, cube_vertices.data, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * size_of(float), cast(*void)0);
    glEnableVertexAttribArray(0);

    glBindVertexArray (0);
	glBindBuffer (GL_ARRAY_BUFFER, 0);

    // Texture
    glGenTextures(1, *g_texture);
    glBindTexture(GL_TEXTURE_2D, g_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);

    // Skybox
    skybox_faces : []string = .[
        "data/textures/skybox/right.png", 
        "data/textures/skybox/left.png", 
        "data/textures/skybox/top.png",
        "data/textures/skybox/bottom.png",
        "data/textures/skybox/front.png",
        "data/textures/skybox/back.png"];
    g_skybox_texture = create_skybox(skybox_faces);

    glGenVertexArrays(1, *g_skybox_vao);
    glBindVertexArray(g_skybox_vao);
    glGenBuffers(1, *g_skybox_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, g_skybox_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(float)*skybox_vertices.count, skybox_vertices.data, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), cast(*void)0);
    glEnableVertexAttribArray(0);

    glBindVertexArray (0);
	glBindBuffer (GL_ARRAY_BUFFER, 0);

    // Gizmo
    glGenVertexArrays (1, *g_gizmo_vao);
	glBindVertexArray (g_gizmo_vao);
    glGenBuffers (1, *g_gizmo_vbo);
	glBindBuffer (GL_ARRAY_BUFFER, g_gizmo_vbo);
    glBufferData (GL_ARRAY_BUFFER, 0, null, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray (0);
	glVertexAttribPointer (0, 3, GL_FLOAT, GL_FALSE, size_of (TG_GeometryVertex), cast (*void) 0);
	glEnableVertexAttribArray (1);
	glVertexAttribPointer (1, 3, GL_FLOAT, GL_FALSE, size_of (TG_GeometryVertex), cast (*void) size_of (TG_Float3));
    glEnableVertexAttribArray (2);
	glVertexAttribPointer (2, 4, GL_FLOAT, GL_FALSE, size_of (TG_GeometryVertex), cast (*void) (size_of (TG_Float3) * 2));

    light_transform = TG_CreateRigidTransform();
    position := TG_Float3.{5.0, 5.0, 0.0};
    TG_SetRigidTransformPosition(light_transform, *position);

    scale := TG_Float3.{0.2, 0.2, 0.2};
    TG_SetRigidTransformScale(light_transform, *scale);
}

update_buffers :: (mdl_model: Model) {
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector2_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(Vector3_GLuint) * mdl_model.indices.count, mdl_model.indices.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindTexture(GL_TEXTURE_2D, g_texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, mdl_model.skins[0].skin_width, mdl_model.skins[0].skin_height, 0, GL_RGB, GL_UNSIGNED_BYTE, mdl_model.skins[0].skin_data.data);
}

render :: (mdl_model: Model, frame: int, frame_next: int, anim_lerp: float, aspect: float, anim_index: int, skin_index: int, shading_mode: s32, show_normals: bool, show_skybox: bool, show_gizmos: bool) {
    // glEnable(GL_CULL_FACE);
    // glCullFace(GL_FRONT);
    // glEnable(GL_MULTISAMPLE);
    // glFrontFace(GL_CCW);

    if mdl_model.animations.count > 0 {
        glUseProgram(g_shader);
        
        glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFramePos);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame].vertices.data);

        glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFramePos);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame_next].vertices.data);

        glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFrameNormals);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame].normals.data);

        glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFrameNormals);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame_next].normals.data);

        glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
        glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector2_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame].texcoords.data);

        glBindTexture(GL_TEXTURE_2D, g_texture);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, mdl_model.skins[skin_index].skin_width, mdl_model.skins[skin_index].skin_height, 0, GL_RGB, GL_UNSIGNED_BYTE, mdl_model.skins[skin_index].skin_data.data);

        model_matrix := get_transform_matrix(mdl_model.transform, mdl_model.static_transform);

        glUniformMatrix4fv(glGetUniformLocation(g_shader, "view_projection"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(g_shader, "model"), 1, GL_TRUE, *model_matrix.coef[0][0]);
        glUniform1f(glGetUniformLocation(g_shader, "interpolation"), anim_lerp);
        glUniform1i(glGetUniformLocation(g_shader, "shading_mode"), shading_mode);

        // TODO(Oskar): What if we dont have specular map?
        glUniform1i(glGetUniformLocation(g_shader, "material.diffuse"), 0);
        glUniform1i(glGetUniformLocation(g_shader, "material.specular"), 0);
        glUniform1f(glGetUniformLocation(g_shader, "material.shininess"), 32.0);

        // Directional Light
        {
            direction := float32.[-0.2, -1.0, -0.3];
            ambient := float32.[0.05, 0.05, 0.05];
            diffuse := float32.[0.4, 0.4, 0.4];
            specular := float32.[0.5, 0.5, 0.5];
            glUniform3fv(glGetUniformLocation(g_shader, "dirLight.direction"), 1, direction.data);
            glUniform3fv(glGetUniformLocation(g_shader, "dirLight.ambient"), 1, ambient.data);
            glUniform3fv(glGetUniformLocation(g_shader, "dirLight.diffuse"), 1, diffuse.data);
            glUniform3fv(glGetUniformLocation(g_shader, "dirLight.specular"), 1, specular.data);
        }

        // Point light 1
        {
            position: TG_Float3;
            TG_GetRigidTransformPosition(light_transform, *position);
            light_position := float32.[position.x, position.y, position.z];
            
            ambient := float32.[0.05, 0.05, 0.05];
            diffuse := float32.[0.8, 0.8, 0.8];
            specular := float32.[1.0, 1.0, 1.0];
            glUniform3fv(glGetUniformLocation(g_shader, "pointLights[0].position"), 1, light_position.data);
            glUniform3fv(glGetUniformLocation(g_shader, "pointLights[0].ambient"), 1, ambient.data);
            glUniform3fv(glGetUniformLocation(g_shader, "pointLights[0].diffuse"), 1, diffuse.data);
            glUniform3fv(glGetUniformLocation(g_shader, "pointLights[0].specular"), 1, specular.data);
            
            glUniform1f(glGetUniformLocation(g_shader, "pointLights[0].constant"), 1.0);
            glUniform1f(glGetUniformLocation(g_shader, "pointLights[0].linear"), 0.09);
            glUniform1f(glGetUniformLocation(g_shader, "pointLights[0].quadratic"), 0.032);
            

            // TODO(Oskar): Remove unused uniforms from shader..
            // glUniform3fv(glGetUniformLocation(g_shader, "lightPos"), 1, light_position.data);
            // glUniform3fv(glGetUniformLocation(g_shader, "lightColor"), 1, lightColor.data);
        }


        camera_position := float32.[g_camera.position.x, g_camera.position.y, g_camera.position.z];
        glUniform3fv(glGetUniformLocation(g_shader, "viewPos"), 1, camera_position.data);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, g_texture);
        glUniform1i(glGetUniformLocation(g_shader, "texture1"), 0);

        glBindVertexArray(g_VAO);
        glDrawArrays(GL_TRIANGLES, 0, mdl_model.vertex_count);
        // glDrawElements(GL_TRIANGLES, xx (mdl_model.indices.count * 3), GL_UNSIGNED_INT, null);

        if show_normals {
            glUseProgram(g_viz_normal_shader);
            glUniformMatrix4fv(glGetUniformLocation(g_viz_normal_shader, "view"), 1, GL_TRUE, *g_camera.view_matrix.coef[0][0]);
            glUniformMatrix4fv(glGetUniformLocation(g_viz_normal_shader, "projection"), 1, GL_TRUE, *g_camera.projection_matrix.coef[0][0]);
            glUniformMatrix4fv(glGetUniformLocation(g_viz_normal_shader, "model"), 1, GL_TRUE, *model_matrix.coef[0][0]);
            glUniform1f(glGetUniformLocation(g_viz_normal_shader, "interpolation"), anim_lerp);
            glDrawArrays(GL_TRIANGLES, 0, mdl_model.vertex_count);
            // glDrawElements(GL_TRIANGLES, xx (mdl_model.indices.count * 3), GL_UNSIGNED_INT, null);
        }

        glBindVertexArray(0);
    }

    draw_cube(light_transform);

    if show_gizmos {
        gizmo_render(mdl_model);
    }

    // Render skybox
    if show_skybox {
        view_matrix := make_matrix4(make_matrix3(g_camera.view_matrix));
        glDepthFunc(GL_LEQUAL);
        glUseProgram(g_skybox_shader);
        glUniformMatrix4fv(glGetUniformLocation(g_skybox_shader, "u_View_Matrix"), 1, GL_TRUE, *view_matrix.coef[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(g_skybox_shader, "u_Projection_Matrix"), 1, GL_TRUE, *g_camera.projection_matrix.coef[0][0]);

        glBindVertexArray(g_skybox_vao);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, g_skybox_texture);
        glDrawArrays(GL_TRIANGLES, 0, 36);

        glBindVertexArray(0);
        glDepthFunc(GL_LESS);
    }
}

SHADER_PREFIX :: #string END
#version 330 core
END

MDL_VERTEX_SHADER :: #string GLSL
layout (location = 0) in vec3 aCurrentFramePos;
layout (location = 1) in vec3 aNextFramePos;
layout (location = 2) in vec3 aCurrentFrameNormal;
layout (location = 3) in vec3 aNextFrameNormal;
layout (location = 4) in vec2 aTexCoord;

uniform mat4 model;
uniform mat4 view_projection;
uniform float interpolation;

out vec2 TexCoords;
out vec3 Normal;
out vec3 FragPos;

void main() {
    vec3 aPos = (aCurrentFramePos * (1.0 - interpolation)) + (aNextFramePos * interpolation);
    vec3 aNormal = (aCurrentFrameNormal * (1.0 - interpolation)) + (aNextFrameNormal * interpolation);

    TexCoords = aTexCoord;
    Normal = mat3(transpose(inverse(model))) * aNormal;
    FragPos = vec3(model * vec4(aPos, 1.0));
    gl_Position = view_projection * vec4(FragPos, 1.0);
}
GLSL

MDL_FRAGMENT_SHADER :: #string GLSL
#define SHADING_SOLID 0
#define SHADING_TEXTURE 1
#define SHADING_NORMAL 2

in vec2 TexCoords;
in vec3 Normal;
in vec3 FragPos;

out vec4 FragColor;

uniform sampler2D texture1;

uniform vec3 lightPos; 
uniform vec3 viewPos; 
uniform vec3 lightColor;

uniform int shading_mode;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};
uniform Material material;

struct DirLight {
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
uniform DirLight dirLight;

struct PointLight {    
    vec3 position;
    
    float constant;
    float linear;
    float quadratic;  

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};  
#define NR_POINT_LIGHTS 1
uniform PointLight pointLights[NR_POINT_LIGHTS];

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);

    // Diffuse Shading
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular shading
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    // Combine results
    vec3 ambient  = light.ambient  * vec3(texture(material.diffuse, TexCoords));
    vec3 diffuse  = light.diffuse  * diff * vec3(texture(material.diffuse, TexCoords));
    vec3 specular = light.specular * spec * vec3(texture(material.specular, TexCoords));
    return (ambient + diffuse + specular);
}

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 lightDir = normalize(light.position - fragPos);

    // Diffuse shading
    float diff = max(dot(normal, lightDir), 0.0);
    
    // Specular shading
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    
    // Attenuation
    float distance    = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
  			     light.quadratic * (distance * distance));    
    
    // Combine results
    vec3 ambient  = light.ambient  * vec3(texture(material.diffuse, TexCoords));
    vec3 diffuse  = light.diffuse  * diff * vec3(texture(material.diffuse, TexCoords));
    vec3 specular = light.specular * spec * vec3(texture(material.specular, TexCoords));
    ambient  *= attenuation;
    diffuse  *= attenuation;
    specular *= attenuation;
    return (ambient + diffuse + specular);
} 

void main() {
    vec4 objectColor = vec4(1.0);//texture(texture1, TexCoords);

    if (shading_mode == SHADING_TEXTURE) {
        objectColor = texture(texture1, TexCoords);
    } else if (shading_mode == SHADING_SOLID) {
        objectColor = vec4(0.5, 0.5, 0.5, 1.0);
    } else if (shading_mode == SHADING_NORMAL) {
        objectColor = vec4(Normal.xyz * 0.5 + 0.5, 1.0);
    } else {
        objectColor = texture(texture1, TexCoords);
    }

    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(viewPos - FragPos);

    vec3 result = CalcDirLight(dirLight, norm, viewDir);
    for (int i = 0; i < NR_POINT_LIGHTS; ++i) {
        result += CalcPointLight(pointLights[i], norm, FragPos, viewDir);
    }

    FragColor = vec4(result, 1.0);

    // // ambient
    // float ambientStrength = 0.1;
    // vec3 ambient = ambientStrength * lightColor;

    // // diffuse 
    // vec3 norm = normalize(Normal);
    // vec3 lightDir = normalize(lightPos - FragPos);
    // float diff = max(dot(norm, lightDir), 0.0);
    // vec3 diffuse = diff * lightColor;

    // vec4 result = vec4(ambient + diffuse, 1.0) * objectColor;
    // FragColor = result;
}
GLSL

LINE_VERTEX_SHADER :: #string GLSL

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec4 a_Color;

uniform mat4 u_View_Projection_Matrix;

out vec4 Color;

void main ()
{
	gl_Position = u_View_Projection_Matrix * vec4 (a_Position, 1);
	Color = a_Color;
}
GLSL

LINE_FRAGMENT_SHADER :: #string GLSL

in vec4 Color;

out vec4 Frag_Color;

void main ()
{
	Frag_Color = Color;
}
GLSL

CUBE_VERTEX_SHADER :: #string GLSL

layout (location = 0) in vec3 aPos;

uniform mat4 u_View_Projection_Matrix;
uniform mat4 u_Model_Matrix;

void main()
{
    gl_Position = u_View_Projection_Matrix * u_Model_Matrix * vec4(aPos, 1);
}

GLSL

CUBE_FRAGMENT_SHADER :: #string GLSL

out vec4 Frag_Color;

void main()
{
    Frag_Color = vec4(1.0);
}

GLSL

VIZ_NORMALS_VERTEX_SHADER :: #string GLSL

layout (location = 0) in vec3 aCurrentFramePos;
layout (location = 1) in vec3 aNextFramePos;
layout (location = 2) in vec3 aCurrentFrameNormal;
layout (location = 3) in vec3 aNextFrameNormal;

out VS_OUT {
    vec3 normal;
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform float interpolation;

void main()
{
    vec3 aPos = (aCurrentFramePos * (1.0 - interpolation)) + (aNextFramePos * interpolation);
    vec3 aNormal = (aCurrentFrameNormal * (1.0 - interpolation)) + (aNextFrameNormal * interpolation);

    gl_Position = view * model * vec4(aPos, 1.0);
    mat3 normalMatrix = mat3(transpose(inverse(view * model)));
    vs_out.normal = normalize(vec3(vec4(normalMatrix * aNormal, 0.0)));
}

GLSL

VIZ_NORMALS_FRAGMENT_SHADER :: #string GLSL

out vec4 Frag_Color;

void main()
{
    Frag_Color = vec4(1.0, 1.0, 0.0, 1.0);
}

GLSL

VIZ_NORMALS_GEOMETRY_SHADER :: #string GLSL

layout(triangles) in;
layout(line_strip, max_vertices = 6) out;

in VS_OUT {
    vec3 normal;
} gs_in[];

const float MAGNITUDE = 0.4;

uniform mat4 projection;

void GenerateLine(int index)
{
    gl_Position = projection * gl_in[index].gl_Position;
    EmitVertex();
    gl_Position = projection * (gl_in[index].gl_Position + 
                                vec4(gs_in[index].normal, 0.0) * MAGNITUDE);
    EmitVertex();
    EndPrimitive();
}

void main()
{
    GenerateLine(0); // first vertex normal
    GenerateLine(1); // second vertex normal
    GenerateLine(2); // third vertex normal
}

GLSL

SKYBOX_VERTEX_SHADER :: #string GLSL

layout (location = 0) in vec3 aPos;

out vec3 TexCoords;

uniform mat4 u_Projection_Matrix;
uniform mat4 u_View_Matrix;

void main()
{
    TexCoords = aPos;
    vec4 pos = u_Projection_Matrix * u_View_Matrix * vec4(aPos, 1);
    gl_Position = pos.xyww;
}

GLSL

SKYBOX_FRAGMENT_SHADER :: #string GLSL

out vec4 Frag_Color;

in vec3 TexCoords;

uniform samplerCube skybox;

void main()
{
    Frag_Color = texture(skybox, TexCoords);
}

GLSL

GIZMO_VERTEX_SHADER :: #string GLSL

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec4 aColor;

out vec4 Color;
out vec3 World;
out vec3 Normal;

uniform mat4 u_View_Projection_Matrix;
uniform mat4 u_Model_Matrix;

void main()
{
    gl_Position = u_View_Projection_Matrix * u_Model_Matrix * vec4(aPos, 1);
    Color = aColor;
    World = aPos;
    Normal = aNormal;
}

GLSL

GIZMO_FRAGMENT_SHADER :: #string GLSL

in vec4 Color;
in vec3 World;
in vec3 Normal;

uniform vec3 u_eye;

out vec4 Frag_Color;

void main()
{
    vec3 light = vec3(1) * max(dot(Normal, normalize(u_eye - World)), 0.50) + 0.25;
    Frag_Color = Color * vec4(light, 1.0);
}

GLSL