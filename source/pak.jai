PakHeader :: struct {
    id: [4]u8;
    offset: u32;
    size: u32;
};

PakFile :: struct {
    name: [56]u8;
    offset: u32;
    size: u32;
};

load_pak :: (file: File) -> [] PakFile {
    // NOTE(Oskar): Read file header.
    header: PakHeader;
    success, bytes := file_read(file, *header, size_of(PakHeader));
    if (!success) || (bytes < size_of(PakHeader)) {
        print("Could not read pak header!\n");
        return .[];
    }

    id_string: string;
    id_string.data = header.id.data;
    id_string.count = 4; 
    print("Pak header content: %\n", id_string);

    header_success := id_string == "PACK";
    if !header_success {
        print("Bad pak header id.\n");
        return .[];
    }

    pak_file_count := header.size / size_of(PakFile);
    print("Number of files: %\n", pak_file_count);

    
    seek_success := file_seek(file, header.offset, .START);
    if !seek_success {
        print("Unable to read full pak file.\n");
        return .[];
    }
    
    pak_files := NewArray(pak_file_count, PakFile);
    for 0..pak_file_count - 1 {
        success, bytes := file_read(file, *pak_files[it], size_of(PakFile));
        if !success {
            print("Failed to read pak file!\n");
            return .[];
        }

        if contains(to_string(pak_files[it].name.data), ".mdl") {
            array_add(*g_model_file_names, copy_string(to_string(pak_files[it].name.data)));
        }

        if contains(to_string(pak_files[it].name.data), ".md2") {
            // TODO(Oskar): better way of doing this? lol
            name := copy_string(to_string(pak_files[it].name.data));
            found, left, right := split_from_right(name, "/");
            if !found {
                array_add(*g_model_file_names, name);
                continue;
            }

            found, left, right = split_from_left(left, "/");
            if !found {
                array_add(*g_model_file_names, name);
                continue;
            }

            found, left, right = split_from_left(right, "/");
            if !found {
                array_add(*g_model_file_names, name);
                continue;
            }

            array_add(*g_model_file_names, right);
        }
    }

    print("Pak file successfully loaded.\n");
    
    return pak_files;
}