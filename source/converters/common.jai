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