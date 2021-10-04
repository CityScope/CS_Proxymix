/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents

import "DXF_Loader.gaml"
global
{
	init {
		do initiliaze_dxf;
	}
}

experiment ValidatedDXF type: gui
{   

	parameter 'fileName:' var: useCase category: 'file' <- "IDB/Level 0";
	output
	{	
		display map type: opengl background:#black toolbar:false draw_env:false
		{
			species dxf_element;
			graphics 'legend'{
			  draw useCase color: #white at: {-world.shape.width*0.1,-world.shape.height*0.1} perspective: true font:font("Helvetica", 20 , #bold);
			  rgb text_color<-#white;
                float y <- 30#px;
                float x<- -40#px;
  				draw "Building Usage" at: { x, y } color: text_color font: font("Helvetica", 20, #bold);
                y <- y + 30 #px;
                loop type over: standard_color_per_layer.keys
                {
                    draw square(10#px) at: { x - 20#px, y } color: standard_color_per_layer[type] border: #white;
                    draw type at: { x, y + 4#px } color: text_color font: font("Helvetica", 16, #plain);
                    y <- y + 25#px;
                }
			}
		}
	}
}