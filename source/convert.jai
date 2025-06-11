#scope_file

// Vertex attribute types
AttributeType :: enum {
    POSITION;
    NORMAL;
    TANGENT;
    BITANGENT;
    TEXCOORD_0;
    TEXCOORD_1;
    TEXCOORD_2;
    TEXCOORD_3;
    COLOR_0;
    COLOR_1;
    JOINTS_0;
    WEIGHTS_0;
    CUSTOM;
}

// Generic attribute data variant
AttributeData :: union {
    float_value: float32;
    vec2_value: Vector2;
    vec3_value: Vector3_Float32;
    vec4_value: Vector4;
    int_value: s32;
    int_array: []s32;
}

// Vertex attribute storage
VertexAttribute :: struct {
    type: AttributeType;
    custom_name: string;  // Used when type == CUSTOM
    data: [..]AttributeData;
}

// Texture information
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
    embedded_data: []u8;  // For embedded textures
    
    width: s32;
    height: s32;

    wrap_s: TextureWrapMode = .REPEAT;
    wrap_t: TextureWrapMode = .REPEAT;
    min_filter: TextureFilterMode = .LINEAR;
    mag_filter: TextureFilterMode = .LINEAR;
    
    // Format-specific properties
    // custom_properties: Table(string, CustomProperty);
}

// Material representation
AlphaMode :: enum {
    OPAQUE;
    MASK;
    BLEND;
}

Material :: struct {
    name: string;
    
    // PBR properties (most modern)
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
    
    // Legacy properties (for older formats like MDL)
    ambient_color: Vector3 = .{0.2, 0.2, 0.2};
    diffuse_color: Vector3 = .{0.8, 0.8, 0.8};
    specular_color: Vector3 = .{1.0, 1.0, 1.0};
    shininess: float32 = 32.0;
    
    diffuse_texture: *Texture;
    specular_texture: *Texture;
    ambient_texture: *Texture;
    
    // Transparency
    alpha_mode: AlphaMode = .OPAQUE;
    alpha_cutoff: float32 = 0.5;
    
    double_sided: bool = false;
    
    // Format-specific properties
    // custom_properties: Table(string, CustomProperty);
}

// Primitive/submesh representation
TopologyType :: enum {
    POINTS;
    LINES;
    LINE_STRIP;
    TRIANGLES;
    TRIANGLE_STRIP;
    TRIANGLE_FAN;
}

TriangleMetadata :: struct {
    is_back_facing: bool; // MDL Specific
    has_seam: bool;       // MDL Specific
}

Primitive :: struct {
    // Vertex data - stored as attributes for maximum flexibility
    attributes: [..]VertexAttribute;
    
    // Index data
    indices: [..]u32;
    
    topology: TopologyType = .TRIANGLES;
    
    // Material reference
    material: *Material;
    
    // Bounding information
    bounding_box_min: Vector3;
    bounding_box_max: Vector3;

    triangle_metadata: [..]TriangleMetadata;
}

// Mesh representation
MorphTarget :: struct {
    name: string;
    attributes: []VertexAttribute;  // Usually POSITION, NORMAL, TANGENT
    weight: float32 = 0.0;
}

Mesh :: struct {
    name: string;
    primitives: [..]Primitive;
    
    // Morph targets (for shape keys/blend shapes)
    morph_targets: [..]MorphTarget;
    
    // Skinning information
    skeleton: *Skeleton;
    
    // Format-specific data
    // custom_data: Table(string, CustomProperty);
}

// Bone/Joint representation for skeletal animation
Bone :: struct {
    name: string;
    parent_index: s32 = -1;  // -1 for root bones
    
    // Bind pose transform
    bind_pose_transform: Matrix4;
    inverse_bind_matrix: Matrix4;
    
    // For formats that store bone hierarchy differently
    child_indices: []s32;
}

// Skeleton representation
Skeleton :: struct {
    name: string;
    bones: []Bone;
    global_inverse_transform: Matrix4;
    
    // Bone name to index mapping for quick lookup
    // bone_name_to_index: Table(string, int);
}

// Animation keyframe data
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

// Animation channel (animates a specific property of a specific target)
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
    target_name: string;  // Alternative identification
    
    // Keyframe data
    vec3_keyframes: [..]Keyframe_Vec3;
    quat_keyframes: [..]Keyframe_Quat;
    float_keyframes: [..]Keyframe_Float;
}

// Animation representation
Animation :: struct {
    name: string;
    duration: float32 = 0.0;
    ticks_per_second: float32 = 25.0;  // For formats like MD2
    
    channels: [..]AnimationChannel;
    
    // Animation metadata
    looping: bool = false;
    start_time: float32 = 0.0;
    
    // Format-specific data
    // custom_properties: Table(string, CustomProperty);
}

// Scene node (for hierarchy and transforms)
Node :: struct {
    name: string;
    
    // Transform data
    translation: Vector3 = .{0.0, 0.0, 0.0};
    rotation: Quaternion = .{0.0, 0.0, 0.0, 1.0};
    scale: Vector3 = .{1.0, 1.0, 1.0};
    
    // Alternative: direct matrix (some formats prefer this)
    matrix: *Matrix4;
    
    // Hierarchy
    children: []*Node;
    parent: *Node;
    
    // Content
    mesh: *Mesh;
    
    // Skinning
    skeleton: *Skeleton;
}

// Main scene representation
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
    
    // Coordinate system information
    up_axis: UpAxis = .Y_UP;
    handedness: Handedness = .RIGHT_HANDED;
    unit_scale: float32 = 1.0;  // Units per meter
    
    // Format-specific metadata
    // custom_metadata: Table(string, CustomProperty);
}

