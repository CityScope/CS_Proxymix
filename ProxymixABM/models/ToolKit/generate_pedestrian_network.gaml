/***
* Name: generatepedestriannetwork
* Author: Patrick Taillandier
* Description: generate the pedestrian network
***/
model generatepedestriannetwork
import "DXF_Loader.gaml"
global {
	string dataset_path <- "../../includes/";
	string useCase <- "IDB/Level 0";
	string parameter_path <-dataset_path + useCase+ "/Pedestrian network generator parameters.csv";
	string walking_area_path <-dataset_path + useCase+ "/walking_area.shp";
	string pedestrian_paths_path <-dataset_path + useCase+ "/pedestrian path.shp";
	string free_space_path <-dataset_path + useCase+ "/free space.shp";
	list<string> layer_to_consider <- [walls,windows,offices, supermarket, meeting_rooms,coffee, furnitures, entrance , lab];
	
	float simplification_dist <- 0.1;
	float buffer_simplication <-  0.001;
	
	bool add_points_open_area <- false;//add points to open areas
 	bool random_densification <- false;//random densification (if true, use random points to fill open areas; if false, use uniform points), 
 	float min_dist_open_area <- 0.1;//min distance to considered an area as open area, 
 	float density_open_area <- 0.1; //density of points in the open areas (float)
 	bool clean_network <-  false; 
	float tol_cliping <- 0.1; //tolerance for the cliping in triangulation (float; distance), 
	float tol_triangulation <- 0.0; //tolerance for the triangulation 
	float min_dist_obstacles_filtering <- 0.0;// minimal distance to obstacles to keep a path (float; if 0.0, no filtering), 
	float dist_reconnection <- 0.1;
	bool get_only_inside_room <- false;
	float dist_min_obst <- 0.2; //cut path closer than that;
	
	bool P_use_body_geometry <- false parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 10.0 parameter: true ;
	
	
	string P_pedestrian_model among: ["simple", "SFM"] <- "SFM" parameter: true ;
	
	bool display_free_space <- false parameter: true category:"Visualization";
	bool display_pedestrian_path <- false parameter: true category:"Visualization";
	bool display_triangles <- false parameter: true category:"Visualization";
	
	float step <- 1.0;
	int limit_cpt_for_entrance_room_creation <- 10;
	
	bool build_pedestrian_network <- true;
	graph network;
	init { 
		if(file_exists(parameter_path)) {
			file csv_parameter <- csv_file(parameter_path, ",", true);
			loop i from: 0 to: csv_parameter.contents.rows - 1 {
				string parameter_name <- csv_parameter.contents[0,i];
				if (parameter_name in ["add_points_open_area","random_densification","clean_network", "get_only_inside_room"]) {
					bool val <- bool(csv_parameter.contents[1,i]);
					world.shape.attributes[parameter_name] <- val;
				}else {
					float val <- float(csv_parameter.contents[1,i]);
					world.shape.attributes[parameter_name] <- val;
				}
				
				
				
			}
		}
		do initiliaze_dxf;
		ask dxf_element where not( each.layer in layer_to_consider) {
			do die;
		} 
		list<dxf_element> wall <- dxf_element where (each.layer = walls);
		write "simplification_dist: " + simplification_dist + " buffer_simplication: " + buffer_simplication;
		if build_pedestrian_network {
			ask wall {
				shape <- simplification(shape + buffer_simplication, simplification_dist) ;
			}
		
		}
		
		list<dxf_element> rooms <- dxf_element where (each.layer in [offices, supermarket, meeting_rooms,coffee,lab]);
		list<dxf_element> rooms_entrances <- dxf_element where (each.layer in [entrance, offices, supermarket, meeting_rooms,coffee,lab]);
		write "Number of dxf elements:" + length(dxf_element);
		
		ask rooms_entrances{
			geometry contour <- nil;
			float dist <-0.3;
			int cpt <- 0;
			loop while: contour = nil {
				cpt <- cpt + 1;
				contour <- copy(shape.contour);
				ask wall at_distance 1.0 {
					contour <- contour - (shape +dist);
				}
				if cpt < limit_cpt_for_entrance_room_creation {
					ask (rooms) at_distance 1.0 {
						contour <- contour - (shape + dist);
					}
				}
				if cpt = 20 {
					break;
				}
				dist <- dist * 0.5;	
			} 
			if contour != nil {
				entrances <- points_on (contour, 2.0);
			}	
		}
		
		write "entrances created";
		
		
		if (build_pedestrian_network or not file_exists(pedestrian_paths_path)) {
			geometry walking_area_g <- copy(shape);
			if empty(wall ) {
				ask dxf_element {
					walking_area_g <- walking_area_g - (shape );
					walking_area_g <- walking_area_g.geometries with_max_of each.area;
				}
			} else {
				if build_pedestrian_network {
					ask dxf_element {
						loop pt over: entrances {
							walking_area_g <- walking_area_g - (square(0.05) at_location pt); 
						}
					}
				}
				
				ask wall {
					walking_area_g <- walking_area_g - (shape );
					walking_area_g <- world.select_geometry(walking_area_g.geometries, rooms) ;
				}
				if (get_only_inside_room) {
					walking_area_g <- walking_area_g inter union(rooms_entrances);
				}
			}
			
			create walking_area from: walking_area_g.geometries;
				write "Walking area created";
	
		 display_pedestrian_path <- true;
			list<geometry> geoms_decomp <- decomp_shape_triangulation();
			list<geometry> pp <- generate_pedestrian_network([],geoms_decomp,add_points_open_area,random_densification,min_dist_open_area,density_open_area,clean_network,tol_cliping,tol_triangulation,min_dist_obstacles_filtering,simplification_dist);
			graph g <-as_edge_graph(pp);
			g <- main_connected_component(g);
			pp <- g.edges;
			create pedestrian_path from: pp  {
				do initialize bounds:walking_area as list distance: min(10.0,(wall closest_to self) distance_to self)  distance_extremity: 1.0; //*masked_by: [wall]
				if free_space = nil or not (free_space covers shape){
					free_space <- shape + dist_min_obst;
				}
				if (free_space = nil or free_space.area = 0) {
				 	do die;
				
				}
			
			}
			save pedestrian_path type: shp to:pedestrian_paths_path;
			save walking_area type: shp to: walking_area_path;
			save pedestrian_path collect each.free_space type: shp to:free_space_path;
			
		} else {
			
			create Wall from: wall collect each.shape;
				
		
			create walking_area from: shape_file(walking_area_path) ;
			file free_spaces_shape_file <- shape_file(free_space_path) ;
			create pedestrian_path from: shape_file(pedestrian_paths_path)  {
				list<geometry> fs <- free_spaces_shape_file overlapping self;
				free_space <- fs first_with (each covers shape); 
				if free_space = nil {
					free_space <- shape + dist_min_obst;
				}
			}
			network <- as_edge_graph(pedestrian_path);
			/*ask pedestrian_path {
				do build_intersection_areas pedestrian_graph: network;
			}*/
		
			create people number: 100 {
				location <- any_location_in(one_of(pedestrian_path).free_space);
			
				pedestrian_species <- [people];
				obstacle_species<-[dxf_element];
				avoid_other <- P_avoid_other;
			}
			
			
		}
	} 
	
	
	list<geometry> decomp_it(geometry g) {
		list<geometry> geom_f;
		try{
			g <- clean(g);
			create triangles from: triangulate(g,tol_cliping,tol_triangulation );
			geom_f << g;
			
		} catch {
			loop gsg over: g.geometries {
				list<geometry> sub_areas <- gsg to_rectangles (gsg.width / 2.0, gsg.height / 2.0) ;
				loop gg over: sub_areas{
					geom_f <- geom_f + decomp_it(gg);
				}
			}			
		}
		return geom_f;		
	}
	list<geometry> decomp_shape_triangulation {
		list<geometry> geom_f;
		loop t over: (walking_area accumulate (each.shape.geometries)) {
			geom_f <- geom_f + decomp_it(t);
		}
		return (geom_f where (each != nil and each.area > 0.1));
	}
	
	geometry select_geometry(list<geometry> geoms, list<dxf_element> rooms) {
		if empty(geoms) {return nil;}
		if length(geoms) = 1 {
			return first(geoms);
		}
		float max_v_o <- 0.0;
		float max_v <- 0.0;
		geometry g_o;
		geometry g_no;
		loop g over: geoms {
			if not empty(rooms overlapping g) {
				if (g.area > max_v_o) {
					g_o <- g;
					max_v_o <- g.area;
				}
			}  else {
				if (g.area > max_v) {
					g_no <- g;
					max_v <- g.area;
				}
			}
		}
		
		if max_v_o > (max_v/10.0) {
			return g_o;
		}
		return g_no;
	}
}

