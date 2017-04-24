## Dungeon Generation API
This is a highly commented, thorough dungeon generation API that uses BSP (Binary Space Partitioning)

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

it is called with (x0,y0,x1,y1)   where the coordinates make a line from two points, the line is always  vertical, and horizontal. it always goes from center of a container to another center of another container. It is guaranteed to go from left to right, or top to bottom.

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

## License
MIT