Scene :: struct {
    name: string;
    
    // Scene graph
    root_nodes: [..]*Node;
    
    // Asset collections
    meshes: [..]*Mesh;
    materials: [..]*Material;
    textures: [..]*Texture;
    animations: [..]*Animation;
    skeletons: [..]*Skeleton;
    
    // Scene metadata
    metadata: SceneMetadata;
    
    // Format-specific extensions
    // extensions: Table(string, CustomProperty);
}

// Helper functions for vertex attributes
create_vertex_attribute :: (type: AttributeType, custom_name: string = "") -> VertexAttribute {
    attr: VertexAttribute;
    attr.type = type;
    attr.custom_name = custom_name;
    return attr;
}

add_vec3_to_attribute :: (attr: *VertexAttribute, value: Vector3_Float32) {
    data: AttributeData;
    data.vec3_value = value;
    array_add(*attr.data, data);
}

add_vec2_to_attribute :: (attr: *VertexAttribute, value: Vector2) {
    data: AttributeData;
    data.vec2_value = value;
    array_add(*attr.data, data);
}

add_float_to_attribute :: (attr: *VertexAttribute, value: float32) {
    data: AttributeData;
    data.float_value = value;
    array_add(*attr.data, data);
}

// MDL to IR conversion function
#scope_export

// convert_mdl_to_ir :: (mdl_model: MDLModel) -> Scene {
//     scene: Scene;
//     scene.name = "MDL Model";
//     scene.metadata.generator = "MDL Converter";
//     scene.metadata.up_axis = .Z_UP;  // Quake uses Z-up
//     scene.metadata.handedness = .LEFT_HANDED;  // Quake uses left-handed
    
//     // Create textures from MDL images
//     for mdl_image, image_index: mdl_model.images {
//         texture := New(Texture);
//         texture.name = mdl_image.name;
//         texture.embedded_data = array_copy(mdl_image.data);

//         texture.width = xx mdl_image.width;
//         texture.height = xx mdl_image.height;
        
//         // Store original dimensions as custom properties
//         // width_prop: CustomProperty;
//         // width_prop.int_prop = xx mdl_image.width;
//         // table_set(*texture.custom_properties, "width", width_prop);
        
//         // height_prop: CustomProperty;
//         // height_prop.int_prop = xx mdl_image.height;
//         // table_set(*texture.custom_properties, "height", height_prop);
        
//         array_add(*scene.textures, texture);
//     }
    
//     // Create a simple material for each texture
//     for texture, texture_index: scene.textures {
//         material := New(Material);
//         material.name = tprint("Material_%", texture_index);
//         material.diffuse_texture = texture;
//         material.base_color_texture = texture;  // Also set for PBR compatibility
        
//         // Set legacy material properties (typical for Quake models)
//         material.ambient_color = .{0.3, 0.3, 0.3};
//         material.diffuse_color = .{0.8, 0.8, 0.8};
//         material.specular_color = .{0.1, 0.1, 0.1};
//         material.shininess = 8.0;
        
//         array_add(*scene.materials, material);
//     }
    
//     // Create mesh from MDL data
//     mesh := New(Mesh);
//     mesh.name = "MDL Mesh";
    
//     // Convert each frame to a separate primitive (could also be morph targets)
//     for frame_data, frame_index: mdl_model.frames {
//         primitive: Primitive;
//         primitive.topology = .TRIANGLES;
        
//         // Create vertex attributes
//         position_attr := create_vertex_attribute(.POSITION);
//         normal_attr := create_vertex_attribute(.NORMAL);
//         texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
        
//         // Convert vertices for this frame
//         for vertex, vertex_index: frame_data.vertices {
//             // Convert position from u8 to float using MDL scale and translate
//             pos: Vector3_Float32;
//             pos.x = (cast(float32)vertex.pos.x) * mdl_model.scale.x + mdl_model.translate.x;
//             pos.y = (cast(float32)vertex.pos.y) * mdl_model.scale.y + mdl_model.translate.y;
//             pos.z = (cast(float32)vertex.pos.z) * mdl_model.scale.z + mdl_model.translate.z;
//             add_vec3_to_attribute(*position_attr, pos);
            
//             // Get normal from lookup table
//             normal_index := vertex.normal_index;
//             if normal_index < anorms_table.count {
//                 normal := anorms_table[normal_index];
//                 add_vec3_to_attribute(*normal_attr, normal);
//             } else {
//                 // Fallback normal
//                 add_vec3_to_attribute(*normal_attr, .{0, 0, 1});
//             }
            
//             // Add texture coordinates
//             if vertex_index < mdl_model.texcoords.count {
//                 texcoord := mdl_model.texcoords[vertex_index];
                
//                 mdl_model_texture_width := mdl_model.images[0].width;
//                 mdl_model_texture_height := mdl_model.images[0].height;

//                 // Convert from integer to normalized float coordinates
//                 // MDL stores texture coordinates as integers that need to be normalized
//                 u := cast(float32)(texcoord.s + 0.5) / mdl_model_texture_width;
//                 v := cast(float32)(texcoord.t + 0.5) / mdl_model_texture_height;
                
//                 add_vec2_to_attribute(*texcoord_attr, .{u, v});
//             } else {
//                 // Fallback UV
//                 add_vec2_to_attribute(*texcoord_attr, .{0, 0});
//             }
//         }
        
//         // Add attributes to primitive
//         array_add(*primitive.attributes, position_attr);
//         array_add(*primitive.attributes, normal_attr);
//         array_add(*primitive.attributes, texcoord_attr);
        
