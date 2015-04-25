#version 440 core // Identifies the version of the shader, this line must be on a separate line from the rest of the shader code

out vec4 color; // Our vec4 color variable containing r, g, b, a

 uniform mat4 MVP; // Our uniform Model-View-Projection matrix to modify our position values

void main(void)
{
	int i = gl_VertexID;
	int TileIndex = i / 6;						// Which square is it? We need 2 triangles, so 6 vertices per square.
	int VertexInTile = i % 6;	                // 0, 1, 2, 3, 4, 5, 0, 1... Which vertex is it in the square?
	int TriangleInTile = VertexInTile / 3;      // 0, 0, 0, 1, 1, 1, 0, 0... Which triangle is it in the square?
												// 0, 1, 2, 1, 2, 3, 0, 1... Indices for a square.
	int Index = VertexInTile - (2 * TriangleInTile);
	vec2 VertexLocation = vec2(
						Index % 2, 				// x = index % 2
						(Index / 2) % 2 );		// z = (index / 2) % 2
	vec2 TileLocation = vec2(
						(TileIndex % 1024),		//   = index % 1024
						(TileIndex / 1024));	//   = index / 1024 (we don't need a mod here, since we know we are using a constant 1024*1024 tiles)
	VertexLocation += TileLocation;
		// Wow, there sure was a lot of information in that simple incremental count from 0 to 1024*1024*6.

	vec3 Offset = vec3( -500.0, -6.0, -500.0 );

	// Let's make some waves.
	float frequency = 3.14159 * 20;                 // how many waves do we want
	float amplitude = 3.0;							// how high do we want them



		// If we use only the tile location, the entire tile will have the same height.
		// Because of this, we get square tiles with discontinuities on the sides.
	vec2 SeedValue1 = TileLocation / 1024;			// Normalize this to a 0 to 1 range; 0 to 1 is usually nicer to work with.
	float height1 = (sin(SeedValue1.x * frequency) + sin(SeedValue1.y * frequency)) * amplitude;
	vec4 Position1 = vec4(VertexLocation.x + Offset.x, height1 + Offset.y, VertexLocation.y + Offset.z, 1.0);

		// However, if we use the location of the vertex itself, the tiles will have varying height
		// across their surface, overlapping their neighbors.
	vec2 SeedValue2 = VertexLocation / 1024;		// Normalize this to a 0 to 1 range; 0 to 1 is usually nicer to work with.
	float height2 = (sin(SeedValue2.x * frequency) + sin(SeedValue2.y * frequency)) * amplitude;
	vec4 Position2 = vec4(VertexLocation.x + Offset.x, height2 + Offset.y, VertexLocation.y + Offset.z, 1.0);



		// So which method will we use? Why not let their screen space locations choose!
		// Just use the first for this calculation; it won't make much difference here.
	vec4 ClipSpace = MVP * Position1;

		// Another interesting thing to note when you run this is where the two
		// lines specified by this if statement lie. ClipSpace.x shrinks with distance from the camera.
		// Dividing it by ClipSpace.w normalizes it to a form of screen coordinates. Or more accurately, 
		// it normalizes it to Normalized Device Coordinates, whose x and y are a space from -1 to 1. 
		// However, this form of NDC is actually not universal. DirectX uses a 0 to 1 space. The projection
		// matrix is the part which puts it into this form, and so projection matrix actually varies between
		// the two APIs. For more info and some fun tricks with projection matrices, see here: http://www.terathon.com/gdc07_lengyel.pdf
	if( ClipSpace.x < 10.0 && ClipSpace.x / ClipSpace.w > -0.5 )
	{
		ClipSpace = MVP * Position2;									   // Use the second position for our vertex position.
		color = vec4( 0.0, abs(height2) / amplitude, 0.0, 1.0 );           // Height-based color.
	}
	else
	{
		// Already calculated final position for Position1 case!
		color = vec4( 0.0, abs(height1) / amplitude, 0.0, 1.0 );           // Height-based color.
	}


		// In fact, if you run this, you will notice a large amount of flickering stuff in the background 
		// on the TileLocation based positions. That's because at the current viewing angle, those off in the distance are 
		// shorter than a pixel, resulting in severe aliasing in and out of the scene. This does not
		// occur with the other position type, since it leaves no gaps. So uncomment the line below to use
		// that clip space position again to simply render those with the VertexLocation based position!
		// These sorts of aliasing problems make up a good portion of graphics programming.
	//if( ClipSpace.z / ClipSpace.w > 0.996 )
	//{
	//	ClipSpace = MVP * Position2;									   // Use the second position for our vertex position.
	//}


	gl_Position = ClipSpace;
}													 

