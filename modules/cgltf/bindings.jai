//
// This file was auto-generated using the following command:
//
// jai generate.jai - -compile
//



cgltf_file_type :: enum s32 {
    invalid  :: 0;
    gltf     :: 1;
    glb      :: 2;
    max_enum :: 3;

    cgltf_file_type_invalid  :: invalid;
    cgltf_file_type_gltf     :: gltf;
    cgltf_file_type_glb      :: glb;
    cgltf_file_type_max_enum :: max_enum;
}

cgltf_result :: enum s32 {
    success         :: 0;
    data_too_short  :: 1;
    unknown_format  :: 2;
    invalid_json    :: 3;
    invalid_gltf    :: 4;
    invalid_options :: 5;
    file_not_found  :: 6;
    io_error        :: 7;
    out_of_memory   :: 8;
    legacy_gltf     :: 9;
    max_enum        :: 10;

    cgltf_result_success         :: success;
    cgltf_result_data_too_short  :: data_too_short;
    cgltf_result_unknown_format  :: unknown_format;
    cgltf_result_invalid_json    :: invalid_json;
    cgltf_result_invalid_gltf    :: invalid_gltf;
    cgltf_result_invalid_options :: invalid_options;
    cgltf_result_file_not_found  :: file_not_found;
    cgltf_result_io_error        :: io_error;
    cgltf_result_out_of_memory   :: out_of_memory;
    cgltf_result_legacy_gltf     :: legacy_gltf;
    cgltf_result_max_enum        :: max_enum;
}

cgltf_memory_options :: struct {
    alloc_func: #type (user: *void, size: u64) -> *void #c_call;
    free_func:  #type (user: *void, ptr: *void) -> void #c_call;
    user_data:  *void;
}

cgltf_file_options :: struct {
    read:      #type (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, path: *u8, size: *u64, data: **void) -> cgltf_result #c_call;
    release:   #type (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, data: *void) -> void #c_call;
    user_data: *void;
}

cgltf_options :: struct {
    type:             cgltf_file_type; /* invalid == auto detect */
    json_token_count: u64; /* 0 == auto */
    memory:           cgltf_memory_options;
    file:             cgltf_file_options;
}

cgltf_buffer_view_type :: enum s32 {
    invalid  :: 0;
    indices  :: 1;
    vertices :: 2;
    max_enum :: 3;

    cgltf_buffer_view_type_invalid  :: invalid;
    cgltf_buffer_view_type_indices  :: indices;
    cgltf_buffer_view_type_vertices :: vertices;
    cgltf_buffer_view_type_max_enum :: max_enum;
}

cgltf_attribute_type :: enum s32 {
    invalid  :: 0;
    position :: 1;
    normal   :: 2;
    tangent  :: 3;
    texcoord :: 4;
    color    :: 5;
    joints   :: 6;
    weights  :: 7;
    custom   :: 8;
    max_enum :: 9;

    cgltf_attribute_type_invalid  :: invalid;
    cgltf_attribute_type_position :: position;
    cgltf_attribute_type_normal   :: normal;
    cgltf_attribute_type_tangent  :: tangent;
    cgltf_attribute_type_texcoord :: texcoord;
    cgltf_attribute_type_color    :: color;
    cgltf_attribute_type_joints   :: joints;
    cgltf_attribute_type_weights  :: weights;
    cgltf_attribute_type_custom   :: custom;
    cgltf_attribute_type_max_enum :: max_enum;
}

cgltf_component_type :: enum s32 {
    invalid  :: 0;
    r_8      :: 1;
    r_8u     :: 2;
    r_16     :: 3;
    r_16u    :: 4;
    r_32u    :: 5;
    r_32f    :: 6;
    max_enum :: 7;

    cgltf_component_type_invalid  :: invalid;
    cgltf_component_type_r_8      :: r_8;
    cgltf_component_type_r_8u     :: r_8u;
    cgltf_component_type_r_16     :: r_16;
    cgltf_component_type_r_16u    :: r_16u;
    cgltf_component_type_r_32u    :: r_32u;
    cgltf_component_type_r_32f    :: r_32f;
    cgltf_component_type_max_enum :: max_enum;
}

