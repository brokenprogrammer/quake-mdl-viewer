#scope_file

PCXHeader :: struct {
    manafacturer: u8;
    version: u8;
    encoding: u8;
    bits_per_pixel: u8;
    
    x: u16;
    y: u16;
    width: u16;
    height: u16;
    horzizontal_resolution: u16;
    vertical_resolution: u16;

    palette: [48]u8;
    reserved: u8;
    number_of_color_planes: u8;

    bytes_per_scan_line: u16;
    palette_type: u16;
    horizontal_size: u16;
    vertical_size: u16;

    padding: [54]u8;
};

pcx_decode_rle :: (encoded_data: []u8, decoded_size: int, header: PCXHeader) -> []u8 {
    decoded_data := NewArray(decoded_size, u8);
    source := 0;
    dest := 0;

    for 0..decoded_size - 1 {
        if source >= encoded_data.count {
            log("Unexpected end of encoded data at position %.", it, flags=.WARNING);
            return decoded_data;
        }
        
        if dest >= decoded_size {
            log("Decoded data buffer overflow at position %.", it, flags=.WARNING);
            return decoded_data;
        }

        byte: u8 = encoded_data[source];
        source += 1;
        run_length: s64 = 1;

        if ((byte & 0xC0) == 0xC0) {
            run_length = byte & 0x3F;
            byte = encoded_data[source];
            source += 1;
        }

        while run_length > 0 {
            decoded_data[dest] = byte;
            dest += 1;
            run_length -= 1;
        }
    }

    return decoded_data;
}

pcx_encode_rle :: (data: []u8, width: s32, height: s32) -> []u8 {
    encoded: [..]u8;
    
    i := 0;
    while i < data.count {
        // Look for runs of identical bytes
        run_value := data[i];
        run_start := i;
        
        while i < data.count && data[i] == run_value && i - run_start < 63 {
            i += 1;
        }
 
        run_length := i - run_start;
        
        if run_length > 1 || run_value >= 0xC0 {
            // Encode the run
            array_add(*encoded, cast(u8)(0xC0 | run_length));
            array_add(*encoded, run_value);
        } else {
            // Store the byte as-is
            array_add(*encoded, run_value);
        }
    }
    
    return encoded;
}

pcx_verify_header :: (pcx_header: PCXHeader) -> bool {
    valid := true;

    if pcx_header.manafacturer   != 10 || 
       pcx_header.version        != 5  || 
       pcx_header.encoding       != 1  || 
       pcx_header.bits_per_pixel != 8  {
        valid = false;
    }

    if pcx_header.bits_per_pixel * pcx_header.number_of_color_planes != 8 {
        valid = false;
    }

    return valid;
}

pcx_read_palette :: (file: File, file_offset: int, file_size: int) -> bool, []u8 {
    palette_magic_value: u8;
    pallete_magic_value_file_location := file_offset + file_size - 769;

    file_seek_success := file_seek(file, pallete_magic_value_file_location, .START);
    if !file_seek_success {
        log("Failed to seek to palette section.", flags=.ERROR);
        return false, .[]; 
    }
    
    file_read_success := file_read(file, *palette_magic_value, 1);
    if !file_read_success {
        log("Failed to read palette magic value.", flags=.ERROR);
        return false, .[];
    }

    if palette_magic_value != 0x0C {
        log("Invalid palette magic value. Got: %, expected: %", palette_magic_value, 0x0C, flags=.ERROR);
        return false, .[];
    }

    palette_data_size := 768;
    palette_data := NewArray(palette_data_size, u8);

    file_read_success = file_read(file, palette_data.data, palette_data_size);
    if !file_read_success {
        log("Failed to read palette data section.", flags=.ERROR);
        array_free(palette_data);
        return false, .[]; 
    }

    return true, palette_data;
}

