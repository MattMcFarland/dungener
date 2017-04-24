## Dungeon Generation API
This is a highly commented, thorough dungeon generation API that uses BSP (Binary Space Partitioning)

## Usage
To use, copy and paste all of the contents of index.lua into your pico8 file.

### `genesis(width,height,max_depth,pathfn,renderfn,min_size) -> rooms, tree`

Generates a dungeon using the BSP algorith.
The width and height are arbitrary units that can be used for pixels, the pico8 map, or something of your own creation.

```lua
local rooms, tree = genesis(
  map_width,
  map_height,
  depth,
  on_path_render,
  on_room_render
)
```

#### max_depth (int)

How deep the BSP tree gets. The greater the number, the more and smaller rooms are generated. For large maps, a higher number is useful, smaller maps, a lower number works better. The program will begin to decrease depth automatically if the process is taking too long. (decreases every second)

#### pathfn (function)

it is called with (x0,y0,x1,y1)   where the coordinates make a line from two points, the line is always  vertical, or horizontal. it always goes from center of a container to another center of another container. It is guaranteed to go from left to right, or top to bottom.

```lua
function render_paths(node)
  if (nil == node.lchild or nil == node.rchild) return
  node.lchild.leaf:render_path(node.rchild.leaf)
  render_paths(node.lchild)
  render_paths(node.rchild)
end
```

#### renderfn (function)

it is called with (x0,y0,x1,y1) where the coordinates make a rectangle called on your own by iterating over rooms and calling room.render() on each used to render tiles to the map, or to pixels.

```lua
function on_room_render (x0,y0,x1,y1)
  rectfill(x0,y0,x1,y1,3)
  rect(x0,y0,x1,y1,6)
end
```

#### min_size (int) (default: 8)

minimum room size before the room is not added to the rooms array, default is 8.
The program will decrease the minimum size automatically if it is taking too long to process, which is usually only the case when the minimum size is too high.

#### returns

A tuple of rooms and the tree. rooms contains data about each room in the map, and the tree contains traversable tree of containing cells primarily used for calling rendering functions

#### Rendering

Assuming you have created something like the `on_path_render` and `on_room_render` functions above, you then iterate over the rooms and traverse the tree to render the map.  In the demo, we use these functions:

```lua
	function render_rooms()
		foreach(rooms, function(room)
			room:render()
		end)
	end

	function render_paths(node)
		if (nil == node.lchild or nil == node.rchild) return
		node.lchild.leaf:render_path(node.rchild.leaf)
		render_paths(node.lchild)
		render_paths(node.rchild)
	end
```


### Full Example
```lua
function _init()
	-- since we are rendering to pixels,
	-- we use the screen resolution
	local map_width=127
	local map_height=127
	-- define how deep our binary trie goes
	-- the higher, the smaller and more rooms you get
	-- for smaller maps, you should use a smaller number.
	local depth=6
	-- declare how the paths are rendered
	function on_path_render (x0,y0,x1,y1)
		line(x0,y0,x1,y1,6)
	end
	-- declare how the rooms are rendered
	function on_room_render (x0,y0,x1,y1)
		rectfill(x0,y0,x1,y1,3)
		rect(x0,y0,x1,y1,6)
	end
	-- get our room and tree tables from
	-- the generator
	local rooms, tree = genesis(
		map_width,
		map_height,
		depth,
		on_path_render,
		on_room_render
	)
	-- now we have our rooms and tree (technically trie)
	-- but they arent going to render themselves.
	-- to do this, we need to iterate over the rooms
	-- and the paths by themselves.

	-- create a function that will render all of the rooms
	-- by calling the render function on each of the rooms,
	-- the rooms themselves will then call the on_room_render
	function render_rooms()
		foreach(rooms, function(room)
			room:render()
		end)
	end
	-- create a function that will recursively walk down the tree
	-- and render paths between each container cell and
	-- rooms. which creates our hallways. it will end when
	-- it reaches the "bottom" of the tree, where a node does not
	-- have children.
	function render_paths(node)
		if (nil == node.lchild or nil == node.rchild) return
		node.lchild.leaf:render_path(node.rchild.leaf)
		render_paths(node.lchild)
		render_paths(node.rchild)
	end
	-- with our functions defined, we can now render the dungeon.
	cls()
	render_paths(tree)
	render_rooms()
end
```


## License
MIT
