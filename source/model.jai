Skin :: struct {
    name: string;

    skin_width: u32;
    skin_height: u32;
    skin_data: []u8;
}

AnimationFrame :: struct {
    vertices: []Vector3_GLfloat;
    normals: []Vector3_GLfloat;
    texcoords: []Vector2_GLfloat;
}

ModelAnimation :: struct {
    name: string;
    frames: [..]AnimationFrame;
}

Model :: struct {
    // vertices: []Vertex;
    animations: [..]ModelAnimation;
    vertex_count: u32;
    skins: []Skin;
    transform: *TG_RigidTransform_t;
    static_transform: Matrix4;
};

model_get_animation_names :: (model: Model) -> []string {
    names: [..]string;
    array_reserve(*names, model.animations.count);

    for model.animations {
        array_add(*names, it.name);
    }

    return names;
}

model_get_skin_names :: (model: Model) -> []string {
    names: [..]string;
    array_reserve(*names, model.skins.count);

    for model.skins {
        array_add(*names, it.name);
    }

    return names;
}

model_create_static_transform :: () -> Matrix4 {
    q: Quaternion;
    set_from_axis_and_angle(*q, 1, 0, 0, -90.0 * PI / 180.0);
    matrix := rotation_matrix(Matrix4, q);
    return matrix;
}

model_create_from_mdl :: (mdl_model: MDLModel) -> Model {
    model: Model;
    
    model.transform = TG_CreateRigidTransform();
    position := TG_Float3.{0.0, 2.0, 0.0};
    TG_SetRigidTransformPosition(model.transform, *position);

    scale := TG_Float3.{0.1, 0.1, 0.1};
    TG_SetRigidTransformScale(model.transform, *scale);

    model.static_transform = model_create_static_transform();

    model.vertex_count = xx (mdl_model.triangles.count * 3);
    model.skins = NewArray(mdl_model.images.count, Skin);
    for 0..model.skins.count - 1 {
        model.skins[it].name = copy_string(mdl_model.images[it].name);
        model.skins[it].skin_width = xx mdl_model.images[it].width;
        model.skins[it].skin_height = xx mdl_model.images[it].height;
        model.skins[it].skin_data.data = xx mdl_model.images[it].data.data;
        model.skins[it].skin_data.count = xx mdl_model.images[it].data.count;
    }

    for frame: mdl_model.frames {
        frame_name := to_string(frame.frame.name.data);
        frame_name = copy_string(trim_right(frame_name, "0123456789"));

        animation_frame: AnimationFrame;
        animation_frame.vertices = NewArray(model.vertex_count, Vector3_GLfloat);
        animation_frame.normals = NewArray(model.vertex_count, Vector3_GLfloat);
        animation_frame.texcoords = NewArray(model.vertex_count, Vector2_GLfloat);

        data_pointer_index := 0;
        for mdl_triangle: mdl_model.triangles {
            is_front_face_triangle := mdl_triangle.frontface;
            triangles: [3]GLuint;
            triangles[0] = mdl_triangle.vertex.x;
            triangles[1] = mdl_triangle.vertex.y;
            triangles[2] = mdl_triangle.vertex.z;

            for triangle: triangles {
                vert0 := mdl_model.scale.x * frame.vertices[triangle].pos.x + mdl_model.translate.x;
                vert1 := mdl_model.scale.y * frame.vertices[triangle].pos.y + mdl_model.translate.y;
                vert2 := mdl_model.scale.z * frame.vertices[triangle].pos.z + mdl_model.translate.z;

                norm0 := anorms_table[frame.vertices[triangle].normal_index % 162].x;
                norm1 := anorms_table[frame.vertices[triangle].normal_index % 162].y;
                norm2 := anorms_table[frame.vertices[triangle].normal_index % 162].z;

                is_uv_seam := mdl_model.texcoords[triangle].seam;
                is_uv_offset := !is_front_face_triangle && is_uv_seam;

                s_offset := ifx is_uv_offset 0.5 else 0.0;
                s := cast(GLfloat) (mdl_model.texcoords[triangle].s + 0.5) / cast(GLfloat)mdl_model.images[0].width;
                t := cast(GLfloat) (mdl_model.texcoords[triangle].t + 0.5) / cast(GLfloat)mdl_model.images[0].height;

                tex0 := s_offset + s;
                tex1 := t;

                animation_frame.vertices[data_pointer_index] = Vector3_GLfloat.{ vert0, vert1, vert2 };
                animation_frame.normals[data_pointer_index] = Vector3_GLfloat.{ norm0, norm1, norm2 };
                animation_frame.texcoords[data_pointer_index] = Vector2_GLfloat.{ tex0, tex1 };
                data_pointer_index += 1;
            }
        }

        // Place animation frame in the correct animation
        animation_does_exist := false;
        animation_index := -1;
        for 0..model.animations.count - 1 {
            if equal(model.animations[it].name, frame_name) {
                animation_does_exist = true;
                animation_index = it;
                break;
            }
        }

        if animation_does_exist {
            array_add(*model.animations[animation_index].frames, animation_frame);
        } else {
            animation: ModelAnimation;
            animation.name = frame_name;
            array_add(*animation.frames, animation_frame);
            array_add(*model.animations, animation);
        }
    }

    return model;
}