//         // Convert triangles to indices
//         for triangle: mdl_model.triangles {
//             array_add(*primitive.indices, triangle.vertex.x);
//             array_add(*primitive.indices, triangle.vertex.y);
//             array_add(*primitive.indices, triangle.vertex.z);
//         }
        
//         for triangle, tri_idx: mdl_model.triangles {
//             metadata: TriangleMetadata;
//             metadata.is_back_facing = triangle.frontface == 0;
//             metadata.has_seam = false;

//             vertex_index_x := triangle.vertex.x;
//             if vertex_index_x < mdl_model.texcoords.count {
//                 if mdl_model.texcoords[vertex_index_x].seam != 0 {
//                     metadata.has_seam = true;
//                 }
//             }

//             vertex_index_y := triangle.vertex.y;
//             if vertex_index_y < mdl_model.texcoords.count {
//                 if mdl_model.texcoords[vertex_index_y].seam != 0 {
//                     metadata.has_seam = true;
//                 }
//             }

//             vertex_index_z := triangle.vertex.z;
//             if vertex_index_z < mdl_model.texcoords.count {
//                 if mdl_model.texcoords[vertex_index_z].seam != 0 {
//                     metadata.has_seam = true;
//                 }
//             }
            
//             array_add(*primitive.triangle_metadata, metadata);
//         }

//         // Assign material (use first material if available)
//         if scene.materials.count > 0 {
//             primitive.material = scene.materials[0];
//         }
        
//         // If this is the first frame, use it as the main mesh
//         if frame_index == 0 {
//             array_add(*mesh.primitives, primitive);
//         } else {
//             // Additional frames could be stored as morph targets
//             // For now, we'll just use the first frame as the base mesh
//             // In a full implementation, you might want to create morph targets here
//         }
//     }
    
//     array_add(*scene.meshes, mesh);
    
//     // Create a root node with the mesh
//     root_node := New(Node);
//     root_node.name = "MDL Root";
//     root_node.mesh = mesh;
    
//     array_add(*scene.root_nodes, root_node);
    
//     // If there are multiple frames, create a simple animation
//     if mdl_model.frames.count > 1 {
//         animation := New(Animation);
//         animation.name = "MDL Animation";
//         animation.duration = cast(float32)(mdl_model.frames.count - 1);
//         animation.ticks_per_second = 10.0;  // 10 FPS default for MDL
//         animation.looping = true;
        
//         // Create a channel that could animate between frames
//         // This is a simplified approach - in practice you might want to
//         // create proper morph target animations
//         channel: AnimationChannel;
//         channel.target_type = .CUSTOM;
//         channel.custom_target_name = "frame_animation";
//         channel.target_index = 0;
        
//         // Add keyframes for each frame
//         for frame_data, frame_index: mdl_model.frames {
//             keyframe: Keyframe_Float;
//             keyframe.time = cast(float32)frame_index;
//             keyframe.value = cast(float32)frame_index;
//             keyframe.interpolation = .STEP;  // Step interpolation for frame animation
            
//             array_add(*channel.float_keyframes, keyframe);
//         }
        
//         array_add(*animation.channels, channel);
//         array_add(*scene.animations, animation);
//     }
    
//     return scene;
// }

    // Track unique vertex combinations (position + UV + normal)
    VertexKey :: struct {
        vertex_index: u32;
        texcoord_index: u32;
        is_seam_vertex: bool;
        is_back_face: bool;
    }

