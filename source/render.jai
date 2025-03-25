g_shader: GLuint;
g_line_shader: GLuint;
g_cube_shader: GLuint;

g_VAO: GLuint;
g_VBO_CurrentFramePos: GLuint;
g_VBO_NextFramePos: GLuint;
g_VBO_CurrentFrameNormals: GLuint;
g_VBO_NextFrameNormals: GLuint;
g_VBO_Texcoords: GLuint;
g_EBO: GLuint;

g_texture: GLuint;

g_line_vao, g_line_vbo: GLuint;
g_cube_vao, g_cube_vbo: GLuint;

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

// Used for line rendering
Vertex_Pos_Color :: struct
{
	position : Vector3;
	color : Vector4;
}

#scope_file 

create_shader_program :: (vertex_source: string, fragment_source: string) -> GLuint, bool {
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

    result := glCreateProgram();
    glAttachShader(result, vs);
    glAttachShader(result, fs);
    glLinkProgram(result);

    ok, info_log = check_link_errors(result);
	if !ok {
		log_error ("Could not link shader program: %", info_log);
		glDeleteProgram(result);
		return 0, false;
	}

    return result, true;
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

draw_cube :: (position: Vector3) {
    glBindVertexArray(g_cube_vao);
    glUseProgram(g_cube_shader);

    model_matrix := make_translation_matrix4(position) * make_scale_matrix4(Vector3.{0.2, 0.2, 0.2});

    glUniformMatrix4fv (glGetUniformLocation (g_cube_shader, "u_View_Projection_Matrix"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
	glUniformMatrix4fv (glGetUniformLocation (g_cube_shader, "u_Model_Matrix"), 1, GL_TRUE, *model_matrix.coef[0][0]);
    glDrawArrays(GL_TRIANGLES, 0, 36);
}


init_buffers :: (mdl_model: MDLModel) {
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

    glGenVertexArrays(1, *g_VAO);
    glGenBuffers(1, *g_VBO_CurrentFramePos);
    glGenBuffers(1, *g_VBO_NextFramePos);
    glGenBuffers(1, *g_VBO_CurrentFrameNormals);
    glGenBuffers(1, *g_VBO_NextFrameNormals);
    glGenBuffers(1, *g_VBO_Texcoords);
    glGenBuffers(1, *g_EBO);

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

    // Normals VBO (will update per frame) ?
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
    glBufferData(GL_ARRAY_BUFFER, mdl_model.texture_coordinates.count * size_of(Vector2_GLfloat), mdl_model.texture_coordinates.data, GL_STATIC_DRAW);
    glVertexAttribPointer(4, 2, GL_FLOAT, GL_FALSE, 2 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(4);


    // Elements (Triangles) VBO (static)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(GLfloat) * MAX_TRIANGLE_COUNT * 3, gl_triangles.data, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(Vector3_GLuint) * mdl_model.indices.count, mdl_model.indices.data, GL_STATIC_DRAW);

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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, mdl_model.texture_width, mdl_model.texture_height, 0, GL_RGB, GL_UNSIGNED_BYTE, mdl_model.texture_data.data);
}

update_buffers :: (mdl_model: MDLModel) {
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFramePos);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFrameNormals);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3_GLfloat) * mdl_model.vertex_count, null, GL_DYNAMIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
    glBufferData(GL_ARRAY_BUFFER, mdl_model.texture_coordinates.count * size_of(Vector2_GLfloat), mdl_model.texture_coordinates.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(Vector3_GLuint) * mdl_model.indices.count, mdl_model.indices.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindTexture(GL_TEXTURE_2D, g_texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, mdl_model.texture_width, mdl_model.texture_height, 0, GL_RGB, GL_UNSIGNED_BYTE, mdl_model.texture_data.data);
}

render :: (mdl_model: MDLModel, frame: int, frame_next: int, anim_lerp: float, aspect: float, angle: float, anim_index: int) {
    glUseProgram(g_shader);

    // TODO(Oskar): Pass vector3 instead of this annoying indexing.
    // TODO(Oskar): Pass this and next frame to shader and let it interpolate.
    // vertices: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    // normals: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    // for 0..(mdl_model.vertex_count) - 1 {
    //     vertices[3 * it + 0] = mdl_model.animations[anim_index].frames[frame].vertices[it].x * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].vertices[it].x * anim_lerp;
    //     vertices[3 * it + 1] = mdl_model.animations[anim_index].frames[frame].vertices[it].y * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].vertices[it].y * anim_lerp;
    //     vertices[3 * it + 2] = mdl_model.animations[anim_index].frames[frame].vertices[it].z * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].vertices[it].z * anim_lerp;

    //     normals[3 * it + 0] = mdl_model.animations[anim_index].frames[frame].normals[it].x * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].normals[it].x * anim_lerp;
    //     normals[3 * it + 1] = mdl_model.animations[anim_index].frames[frame].normals[it].y * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].normals[it].y * anim_lerp;
    //     normals[3 * it + 2] = mdl_model.animations[anim_index].frames[frame].normals[it].z * (1.0 - anim_lerp) + mdl_model.animations[anim_index].frames[frame_next].normals[it].z * anim_lerp;
    // }
    
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFramePos);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame].vertices.data);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFramePos);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame_next].vertices.data);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_CurrentFrameNormals);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame].normals.data);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_NextFrameNormals);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(Vector3_GLfloat) * mdl_model.vertex_count, mdl_model.animations[anim_index].frames[frame_next].normals.data);

    r1: Quaternion;
    set_from_axis_and_angle(*r1, 0, 1, 0, angle * PI / 180.0);

    r2: Quaternion;
    set_from_axis_and_angle(*r2, 1, 0, 0, -90.0 * PI / 180.0);    


    model_matrix := rotation_matrix(Matrix4, r1*r2) * make_translation_matrix4(Vector3.{0.0, 0.0, 2.0}) * make_scale_matrix4(Vector3.{0.1, 0.1, 0.1});

    glUniformMatrix4fv(glGetUniformLocation(g_shader, "view_projection"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
    glUniformMatrix4fv(glGetUniformLocation(g_shader, "model"), 1, GL_TRUE, *model_matrix.coef[0][0]);
    glUniform1f(glGetUniformLocation(g_shader, "interpolation"), anim_lerp);

    lightPos := float32.[5.0, 5.0, 0.0];
    lightColor := float32.[1.0, 1.0, 1.0];

    glUniform3fv(glGetUniformLocation(g_shader, "lightPos"), 1, lightPos.data);
    glUniform3fv(glGetUniformLocation(g_shader, "lightColor"), 1, lightColor.data);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, g_texture);
    glUniform1i(glGetUniformLocation(g_shader, "texture1"), 0);

    glBindVertexArray(g_VAO);
    glDrawElements(GL_TRIANGLES, xx (mdl_model.indices.count * 3), GL_UNSIGNED_INT, null);
    glBindVertexArray(0);

    draw_cube(Vector3.{lightPos[0], lightPos[1], lightPos[2]});
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

out vec2 TexCoord;
out vec3 Normal;
out vec3 FragPos;

void main() {
    vec3 aPos = (aCurrentFramePos * (1.0 - interpolation)) + (aNextFramePos * interpolation);
    vec3 aNormal = (aCurrentFrameNormal * (1.0 - interpolation)) + (aNextFrameNormal * interpolation);

    TexCoord = aTexCoord;
    Normal = mat3(transpose(inverse(model))) * aNormal;
    FragPos = vec3(model * vec4(aPos, 1.0));
    gl_Position = view_projection * vec4(FragPos, 1.0);
}
GLSL

MDL_FRAGMENT_SHADER :: #string GLSL
in vec2 TexCoord;
in vec3 Normal;
in vec3 FragPos;

out vec4 FragColor;

uniform sampler2D texture1;

uniform vec3 lightPos; 
uniform vec3 viewPos; 
uniform vec3 lightColor;

void main() {
    // ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;

    // diffuse 
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    vec4 objectColor = texture(texture1, TexCoord);
    vec4 result = vec4(ambient + diffuse, 1.0) * objectColor;
    FragColor = result;
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