cgltf_type :: enum s32 {
    invalid  :: 0;
    scalar   :: 1;
    vec2     :: 2;
    vec3     :: 3;
    vec4     :: 4;
    mat2     :: 5;
    mat3     :: 6;
    mat4     :: 7;
    max_enum :: 8;

    cgltf_type_invalid  :: invalid;
    cgltf_type_scalar   :: scalar;
    cgltf_type_vec2     :: vec2;
    cgltf_type_vec3     :: vec3;
    cgltf_type_vec4     :: vec4;
    cgltf_type_mat2     :: mat2;
    cgltf_type_mat3     :: mat3;
    cgltf_type_mat4     :: mat4;
    cgltf_type_max_enum :: max_enum;
}

cgltf_primitive_type :: enum s32 {
    invalid        :: 0;
    points         :: 1;
    lines          :: 2;
    line_loop      :: 3;
    line_strip     :: 4;
    triangles      :: 5;
    triangle_strip :: 6;
    triangle_fan   :: 7;
    max_enum       :: 8;

    cgltf_primitive_type_invalid        :: invalid;
    cgltf_primitive_type_points         :: points;
    cgltf_primitive_type_lines          :: lines;
    cgltf_primitive_type_line_loop      :: line_loop;
    cgltf_primitive_type_line_strip     :: line_strip;
    cgltf_primitive_type_triangles      :: triangles;
    cgltf_primitive_type_triangle_strip :: triangle_strip;
    cgltf_primitive_type_triangle_fan   :: triangle_fan;
    cgltf_primitive_type_max_enum       :: max_enum;
}

cgltf_alpha_mode :: enum s32 {
    opaque   :: 0;
    mask     :: 1;
    blend    :: 2;
    max_enum :: 3;

    cgltf_alpha_mode_opaque   :: opaque;
    cgltf_alpha_mode_mask     :: mask;
    cgltf_alpha_mode_blend    :: blend;
    cgltf_alpha_mode_max_enum :: max_enum;
}

cgltf_animation_path_type :: enum s32 {
    invalid     :: 0;
    translation :: 1;
    rotation    :: 2;
    scale       :: 3;
    weights     :: 4;
    max_enum    :: 5;

    cgltf_animation_path_type_invalid     :: invalid;
    cgltf_animation_path_type_translation :: translation;
    cgltf_animation_path_type_rotation    :: rotation;
    cgltf_animation_path_type_scale       :: scale;
    cgltf_animation_path_type_weights     :: weights;
    cgltf_animation_path_type_max_enum    :: max_enum;
}

cgltf_interpolation_type :: enum s32 {
    linear       :: 0;
    step         :: 1;
    cubic_spline :: 2;
    max_enum     :: 3;

    cgltf_interpolation_type_linear       :: linear;
    cgltf_interpolation_type_step         :: step;
    cgltf_interpolation_type_cubic_spline :: cubic_spline;
    cgltf_interpolation_type_max_enum     :: max_enum;
}

cgltf_camera_type :: enum s32 {
    invalid      :: 0;
    perspective  :: 1;
    orthographic :: 2;
    max_enum     :: 3;

    cgltf_camera_type_invalid      :: invalid;
    cgltf_camera_type_perspective  :: perspective;
    cgltf_camera_type_orthographic :: orthographic;
    cgltf_camera_type_max_enum     :: max_enum;
}

cgltf_light_type :: enum s32 {
    invalid     :: 0;
    directional :: 1;
    point       :: 2;
    spot        :: 3;
    max_enum    :: 4;

    cgltf_light_type_invalid     :: invalid;
    cgltf_light_type_directional :: directional;
    cgltf_light_type_point       :: point;
    cgltf_light_type_spot        :: spot;
    cgltf_light_type_max_enum    :: max_enum;
}

cgltf_data_free_method :: enum s32 {
    none         :: 0;
    file_release :: 1;
    memory_free  :: 2;
    max_enum     :: 3;

    cgltf_data_free_method_none         :: none;
    cgltf_data_free_method_file_release :: file_release;
    cgltf_data_free_method_memory_free  :: memory_free;
    cgltf_data_free_method_max_enum     :: max_enum;
}

cgltf_extras :: struct {
    start_offset: u64; /* this field is deprecated and will be removed in the future; use data instead */
    end_offset:   u64; /* this field is deprecated and will be removed in the future; use data instead */

    data:         *u8;
}

