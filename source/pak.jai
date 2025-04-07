PakHeader :: struct {
    id: [4]u8;
    offset: u32;
    size: u32;
};

PakFile :: struct {
    name: [56]u8;
    offset: u32;
    size: u32;
    file: File;
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

    pak_file_count := header.size / (size_of(PakFile) - size_of(File));
    print("Number of files: %\n", pak_file_count);

    
    seek_success := file_seek(file, header.offset, .START);
    if !seek_success {
        print("Unable to read full pak file.\n");
        return .[];
    }
    
    pak_files := NewArray(pak_file_count, PakFile);
    this_allocation_is_not_a_leak(pak_files.data);

    for 0..pak_file_count - 1 {
        success := file_read(file, *pak_files[it], size_of(PakFile) - size_of(File));
        if !success {
            print("Failed to read pak file!\n");
            return .[];
        }

        pak_files[it].file = file;
        pak_file_name := to_string(pak_files[it].name.data);

        if contains(pak_file_name, ".mdl") {
            array_add(*g_model_file_names, copy_string(pak_file_name));
        }

        if contains(pak_file_name, ".md2") {
            // TODO(Oskar): better way of doing this? lol
            name := copy_string(pak_file_name);
            defer free(name);

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