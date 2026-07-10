def parse_file(file_name):
    KAT_directory = dict()

    with open(file_name, "r") as f:
        lines = f.readlines()
        msg = ""
        for line in lines:
            split_line = line.split(" = ")
            if "Msg" in line:
                msg = split_line[1].strip().lower()
            if "MD" in line:
                KAT_directory[msg] = split_line[1].strip().lower()
    
    return KAT_directory