cgltf_extension :: struct {
    name: *u8;
    data: *u8;
}

cgltf_buffer :: struct {
    name:             *u8;
    size:             u64;
    uri:              *u8;
    data:             *void; /* loaded by cgltf_load_buffers */
    data_free_method: cgltf_data_free_method;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_meshopt_compression_mode :: enum s32 {
    invalid    :: 0;
    attributes :: 1;
    triangles  :: 2;
    indices    :: 3;
    max_enum   :: 4;

    cgltf_meshopt_compression_mode_invalid    :: invalid;
    cgltf_meshopt_compression_mode_attributes :: attributes;
    cgltf_meshopt_compression_mode_triangles  :: triangles;
    cgltf_meshopt_compression_mode_indices    :: indices;
    cgltf_meshopt_compression_mode_max_enum   :: max_enum;
}

cgltf_meshopt_compression_filter :: enum s32 {
    none        :: 0;
    octahedral  :: 1;
    quaternion  :: 2;
    exponential :: 3;
    max_enum    :: 4;

    cgltf_meshopt_compression_filter_none        :: none;
    cgltf_meshopt_compression_filter_octahedral  :: octahedral;
    cgltf_meshopt_compression_filter_quaternion  :: quaternion;
    cgltf_meshopt_compression_filter_exponential :: exponential;
    cgltf_meshopt_compression_filter_max_enum    :: max_enum;
}

cgltf_meshopt_compression :: struct {
    buffer: *cgltf_buffer;
    offset: u64;
    size:   u64;
    stride: u64;
    count:  u64;
    mode:   cgltf_meshopt_compression_mode;
    filter: cgltf_meshopt_compression_filter;
}

cgltf_buffer_view :: struct {
    name:                    *u8;
    buffer:                  *cgltf_buffer;
    offset:                  u64;
    size:                    u64;
    stride:                  u64; /* 0 == automatically determined by accessor */
    type:                    cgltf_buffer_view_type;
    data:                    *void; /* overrides buffer->data if present, filled by extensions */
    has_meshopt_compression: s32;
    meshopt_compression:     cgltf_meshopt_compression;
    extras:                  cgltf_extras;
    extensions_count:        u64;
    extensions:              *cgltf_extension;
}

cgltf_accessor_sparse :: struct {
    count:                  u64;
    indices_buffer_view:    *cgltf_buffer_view;
    indices_byte_offset:    u64;
    indices_component_type: cgltf_component_type;
    values_buffer_view:     *cgltf_buffer_view;
    values_byte_offset:     u64;
}

cgltf_accessor :: struct {
    name:             *u8;
    component_type:   cgltf_component_type;
    normalized:       s32;
    type:             cgltf_type;
    offset:           u64;
    count:            u64;
    stride:           u64;
    buffer_view:      *cgltf_buffer_view;
    has_min:          s32;
    min:              [16] float;
    has_max:          s32;
    max:              [16] float;
    is_sparse:        s32;
    sparse:           cgltf_accessor_sparse;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_attribute :: struct {
    name:  *u8;
    type:  cgltf_attribute_type;
    index: s32;
    data:  *cgltf_accessor;
}

cgltf_image :: struct {
    name:             *u8;
    uri:              *u8;
    buffer_view:      *cgltf_buffer_view;
    mime_type:        *u8;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_filter_type :: enum s32 {
    undefined              :: 0;
    nearest                :: 9728;
    linear                 :: 9729;
    nearest_mipmap_nearest :: 9984;
    linear_mipmap_nearest  :: 9985;
    nearest_mipmap_linear  :: 9986;
    linear_mipmap_linear   :: 9987;

    cgltf_filter_type_undefined              :: undefined;
    cgltf_filter_type_nearest                :: nearest;
    cgltf_filter_type_linear                 :: linear;
    cgltf_filter_type_nearest_mipmap_nearest :: nearest_mipmap_nearest;
    cgltf_filter_type_linear_mipmap_nearest  :: linear_mipmap_nearest;
    cgltf_filter_type_nearest_mipmap_linear  :: nearest_mipmap_linear;
    cgltf_filter_type_linear_mipmap_linear   :: linear_mipmap_linear;
}

cgltf_wrap_mode :: enum s32 {
    clamp_to_edge   :: 33071;
    mirrored_repeat :: 33648;
    repeat          :: 10497;

    cgltf_wrap_mode_clamp_to_edge   :: clamp_to_edge;
    cgltf_wrap_mode_mirrored_repeat :: mirrored_repeat;
    cgltf_wrap_mode_repeat          :: repeat;
}

cgltf_sampler :: struct {
    name:             *u8;
    mag_filter:       cgltf_filter_type;
    min_filter:       cgltf_filter_type;
    wrap_s:           cgltf_wrap_mode;
    wrap_t:           cgltf_wrap_mode;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_texture :: struct {
    name:             *u8;
    image:            *cgltf_image;
    sampler:          *cgltf_sampler;
    has_basisu:       s32;
    basisu_image:     *cgltf_image;
    has_webp:         s32;
    webp_image:       *cgltf_image;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_texture_transform :: struct {
    offset:       [2] float;
    rotation:     float;
    scale:        [2] float;
    has_texcoord: s32;
    texcoord:     s32;
}

cgltf_texture_view :: struct {
    texture:       *cgltf_texture;
    texcoord:      s32;
    scale:         float; /* equivalent to strength for occlusion_texture */
    has_transform: s32;
    transform:     cgltf_texture_transform;
}

cgltf_pbr_metallic_roughness :: struct {
    base_color_texture:         cgltf_texture_view;
    metallic_roughness_texture: cgltf_texture_view;

    base_color_factor:          [4] float;
    metallic_factor:            float;
    roughness_factor:           float;
}

cgltf_pbr_specular_glossiness :: struct {
    diffuse_texture:             cgltf_texture_view;
    specular_glossiness_texture: cgltf_texture_view;

    diffuse_factor:              [4] float;
    specular_factor:             [3] float;
    glossiness_factor:           float;
}

cgltf_clearcoat :: struct {
    clearcoat_texture:           cgltf_texture_view;
    clearcoat_roughness_texture: cgltf_texture_view;
    clearcoat_normal_texture:    cgltf_texture_view;

    clearcoat_factor:            float;
    clearcoat_roughness_factor:  float;
}

cgltf_transmission :: struct {
    transmission_texture: cgltf_texture_view;
    transmission_factor:  float;
}

cgltf_ior :: struct {
    ior: float;
}

cgltf_specular :: struct {
    specular_texture:       cgltf_texture_view;
    specular_color_texture: cgltf_texture_view;
    specular_color_factor:  [3] float;
    specular_factor:        float;
}

cgltf_volume :: struct {
    thickness_texture:    cgltf_texture_view;
    thickness_factor:     float;
    attenuation_color:    [3] float;
    attenuation_distance: float;
}

cgltf_sheen :: struct {
    sheen_color_texture:     cgltf_texture_view;
    sheen_color_factor:      [3] float;
    sheen_roughness_texture: cgltf_texture_view;
    sheen_roughness_factor:  float;
}

cgltf_emissive_strength :: struct {
    emissive_strength: float;
}

cgltf_iridescence :: struct {
    iridescence_factor:            float;
    iridescence_texture:           cgltf_texture_view;
    iridescence_ior:               float;
    iridescence_thickness_min:     float;
    iridescence_thickness_max:     float;
    iridescence_thickness_texture: cgltf_texture_view;
}

cgltf_diffuse_transmission :: struct {
    diffuse_transmission_texture:       cgltf_texture_view;
    diffuse_transmission_factor:        float;
    diffuse_transmission_color_factor:  [3] float;
    diffuse_transmission_color_texture: cgltf_texture_view;
}

cgltf_anisotropy :: struct {
    anisotropy_strength: float;
    anisotropy_rotation: float;
    anisotropy_texture:  cgltf_texture_view;
}

cgltf_dispersion :: struct {
    dispersion: float;
}

cgltf_material :: struct {
    name:                        *u8;
    has_pbr_metallic_roughness:  s32;
    has_pbr_specular_glossiness: s32;
    has_clearcoat:               s32;
    has_transmission:            s32;
    has_volume:                  s32;
    has_ior:                     s32;
    has_specular:                s32;
    has_sheen:                   s32;
    has_emissive_strength:       s32;
    has_iridescence:             s32;
    has_diffuse_transmission:    s32;
    has_anisotropy:              s32;
    has_dispersion:              s32;
    pbr_metallic_roughness:      cgltf_pbr_metallic_roughness;
    pbr_specular_glossiness:     cgltf_pbr_specular_glossiness;
    clearcoat:                   cgltf_clearcoat;
    ior:                         cgltf_ior;
    specular:                    cgltf_specular;
    sheen:                       cgltf_sheen;
    transmission:                cgltf_transmission;
    volume:                      cgltf_volume;
    emissive_strength:           cgltf_emissive_strength;
    iridescence:                 cgltf_iridescence;
    diffuse_transmission:        cgltf_diffuse_transmission;
    anisotropy:                  cgltf_anisotropy;
    dispersion:                  cgltf_dispersion;
    normal_texture:              cgltf_texture_view;
    occlusion_texture:           cgltf_texture_view;
    emissive_texture:            cgltf_texture_view;
    emissive_factor:             [3] float;
    alpha_mode:                  cgltf_alpha_mode;
    alpha_cutoff:                float;
    double_sided:                s32;
    unlit:                       s32;
    extras:                      cgltf_extras;
    extensions_count:            u64;
    extensions:                  *cgltf_extension;
}

cgltf_material_mapping :: struct {
    variant:  u64;
    material: *cgltf_material;
    extras:   cgltf_extras;
}

cgltf_morph_target :: struct {
    attributes:       *cgltf_attribute;
    attributes_count: u64;
}

cgltf_draco_mesh_compression :: struct {
    buffer_view:      *cgltf_buffer_view;
    attributes:       *cgltf_attribute;
    attributes_count: u64;
}

cgltf_mesh_gpu_instancing :: struct {
    attributes:       *cgltf_attribute;
    attributes_count: u64;
}

cgltf_primitive :: struct {
    type:                       cgltf_primitive_type;
    indices:                    *cgltf_accessor;
    material:                   *cgltf_material;
    attributes:                 *cgltf_attribute;
    attributes_count:           u64;
    targets:                    *cgltf_morph_target;
    targets_count:              u64;
    extras:                     cgltf_extras;
    has_draco_mesh_compression: s32;
    draco_mesh_compression:     cgltf_draco_mesh_compression;
    mappings:                   *cgltf_material_mapping;
    mappings_count:             u64;
    extensions_count:           u64;
    extensions:                 *cgltf_extension;
}

cgltf_mesh :: struct {
    name:               *u8;
    primitives:         *cgltf_primitive;
    primitives_count:   u64;
    weights:            *float;
    weights_count:      u64;
    target_names:       **u8;
    target_names_count: u64;
    extras:             cgltf_extras;
    extensions_count:   u64;
    extensions:         *cgltf_extension;
}

cgltf_skin :: struct {
    name:                  *u8;
    joints:                **cgltf_node;
    joints_count:          u64;
    skeleton:              *cgltf_node;
    inverse_bind_matrices: *cgltf_accessor;
    extras:                cgltf_extras;
    extensions_count:      u64;
    extensions:            *cgltf_extension;
}

cgltf_camera_perspective :: struct {
    has_aspect_ratio: s32;
    aspect_ratio:     float;
    yfov:             float;
    has_zfar:         s32;
    zfar:             float;
    znear:            float;
    extras:           cgltf_extras;
}

cgltf_camera_orthographic :: struct {
    xmag:   float;
    ymag:   float;
    zfar:   float;
    znear:  float;
    extras: cgltf_extras;
}

cgltf_camera :: struct {
    name:             *u8;
    type:             cgltf_camera_type;
    data:             union {
        perspective:  cgltf_camera_perspective;
        orthographic: cgltf_camera_orthographic;
    };

    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_light :: struct {
    name:                  *u8;
    color:                 [3] float;
    intensity:             float;
    type:                  cgltf_light_type;
    range:                 float;
    spot_inner_cone_angle: float;
    spot_outer_cone_angle: float;
    extras:                cgltf_extras;
}

cgltf_node :: struct {
    name:                    *u8;
    parent:                  *cgltf_node;
    children:                **cgltf_node;
    children_count:          u64;
    skin:                    *cgltf_skin;
    mesh:                    *cgltf_mesh;
    camera:                  *cgltf_camera;
    light:                   *cgltf_light;
    weights:                 *float;
    weights_count:           u64;
    has_translation:         s32;
    has_rotation:            s32;
    has_scale:               s32;
    has_matrix:              s32;
    translation:             [3] float;
    rotation:                [4] float;
    scale:                   [3] float;
    matrix:                  [16] float;
    extras:                  cgltf_extras;
    has_mesh_gpu_instancing: s32;
    mesh_gpu_instancing:     cgltf_mesh_gpu_instancing;
    extensions_count:        u64;
    extensions:              *cgltf_extension;
}

cgltf_scene :: struct {
    name:             *u8;
    nodes:            **cgltf_node;
    nodes_count:      u64;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_animation_sampler :: struct {
    input:            *cgltf_accessor;
    output:           *cgltf_accessor;
    interpolation:    cgltf_interpolation_type;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_animation_channel :: struct {
    sampler:          *cgltf_animation_sampler;
    target_node:      *cgltf_node;
    target_path:      cgltf_animation_path_type;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_animation :: struct {
    name:             *u8;
    samplers:         *cgltf_animation_sampler;
    samplers_count:   u64;
    channels:         *cgltf_animation_channel;
    channels_count:   u64;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_material_variant :: struct {
    name:   *u8;
    extras: cgltf_extras;
}

cgltf_asset :: struct {
    copyright:        *u8;
    generator:        *u8;
    version:          *u8;
    min_version:      *u8;
    extras:           cgltf_extras;
    extensions_count: u64;
    extensions:       *cgltf_extension;
}

cgltf_data :: struct {
    file_type:                 cgltf_file_type;
    file_data:                 *void;

    asset:                     cgltf_asset;

    meshes:                    *cgltf_mesh;
    meshes_count:              u64;

    materials:                 *cgltf_material;
    materials_count:           u64;

    accessors:                 *cgltf_accessor;
    accessors_count:           u64;

    buffer_views:              *cgltf_buffer_view;
    buffer_views_count:        u64;

    buffers:                   *cgltf_buffer;
    buffers_count:             u64;

    images:                    *cgltf_image;
    images_count:              u64;

    textures:                  *cgltf_texture;
    textures_count:            u64;

    samplers:                  *cgltf_sampler;
    samplers_count:            u64;

    skins:                     *cgltf_skin;
    skins_count:               u64;

    cameras:                   *cgltf_camera;
    cameras_count:             u64;

    lights:                    *cgltf_light;
    lights_count:              u64;

    nodes:                     *cgltf_node;
    nodes_count:               u64;

    scenes:                    *cgltf_scene;
    scenes_count:              u64;

    scene:                     *cgltf_scene;

    animations:                *cgltf_animation;
    animations_count:          u64;

    variants:                  *cgltf_material_variant;
    variants_count:            u64;

    extras:                    cgltf_extras;

    data_extensions_count:     u64;
    data_extensions:           *cgltf_extension;

    extensions_used:           **u8;
    extensions_used_count:     u64;

    extensions_required:       **u8;
    extensions_required_count: u64;

    json:                      *u8;
    json_size:                 u64;

    bin:                       *void;
    bin_size:                  u64;

    memory:                    cgltf_memory_options;
    file:                      cgltf_file_options;
}

cgltf_parse :: (options: *cgltf_options, data: *void, size: u64, out_data: **cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_parse_file :: (options: *cgltf_options, path: *u8, out_data: **cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_load_buffers :: (options: *cgltf_options, data: *cgltf_data, gltf_path: *u8) -> cgltf_result #foreign cgltf;

cgltf_load_buffer_base64 :: (options: *cgltf_options, size: u64, base64: *u8, out_data: **void) -> cgltf_result #foreign cgltf;

cgltf_decode_string :: (_string: *u8) -> u64 #foreign cgltf;
cgltf_decode_uri :: (uri: *u8) -> u64 #foreign cgltf;

cgltf_validate :: (data: *cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_free :: (data: *cgltf_data) -> void #foreign cgltf;

cgltf_node_transform_local :: (node: *cgltf_node, out_matrix: *float) -> void #foreign cgltf;
cgltf_node_transform_world :: (node: *cgltf_node, out_matrix: *float) -> void #foreign cgltf;

cgltf_buffer_view_data :: (view: *cgltf_buffer_view) -> *u8 #foreign cgltf;

cgltf_find_accessor :: (prim: *cgltf_primitive, type: cgltf_attribute_type, index: s32) -> *cgltf_accessor #foreign cgltf;

cgltf_accessor_read_float :: (accessor: *cgltf_accessor, index: u64, out: *float, element_size: u64) -> s32 #foreign cgltf;
cgltf_accessor_read_uint :: (accessor: *cgltf_accessor, index: u64, out: *u32, element_size: u64) -> s32 #foreign cgltf;
cgltf_accessor_read_index :: (accessor: *cgltf_accessor, index: u64) -> u64 #foreign cgltf;

cgltf_num_components :: (type: cgltf_type) -> u64 #foreign cgltf;
cgltf_component_size :: (component_type: cgltf_component_type) -> u64 #foreign cgltf;
cgltf_calc_size :: (type: cgltf_type, component_type: cgltf_component_type) -> u64 #foreign cgltf;

cgltf_accessor_unpack_floats :: (accessor: *cgltf_accessor, out: *float, float_count: u64) -> u64 #foreign cgltf;
cgltf_accessor_unpack_indices :: (accessor: *cgltf_accessor, out: *void, out_component_size: u64, index_count: u64) -> u64 #foreign cgltf;

/* this function is deprecated and will be removed in the future; use cgltf_extras::data instead */
cgltf_copy_extras_json :: (data: *cgltf_data, extras: *cgltf_extras, dest: *u8, dest_size: *u64) -> cgltf_result #foreign cgltf;

cgltf_mesh_index :: (data: *cgltf_data, object: *cgltf_mesh) -> u64 #foreign cgltf;
cgltf_material_index :: (data: *cgltf_data, object: *cgltf_material) -> u64 #foreign cgltf;
cgltf_accessor_index :: (data: *cgltf_data, object: *cgltf_accessor) -> u64 #foreign cgltf;
cgltf_buffer_view_index :: (data: *cgltf_data, object: *cgltf_buffer_view) -> u64 #foreign cgltf;
cgltf_buffer_index :: (data: *cgltf_data, object: *cgltf_buffer) -> u64 #foreign cgltf;
cgltf_image_index :: (data: *cgltf_data, object: *cgltf_image) -> u64 #foreign cgltf;
cgltf_texture_index :: (data: *cgltf_data, object: *cgltf_texture) -> u64 #foreign cgltf;
cgltf_sampler_index :: (data: *cgltf_data, object: *cgltf_sampler) -> u64 #foreign cgltf;
cgltf_skin_index :: (data: *cgltf_data, object: *cgltf_skin) -> u64 #foreign cgltf;
cgltf_camera_index :: (data: *cgltf_data, object: *cgltf_camera) -> u64 #foreign cgltf;
cgltf_light_index :: (data: *cgltf_data, object: *cgltf_light) -> u64 #foreign cgltf;
cgltf_node_index :: (data: *cgltf_data, object: *cgltf_node) -> u64 #foreign cgltf;
cgltf_scene_index :: (data: *cgltf_data, object: *cgltf_scene) -> u64 #foreign cgltf;
cgltf_animation_index :: (data: *cgltf_data, object: *cgltf_animation) -> u64 #foreign cgltf;
cgltf_animation_sampler_index :: (animation: *cgltf_animation, object: *cgltf_animation_sampler) -> u64 #foreign cgltf;
cgltf_animation_channel_index :: (animation: *cgltf_animation, object: *cgltf_animation_channel) -> u64 #foreign cgltf;

#scope_file


#if OS == .WINDOWS {
    cgltf :: #library,no_dll "windows/cgltf";
} else #if OS == .LINUX {
    cgltf :: #library,no_dll "linux/cgltf";
} else #if OS == .MACOS {
    cgltf :: #library,no_dll "macos/cgltf";
} else #if OS == .ANDROID {
    #if CPU == .X64 {
        cgltf :: #library,no_dll "android/x64/cgltf";
    } else #if CPU == .ARM64 {
        cgltf :: #library,no_dll "android/arm64/cgltf";
    }
} else #if OS == .PS5 {
    cgltf :: #library,no_dll "ps5/cgltf";
} else {
    #assert false;
}

