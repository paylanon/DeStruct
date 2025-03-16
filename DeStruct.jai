//  ----------
// | DeStruct |
//  ----------

// An in-terminal struct visualizer.

// DEMO: Uncomment and compile me!
// Comment out again before using.

// #run demo();

demo :: () {

    #import "Compiler";
    set_build_options_dc(.{do_output = false});

    Demo_Struct :: struct {
	
	id: u16;
        inner: Inner_Struct;
	union {
	    uint: u64;
	    sint: s32;
	    flt:  float;
	}
    }

    Inner_Struct :: struct {

        flag:  u8;
        dword: u32;
    }

    Place :: struct {
        
	id: u16;
        inner: Inner_Struct;
        
        #place inner;
	double: float64;
    }
    
    print_cyan("\n\n[DeStruct] ");
    print_gray(250, "DEMO:\n");
    
    de_struct(Demo_Struct, bytes_per_line=2);
    de_struct(Inner_Struct);
    de_struct(Place, bytes_per_line=2);
}

MIN_WIDTH    :: 20;
NAME_PADDING :: 4;

Box :: struct {
    m: Type_Info_Struct_Member;
    p: s64;
}

/*
==========
de_struct
Print visualization of struct to stdout.
----------------------------------------
*/
de_struct :: (struct_type: Type, bytes_per_line: s64 = 4) {

    start_gray(250);
    defer reset_termcolor();
    
    ti := transmute(*Type_Info_Struct, *struct_type);
    if ti.type != .STRUCT {
        print_cyan("\n[DeStruct] Not a struct type!\n\n");
        return;
    }
    
    // ---- Prepare -------------------------------------------------------------
    
    offset_cursor: s64;
    width := MIN_WIDTH;
    boxes: [..] Box;
    
    for ti.members {

        // Check for padding
        padding := it.offset_in_bytes - offset_cursor;
	if padding array_add(*boxes, .{p=padding});
        
	array_add(*boxes, .{m=it});
        
	offset_cursor = it.offset_in_bytes + it.type.runtime_size;
        width = max(width, it.name.count + NAME_PADDING);
    }

    tail := ti.runtime_size - offset_cursor;
    if tail array_add(*boxes, .{p=tail});

    // ---- Draw ----------------------------------------------------------------
    
    print_cyan("\n[DeStruct]\n");
    start_gray(250);
    print(" % (% bytes)\n", ti.name, ti.runtime_size);
    
    print("┌");
    for 0..width-1 print("─");
    print("┐\n");

    for boxes {

	start_gray(250);

	if it.p {
	    
	    // Draw padding box
	    height := max(1, it.p / bytes_per_line);

	    for line: 0..height-1 {
		print("│");
		for 0..width-1 print("░");
		print("│");
		if line == 0 {
                    if it.p < 0 {  // #place shenanigans
		        print_warn("  % bytes (#place)", it.p);
                    } else {
		        print_gray(246, "  % bytes", it.p);
		        print_gray(248, " pad");
                    }
		}
		print("\n");
	    }

            draw_separator();
            continue;
	}

	field := it.m;
	height := max(1, field.type.runtime_size / bytes_per_line);

        if field.type.type == .STRUCT {
            
            ti_inner_struct := transmute(*Type_Info_Struct, **field.type.type);

            if ti_inner_struct.textual_flags & .UNION {

	        // Draw union
                member_names: [..] string;

                for < ti_inner_struct.members {
                    array_add(*member_names, it.name);
                }
                
	        for line: 0..height-1 {
                    
		    if line == 0 {
		        print("│");
		        name_padding := (width - 5) / 2;
		        for 0..name_padding-1 print(" ");
		        print_gray(246, "union");
	                start_gray(250);
		        for 0..width-name_padding-6 print(" ");
		        print("│ % bytes\n", field.type.runtime_size);
                        continue;
		    }

                    mn := "";
                    if member_names mn = pop(*member_names);

                    if line == height-1 && member_names {
		        print("│");
		        name_padding := (width - 3) / 2;
		        for 0..name_padding-1 print(" ");
		        print_gray(246, "...");
	                start_gray(250);
		        for 0..width-name_padding-4 print(" ");
		        print("│\n");
                    } else if mn {
		        print("│");
		        name_padding := (width - mn.count) / 2;
		        for 0..name_padding-1 print(" ");
		        print("%", mn);
		        for 0..width-name_padding-mn.count-1 print(" ");
		        print("│\n");
                    } else {
		        print("│");
		        for 0..width-1 print(" ");
		        print("│\n");
		    }
	        }
                
            } else {

	        // Draw struct field
	        for line: 0..height-1 {
		    if line == 0 {
		        print("│");
		        name_padding := (width - field.name.count) / 2;
		        for 0..name_padding-1 print(" ");
		        print_gray(252, "%", field.name);
	                start_gray(250);
		        for 0..width - name_padding - field.name.count - 1 print(" ");
		        print("│ % bytes\n", field.type.runtime_size);
		    } else {
		        print("│");
		        for 0..width-1 print(" ");
		        print("│\n");
		    }
	        }                
            }
            
            draw_separator();
	    
	} else {

	    // Draw single field
	    for line: 0..height-1 {
		if line == 0 {
		    print("│");
		    name_padding := (width - field.name.count) / 2;
		    for 0..name_padding-1 print(" ");
		    print("%", field.name);
		    for 0..width - name_padding - field.name.count - 1 print(" ");
		    print("│ % bytes\n", field.type.runtime_size);
		} else {
		    print("│");
		    for 0..width-1 print(" ");
		    print("│\n");
		}
	    }

            draw_separator();
	}
    }

    print("└");
    for 0..width-1 print("─");
    print("┘\n");
}

#scope_module

draw_separator :: () #expand {

    // Draw separator
    if `it_index < `boxes.count - 1 {
        print("├");
        for 0..`width-1 print("─");
        print("┤\n");
    }    
}

start_gray :: (shade: u8) {
    print("\x1b[38;5;%m", shade);
}

print_gray :: (shade: u8, msg: string, args: .. Any) {
    final_msg := tprint(msg, .. args);
    print("\x1b[38;5;%m%\x1b[0m", shade, final_msg);
}

print_cyan :: (msg: string, args: .. Any) {
    final_msg := tprint(msg, .. args);
    print("\x1b[38;5;152m%\x1b[0m", final_msg);
}

print_warn :: (msg: string, args: .. Any) {
    final_msg := tprint(msg, .. args);
    print("\x1b[38;5;180m%\x1b[0m", final_msg);
}

reset_termcolor :: () {
    print("\x1b[0m");
}

/*
==========
transmute
Convenience, a bitcast.
-----------------------
*/
transmute :: ($T: Type, pfrom: *void) -> T {
    return (pfrom.(*T)).*;
}

#import "Basic";