model_create_from_md2 :: (md2_model: MD2Model) -> Model {
    model: Model;

    model.transform = TG_CreateRigidTransform();
    position := TG_Float3.{0.0, 2.0, 0.0};
    TG_SetRigidTransformPosition(model.transform, *position);

    scale := TG_Float3.{0.1, 0.1, 0.1};
    TG_SetRigidTransformScale(model.transform, *scale);

    model.static_transform = model_create_static_transform();

    model.vertex_count = xx (md2_model.triangles.count * 3);
    model.skins = NewArray(md2_model.skins.count, Skin);
    for 0..model.skins.count - 1 {
        // TODO(Oskar): This causes some skins to have duplicate names, fix sometime..
        skin_name := to_string(md2_model.skins[it].name.data);
        found, left, right := split_from_right(skin_name, "/");
        if !found {
            model.skins[it].name = copy_string(trim(skin_name));
        } else {
            model.skins[it].name = copy_string(trim(right));
        }

        model.skins[it].skin_width = xx md2_model.images[it].width;
        model.skins[it].skin_height = xx md2_model.images[it].height;
        model.skins[it].skin_data.data = md2_model.images[it].data;
        model.skins[it].skin_data.count = xx md2_model.images[it].data_count;
    }

    for frame: md2_model.frames {
        frame_name := to_string(frame.name.data);
        frame_name = copy_string(trim_right(frame_name, "0123456789"));

        animation_frame: AnimationFrame;
        animation_frame.vertices = NewArray(model.vertex_count, Vector3_GLfloat);
        animation_frame.normals = NewArray(model.vertex_count, Vector3_GLfloat);
        animation_frame.texcoords = NewArray(model.vertex_count, Vector2_GLfloat);

        data_pointer_index := 0;
        for tri: md2_model.triangles {
            for 0..2 {
                vert0 := frame.scale.x * frame.vertices[tri.vertex[it]].pos.x + frame.translate.x;
                vert1 := frame.scale.y * frame.vertices[tri.vertex[it]].pos.y + frame.translate.y;
                vert2 := frame.scale.z * frame.vertices[tri.vertex[it]].pos.z + frame.translate.z;

                norm0 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].x;
                norm1 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].y;
                norm2 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].z;

                tex0 := cast(GLfloat) md2_model.texcoords[tri.texcoord_indice[it]].s / md2_model.skin_width;
                tex1 := cast(GLfloat) md2_model.texcoords[tri.texcoord_indice[it]].t / md2_model.skin_height;
                
                animation_frame.vertices[data_pointer_index + it] = Vector3_GLfloat.{ vert0, vert1, vert2 };
                animation_frame.normals[data_pointer_index + it] = Vector3_GLfloat.{ norm0, norm1, norm2 };
                animation_frame.texcoords[data_pointer_index + it] = Vector2_GLfloat.{ tex0, tex1 };
            }
            data_pointer_index += 3;
        }

        // Place animation frame in the correct animation
        animation_does_exist := false;
        animation_index := -1;
        for 0..model.animations.count - 1 {
            if equal(model.animations[it].name, frame_name) {
                animation_does_exist = true;
                animation_index = it;
                break;
            }
        }

        if animation_does_exist {
            array_add(*model.animations[animation_index].frames, animation_frame);
        } else {
            animation: ModelAnimation;
            animation.name = frame_name;
            array_add(*animation.frames, animation_frame);
            array_add(*model.animations, animation);
        }
    }

    return model;
}