species Wall;
species walking_area;
species pedestrian_path skills: [pedestrian_road] {
	aspect default {
		if (display_pedestrian_path) {
			if(display_free_space and free_space != nil) {draw free_space color: #lightpink border: #black;}
			draw shape color: #red;
		}
		
	}
}

species triangles {
	rgb color <- #magenta;
	aspect default {
		if display_triangles {
			draw shape color: color border: #black;
		}
	}
}

species people skills: [pedestrian] {
	rgb color <- rnd_color(255);
	float speed <- gauss(3,1.5) #km/#h min: 1 #km/#h;
	
	reflex choose_target when: final_waypoint = nil  {
		final_waypoint <- any_location_in(one_of(pedestrian_path).free_space);
		do compute_virtual_path pedestrian_graph:network target: final_waypoint ;
		if empty(waypoints ) {
			write name + " -> " + current_path;
		}
	}
	reflex move when: final_waypoint != nil {
		do walk ;
	}	
	
	aspect default {
		draw circle(0.3) color: color;
	}
	
}


experiment generate_pedestrian_network type: gui {
	action _init_ {
		create simulation with: [build_pedestrian_network::true, dataset_path::"../../includes/",validator::false];
	}
	output {
		display map {
			species dxf_element;
			species walking_area;
			species triangles;
			species pedestrian_path;
		
		}
	}
}



experiment test_pedestrian_network type: gui {
	float minimum_cycle_duration <- 0.05;
	action _init_ {
		create simulation with: [build_pedestrian_network::false, dataset_path::"../../includes/", validator::false];
	}
	output {
		display map  {
			species dxf_element;
			species pedestrian_path;
			species people;
		}
	}
}
