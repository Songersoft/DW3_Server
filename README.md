# DW3_Server
A remake of Dragon Warrior / Quest 3 with a Server for Multiplayer

Some concepts:
I use a board surface to quickly display the environment around the player.
Board is created at some size and world surrounding player is drawn to it.
The bigger the board surface the less likely a board redraw event will need to occure, but more memory the client consumes.

Board must be redrawn when the player reaches the bounds of the board (board of course gets it's data from tile[ world[w][l][x][y] ].
Board has layers just like world so that I may seporate drawing and draw between them. aBoard[layer_max]
 
A rectange surrounding player of screen size is copied from aBoard to screen.

[picture]

This is just the basic outline, aBoard and aWorld are probably dllstructs.

Areas are to subdivide words.  They will be extreamly useful for managing world: people[npc], items, hotspot, ect.  Areas have a position: x, y, w, h an out-of-bounds tile to draw outside of the bounds of the area position.  A world and position to load if you step out of the area position bounds.  But srsly if you care you can just look at the code.

The world data

World[x][y] = 

Pair the world with tile, kinda like this: tile[ world[x][y].iTile ]

World Data starts with a header: width, height, tile_max
Tile_max is to create and then read back the cell padding of this human friendly world data file: 

Ultimatly I want to 
and tile[] is a list of tile surfaces.
I'm so far ahead of myself I really just want to provide the source and start asking some of my questions to mold this project into a 
client-server game.