convert_mdl_to_ir :: (mdl_model: MDLModel) -> Scene {
    scene: Scene;
    scene.name = "MDL Model";
    scene.metadata.generator = "MDL Converter";
    scene.metadata.up_axis = .Z_UP;
    scene.metadata.handedness = .LEFT_HANDED;
    
    // Create textures and materials (same as before)
    for mdl_image, image_index: mdl_model.images {
        texture := New(Texture);
        texture.name = mdl_image.name;
        texture.embedded_data = array_copy(mdl_image.data);
        texture.width = xx mdl_image.width;
        texture.height = xx mdl_image.height;
        array_add(*scene.textures, texture);
    }
    
    for texture, texture_index: scene.textures {
        material := New(Material);
        material.name = tprint("Material_%", texture_index);
        material.diffuse_texture = texture;
        material.base_color_texture = texture;
        material.ambient_color = .{0.3, 0.3, 0.3};
        material.diffuse_color = .{0.8, 0.8, 0.8};
        material.specular_color = .{0.1, 0.1, 0.1};
        material.shininess = 8.0;
        array_add(*scene.materials, material);
    }
    
    // Create mesh with proper seam handling
    mesh := New(Mesh);
    mesh.name = "MDL Mesh";
    
    // Process first frame to establish vertex structure
    frame_data := mdl_model.frames[0];
    
    vertex_map: Table(VertexKey, u32, get_hash, VertexKeyCompare);
    defer deinit(*vertex_map);
    
    expanded_vertices: [..]Vector3_Float32;
    expanded_normals: [..]Vector3_Float32;
    expanded_texcoords: [..]Vector2;
    triangle_indices: [..]u32;
    
    current_vertex_index: u32 = 0;
    
    // Process each triangle and handle seams
    for triangle, tri_idx: mdl_model.triangles {
        is_back_face := triangle.frontface == 0;
        
        triangle_vertex_indices: [3]u32;
        
        triangle_vertices := u32.[triangle.vertex.x, triangle.vertex.y, triangle.vertex.z];

        for corner: 0..2 {
            mdl_vertex_idx := triangle_vertices[corner];
            
            // Check if this vertex has a seam
            has_seam := mdl_model.texcoords[mdl_vertex_idx].seam != 0;
            needs_seam_offset := is_back_face && has_seam;
            
            vertex_key: VertexKey;
            vertex_key.vertex_index = mdl_vertex_idx;
            vertex_key.texcoord_index = mdl_vertex_idx;
            vertex_key.is_seam_vertex = has_seam;
            vertex_key.is_back_face = is_back_face;
            
            // Check if we already have this vertex combination
            existing_index, found := table_find(*vertex_map, vertex_key);
            
            if found {
                triangle_vertex_indices[corner] = existing_index;
            } else {
                // Create new vertex
                mdl_vertex := frame_data.vertices[mdl_vertex_idx];
                
                // Transform position
                pos: Vector3_Float32;
                pos.x = cast(float32)mdl_vertex.pos.x * mdl_model.scale.x + mdl_model.translate.x;
                pos.y = cast(float32)mdl_vertex.pos.y * mdl_model.scale.y + mdl_model.translate.y;
                pos.z = cast(float32)mdl_vertex.pos.z * mdl_model.scale.z + mdl_model.translate.z;
                
                // Get normal
                normal_index := mdl_vertex.normal_index;
                normal: Vector3_Float32;
                if normal_index < anorms_table.count {
                    normal = anorms_table[normal_index];
                } else {
                    normal = .{0, 0, 1};
                }
                
                // Get texture coordinates with seam handling
                texcoord := mdl_model.texcoords[mdl_vertex_idx];
                tex_width := cast(float32)mdl_model.images[0].width;
                tex_height := cast(float32)mdl_model.images[0].height;
                
                u := cast(float32)(texcoord.s + 0.5) / tex_width;
                v := cast(float32)(texcoord.t + 0.5) / tex_height;
                
                // Apply seam offset if needed
                if needs_seam_offset {
                    u += 0.5;
                    if u > 1.0 u -= 1.0; // Wrap around
                }
                
                array_add(*expanded_vertices, pos);
                array_add(*expanded_normals, normal);
                array_add(*expanded_texcoords, Vector2.{u, v});
                
                table_set(*vertex_map, vertex_key, current_vertex_index);
                triangle_vertex_indices[corner] = current_vertex_index;
                current_vertex_index += 1;
            }
        }
        
        // Add triangle indices
        array_add(*triangle_indices, triangle_vertex_indices[0]);
        array_add(*triangle_indices, triangle_vertex_indices[1]);
        array_add(*triangle_indices, triangle_vertex_indices[2]);
    }
    
    // Create primitive with processed data
    primitive: Primitive;
    primitive.topology = .TRIANGLES;
    
    // Create vertex attributes
    position_attr := create_vertex_attribute(.POSITION);
    normal_attr := create_vertex_attribute(.NORMAL);
    texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
    
    for i: 0..expanded_vertices.count-1 {
        add_vec3_to_attribute(*position_attr, expanded_vertices[i]);
        add_vec3_to_attribute(*normal_attr, expanded_normals[i]);
        add_vec2_to_attribute(*texcoord_attr, expanded_texcoords[i]);
    }
    
    array_add(*primitive.attributes, position_attr);
    array_add(*primitive.attributes, normal_attr);
    array_add(*primitive.attributes, texcoord_attr);
    
    primitive.indices = triangle_indices;
    
    if scene.materials.count > 0 {
        primitive.material = scene.materials[0];
    }
    
    array_add(*mesh.primitives, primitive);
    array_add(*scene.meshes, mesh);
    
    // Create root node
    root_node := New(Node);
    root_node.name = "MDL Root";
    root_node.mesh = mesh;
    array_add(*scene.root_nodes, root_node);
    
    // Clean up temporary arrays
    array_free(expanded_vertices);
    array_free(expanded_normals);
    array_free(expanded_texcoords);
    
    return scene;
}

// Cleanup function for the scene
cleanup_scene :: (scene: *Scene) {
    // Clean up textures
    for texture: scene.textures {
        array_free(texture.embedded_data);
        // deinit(*texture.custom_properties);
        free(texture);
    }
    array_free(scene.textures);
    
    // Clean up materials
    for material: scene.materials {
        // deinit(*material.custom_properties);
        free(material);
    }
    array_free(scene.materials);
    
    // Clean up meshes
    for mesh: scene.meshes {
        for *primitive: mesh.primitives {
            for *attribute: primitive.attributes {
                array_free(attribute.data);
            }
            array_free(primitive.attributes);
            array_free(primitive.indices);
        }
        array_free(mesh.primitives);
        array_free(mesh.morph_targets);
        // deinit(*mesh.custom_data);
        free(mesh);
    }
    array_free(scene.meshes);
    
    // Clean up animations
    for animation: scene.animations {
        for *channel: animation.channels {
            array_free(channel.vec3_keyframes);
            array_free(channel.quat_keyframes);
            array_free(channel.float_keyframes);
        }
        array_free(animation.channels);
        // deinit(*animation.custom_properties);
        free(animation);
    }
    array_free(scene.animations);
    
    // Clean up skeletons
    for skeleton: scene.skeletons {
        for *bone: skeleton.bones {
            array_free(bone.child_indices);
        }
        array_free(skeleton.bones);
        // deinit(*skeleton.bone_name_to_index);
        free(skeleton);
    }
    array_free(scene.skeletons);
    
    // Clean up nodes
    for node: scene.root_nodes {
        cleanup_node_recursive(node);
    }
    array_free(scene.root_nodes);
    
    // Clean up scene metadata
    // deinit(*scene.metadata.custom_metadata);
    // deinit(*scene.extensions);
}

cleanup_node_recursive :: (node: *Node) {
    for child: node.children {
        cleanup_node_recursive(child);
    }
    array_free(node.children);
    free(node);
}

