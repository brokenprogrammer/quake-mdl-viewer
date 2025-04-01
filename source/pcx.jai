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

PCXImage :: struct {
    data: *u8;
    data_count: u64;
    width: u64;
    height: u64;
};

decode_rle :: (encoded_data: []u8, decoded_size: int, header: PCXHeader) -> []u8 {
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

load_pcx :: (file: File, file_offset: int, file_size: int) -> PCXImage, bool {
    pcx_header: PCXHeader;
    if !file_read(file, *pcx_header, size_of(PCXHeader)) { 
        return .{}, false; 
    }

    if pcx_header.manafacturer != 10 || pcx_header.version != 5 || 
       pcx_header.encoding != 1 || pcx_header.bits_per_pixel != 8 {
        return .{}, false;
    }

    if pcx_header.bits_per_pixel * pcx_header.number_of_color_planes != 8 {
        return .{}, false;
    }

    pcx_header.width = (pcx_header.width - pcx_header.x) + 1;
    pcx_header.height = (pcx_header.height - pcx_header.y) + 1;

    texture_width: int = pcx_header.width;
    texture_height: int = pcx_header.height;
    texture_data_size : int = texture_width * texture_height;

    encoded_size := file_size - 128;
    encoded_data := NewArray(xx encoded_size, u8);
    defer array_free(encoded_data);

    if !file_seek(file, xx file_offset + 128, .START) {
        return .{}, false; 
    }

    if !file_read(file, encoded_data.data, encoded_size) {
        return .{}, false; 
    }

    decoded_data := decode_rle(encoded_data, texture_data_size, pcx_header);
    defer array_free(decoded_data);

    pallete_magic_value_offset := file_offset + file_size - 769;
    if !file_seek(file, pallete_magic_value_offset, .START) {
        return .{}, false; 
    }
    
    palette_magic_value: u8;
    if !file_read(file, *palette_magic_value, 1) {
        return .{}, false;
    }

    if palette_magic_value != 0x0C {
        return .{}, false;
    }

    palette_data := cast(*u8) alloc(768);
    if !file_read(file, palette_data, 768) {
        return .{}, false; 
    }

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