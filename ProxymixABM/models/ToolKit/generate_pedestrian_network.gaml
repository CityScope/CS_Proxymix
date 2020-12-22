/***
* Name: generatepedestriannetwork
* Author: Patrick Taillandier
* Description: generate the pedestrian network
***/
model generatepedestriannetwork
import "DXF_Loader.gaml"
global {
	
	string useCase <- "Andorra/Low_Covid19_Ordino";
	string parameter_path <-dataset_path + useCase+ "/Pedestrian network generator parameters.csv";
	string walking_area_path <-dataset_path + useCase+ "/walking_area.shp";
	list<string> layer_to_consider <- [walls,windows,offices, supermarket, meeting_rooms,coffee, furnitures, entrance , lab];
	
	bool recreate_walking_area <- true;
	
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
		if (not recreate_walking_area) and file_exists(walking_area_path) {
			create walking_area from: file(walking_area_path);
		} else {
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
							walking_area_g <- walking_area_g - (square(0.1) at_location pt); 
						}
					}
				}
				ask wall {
					walking_area_g <- walking_area_g - (shape );
					walking_area_g <- walking_area_g.geometries with_max_of each.area;
				}
				if (get_only_inside_room) {
					walking_area_g <- walking_area_g inter union(rooms_entrances);
				}
			}
			
			
			create walking_area from: walking_area_g.geometries;
			save walking_area type: shp to: walking_area_path;
		}
		write "Walking area created";
		
		
		
		if (build_pedestrian_network) {
			display_pedestrian_path <- true;
			list<geometry> geoms_decomp <- decomp_shape_triangulation();
			list<geometry> pp <- generate_pedestrian_network([],geoms_decomp,add_points_open_area,random_densification,min_dist_open_area,density_open_area,clean_network,tol_cliping,tol_triangulation,min_dist_obstacles_filtering);
			
			
			list<geometry> ggs;
			if (clean_network) {
				geometry wa <- union(walking_area);
				geometry wa_b <- wa buffer (-dist_min_obst);
				loop p over:pp {
					if not(wa covers p) {
						geometry g <- p inter wa_b;
						if (g != nil and g.perimeter > dist_reconnection) {
							if (length(g.geometries) > 1 ) {
								loop g1 over: g.geometries where (each != nil and each.perimeter > dist_reconnection) {
									ggs << g;
								}
							} else {
								ggs << g;
							}
							
						}
					} else if (p != nil and p.perimeter > dist_reconnection){
						ggs <<p;
					}
				}
			} else {
				ggs <- pp;
			}
			
			//list<geometry> cn <- clean_network(ggs, dist_reconnection,true,true);
			
			list<geometry> fcn;
			loop c over: ggs {
				fcn <- fcn + c.geometries;
			}
			fcn <- clean_network(fcn, dist_reconnection,true,true);
			
			create pedestrian_path from: fcn;
			
			save pedestrian_path type: shp to:dataset_path  + useCase+ "/pedestrian_path.shp";  
		} else {
			
			create pedestrian_path from: shape_file(dataset_path + useCase+ "/pedestrian_path.shp") ;
			geometry walking_area_g;
			if (not recreate_walking_area) and file_exists(walking_area_path) {
				create walking_area from: file(walking_area_path);
				walking_area_g <- union(walking_area);
			} else {	
		 		geometry walking_area_g <- copy(shape);
				
				ask wall {
					walking_area_g <- walking_area_g - (shape );
					walking_area_g <- walking_area_g.geometries with_max_of each.area;
				}
				create walking_area from: walking_area_g.geometries;
				save walking_area type: shp to: walking_area_path;
			
			}
			create Wall from: wall collect each.shape;
				
			ask pedestrian_path {
				do initialize obstacles:[Wall] distance: 1.0;
				free_space <- (free_space);// inter walking_area_g);// union (shape + 0.001);
				//write free_space.area;
				
				if (free_space = nil) {
					free_space <- copy(shape);
				} else {
					geometry free_s2 <- free_space - 0.2;
					if (free_space != nil) {
						free_space <- free_s2;
					} 				}
				
				free_space <- (free_space.geometries where (each != nil)) with_max_of each.area;
			}
			network <- as_edge_graph(pedestrian_path);
		
		
			create people number: 500 {
				location <- any_location_in(one_of(pedestrian_path).free_space);
				pedestrian_model <- P_pedestrian_model;
				avoid_other <- P_avoid_other;
				obstacle_species <- [people, dxf_element];
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

species people skills: [escape_pedestrian] {
	rgb color <- rnd_color(255);
	float speed <- gauss(3,1.5) #km/#h min: 1 #km/#h;
	
	reflex choose_target when: final_target = nil  {
		final_target <- any_location_in(one_of(pedestrian_path).free_space);
		do compute_virtual_path pedestrian_graph:network final_target: final_target ;
		if empty(targets ) {
			write name + " -> " + current_path;
		}
		
	}
	reflex move when: final_target != nil {
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
		display map {
			species dxf_element;
			species pedestrian_path;
			species people;
		}
	}
}