// IR to MD2 conversion function
#scope_export

// convert_ir_to_md2 :: (scene: Scene, output_file: string) -> bool {
//     if scene.meshes.count == 0 {
//         log("No meshes found in scene", flags=.ERROR);
//         return false;
//     }

//     // Use first mesh for conversion (MD2 supports single mesh)
//     mesh := scene.meshes[0];
//     if mesh.primitives.count == 0 {
//         log("No primitives found in mesh", flags=.ERROR);
//         return false;
//     }

//     // Get the main primitive (MD2 doesn't support multiple primitives per mesh)
//     primitive := mesh.primitives[0];
    
//     // Extract vertex attributes
//     position_attr := find_attribute(primitive, .POSITION);
//     normal_attr   := find_attribute(primitive, .NORMAL);
//     texcoord_attr := find_attribute(primitive, .TEXCOORD_0);
    
//     if !position_attr {
//         log("No position attribute found", flags=.ERROR);
//         return false;
//     }

//     vertex_count := position_attr.data.count;
//     triangle_count := primitive.indices.count / 3;

//     // Create MD2 model structure
//     md2_model: MD2Model;

//     if scene.textures.count > 0 {
//         first_texture := scene.textures[0];

//         md2_model.skin_width = first_texture.width;
//         md2_model.skin_height = first_texture.height;
//     }

//     // Convert textures to skins
//     md2_model.skins = NewArray(max(1, scene.textures.count), MD2Skin);
//     if scene.textures.count > 0 {
//         for texture, i: scene.textures {
//             if i >= md2_model.skins.count break;
            
//             // Copy texture name to skin name (truncate if necessary)
//             name_length := min(texture.name.count, 63);
//             memcpy(md2_model.skins[i].name.data, texture.name.data, name_length);
//             md2_model.skins[i].name[name_length] = 0; // Null terminate
//         }
//     } else {
//         // Default skin name
//         default_name := "default.pcx";
//         memcpy(md2_model.skins[0].name.data, default_name.data, default_name.count);
//         md2_model.skins[0].name[default_name.count] = 0;
//     }

//     // // Convert texture coordinates
//     // md2_model.texcoords = NewArray(vertex_count, MD2TexCoord);
//     // if texcoord_attr {
//     //     for i: 0..vertex_count-1 {
//     //         uv := texcoord_attr.data[i].vec2_value;
            
//     //         // Convert normalized coordinates to MD2 integer format
//     //         md2_model.texcoords[i].s = cast(s16)(uv.x * cast(float32)md2_model.skin_width);
//     //         md2_model.texcoords[i].t = cast(s16)(uv.y * cast(float32)md2_model.skin_height);
//     //     }
//     // } else {
//     //     // Default texture coordinates
//     //     for i: 0..vertex_count-1 {
//     //         md2_model.texcoords[i].s = 0;
//     //         md2_model.texcoords[i].t = 0;
//     //     }
//     // }

//     // // Convert triangles
//     // md2_model.triangles = NewArray(triangle_count, MD2Triangle);
//     // for i: 0..triangle_count-1 {
//     //     base_index := i * 3;
//     //     md2_model.triangles[i].vertex[0] = cast(u16)primitive.indices[base_index];
//     //     md2_model.triangles[i].vertex[1] = cast(u16)primitive.indices[base_index + 1];
//     //     md2_model.triangles[i].vertex[2] = cast(u16)primitive.indices[base_index + 2];
        
//     //     // Use same indices for texture coordinates (assuming 1:1 mapping)
//     //     md2_model.triangles[i].texcoord_indice[0] = cast(u16)primitive.indices[base_index];
//     //     md2_model.triangles[i].texcoord_indice[1] = cast(u16)primitive.indices[base_index + 1];
//     //     md2_model.triangles[i].texcoord_indice[2] = cast(u16)primitive.indices[base_index + 2];
//     // }

//     // Create texture coordinates array with proper indexing
//     unique_texcoords: [..]Vector2;
//     texcoord_indices: [..]u16;  // Maps triangle corner to texcoord index

//     // First, gather all unique texture coordinates
//     if texcoord_attr {
//         for i: 0..triangle_count-1 {
//             is_back_facing := primitive.triangle_metadata[i].is_back_facing;
//             has_seam := primitive.triangle_metadata[i].has_seam;
            
//             for j: 0..2 {
//                 idx := primitive.indices[i*3 + j];
//                 uv := texcoord_attr.data[idx].vec2_value;
                
//                 if is_back_facing && has_seam {
//                     uv.x += 0.5;  // Apply seam offset for MD2
//                     if uv.x > 1.0 uv.x -= 1.0;  // Wrap around
//                 }

//                 // Check if this UV is already in our unique list
//                 found := false;
//                 texcoord_idx: u16 = 0;
                
//                 for unique_idx: 0..unique_texcoords.count-1 {
//                     unique_uv := unique_texcoords[unique_idx];
//                     if abs(unique_uv.x - uv.x) < 0.0001 && abs(unique_uv.y - uv.y) < 0.0001 {
//                         found = true;
//                         texcoord_idx = xx unique_idx;
//                         break;
//                     }
//                 }
                
//                 if !found {
//                     texcoord_idx = xx unique_texcoords.count;
//                     array_add(*unique_texcoords, uv);
//                 }
                
//                 array_add(*texcoord_indices, texcoord_idx);
//             }
//         }
//     }

//     // Convert unique texture coordinates to MD2 format
//     md2_model.texcoords = NewArray(unique_texcoords.count, MD2TexCoord);
//     for i: 0..unique_texcoords.count-1 {
//         uv := unique_texcoords[i];
        
