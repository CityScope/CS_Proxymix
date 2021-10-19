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
                float x<- -100#px;
  				draw "Existing type" at: { x, y } color: text_color font: font("Helvetica", 20, #bold);
                y <- y + 30 #px;
                loop type over: existing_types
                {
                    draw square(10#px) at: { x - 20#px, y } color: standard_color_per_layer[type] border: #white;
                    draw type at: { x, y + 4#px } color: text_color font: font("Helvetica", 16, #plain);
                    y <- y + 25#px;
                }
                y <- y + 30 #px;
                draw "Missing type" at: { x, y } color: text_color font: font("Helvetica", 20, #bold);
                y <- y + 30 #px;
                loop type over: missing_type_elements
                {
                    draw square(10#px) at: { x - 20#px, y } color: standard_color_per_layer[type] border: #white;
                    draw type at: { x, y + 4#px } color: text_color font: font("Helvetica", 16, #plain);
                    y <- y + 25#px;
                }
                y <- y + 30 #px;
                draw "Useless type" at: { x, y } color: text_color font: font("Helvetica", 20, #bold);
                y <- y + 30 #px;
                loop type over: useless_type_elements
                {
                    draw square(10#px) at: { x - 20#px, y } color: standard_color_per_layer[type] border: #white;
                    draw type at: { x, y + 4#px } color: text_color font: font("Helvetica", 16, #plain);
                    y <- y + 25#px;
                }
			}
		}
	}
}