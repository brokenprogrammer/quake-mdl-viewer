g_shader: GLuint;
g_line_shader: GLuint;
g_cube_shader: GLuint;

g_VAO: GLuint;
g_VBO_Pos: GLuint;
g_VBO_Texcoords: GLuint;
g_VBO_Normals: GLuint;
g_EBO: GLuint;

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

init_buffers :: (gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat, gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint) {
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
    glGenBuffers(1, *g_VBO_Pos);
    glGenBuffers(1, *g_VBO_Texcoords);
    glGenBuffers(1, *g_VBO_Normals);
    glGenBuffers(1, *g_EBO);

    glBindVertexArray(g_VAO);

    // Positions VBO (will update per frame)
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Pos);
    glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) * 3), null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(0);

    // Texture Coordinates VBO (static)
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
    glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) * 2), gl_texcoords.data, GL_STATIC_DRAW);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(1);

    // Normals VBO (will update per frame) ?
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Normals);
    glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) * 3), null, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * size_of(GLfloat), cast(*void)0);
    glEnableVertexAttribArray(2);

    // Elements (Triangles) VBO (static)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(GLfloat) * MAX_TRIANGLE_COUNT * 3, gl_triangles.data, GL_STATIC_DRAW);

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
}

update_buffers :: (gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat, gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint) {
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Texcoords);
    glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) * 2), gl_texcoords.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(GLfloat) * MAX_TRIANGLE_COUNT * 3, gl_triangles.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

render :: (gl_vertices: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat, gl_vertex_count: GLsizei, frame: int, frame_next: int, anim_lerp: float, aspect: float, texture: GLuint, angle: float) {
    glUseProgram(g_shader);

    vertices: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    normals: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    for 0..(2 * gl_vertex_count) - 1 {
        vertices[3 * it + 0] = gl_vertices[frame][it][0] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][0] * anim_lerp;
        vertices[3 * it + 1] = gl_vertices[frame][it][1] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][1] * anim_lerp;
        vertices[3 * it + 2] = gl_vertices[frame][it][2] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][2] * anim_lerp;

        normals[3 * it + 0] = gl_normals[frame][it][0] * (1.0 - anim_lerp) + gl_normals[frame_next][it][0] * anim_lerp;
        normals[3 * it + 1] = gl_normals[frame][it][1] * (1.0 - anim_lerp) + gl_normals[frame_next][it][1] * anim_lerp;
        normals[3 * it + 2] = gl_normals[frame][it][2] * (1.0 - anim_lerp) + gl_normals[frame_next][it][2] * anim_lerp;
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Pos);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(GLfloat) * (((2 * gl_vertex_count) * 3)), *vertices);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Normals);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(GLfloat) * (((2 * gl_vertex_count) * 3)), *normals);

    r1: Quaternion;
    set_from_axis_and_angle(*r1, 0, 1, 0, angle * PI / 180.0);

    r2: Quaternion;
    set_from_axis_and_angle(*r2, 1, 0, 0, -90.0 * PI / 180.0);    


    model_matrix := rotation_matrix(Matrix4, r1*r2) * make_translation_matrix4(Vector3.{0.0, 0.0, 2.0}) * make_scale_matrix4(Vector3.{0.1, 0.1, 0.1});

    glUniformMatrix4fv(glGetUniformLocation(g_shader, "view_projection"), 1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
    glUniformMatrix4fv(glGetUniformLocation(g_shader, "model"), 1, GL_TRUE, *model_matrix.coef[0][0]);

    lightPos := float32.[5.0, 5.0, 0.0];
    lightColor := float32.[1.0, 1.0, 1.0];

    glUniform3fv(glGetUniformLocation(g_shader, "lightPos"), 1, lightPos.data);
    glUniform3fv(glGetUniformLocation(g_shader, "lightColor"), 1, lightColor.data);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(glGetUniformLocation(g_shader, "texture1"), 0);

    glBindVertexArray(g_VAO);
    glDrawElements(GL_TRIANGLES, gl_triangle_count * 3, GL_UNSIGNED_INT, null);
    glBindVertexArray(0);

    draw_cube(Vector3.{lightPos[0], lightPos[1], lightPos[2]});
}

SHADER_PREFIX :: #string END
#version 330 core
END

MDL_VERTEX_SHADER :: #string GLSL
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view_projection;

out vec2 TexCoord;
out vec3 Normal;
out vec3 FragPos;

void main() {
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