//         // Convert normalized coordinates to MD2 integer format
//         // IMPORTANT: Flip the V coordinate for MD2 format (1.0 - v)
//         md2_model.texcoords[i].s = cast(s16)(uv.x * cast(float32)md2_model.skin_width);
//         md2_model.texcoords[i].t = cast(s16)((1.0 - uv.y) * cast(float32)md2_model.skin_height);
//     }

//     // Convert triangles with proper texture coordinate indices
//     md2_model.triangles = NewArray(triangle_count, MD2Triangle);
//     for i: 0..triangle_count-1 {
//         base_index := i * 3;
        
//         // Vertex indices
//         md2_model.triangles[i].vertex[0] = cast(u16)primitive.indices[base_index];
//         md2_model.triangles[i].vertex[1] = cast(u16)primitive.indices[base_index + 1];
//         md2_model.triangles[i].vertex[2] = cast(u16)primitive.indices[base_index + 2];
        
//         // Texture coordinate indices (separate from vertex indices)
//         if texcoord_indices.count >= (base_index + 3) {
//             md2_model.triangles[i].texcoord_indice[0] = texcoord_indices[base_index];
//             md2_model.triangles[i].texcoord_indice[1] = texcoord_indices[base_index + 1];
//             md2_model.triangles[i].texcoord_indice[2] = texcoord_indices[base_index + 2];
//         } else {
//             // Fallback
//             md2_model.triangles[i].texcoord_indice[0] = 0;
//             md2_model.triangles[i].texcoord_indice[1] = 0;
//             md2_model.triangles[i].texcoord_indice[2] = 0;
//         }
//     }

//     // Clean up temporary arrays
//     array_free(unique_texcoords);
//     array_free(texcoord_indices);

//     // Convert frames
//     frame_count := 1;
    
//     // Check if we have morph targets for animation frames
//     if mesh.morph_targets.count > 0 {
//         frame_count = mesh.morph_targets.count + 1; // +1 for base mesh
//     }
    
//     // Check if we have animation data that could represent frame animation
//     if scene.animations.count > 0 {
//         for animation: scene.animations {
//             for channel: animation.channels {
//                 if channel.target_type == .CUSTOM && channel.custom_target_name == "frame_animation" {
//                     frame_count = max(frame_count, channel.float_keyframes.count);
//                 }
//             }
//         }
//     }

//     md2_model.frames = NewArray(frame_count, MD2Frame);

//     // Convert base frame (frame 0)
//     success := convert_frame_to_md2(*md2_model.frames[0], position_attr, normal_attr, vertex_count, "base");
//     if !success {
//         cleanup_md2_model(*md2_model);
//         return false;
//     }

//     // Convert additional frames from morph targets
//     // if mesh.morph_targets.count > 0 {
//     //     for morph_target, i: mesh.morph_targets {
//     //         if i + 1 >= frame_count break;
            
//     //         morph_position_attr := find_morph_attribute(morph_target, .POSITION);
//     //         if morph_position_attr {
//     //             frame_name := morph_target.name;
//     //             if frame_name.count == 0 {
//     //                 frame_name = tprint("frame_%", i + 1);
//     //             }
                
//     //             success = convert_frame_to_md2(*md2_model.frames[i + 1], morph_position_attr, vertex_count, frame_name);
//     //             if !success {
//     //                 cleanup_md2_model(*md2_model);
//     //                 return false;
//     //             }
//     //         }
//     //     }
//     // }

//     // Write MD2 file
//     success = write_md2_file(md2_model, output_file);
    
//     cleanup_md2_model(*md2_model);
//     return success;
// }
convert_ir_to_md2 :: (scene: Scene, output_file: string) -> bool {
    if scene.meshes.count == 0 {
        log("No meshes found in scene", flags=.ERROR);
        return false;
    }

    mesh := scene.meshes[0];
    if mesh.primitives.count == 0 {
        log("No primitives found in mesh", flags=.ERROR);
        return false;
    }

    primitive := mesh.primitives[0];
    
    position_attr := find_attribute(primitive, .POSITION);
    normal_attr := find_attribute(primitive, .NORMAL);
    texcoord_attr := find_attribute(primitive, .TEXCOORD_0);
    
    if !position_attr {
        log("No position attribute found", flags=.ERROR);
        return false;
    }

    vertex_count := position_attr.data.count;
    triangle_count := primitive.indices.count / 3;

    md2_model: MD2Model;

    // Set texture dimensions
    if scene.textures.count > 0 {
        first_texture := scene.textures[0];
        md2_model.skin_width = first_texture.width;
        md2_model.skin_height = first_texture.height;
    } else {
        md2_model.skin_width = 256;
        md2_model.skin_height = 256;
    }

    // Convert skins
    md2_model.skins = NewArray(max(1, scene.textures.count), MD2Skin);
    if scene.textures.count > 0 {
        for texture, i: scene.textures {
            if i >= md2_model.skins.count break;
            name_length := min(texture.name.count, 63);
            memcpy(md2_model.skins[i].name.data, texture.name.data, name_length);
            md2_model.skins[i].name[name_length] = 0;
        }
    } else {
        default_name := "default.pcx";
        memcpy(md2_model.skins[0].name.data, default_name.data, default_name.count);
        md2_model.skins[0].name[default_name.count] = 0;
    }

    // Convert texture coordinates - Direct mapping, no seam re-processing
    md2_model.texcoords = NewArray(vertex_count, MD2TexCoord);
    if texcoord_attr {
        for i: 0..vertex_count-1 {
            uv := texcoord_attr.data[i].vec2_value;
            
            // Convert to MD2 format without additional seam processing
            // The seams have already been handled in the MDL->IR conversion
            md2_model.texcoords[i].s = cast(s16)(uv.x * cast(float32)md2_model.skin_width);
            md2_model.texcoords[i].t = cast(s16)(uv.y * cast(float32)md2_model.skin_height);
        }
    } else {
        for i: 0..vertex_count-1 {
            md2_model.texcoords[i].s = 0;
            md2_model.texcoords[i].t = 0;
        }
    }

    // Convert triangles - Simple 1:1 mapping since we've already expanded vertices
    md2_model.triangles = NewArray(triangle_count, MD2Triangle);
    for i: 0..triangle_count-1 {
        base_index := i * 3;
        
        // Both vertex and texture coordinate indices are the same
        // since we expanded vertices to handle seams
        md2_model.triangles[i].vertex[0] = cast(u16)primitive.indices[base_index];
        md2_model.triangles[i].vertex[1] = cast(u16)primitive.indices[base_index + 1];
        md2_model.triangles[i].vertex[2] = cast(u16)primitive.indices[base_index + 2];
        
        md2_model.triangles[i].texcoord_indice[0] = cast(u16)primitive.indices[base_index];
        md2_model.triangles[i].texcoord_indice[1] = cast(u16)primitive.indices[base_index + 1];
        md2_model.triangles[i].texcoord_indice[2] = cast(u16)primitive.indices[base_index + 2];
    }

    // Convert frames
    md2_model.frames = NewArray(1, MD2Frame);
    
    success := convert_frame_to_md2(*md2_model.frames[0], position_attr, normal_attr, vertex_count, "base");
    if !success {
        cleanup_md2_model(*md2_model);
        return false;
    }

    // Write MD2 file
    success = write_md2_file(md2_model, output_file);
    
    cleanup_md2_model(*md2_model);
    return success;
}

