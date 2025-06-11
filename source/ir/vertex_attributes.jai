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