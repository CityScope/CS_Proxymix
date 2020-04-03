/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents


global
{
	file the_dxf_file <- dxf_file("../includes/MediaLab/ML_3.dxf",#cm);
	geometry shape <- envelope(the_dxf_file);
	init
	{
		create dxf_element from: the_dxf_file with: [layer::string(get("layer"))];
		map layers <- list(dxf_element) group_by each.layer;
		loop la over: layers.keys
		{
			rgb col <- rnd_color(255);
			ask layers[la]
			{
				color <- col;
			}
		}
	}
}

species dxf_element
{
	string layer;
	rgb color;
	aspect default
		{
		draw shape color: color;
	}
	init {
		shape <- polygon(shape.points);
	}
}

experiment DXFAgents type: gui
{   
	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}
