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

	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUCEA";
	output
	{	
		display map type: opengl background:#black toolbar:false draw_env:false
		{
			species dxf_element;
			graphics 'legend'{
			  draw useCase color: #white at: {-world.shape.width*0.1,-world.shape.height*0.1} perspective: true font:font("Helvetica", 20 , #bold);
			}
		}
	}
}