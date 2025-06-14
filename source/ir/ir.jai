TextureWrapMode :: enum {
    REPEAT;
    MIRRORED_REPEAT;
    CLAMP_TO_EDGE;
}

TextureFilterMode :: enum {
    NEAREST;
    LINEAR;
    NEAREST_MIPMAP_NEAREST;
    LINEAR_MIPMAP_NEAREST;    
    NEAREST_MIPMAP_LINEAR;
    LINEAR_MIPMAP_LINEAR;
}

CustomProperty :: union {
    int_prop: s32;
    float_prop: float32;
    string_prop: string;
    bool_prop: bool;
    bytes_prop: []u8;
}

Texture :: struct {
    name: string;
    file_path: string;
    embedded_data: []u8;
    
    width: s32;
    height: s32;

    wrap_s: TextureWrapMode = .REPEAT;
    wrap_t: TextureWrapMode = .REPEAT;
    min_filter: TextureFilterMode = .LINEAR;
    mag_filter: TextureFilterMode = .LINEAR;
    
    // Format-specific properties
    // custom_properties: Table(string, CustomProperty);
}

AlphaMode :: enum {
    OPAQUE;
    MASK;
    BLEND;
}

Material :: struct {
    name: string;
    
    // PBR properties
    base_color_factor: Vector4 = .{1.0, 1.0, 1.0, 1.0};
    base_color_texture: *Texture;
    
    metallic_factor: float32 = 1.0;
    roughness_factor: float32 = 1.0;
    metallic_roughness_texture: *Texture;
    
    normal_texture: *Texture;
    normal_scale: float32 = 1.0;
    
    occlusion_texture: *Texture;
    occlusion_strength: float32 = 1.0;
    
    emissive_factor: Vector3 = .{0.0, 0.0, 0.0};
    emissive_texture: *Texture;
    
    // Legacy properties
    ambient_color: Vector3 = .{0.2, 0.2, 0.2};
    diffuse_color: Vector3 = .{0.8, 0.8, 0.8};
    specular_color: Vector3 = .{1.0, 1.0, 1.0};
    shininess: float32 = 32.0;
    
    diffuse_texture: *Texture;
    specular_texture: *Texture;
    ambient_texture: *Texture;
    
    alpha_mode: AlphaMode = .OPAQUE;
    alpha_cutoff: float32 = 0.5;
    
    double_sided: bool = false;
    
    // Format-specific properties
    // custom_properties: Table(string, CustomProperty);
}

TopologyType :: enum {
    POINTS;
    LINES;
    LINE_STRIP;
    TRIANGLES;
    TRIANGLE_STRIP;
    TRIANGLE_FAN;
}

Primitive :: struct {
    attributes: [..]VertexAttribute;
    
    indices: [..]u32;
    
    topology: TopologyType = .TRIANGLES;
    
    material: *Material;
    
    bounding_box_min: Vector3;
    bounding_box_max: Vector3;
}

MorphTarget :: struct {
    name: string;
    attributes: [..]VertexAttribute;  // Usually POSITION, NORMAL, TANGENT
    weight: float32 = 0.0;
}

Mesh :: struct {
    name: string;
    primitives: [..]Primitive;
    
    morph_targets: [..]MorphTarget;
    
    skeleton: *Skeleton;
    
    // Format-specific data
    // custom_data: Table(string, CustomProperty);
}

Bone :: struct {
    name: string;
    parent_index: s32 = -1;
    
    bind_pose_transform: Matrix4;
    inverse_bind_matrix: Matrix4;
    
    child_indices: []s32;
}

Skeleton :: struct {
    name: string;
    bones: []Bone;
    global_inverse_transform: Matrix4;
    
    // Bone name to index mapping for quick lookup
    // bone_name_to_index: Table(string, int);
}

InterpolationType :: enum {
    LINEAR;
    STEP;
    CUBIC_SPLINE;
}

Keyframe_Vec3 :: struct {
    time: float32;
    value: Vector3;
    interpolation: InterpolationType = .LINEAR;
    in_tangent: Vector3;
    out_tangent: Vector3;
}

Keyframe_Quat :: struct {
    time: float32;
    value: Quaternion;
    interpolation: InterpolationType = .LINEAR;
    in_tangent: Quaternion;
    out_tangent: Quaternion;
}

Keyframe_Float :: struct {
    time: float32;
    value: float32;
    interpolation: InterpolationType = .LINEAR;
    in_tangent: float32;
    out_tangent: float32;
}

TargetType :: enum {
    TRANSLATION;
    ROTATION;
    SCALE;
    WEIGHTS;
    CUSTOM;
}

AnimationChannel :: struct {
    target_type: TargetType;
    custom_target_name: string;  // Used when target_type == CUSTOM
    
    // Target reference (could be node index, bone index, etc.)
    target_index: s32 = -1;
    target_name: string;
    
    vec3_keyframes: [..]Keyframe_Vec3;
    quat_keyframes: [..]Keyframe_Quat;
    float_keyframes: [..]Keyframe_Float;
}

Animation :: struct {
    name: string;
    duration: float32 = 0.0;
    ticks_per_second: float32 = 25.0;  // For formats like MD2
    
    channels: [..]AnimationChannel;
    
    looping: bool = false;
    start_time: float32 = 0.0;
    
    // Format-specific data
    // custom_properties: Table(string, CustomProperty);
}

Node :: struct {
    name: string;
    
    translation: Vector3 = .{0.0, 0.0, 0.0};
    rotation: Quaternion = .{0.0, 0.0, 0.0, 1.0};
    scale: Vector3 = .{1.0, 1.0, 1.0};
    
    matrix: *Matrix4;
    
    children: []*Node;
    parent: *Node;
    
    mesh: *Mesh;
    
    skeleton: *Skeleton;
}

UpAxis :: enum {
    Y_UP;
    Z_UP;
}

Handedness :: enum {
    LEFT_HANDED;
    RIGHT_HANDED;
}

SceneMetadata :: struct {
    generator: string;
    version: string;
    copyright: string;
    
    up_axis: UpAxis = .Y_UP;
    handedness: Handedness = .RIGHT_HANDED;
    unit_scale: float32 = 1.0;  // Units per meter
    
    // Format-specific metadata
    // custom_metadata: Table(string, CustomProperty);
}

Scene :: struct {
    name: string;
    
    root_nodes: [..]*Node;
    
    meshes: [..]*Mesh;
    materials: [..]*Material;
    textures: [..]*Texture;
    animations: [..]*Animation;
    skeletons: [..]*Skeleton;
    
    metadata: SceneMetadata;
    
    // Format-specific extensions
    // extensions: Table(string, CustomProperty);
}