#scope_file

#load "ir/ir.jai";
#load "ir/vertex_attributes.jai";

#scope_export

#load "converters/common.jai";
#load "converters/mdl_to_ir.jai";
#load "converters/ir_to_md2.jai";

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