Skin :: struct {
    name: string;

    skin_width: u32;
    skin_height: u32;
    skin_data: []u8;
}

// Vertex :: struct {
//     position: Vector3_GLfloat;
//     normal: Vector3_GLfloat;
//     texcoord: Vector2_GLfloat;
// };

AnimationFrame :: struct {
    vertices: []Vector3_GLfloat;
    normals: []Vector3_GLfloat;
    texcoords: []Vector2_GLfloat;
}

Animation :: struct {
    name: string;
    frames: [..]AnimationFrame;
}

Model :: struct {
    // vertices: []Vertex;
    animations: [..]Animation;
    vertex_count: u32;
    skins: []Skin;
};