// Add hash function for VertexKey
// operator == :: (a: VertexKey, b: VertexKey) -> bool {
//     return a.vertex_index == b.vertex_index && 
//            a.texcoord_index == b.texcoord_index && 
//            a.is_seam_vertex == b.is_seam_vertex && 
//            a.is_back_face == b.is_back_face;
// }

VertexKeyCompare :: (a: VertexKey, b: VertexKey) -> bool {
    return a.vertex_index == b.vertex_index && 
           a.texcoord_index == b.texcoord_index && 
           a.is_seam_vertex == b.is_seam_vertex && 
           a.is_back_face == b.is_back_face;
}

get_hash :: (key: VertexKey) -> u32 {
    hash: u32 = 0;
    hash = hash * 31 + key.vertex_index;
    hash = hash * 31 + key.texcoord_index;
    hash = hash * 31 + cast(u32)key.is_seam_vertex;
    hash = hash * 31 + cast(u32)key.is_back_face;
    return hash;
}

// Helper function to find vertex attribute by type
find_attribute :: (primitive: Primitive, attr_type: AttributeType) -> *VertexAttribute {
    for *attr: primitive.attributes {
        if attr.type == attr_type {
            return attr;
        }
    }
    return null;
}

// Helper function to find morph target attribute by type
find_morph_attribute :: (morph_target: MorphTarget, attr_type: AttributeType) -> *VertexAttribute {
    for *attr: morph_target.attributes {
        if attr.type == attr_type {
            return attr;
        }
    }
    return null;
}

// Helper function to convert a frame's vertex data to MD2 format
convert_frame_to_md2 :: (frame: *MD2Frame, position_attr: *VertexAttribute, normal_attr: *VertexAttribute, vertex_count: int, frame_name: string) -> bool {
    if position_attr.data.count != vertex_count {
        log("Position attribute vertex count mismatch", flags=.ERROR);
        return false;
    }

    // Calculate bounding box for scale and translate
    min_pos := Vector3_Float32.{9999.0, 9999.0, 9999.0};
    max_pos := Vector3_Float32.{-9999.0, -9999.0, -9999.0};

    for i: 0..vertex_count-1 {
        pos := position_attr.data[i].vec3_value;
        min_pos.x = min(min_pos.x, pos.x);
        min_pos.y = min(min_pos.y, pos.y);
        min_pos.z = min(min_pos.z, pos.z);
        max_pos.x = max(max_pos.x, pos.x);
        max_pos.y = max(max_pos.y, pos.y);
        max_pos.z = max(max_pos.z, pos.z);
    }

    vec_minus :: (a: Vector3_Float32, b: Vector3_Float32) -> Vector3_Float32 {
        result: Vector3_Float32;
        result.x = a.x - b.x;
        result.y = a.y - b.y;
        result.z = a.z - b.z;

        return result;
    }

    // Calculate scale and translate for compression
    range := vec_minus(max_pos, min_pos);//max_pos - min_pos;
    frame.scale.x = range.x / 255.0;
    frame.scale.y = range.y / 255.0;
    frame.scale.z = range.z / 255.0;
    frame.translate = min_pos;

    // Handle zero scale (when all vertices have same coordinate)
    if frame.scale.x == 0.0 frame.scale.x = 1.0;
    if frame.scale.y == 0.0 frame.scale.y = 1.0;
    if frame.scale.z == 0.0 frame.scale.z = 1.0;

    // Set frame name
    name_length := min(frame_name.count, 15);
    memcpy(frame.name.data, frame_name.data, name_length);
    frame.name[name_length] = 0; // Null terminate

    // Convert vertices
    frame.vertices = NewArray(vertex_count, MD2Vertex);
    for i: 0..vertex_count-1 {
        pos := position_attr.data[i].vec3_value;
        
        // Compress position to u8 range
        compressed_pos: Vector3_U8;
        compressed_pos.x = cast(u8)((pos.x - frame.translate.x) / frame.scale.x);
        compressed_pos.y = cast(u8)((pos.y - frame.translate.y) / frame.scale.y);
        compressed_pos.z = cast(u8)((pos.z - frame.translate.z) / frame.scale.z);
        
        frame.vertices[i].pos = compressed_pos;
        
        if normal_attr {
            normal_vec := normal_attr.data[i].vec3_value;
            // Find closest normal in MD2 normal table (similar to anorms_table)
            frame.vertices[i].normal_index = find_closest_normal_index(normal_vec);
        }
        // // Set default normal index (pointing up)
        // frame.vertices[i].normal_index = 0; // You might want to calculate proper normals
    }

    return true;
}