// Find the closest color in the palette to the given RGB color
find_nearest_color :: (r: u8, g: u8, b: u8, palette: []Vector3_U8) -> u8 {
    best_index := 0;
    best_distance := 0xFFFFFF;  // Maximum possible distance
    
    for color, i: palette {
        // Calculate color distance (simple Euclidean distance in RGB space)
        dr := cast(s32)r - cast(s32)color.x;
        dg := cast(s32)g - cast(s32)color.y;
        db := cast(s32)b - cast(s32)color.z;
        
        distance := dr*dr + dg*dg + db*db;
        
        if distance < best_distance {
            best_distance = distance;
            best_index = i;
        }
    }
    
    return cast(u8)best_index;
}

#scope_export

PCXImage :: struct {
    data: *u8;
    data_count: u64;
    width: u64;
    height: u64;
};

pcx_load :: (file: File, pcx_file_offset: int, pcx_file_size: int) -> PCXImage, bool {
    pcx_logger_data := project_setup_logger("[PCX Loader]");
    defer project_cleanup_logger(pcx_logger_data);    

    file_seek_success := file_seek(file, pcx_file_offset, .START);
    if !file_seek_success {
        log("Failed to seek to file start location.", flags=.ERROR);
        return .{}, false; 
    }

    pcx_header: PCXHeader;    
    file_read_success := file_read(file, *pcx_header, size_of(PCXHeader));  
    if !file_read_success {
        log("Failed to read header from file.", flags=.ERROR);
        return .{}, false; 
    }

    if !pcx_verify_header(pcx_header) {
        log("Invalid header.", flags=.ERROR);
        return .{}, false;
    }

    pcx_header.width = (pcx_header.width - pcx_header.x) + 1;
    pcx_header.height = (pcx_header.height - pcx_header.y) + 1;

    texture_width: int = pcx_header.width;
    texture_height: int = pcx_header.height;
    texture_data_size : int = texture_width * texture_height;

    encoded_size := pcx_file_size - 128;
    encoded_data := NewArray(encoded_size, u8);
    encoded_data_file_location := pcx_file_offset + 128; 
    defer array_free(encoded_data);

    file_seek_success = file_seek(file, encoded_data_file_location, .START);
    if !file_seek_success {
        log("Failed to seek to encoded data section.", flags=.ERROR);
        return .{}, false; 
    }

    file_read_success = file_read(file, encoded_data.data, encoded_size);
    if !file_read_success {
        log("Failed to read encoded data.", flags=.ERROR);
        return .{}, false; 
    }

    decoded_data := pcx_decode_rle(encoded_data, texture_data_size, pcx_header);
    defer array_free(decoded_data);

    palette_read_success, palette_data := pcx_read_palette(file, pcx_file_offset, pcx_file_size);
    if !palette_read_success {
        return .{}, false;
    }
    defer array_free(palette_data);

    pixel_count := cast(u64) texture_data_size * 3;
    pixels := cast(*u8) alloc(xx pixel_count);
    for 0..(texture_data_size - 1) {
        color_index: int = decoded_data[it];
        pixels[it * 3 + 0] = palette_data[color_index * 3 + 0];
        pixels[it * 3 + 1] = palette_data[color_index * 3 + 1];
        pixels[it * 3 + 2] = palette_data[color_index * 3 + 2];
    }

    pcx_image: PCXImage;
    pcx_image.data = pixels;
    pcx_image.data_count = pixel_count;
    pcx_image.width = pcx_header.width;
    pcx_image.height = pcx_header.height;
    return pcx_image, true;
}

