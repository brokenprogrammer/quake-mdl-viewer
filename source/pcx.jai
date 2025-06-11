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
    palette: []Vector3_U8;
};

pcx_cleanup :: (pcx_image: *PCXImage) {
    if pcx_image.data {
        free(pcx_image.data);
        pcx_image.data = null;
    }
    array_free(pcx_image.palette);
    pcx_image.data_count = 0;
    pcx_image.width = 0;
    pcx_image.height = 0;
}

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

    // Convert palette data to Vector3_U8 array
    palette := NewArray(256, Vector3_U8);
    for i: 0..255 {
        palette[i].x = palette_data[i*3];
        palette[i].y = palette_data[i*3 + 1];
        palette[i].z = palette_data[i*3 + 2];
    }
    array_free(palette_data); // Now we can free the raw palette data

    pixel_count := cast(u64) texture_data_size * 3;
    pixels := cast(*u8) alloc(xx pixel_count);
    for 0..(texture_data_size - 1) {
        color_index: int = decoded_data[it];
        pixels[it * 3 + 0] = palette[color_index].x;
        pixels[it * 3 + 1] = palette[color_index].y;
        pixels[it * 3 + 2] = palette[color_index].z;
    }

    pcx_image: PCXImage;
    pcx_image.data = pixels;
    pcx_image.data_count = pixel_count;
    pcx_image.width = pcx_header.width;
    pcx_image.height = pcx_header.height;
    pcx_image.palette = palette;
    return pcx_image, true;
}

// TODO(Oskar): Fix convention to look more like load function.
// TODO(Oskar): Support for building color_palette with all unique colors in texture.
pcx_write :: (filename: string, rgb_data: []u8, width: s32, height: s32, color_palette: []Vector3_U8) -> bool {
    pcx_logger_data := project_setup_logger("[PCX Loader]");
    defer project_cleanup_logger(pcx_logger_data);

    // Ensure the RGB data size matches width * height * 3
    expected_size := width * height * 3;
    if rgb_data.count != expected_size {
        log("RGB data size (%) doesn't match expected size (%)", rgb_data.count, expected_size, flags=.ERROR);
        return false;
    }

    // Validate palette size
    if color_palette.count == 0 {
        log("Color palette is empty", flags=.ERROR);
        return false;
    }
    
    if color_palette.count > 256 {
        log("Color palette too large (%), maximum is 256", color_palette.count, flags=.ERROR);
        return false;
    }

    // Convert RGB data to indexed data using the provided palette
    indexed_data := NewArray(width * height, u8);
    defer array_free(indexed_data);
    
    for y: 0..height-1 {
        for x: 0..width-1 {
            idx := (y * width + x) * 3;
            r := rgb_data[idx];
            g := rgb_data[idx + 1];
            b := rgb_data[idx + 2];
            
            // Find the nearest color in the palette
            color_idx := find_nearest_color(r, g, b, color_palette);
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
    
    // Fill palette data from the provided color_palette
    for i: 0..255 {
        if i < color_palette.count {
            palette_data[i*3]     = color_palette[i].x;
            palette_data[i*3 + 1] = color_palette[i].y;
            palette_data[i*3 + 2] = color_palette[i].z;
        } else {
            // Pad remaining entries with black
            palette_data[i*3]     = 0;
            palette_data[i*3 + 1] = 0;
            palette_data[i*3 + 2] = 0;
        }
    }
    
    file_write(*file, palette_data.data, palette_data.count);
    
    return true;
}

pcx_write_image :: (pcx_image: PCXImage, filename: string) -> bool {
    pcx_logger_data := project_setup_logger("[PCX Loader]");
    defer project_cleanup_logger(pcx_logger_data);

    if !pcx_image.data || pcx_image.data_count == 0 {
        log("PCXImage has no data", flags=.ERROR);
        return false;
    }

    if pcx_image.palette.count == 0 {
        log("PCXImage has no palette", flags=.ERROR);
        return false;
    }

    width := cast(s32)pcx_image.width;
    height := cast(s32)pcx_image.height;
    
    // Convert RGB data back to indexed data using the stored palette
    indexed_data := NewArray(width * height, u8);
    defer array_free(indexed_data);
    
    for y: 0..height-1 {
        for x: 0..width-1 {
            pixel_idx := (y * width + x) * 3;
            r := pcx_image.data[pixel_idx];
            g := pcx_image.data[pixel_idx + 1];
            b := pcx_image.data[pixel_idx + 2];
            
            // Find the matching color in the palette
            color_idx := find_nearest_color(r, g, b, pcx_image.palette);
            indexed_data[y * width + x] = color_idx;
        }
    }
    
    // Create PCX header
    header: PCXHeader;
    header.manafacturer = 10;
    header.version = 5;
    header.encoding = 1;
    header.bits_per_pixel = 8;
    header.x = 0;
    header.y = 0;
    header.width = cast(u16)(width - 1);
    header.height = cast(u16)(height - 1);
    header.horzizontal_resolution = 72;
    header.vertical_resolution = 72;
    header.number_of_color_planes = 1;
    header.bytes_per_scan_line = cast(u16)width;
    header.palette_type = 1;
    
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
    
    // Write palette marker
    palette_marker: u8 = 0x0C;
    file_write(*file, *palette_marker, 1);
    
    // Write palette data (256 RGB triplets)
    palette_data := NewArray(256 * 3, u8);
    defer array_free(palette_data);
    
    for i: 0..255 {
        if i < pcx_image.palette.count {
            palette_data[i*3]     = pcx_image.palette[i].x;
            palette_data[i*3 + 1] = pcx_image.palette[i].y;
            palette_data[i*3 + 2] = pcx_image.palette[i].z;
        } else {
            // Pad with black
            palette_data[i*3]     = 0;
            palette_data[i*3 + 1] = 0;
            palette_data[i*3 + 2] = 0;
        }
    }
    
    file_write(*file, palette_data.data, palette_data.count);
    
    return true;
}