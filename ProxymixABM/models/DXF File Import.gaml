/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents


global
{
	//define the path to the dataset folder
	string dataset_path <- "./../includes/";
	string fileName;
	//define the bounds of the studied area
	file the_dxf_file <- dxf_file(dataset_path + fileName +".dxf",#cm);
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
{   parameter 'fileName:' var: fileName category: 'file' <- "Standard_Factory_Gama" among: ["Standard_Factory_Gama", "MediaLab/ML_3","Grand-Hotel-Dieu_Lyon","Learning_Center_Lyon","ENSAL-RDC","ENSAL-1"];
	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}