pcx_write :: (filename: string, rgb_data: []u8, width: s32, height: s32) -> bool {
    // Ensure the RGB data size matches width * height * 3
    expected_size := width * height * 3;
    if rgb_data.count != expected_size {
        log("RGB data size (%) doesn't match expected size (%)", rgb_data.count, expected_size, flags=.ERROR);
        return false;
    }

    // Create palette by collecting unique colors (up to 256)
    palette: [..]Vector3_U8;
    palette_lookup: Table(u32, u8);  // Maps RGB values to palette indices
    init(*palette_lookup, 256);
    defer deinit(*palette_lookup);

    // Function to add a color to the palette
    add_color_to_palette :: (r: u8, g: u8, b: u8, palette: *[..]Vector3_U8, lookup: *Table(u32, u8)) -> u8 {
        // Create a single u32 from RGB components for the lookup table
        key := (cast(u32)r << 16) | (cast(u32)g << 8) | b;
        
        // Check if this color is already in the palette
        index, found := table_find(lookup, key);
        if found return index;
        
        // If palette is full, return the nearest color
        if palette.count >= 256 {
            return find_nearest_color(r, g, b, palette.*);
        }
        
        // Add new color to palette
        index = cast(u8)palette.count;
        array_add(palette, Vector3_U8.{r, g, b});
        table_set(lookup, key, index);
        return index;
    }

    // First pass: build the palette
    for y: 0..height-1 {
        for x: 0..width-1 {
            idx := (y * width + x) * 3;
            r := rgb_data[idx];
            g := rgb_data[idx + 1];
            b := rgb_data[idx + 2];
            
            add_color_to_palette(r, g, b, *palette, *palette_lookup);
            
            // Stop if we have 256 colors (palette is full)
            if palette.count == 256 break;
        }
        if palette.count == 256 break;
    }
    
    // Ensure we have at least one color in the palette
    if palette.count == 0 {
        array_add(*palette, Vector3_U8.{0, 0, 0});
    }
    
    // Fill the rest of the palette with black if needed
    while palette.count < 256 {
        array_add(*palette, Vector3_U8.{0, 0, 0});
    }
    
    // Second pass: create indexed data
    indexed_data := NewArray(width * height, u8);
    defer array_free(indexed_data);
    
    for y: 0..height-1 {
        for x: 0..width-1 {
            idx := (y * width + x) * 3;
            r := rgb_data[idx];
            g := rgb_data[idx + 1];
            b := rgb_data[idx + 2];
            
            // Get color index from palette
            key := (cast(u32)r << 16) | (cast(u32)g << 8) | b;
            color_idx, found := table_find(*palette_lookup, key);
            
            if !found {
                // Find nearest color if not found (happens if palette filled up)
                color_idx = find_nearest_color(r, g, b, palette);
            }
            
            indexed_data[y * width + x] = color_idx;
        }
    }
    
    // Create PCX header
    header: PCXHeader;
    header.manafacturer = 10;       // ZSoft .PCX
    header.version = 5;             // Version 5
    header.encoding = 1;            // RLE encoding
    header.bits_per_pixel = 8;      // 8 bits per pixel (indexed)
    header.x = 0;
    header.y = 0;
    header.width = cast(u16)(width - 1);
    header.height = cast(u16)(height - 1);
    header.horzizontal_resolution = 72;  // DPI
    header.vertical_resolution = 72;     // DPI
    header.number_of_color_planes = 1;   // 1 plane for 8-bit indexed
    header.bytes_per_scan_line = cast(u16)width;
    header.palette_type = 1;             // Color palette
    
    // Open output file
    file, success := file_open(filename, true);
    if !success {
        log("Failed to open output file: %", filename, flags=.ERROR);
        return false;
    }
    defer file_close(*file);
    
    // Write PCX header
    file_write(*file, *header, size_of(PCXHeader));
    
    // Write RLE-encoded pixel data
    encoded_data := pcx_encode_rle(indexed_data, width, height);
    defer array_free(encoded_data);
    
    file_write(*file, encoded_data.data, encoded_data.count);
    
    // Write palette marker and palette
    palette_marker: u8 = 0x0C;
    file_write(*file, *palette_marker, 1);
    
    // Write out palette (256 RGB triplets)
    palette_data := NewArray(256 * 3, u8);
    defer array_free(palette_data);
    
    for i: 0..255 {
        if i < palette.count {
            palette_data[i*3]     = palette[i].x;
            palette_data[i*3 + 1] = palette[i].y;
            palette_data[i*3 + 2] = palette[i].z;
        } else {
            // This shouldn't happen since we padded the palette to 256 entries
            palette_data[i*3]     = 0;
            palette_data[i*3 + 1] = 0;
            palette_data[i*3 + 2] = 0;
        }
    }
    
    file_write(*file, palette_data.data, palette_data.count);
    
    return true;
}