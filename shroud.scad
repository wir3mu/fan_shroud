// --- PARAMETERS ---

// Rendering Options
// [both_split, left_half, right_half, full_assembled]
render_mode = "both_split"; 
joint_clearance = 0.5;    // Total clearance: male pin is 0.5mm smaller overall (0.25mm gap per side)

wall_thickness = 2.5;

// Fillet & Rounding Settings
corner_radius = 4.0;       // Outer corner rounding radius for housing & base
boss_fillet_radius = 3.0;  // Fillet radius for screw boss attachment transitions
airway_fillet = 3.0;       // Internal corner rounding radius for smooth airflow

// Base Plate (Mirrored from center green line)
base_length_half = 187.5; // Mirrored total length = 375mm
base_y_top = 25;          
base_y_bottom = 50;       
base_thickness = 4;       

// Base Screw Holes & Bosses
hole_diameter = 3.34;     
screw_head_dia = 7.0;     
boss_diameter = 11;       
boss_height = 3;         
screw_hole_x = 187.5;     

// Fan Array (4x 80mm)
fan_size = 80;
fan_depth = 25;       // Height of the fan rim
num_fans = 4;
fan_hole_dist = 71.5; // Standard 80mm hole spacing
fan_cutout_size = 60; // Overall square size for the grill area
fan_plate_thickness = 3; // Thickness of the grill plate on top
fan_tolerance = 1.0;  

// Center Gap & Dovetail Rib Alignment
fan_center_gap = 24;  // Shifts fans outward to give 24mm clearance for the solid dovetail rib

// Fan Screw Slots
fan_screw_dia = 4.3;      
fan_screw_slot_ext = 3.0; 

// Grill Settings
grill_slot_count = 8;      
grill_bar_thickness = 3.0; 

// Back Wall Slot Settings
enable_back_slots = true;
back_slot_width = 15.0;          // Width of the slot
back_slot_height = 15.0;         // Height of the slot
back_slot_corner_radius = 2.5;   // Radius for corner rounding
back_slot_z_offset = 15.0;       // Height from the bottom of the fan tray
back_slot_x_offset = -20.0;      // Horizontal X-axis shift for back wall slots

// Dovetail Settings
dovetail_depth = 5.0;            
dovetail_neck_width = 10.0;      
dovetail_flare_width = 18.0;     
dovetail_count = 2;              // Number of dovetail joints
dovetail_y_min = -35;            // Starting Y position
dovetail_y_max = -5;             // Ending Y position

// Shroud Placement
shroud_z_height = 8;  
shroud_y_shift = -43; // Centers the duct over the asymmetric Y
shroud_angle = 45;

$fn = 60;

// --- COMPUTED VARIABLES ---
total_fan_array_width = (fan_size * num_fans) + fan_center_gap;
fan_start_x = -(total_fan_array_width / 2); 
half_rib = fan_center_gap / 2; // 12mm half-width for solid central wall

// ==========================================
// HELPER MODULE: ROUNDED 2D RECTANGLE
// ==========================================
module rounded_rect_2d(w, h, r) {
    cr = min(r, w/2 - 0.1, h/2 - 0.1);
    hull() {
        translate([cr, cr]) circle(r=cr);
        translate([w - cr, cr]) circle(r=cr);
        translate([w - cr, h - cr]) circle(r=cr);
        translate([cr, h - cr]) circle(r=cr);
    }
}

// ==========================================
// MODULE: UNIFIED OUTER SOLID
// ==========================================
module outer_solid() {
    union() {
        // Base Plate Footprint (Rounded Outer Corners)
        translate([-base_length_half, -base_y_bottom, 0]) 
            linear_extrude(height = base_thickness)
            rounded_rect_2d(base_length_half * 2, base_y_top + base_y_bottom, corner_radius);
            
        // Outer Loft (Base to Fan Tray with Rounded Profiles)
        hull() {
            translate([-base_length_half, -base_y_bottom, base_thickness]) 
                linear_extrude(height = 0.1)
                rounded_rect_2d(base_length_half * 2, base_y_top + base_y_bottom, corner_radius);
                
            translate([fan_start_x - wall_thickness, shroud_y_shift - wall_thickness, shroud_z_height])
                rotate([shroud_angle, 0, 0])
                linear_extrude(height = 0.1)
                rounded_rect_2d(total_fan_array_width + (wall_thickness * 2), fan_size + (wall_thickness * 2), corner_radius);
        }
        
        // Outer Fan Housing Tray (Rounded Outer Vertical Edges)
        translate([fan_start_x - wall_thickness, shroud_y_shift - wall_thickness, shroud_z_height])
            rotate([shroud_angle, 0, 0])
            linear_extrude(height = fan_depth + fan_plate_thickness)
            rounded_rect_2d(total_fan_array_width + (wall_thickness * 2), fan_size + (wall_thickness * 2), corner_radius);
            
