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


decode_rle :: (encoded_data: *u8, encoded_data_size: u32, decoded_size: u32, header: PCXHeader) -> *u8{
    decoded_data := cast(*u8) alloc(decoded_size);
    source : u32 = 0;
    dest : u32 = 0;

    while (dest < decoded_size) && (source < encoded_data_size) {
        byte : u8 = encoded_data[source];
        source += 1;
        run_lenght:s32 = 1;

        if ((byte & 0xC0) == 0xC0) {
            run_length := byte & 0x3F;
            byte = encoded_data[source];
            source += 1;

            while run_lenght > 0 {
                decoded_data[dest] = byte;
                dest += 1;
                run_lenght -= 1;
            }
        } else {
            decoded_data[dest] = byte;
            dest += 1;
        }
    }

    return decoded_data;
}

load_pcx :: (file: File, file_offset: u32, file_size: u32) -> *u8, u32, u32 {
    pcx_header: PCXHeader;
    if !file_read(file, *pcx_header, size_of(PCXHeader)) { 
        return null, 0, 0; 
    }

    if pcx_header.manafacturer != 10 || pcx_header.version != 5 || 
       pcx_header.encoding != 1 || pcx_header.bits_per_pixel != 8 {
        return null, 0, 0;
    }

    if pcx_header.bits_per_pixel * pcx_header.number_of_color_planes != 8 {
        return null, 0, 0;
    }

    pcx_header.width = (pcx_header.width - pcx_header.x) + 1;
    pcx_header.height = (pcx_header.height - pcx_header.y) + 1;
    texture_data_size : u32 = cast(u32)pcx_header.width * cast(u32)pcx_header.height;

    encoded_size := file_size - 128;
    encoded_data := cast(*u8) alloc(encoded_size);

    if !file_seek(file, file_offset + 128, .START) { 
        return null, 0, 0; 
    }

    if !file_read(file, encoded_data, encoded_size) { 
        return null, 0, 0; 
    }

    decoded_data := decode_rle(encoded_data, encoded_size, cast(u32)pcx_header.width * cast(u32)pcx_header.height, pcx_header);

    if !file_seek(file, file_offset + file_size - 769, .START) { 
        return null, 0, 0; 
    }
    
    palette_magic_value: u8;
    if !file_read(file, *palette_magic_value, 1) {
        return null, 0, 0;
    }

    if palette_magic_value != 12 {
        return null, 0, 0;
    }

    palette_data := cast(*u8) alloc(768);
    if !file_read(file, palette_data, 768) { 
        return null, 0, 0; 
    }

    pixels := cast(*u8) alloc(texture_data_size * 3);
    for 0..(texture_data_size - 1) {
        color_index : u32 = decoded_data[it];
        pixels[it * 3 + 0] = palette_data[color_index * 3 + 0];
        pixels[it * 3 + 1] = palette_data[color_index * 3 + 1];
        pixels[it * 3 + 2] = palette_data[color_index * 3 + 2];
    }

    return pixels, pcx_header.width, pcx_header.height;
}