// Helper function to write MD2 file
write_md2_file :: (md2_model: MD2Model, filename: string) -> bool {
    file, success := file_open(filename, true);
    if !success {
        log("Failed to open output file", flags=.ERROR);
        return false;
    }
    defer file_close(*file);

    // Calculate header values
    header: MD2Header;
    header.id = .[#char "I", #char "D", #char "P", #char "2"];
    header.version = 8;
    header.texture_width = md2_model.skin_width;
    header.texture_height = md2_model.skin_height;
    header.skin_count = cast(s32)md2_model.skins.count;
    header.vertex_count = cast(s32)md2_model.frames[0].vertices.count;
    header.texture_coordinate_count = cast(s32)md2_model.texcoords.count;
    header.triangle_count = cast(s32)md2_model.triangles.count;
    header.frame_count = cast(s32)md2_model.frames.count;
    header.gl_commands_count = 0; // Not implementing GL commands

    // Calculate frame size
    header.frame_size = cast(s32)(size_of(Vector3_Float32) * 2 + 16 + size_of(MD2Vertex) * header.vertex_count);

    // Calculate offsets
    current_offset := size_of(MD2Header);
    
    header.skin_offset = cast(s32)current_offset;
    current_offset += size_of(MD2Skin) * header.skin_count;
    
    header.texture_coordinate_offset = cast(s32)current_offset;
    current_offset += size_of(MD2TexCoord) * header.texture_coordinate_count;
    
    header.triangle_offset = cast(s32)current_offset;
    current_offset += size_of(MD2Triangle) * header.triangle_count;
    
    header.frame_offset = cast(s32)current_offset;
    current_offset += header.frame_size * header.frame_count;
    
    header.gl_commands_offset = cast(s32)current_offset;
    header.eof_offset = cast(s32)current_offset;

    // Write header
    write_success := file_write(*file, *header, size_of(MD2Header));
    if !write_success {
        log("Failed to write header", flags=.ERROR);
        return false;
    }

    // Write skins
    write_success = file_write(*file, md2_model.skins.data, size_of(MD2Skin) * md2_model.skins.count);
    if !write_success {
        log("Failed to write skins", flags=.ERROR);
        return false;
    }

    // Write texture coordinates
    write_success = file_write(*file, md2_model.texcoords.data, size_of(MD2TexCoord) * md2_model.texcoords.count);
    if !write_success {
        log("Failed to write texture coordinates", flags=.ERROR);
        return false;
    }

    // Write triangles
    write_success = file_write(*file, md2_model.triangles.data, size_of(MD2Triangle) * md2_model.triangles.count);
    if !write_success {
        log("Failed to write triangles", flags=.ERROR);
        return false;
    }

    // Write frames
    for frame: md2_model.frames {
        // Write frame header (scale, translate, name)
        write_success = file_write(*file, *frame.scale, size_of(Vector3_Float32));
        if !write_success {
            log("Failed to write frame scale", flags=.ERROR);
            return false;
        }

        write_success = file_write(*file, *frame.translate, size_of(Vector3_Float32));
        if !write_success {
            log("Failed to write frame translate", flags=.ERROR);
            return false;
        }

        write_success = file_write(*file, frame.name.data, 16);
        if !write_success {
            log("Failed to write frame name", flags=.ERROR);
            return false;
        }

        // Write frame vertices
        write_success = file_write(*file, frame.vertices.data, size_of(MD2Vertex) * frame.vertices.count);
        if !write_success {
            log("Failed to write frame vertices", flags=.ERROR);
            return false;
        }
    }

    return true;
}

// Helper function to cleanup MD2Model
cleanup_md2_model :: (md2_model: *MD2Model) {
    array_free(md2_model.skins);
    array_free(md2_model.texcoords);
    array_free(md2_model.triangles);
    
    for *frame: md2_model.frames {
        array_free(frame.vertices);
    }
    array_free(md2_model.frames);
}

find_closest_normal_index :: (normal: Vector3_Float32) -> u8 {
    // MD2 normal table
    // You can either embed the full table here or use a simplified approach
    best_index := 0;
    best_dot := -1.0;
    
    // Normalize the input normal
    length := sqrt(normal.x*normal.x + normal.y*normal.y + normal.z*normal.z);
    if length < 0.0001 return 0;  // Default to first normal if zero length
    
    normalized := Vector3_Float32.{
        normal.x / length,
        normal.y / length,
        normal.z / length
    };
    
    // Find the closest normal in the MD2 normal table using dot product
    for normal_index: 0..161 {
        md2_normal := anorms_table[normal_index];
        dot := normalized.x * md2_normal.x + normalized.y * md2_normal.y + normalized.z * md2_normal.z;
        
        if dot > best_dot {
            best_dot = dot;
            best_index = normal_index;
        }
    }
    
    return cast(u8)best_index;
}