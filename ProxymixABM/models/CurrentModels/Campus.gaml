/**
* Name: Campus
* Based on the internal empty template. 
* Author: Arno
* Tags: 
*/


model Campus

/* Insert your model definition here */

global {
	string dataset_path <- "./../../includes/CUCS/";
	file shape_file_buildings <- file(dataset_path+"buildings.shp");
	file shape_file_roads <- file(dataset_path+"roads.shp");
	file shape_file_bounds <- file(dataset_path+"bounds.shp");
	geometry shape <- envelope(shape_file_bounds);

	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))]{
		}
		create road from: shape_file_roads ;
		write "total number of building" + length(building);
		list buildings_area <- building collect each.shape.area;
		write "world area: " + world.shape.area + " m2;";
		write "total area: " + sum(buildings_area) + " m2;";
		write "min area: " + min(buildings_area) + " m2;";
		write "max area: " + max(buildings_area) + " m2;";
		write "mean area: " + mean(buildings_area) + " m2;";
	}
}

species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species road  {
	rgb color <- #black ;
	aspect base {
		draw shape color: color ;
	}
}

experiment road_traffic type: gui {
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;
		
	output {
		display city_display type:opengl {
			species building aspect: base ;
			species road aspect: base ;
		}
	}
}