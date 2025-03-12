g_shader: GLuint;
g_VAO: GLuint;
g_VBO_Pos: GLuint;
g_VBO_Texcoords: GLuint;
g_VBO_Normals: GLuint;
g_EBO: GLuint;

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

init_buffers :: (gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat, gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint) {
    ok: bool;

    g_shader, ok = create_shader_program (VERTEX_SHADER, FRAGMENT_SHADER);
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
}

render :: (gl_vertices: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat, gl_vertex_count: GLsizei, frame: int, frame_next: int, anim_lerp: float, aspect: float, texture: GLuint, angle: float) {
    glUseProgram(g_shader);

    vertices: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    normals: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
    for 0..(2 * gl_vertex_count) - 1 {
        vertices[3 * it + 0] = gl_vertices[frame][it][0] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][0] * anim_lerp;
        vertices[3 * it + 1] = gl_vertices[frame][it][1] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][1] * anim_lerp;
        vertices[3 * it + 2] = gl_vertices[frame][it][2] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][2] * anim_lerp;

        normals[3 * it + 0] = gl_normals[frame][it][0];
        normals[3 * it + 1] = gl_normals[frame][it][1];
        normals[3 * it + 2] = gl_normals[frame][it][2];
    }
    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Pos);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) - 1), *vertices);

    glBindBuffer(GL_ARRAY_BUFFER, g_VBO_Normals);
    glBufferSubData(GL_ARRAY_BUFFER, 0, size_of(GLfloat) * ((2 * MAX_VERTEX_COUNT) - 1), *normals);

    projection_matrix := make_projection_matrix(60.0 * PI / 180.0, aspect, 0.1, 1000.0);
    view_matrix := make_translation_matrix4 (Vector3.{0.0, 0.0, -90.0});

    r1: Quaternion;
    set_from_axis_and_angle(*r1, 0, 1, 0, angle * PI / 180.0);

    r2: Quaternion;
    set_from_axis_and_angle(*r2, 1, 0, 0, -90.0 * PI / 180.0);    

    model_matrix := rotation_matrix(Matrix4, r1*r2) * make_translation_matrix4(Vector3.{0.0, 0.0, -10.0}) ;

    glUniformMatrix4fv(glGetUniformLocation(g_shader, "projection"), 1, GL_TRUE, *projection_matrix.coef[0][0]);
    glUniformMatrix4fv(glGetUniformLocation(g_shader, "view"), 1, GL_TRUE, *view_matrix.coef[0][0]);
    glUniformMatrix4fv(glGetUniformLocation(g_shader, "model"), 1, GL_TRUE, *model_matrix.coef[0][0]);

    lightPos := float32.[5.0, 10.0, 5.0];
    lightColor := float32.[1.0, 1.0, 1.0];

    glUniform3fv(glGetUniformLocation(g_shader, "lightPos"), 1, lightPos.data);
    glUniform3fv(glGetUniformLocation(g_shader, "lightColor"), 1, lightColor.data);


    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(glGetUniformLocation(g_shader, "texture1"), 0);

    glBindVertexArray(g_VAO);
    glDrawElements(GL_TRIANGLES, gl_triangle_count * 3, GL_UNSIGNED_INT, null);
    glBindVertexArray(0);
}

SHADER_PREFIX :: #string END
#version 330 core
END

VERTEX_SHADER :: #string GLSL
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 TexCoord;
out vec3 Normal;
out vec3 FragPos;

void main() {
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    
    TexCoord = aTexCoord;
    Normal = aNormal;
    FragPos = vec3(model * vec4(aPos, 1.0));
}
GLSL

FRAGMENT_SHADER :: #string GLSL
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
    FragColor = result;//texture(texture1, TexCoord);
}
GLSL