        // Left Screw Boss Bracket (Filleted Blend into Main Base)
        hull() {
            translate([-screw_hole_x, 0, 0]) cylinder(d=boss_diameter, h=boss_height);
            translate([-screw_hole_x + boss_diameter, -boss_diameter/2, 0]) 
                cube([0.1, boss_diameter, boss_height]);
            translate([-screw_hole_x + boss_diameter + boss_fillet_radius, 0, 0]) 
                cylinder(r=boss_fillet_radius, h=boss_height);
        }
        
        // Right Screw Boss Bracket (Filleted Blend into Main Base)
        hull() {
            translate([screw_hole_x, 0, 0]) cylinder(d=boss_diameter, h=boss_height);
            translate([screw_hole_x - boss_diameter, -boss_diameter/2, 0]) 
                cube([0.1, boss_diameter, boss_height]);
            translate([screw_hole_x - boss_diameter - boss_fillet_radius, 0, 0]) 
                cylinder(r=boss_fillet_radius, h=boss_height);
        }
    }
}

// ==========================================
// MODULE: VOID CUTOUTS
// ==========================================
module void_cuts() {
    difference() {
        union() {
            // A1. Left Airway Loft Cutout (Smooth Rounded Inner Corners)
            hull() {
                translate([-base_length_half + wall_thickness, -base_y_bottom + wall_thickness, base_thickness]) 
                    linear_extrude(height = 0.1)
                    rounded_rect_2d(base_length_half - wall_thickness - half_rib, (base_y_top + base_y_bottom) - (wall_thickness*2), airway_fillet);
                    
                translate([fan_start_x - wall_thickness, shroud_y_shift - wall_thickness, shroud_z_height])
                    rotate([shroud_angle, 0, 0])
                    translate([wall_thickness, wall_thickness, -0.1]) 
                    linear_extrude(height = 0.2)
                    rounded_rect_2d(fan_size * 2, fan_size, airway_fillet); 
            }

            // A2. Right Airway Loft Cutout (Smooth Rounded Inner Corners)
            hull() {
                translate([half_rib, -base_y_bottom + wall_thickness, base_thickness]) 
                    linear_extrude(height = 0.1)
                    rounded_rect_2d(base_length_half - wall_thickness - half_rib, (base_y_top + base_y_bottom) - (wall_thickness*2), airway_fillet);
                    
                translate([fan_start_x - wall_thickness, shroud_y_shift - wall_thickness, shroud_z_height])
                    rotate([shroud_angle, 0, 0])
                    translate([wall_thickness + (fan_size * 2) + fan_center_gap, wall_thickness, -0.1]) 
                    linear_extrude(height = 0.2)
                    rounded_rect_2d(fan_size * 2, fan_size, airway_fillet); 
            }
            
            // B1. Left downward punch
            translate([-base_length_half + wall_thickness, -base_y_bottom + wall_thickness, -1]) 
                linear_extrude(height = base_thickness + 1.01)
                rounded_rect_2d(base_length_half - wall_thickness - half_rib, (base_y_top + base_y_bottom) - (wall_thickness*2), airway_fillet);

            // B2. Right downward punch
            translate([half_rib, -base_y_bottom + wall_thickness, -1]) 
                linear_extrude(height = base_thickness + 1.01)
                rounded_rect_2d(base_length_half - wall_thickness - half_rib, (base_y_top + base_y_bottom) - (wall_thickness*2), airway_fillet);
            
            // C. Fan Pockets & Integrated Grill Cutouts
            translate([fan_start_x - wall_thickness, shroud_y_shift - wall_thickness, shroud_z_height])
            rotate([shroud_angle, 0, 0]) {
                
                // Left 2-Fan Pocket (Rounded Internal Corners)
                translate([wall_thickness - (fan_tolerance/2), wall_thickness - (fan_tolerance/2), -0.1])
                    linear_extrude(height = fan_depth + 0.2)
                    rounded_rect_2d((fan_size * 2) + fan_tolerance, fan_size + fan_tolerance, airway_fillet);

                // Right 2-Fan Pocket (Rounded Internal Corners)
                translate([wall_thickness + (fan_size * 2) + fan_center_gap - (fan_tolerance/2), wall_thickness - (fan_tolerance/2), -0.1])
                    linear_extrude(height = fan_depth + 0.2)
                    rounded_rect_2d((fan_size * 2) + fan_tolerance, fan_size + fan_tolerance, airway_fillet);
                    
                // Grill & Screw Slots for all 4 fans
                translate([wall_thickness, wall_thickness, fan_depth - 0.1]) {
                    for (i = [0 : num_fans - 1]) {
                        
                        x_shift = (i >= (num_fans / 2)) ? fan_center_gap : 0;
                        
                        translate([fan_size/2 + (i * fan_size) + x_shift, fan_size/2, 0]) {
                            
                            slot_width = (fan_cutout_size - ((grill_slot_count - 1) * grill_bar_thickness)) / grill_slot_count;
                            for (s = [0 : grill_slot_count - 1]) {
                                sx = -(fan_cutout_size / 2) + (s * (slot_width + grill_bar_thickness));
                                translate([sx, -fan_cutout_size/2, 0])
                                    cube([slot_width, fan_cutout_size, fan_plate_thickness + 0.2]);
                            }
                            
                            for (dx = [-fan_hole_dist/2, fan_hole_dist/2]) {
                                for (dy = [-fan_hole_dist/2, fan_hole_dist/2]) {
                                    translate([dx, dy, 0]) 
                                    rotate([0, 0, atan2(-dy, -dx)]) 
                                    hull() {
                                        cylinder(d=fan_screw_dia, h=fan_plate_thickness + 0.2);
                                        translate([fan_screw_slot_ext, 0, 0]) 
                                            cylinder(d=fan_screw_dia, h=fan_plate_thickness + 0.2);
                                    }
                                }
                            }
                        }
                    }
                }

                // D. Back Wall Parametric Rounded Rectangle Slots
                if (enable_back_slots) {
                    for (i = [0 : num_fans - 1]) {
                        x_shift = (i >= (num_fans / 2)) ? fan_center_gap : 0;
                        fan_center_x = wall_thickness + fan_size/2 + (i * fan_size) + x_shift;
                        
                        translate([fan_center_x + back_slot_x_offset, wall_thickness + fan_size, back_slot_z_offset]) {
                            hull() {
                                for (dx = [-back_slot_width/2 + back_slot_corner_radius, back_slot_width/2 - back_slot_corner_radius]) {
                                    for (dz = [-back_slot_height/2 + back_slot_corner_radius, back_slot_height/2 - back_slot_corner_radius]) {
                                        translate([dx, -wall_thickness, dz])
                                            rotate([-90, 0, 0])
                                            cylinder(r=back_slot_corner_radius, h=wall_thickness * 4);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // --- PROTECT THE BOSS BRACKETS ---
        hull() {
            translate([-screw_hole_x, 0, -50]) cylinder(d=boss_diameter, h=200);
            translate([-screw_hole_x + boss_diameter, -boss_diameter/2, -50]) cube([0.1, boss_diameter, 200]);
        }
        hull() {
            translate([screw_hole_x, 0, -50]) cylinder(d=boss_diameter, h=200);
            translate([screw_hole_x - boss_diameter, -boss_diameter/2, -50]) cube([0.1, boss_diameter, 200]);
        }
    }
    
    // E. Base Screw Holes 
    translate([-screw_hole_x, 0, -1]) {
        cylinder(d=hole_diameter, h=base_thickness + 2);
        translate([0, 0, base_thickness]) cylinder(d=screw_head_dia, h=200); 
    }
        
    translate([screw_hole_x, 0, -1]) {
        cylinder(d=hole_diameter, h=base_thickness + 2);
        translate([0, 0, base_thickness]) cylinder(d=screw_head_dia, h=200); 
    }
}

// ==========================================
// MODULE: JOINED MODEL
// ==========================================
module joined_model() {
    difference() {
        outer_solid();
        void_cuts();
    }
}

// ==========================================
// MODULE: PARAMETRIC DOVETAIL SPLIT TOOL
// ==========================================
module split_tool_2d() {
    union() {
        // Main left half mask
        translate([-500, -500]) square([500, 1000]);
        
        // Parametric Dovetail Pins
        for (i = [0 : dovetail_count - 1]) {
            y_pos = (dovetail_count > 1) 
                ? dovetail_y_min + (i * ((dovetail_y_max - dovetail_y_min) / (dovetail_count - 1))) 
                : (dovetail_y_min + dovetail_y_max) / 2;
                
            translate([0, y_pos]) {
                polygon([
                    [0, -dovetail_neck_width / 2],
                    [dovetail_depth, -dovetail_flare_width / 2],
                    [dovetail_depth, dovetail_flare_width / 2],
                    [0, dovetail_neck_width / 2]
                ]);
            }
        }
    }
}

module split_tool(delta) {
    translate([0, 0, -50])
    linear_extrude(height = 300)
    offset(delta=delta)
    split_tool_2d();
}

// ==========================================
// MAIN RENDER SWITCH
// ==========================================
if (render_mode == "full_assembled") {
    joined_model();
} 
else if (render_mode == "left_half") {
    intersection() {
        joined_model();
        split_tool(delta = -(joint_clearance / 2));
    }
} 
else if (render_mode == "right_half") {
    difference() {
        joined_model();
        split_tool(delta = (joint_clearance / 2));
    }
} 
else if (render_mode == "both_split") {
    intersection() {
        joined_model();
        split_tool(delta = -(joint_clearance / 2));
    }
    
    translate([20, 0, 0])
    difference() {
        joined_model();
        split_tool(delta = (joint_clearance / 2));
    }
}
