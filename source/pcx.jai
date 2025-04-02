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
            print("PCX Warning: Unexpected end of encoded data at position %.\n", it);
            return decoded_data;
        }
        
        if dest >= decoded_size {
            print("PCX Warning: Decoded data buffer overflow at position %.\n", it);
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
        return false, .[]; 
    }
    
    file_read_success := file_read(file, *palette_magic_value, 1);
    if !file_read_success {
        return false, .[];
    }

    if palette_magic_value != 0x0C {
        return false, .[];
    }

    palette_data_size := 768;
    palette_data := NewArray(palette_data_size, u8);

    file_read_success = file_read(file, palette_data.data, palette_data_size);
    if !file_read_success {
        array_free(palette_data);
        return false, .[]; 
    }

    return true, palette_data;
}

PCXLoggerData :: struct {
    prefix := "[PCX Loader]";
    old_context_logger: (string, *void, Log_Info);
    old_context_logger_data: *void;
}

pcx_logger :: (message: string, data: *void, info: Log_Info) {
    pcx_logger_data := cast(*PCXLoggerData)data;
    prefixed_message := tprint("% %", pcx_logger_data.prefix, message);
    pcx_logger_data.old_context_logger(prefixed_message, pcx_logger_data.old_context_logger_data, info);
}

pcx_setup_logger :: () -> *PCXLoggerData {
    pcx_logger_data := New(PCXLoggerData);
    pcx_logger_data.old_context_logger = context.logger;
    pcx_logger_data.old_context_logger_data = context.logger_data;

    context.logger = pcx_logger;
    context.logger_data = pcx_logger_data;

    return pcx_logger_data;
}

pcx_cleanup_logger :: (pcx_logger_data: *PCXLoggerData) {
    context.logger      = pcx_logger_data.old_context_logger;
    context.logger_data = pcx_logger_data.old_context_logger_data;
    free(pcx_logger_data);
}

#scope_export

PCXImage :: struct {
    data: *u8;
    data_count: u64;
    width: u64;
    height: u64;
};

pcx_load :: (file: File, file_offset: int, file_size: int) -> PCXImage, bool {
    pcx_logger_data := pcx_setup_logger();
    defer pcx_cleanup_logger(pcx_logger_data);    

    log("Testing my logger");
    log("Testing it again");

    pcx_header: PCXHeader;
    
    file_read_success := file_read(file, *pcx_header, size_of(PCXHeader));  
    if !file_read_success {
        return .{}, false; 
    }

    if !pcx_verify_header(pcx_header) {
        return .{}, false;
    }

    pcx_header.width = (pcx_header.width - pcx_header.x) + 1;
    pcx_header.height = (pcx_header.height - pcx_header.y) + 1;

    texture_width: int = pcx_header.width;
    texture_height: int = pcx_header.height;
    texture_data_size : int = texture_width * texture_height;

    encoded_size := file_size - 128;
    encoded_data := NewArray(encoded_size, u8);
    encoded_data_file_location := file_offset + 128; 
    defer array_free(encoded_data);

    file_seek_success := file_seek(file, encoded_data_file_location, .START);
    if !file_seek_success {
        return .{}, false; 
    }

    file_read_success = file_read(file, encoded_data.data, encoded_size);
    if !file_read_success {
        return .{}, false; 
    }

    decoded_data := pcx_decode_rle(encoded_data, texture_data_size, pcx_header);
    defer array_free(decoded_data);

    palette_read_success, palette_data := pcx_read_palette(file, file_offset, file_size);
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