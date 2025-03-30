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
}

load_pcx :: (file: File, file_offset: u32, file_size: u32) -> *u8, u32, u32 {
    pcx_header: PCXHeader;
    if !file_read(file, *pcx_header, size_of(PCXHeader)) { return null, 0, 0; }

    if pcx_header.manafacturer != 10 || pcx_header.version != 5 || 
       pcx_header.encoding != 1 || pcx_header.bits_per_pixel != 8 {
        return null, 0, 0;
    }

    pcx_header.width = pcx_header.width - pcx_header.x + 1;
    pcx_header.height = pcx_header.height - pcx_header.y + 1;
    texture_data_size := pcx_header.width * pcx_header.height;

    // Read actual encoded data size
    encoded_size := texture_data_size;
    encoded_data := cast(*u8) alloc(encoded_size);
    defer free(encoded_data);
    if !file_read(file, encoded_data, encoded_size) { return null, 0, 0; }

    unencoded_data := cast(*u8) alloc(texture_data_size);
    defer free(unencoded_data);

    i := 0;
    buffer_index := 0;
    for y: 0..pcx_header.height - 1 {
        for x: 0..pcx_header.width - 1 {
            c := encoded_data[buffer_index];
            buffer_index += 1;

            repeat_number := 1;
            if ((c & 0xC0) == 0xC0) {
                repeat_number := c & 0x3F;
                c = encoded_data[buffer_index];
                buffer_index += 1;
            }

            while repeat_number > 0 {
                defer repeat_number -= 1;
                unencoded_data[i] = c;
                i += 1;
            }
        }
    }

    if !file_seek(file, file_offset + file_size - 769, .START) { return null, 0, 0; }
    palette_magic_value: u8;
    if !file_read(file, *palette_magic_value, 1) || palette_magic_value != 0x0C {
        return null, 0, 0;
    }
    palette_data: [768]u8;
    if !file_read(file, palette_data.data, 768) { return null, 0, 0; }

    pixels := cast(*u8) alloc(texture_data_size * 4);

    j : s32 = pcx_header.height - 1;
    pixel_pointer : *u8 = pixels;
    while j >= 0 { 
        pixel_pointer := pixels + ((pcx_header.height - (j + 1)) * pcx_header.width * 4);

        for i: 0..pcx_header.width - 1{
            color := unencoded_data[j * pcx_header.width + i];

            pixel_pointer[0] = palette_data[color * 3 + 0]; // Red
            pixel_pointer[1] = palette_data[color * 3 + 1]; // Green
            pixel_pointer[2] = palette_data[color * 3 + 2]; // Blue
            pixel_pointer[3] = 255; // Alpha

            pixel_pointer += 4;
        }

        j -= 1;
    }

    return pixels, pcx_header.width, pcx_header.height;
}