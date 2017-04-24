map_width = 60
map_height = 50
max_depth = 4
wall = 2
empty = 0
top_wall = 2
top_wall2 = 34
top_wall3 = 35
top_wall4 = 5
top_wall5 = 38
top_wall6 = 39
dbl_vert_hall = 41
top_door = 53
right_door = 54
left_door = 56
up_right_wall = 3
right_wall = 19
low_right_wall = 2
bottom_wall = 8
low_left_wall = 2
left_wall = 17
up_left_wall = 1
up_inl_corner = 43
up_inr_corner = 42
out_ur_corner2 = 97
out_ul_corner = 28
out_ul_corner2 = 96
out_lr_corner = 45
out_lr_corner2 = 113
out_ll_corner = 44
out_ll_corner2 = 112
floor = 18
floor2= 21
floor3= 46
floor4= 62
floor5= 30
floor6= 63

hall_floor=21
hall_v = 15
hall_h = 14
left_hall = 7
right_hall = 23
low_right_corner = 24
low_left_corner = 25
up_left_corner = 26
up_right_corner = 27
top_narrow = 12

function _init()
 -- modify seed so you can
 -- fix bugs related to specfic
 -- maps
 seed = flr(rnd(3500))
 seed=958
 srand(seed)

 clean_map()
 rooms = {}
 main_container = container(0, 0, map_width, map_height)
 container_tree = split_container(main_container, max_depth)
 foreach(rooms, function(room)
  room:tomap()
 end)
 add_walls()
 paths(container_tree)

 add_walls_and_doors()
 refine_edges()
 season()
end


cam_x = 0
cam_y = 0

function _update()
  if (btn(0) and cam_x > 0) cam_x -= 8
  if (btn(1) and cam_x < 395) cam_x += 8
  if (btn(2) and cam_y > 0) cam_y -= 8
  if (btn(3) and cam_y < 290) cam_y += 8
  if (btnp(4)) _init()
  if (btnp(5)) refine_edges()

end

function _draw()
  cls()
  -- set the camera to the current location
  camera(cam_x, cam_y)

  -- draw the entire map at (0, 0), allowing
  -- the camera and clipping region to decide
  -- what is shown
  map(0, 0, 0, 0, 128, 64)

  -- reset the camera then print the camera
  -- coordinates on screen
  camera()
  print('('..cam_x..', '..cam_y..')', 0, 0, 7)
  print("seed: "..seed,0,9,7)
end

function tree(leaf)
 return {
  leaf=leaf,
  lchild=nil,
  rchild=nil,
  paint=function(self)
   self.leaf:paint()
   if (self.lchild ~= nil) then
    self.lchild:paint()
   end
   if (self.rchild ~= nil) then
    self.rchild:paint()
   end
  end,
 }
end

function paths(t, tries)
 if (nil == tries) tries = 0
 --print("mapping paths "..tries)
 if (tries > 40) _init()
 if (nil == t.lchild or nil == t.rchild) return
 tries +=1
 t.lchild.leaf:path(t.rchild.leaf)
 paths(t.lchild, tries)
 paths(t.rchild, tries)
end

function container(x, y, w, h, tries)
 if (nil == tries) tries = 0
 tries += 1
 -- create a container cell
 -- it may be discarded
 local c = {
  x=flr(x), y=flr(y),
  w=flr(w), h=flr(h),
 }
 c.cx=c.x+flr(c.w/2)
 c.cy=c.y+flr(c.h/2)
 function c:paint()
	  rect(
	   self.x,  self.y,
	   self.x + self.w,
	   self.y + self.h,
	   7
	  )
 end
 function c:path(o)
  local x0 = min(self.cx, o.cx)
  local y0 = min(self.cy, o.cy)
  local x1 = max(self.cx, o.cx)
  local y1 = max(self.cy, o.cy)
  map_path(x0,y0,x1,y1)
 end
 return c
end


function map_path_spr(x0, y0, x1, y1, s)
 for x=x0,x1 do
  for y=y0,y1 do
   if (mget(x, y) ~= floor) mset(x, y, s)
  end
 end
end

function scan_path(x0, y0, x1, y1, tries)
 if (nil == tries) tries = 0
 local is_vertical = x0 == x1
 local is_horizontal = y0 == y1
 tries += 1
 for x=x0,x1 do
  for y=y0,y1 do
   local tile = mget(x,y)

   if (is_horizontal) then
	   if (tile == top_wall) then
	    return scan_path(x0, y+1, x1, y1+1, hall_v, tries)
	   end
	   if (tile == bottom_wall) then
	    return scan_path(x0, y+1, x1, y1+1, hall_v, tries)
	   end
	  end
   if (is_vertical) then
	   if (tile == left_wall) then
	    return scan_path(x+1, y0, x1+1, y1, hall_h, tries)
	   end
	   if (tile == right_wall) then
	    return scan_path(x+1, y0, x1+1, y1, hall_h, tries)
	   end
	  end
  end
 end
 return x0,y0,x1,y1
end

function map_path(x0, y0, x1, y1)
 local is_vertical = x0 == x1
 local is_horizontal = y0 == y1

 x2,y2,x3,y3 = scan_path(x0,y0,x1,y1)

 if (is_vertical) then
  map_path_spr(x2, y2, x3, y3, hall_v)
 end
 if (is_horizontal) then
  map_path_spr(x2, y2, x3, y3, hall_h)
 end

end

function map_room(x0, y0, x1, y1)
 for x=x0,x1 do
  for y=y0,y1 do
    mset(x, y, floor)
  end
 end
end

function make_room(c)
 if (nil == c) return
 -- create and add room from
 -- the given container's info
 local r = {}

 local w_padding = flr(c.w*.3)
 local h_padding = flr(c.h*.35)
 r.x=c.x + w_padding
 r.y=c.y + h_padding
 r.w=c.w - (w_padding * 2)
 r.h=c.h - (h_padding * 2)
 c.cx=r.x+flr(r.w/2)
 c.cy=r.y+flr(r.h/2)
 function r:tomap()
  map_room(
	  self.x,  self.y,
	  self.x + self.w,
	  self.y + self.h
  )
 end
 function r:paint()
  rectfill(
	  self.x,  self.y,
	  self.x + self.w,
	  self.y + self.h,
	  3
  )
 end
 add(rooms, r)
end

-- "random split" a container
function r_split(cont, tries)
 if (nil == tries) tries = 0
 tries += 1
 if (tries > 90) _init()
 local r1 = nil
 local r2 = nil
 if (rint(1, 2) == 1) then
  r1 = container(
   cont.x, cont.y,
   rint(1, cont.w), cont.h,
   tries
  )
  r2 = container(
   cont.x + r1.w, cont.y,
   cont.w - r1.w, cont.h,
   tries
  )
  if (r1.w / r1.h < 0.45 or r2.w / r2.h < 0.45) then
   return r_split(cont, tries)
  end
 else
  r1 = container(
   cont.x, cont.y,
   cont.w, rint(1, cont.h),
   tries
  )
  r2 = container(
   cont.x, cont.y + r1.h,
   cont.w, cont.h - r1.h,
   tries
  )

  if (r1.h / r1.w < 0.45 or r2.h / r2.w < 0.45) then
   return r_split(cont, tries)
  end
 end
 return r1, r2
end

function split_container(c, iter)
 local root = tree(c)
 if (iter ~= 0) then
  local sr1, sr2 = r_split(c)
  root.lchild = split_container(sr1, iter-1)
  root.lchild.parent = root
  root.rchild = split_container(sr2, iter-1)
  root.rchild.parent = root
  -- when we reach the end,
  -- add rooms to the containers
  if (iter == 1) then
   if (sr1.w > 4 and sr1.h > 4) make_room(sr1)
   if (sr2.w > 4 and sr2.h > 4) make_room(sr2)
  end
 end
 return root
end

function clean_map()
 --print("cleaning map")
 for x=0, 128 do
  for y = 0, 64 do
   mset(x,y,0)
  end
 end
end


function calc_walltype(x,y)
 local edges=0
 local top=mget(x,y-1)
 local right=mget(x+1,y)
 local bottom=mget(x,y+1)
 local left=mget(x-1,y)
 local is_bottom=(
  top ~= empty and
  bottom == empty
 )
 local is_top=(
  top == empty and
  bottom == floor)
 local is_ul=(
  is_top == true and
  left == empty)
 local is_ur=(
  is_top == true and
  right == empty)
 local is_right=(
  right == empty and
  is_top == false
 )
 local is_left=(
  left == empty and
  is_top == false
 )
 local is_ll=(
  left == empty and
  is_bottom == true
 )
 local is_lr=(
  right == empty and
  is_bottom == true
 )
 local is_vertical_hall=(
  left == empty and
  right == empty
 )
 local is_horizontal_hall=(
  top == empty and
  bottom == empty
 )
 if (is_horizontal_hall or is_vertical_hall) return

 if (is_bottom) mset(x,y+1, bottom_wall)
 if (is_top) mset(x,y-1,top_wall)
 if (is_ul) mset(x-1,y-1,up_left_wall)
 if (is_ur) mset(x+1,y-1,up_right_wall)
 if (is_ll) then
  mset(x-1,y, left_wall)
  mset(x-1,y+1,bottom_wall)
 end
 if (is_lr) then
  mset(x+1,y, right_wall)
  mset(x+1,y+1,bottom_wall)
 end

 if (is_right) mset(x+1,y-1, right_wall)
 if (is_left) mset(x-1,y-1, left_wall)
end

function season()
 local x = nil
 local y = nil
 for x=0, map_width do
  for y=0, map_height do
   local tile = mget(x,y)
   if (tile == floor) then
    local r=rnd()
    if (r>0.69) mset(x,y,floor2)
    if (r>=0.76) mset(x,y,floor3)
    if (r>=0.87) mset(x,y,floor4)
    if (r>=0.97) mset(x,y,floor5)
    if (r>=0.98) mset(x,y,floor6)
   end
   if (tile == top_wall) then
    local r=rnd()
    if (r>0.70) mset(x,y,top_wall2)
    if (r>=0.76) mset(x,y,top_wall3)
    if (r>=0.87) mset(x,y,top_wall4)
    if (r>=0.97) mset(x,y,top_wall5)
    if (r>=0.98) mset(x,y,top_wall6)
   end
  end
 end
end

function add_walls()
 local x = nil
 local y = nil
 for x=0, map_width do
  for y=0, map_height do
   local tile = mget(x,y)
   if (tile == floor) calc_walltype(x, y)
  end
 end
end

function refine_edges()
 --fixes until no mutations
 --dont use random detail here
 local x = nil
 local y = nil
 local mutations = 0
 for x=0, map_width do
  for y=0, map_height do
   local tile=mget(x,y)
   local above=mget(x,y-1)
   local right=mget(x+1,y)
   local below=mget(x,y+1)
   local left=mget(x-1,y)
   -- doors to nowhere lol
   if (tile==left_door) then
    if (left==left_hall) then
     mset(x-1,y,empty)
     mset(x,y,left_hall)
     mutations+=1
    end
   end
   -- doors to nowhere xd
   if (tile == right_door) then
    if (right==right_hall) then
     mset(x+1,y,empty)
     mset(x,y,right_hall)
     mutations+=1
    end
   end

   -- issues top doors
   if (tile == top_door) then
    if (right==up_inr_corner and
        mget(x+2,y)==top_wall) then
			  mutations +=1
     mset(x+1,y,top_wall)
    end
    --fix double doors ffs
    if (above==top_door) then
     mutations +=1
     mset(x, y, below)
    end
    --fix orphan doors
    if (right==hall_v or right==hall_h) then
     mutations+=1
     mset(x,y,right)
    end
    if (left==hall_v or left==hall_h) then
     mutations+=1
     mset(x,y,left)
    end
   end

   --correct bad up_inr_corner placements
   if (tile == up_inr_corner) then
    if (right==top_wall) then
     mset(x,y,top_wall)
			  mutations +=1
    end
			end

   --correct bad up_inl_corner placements
   if (tile==up_inl_corner) then
    -- on occasion this corner
    -- tile should be a top_wall
    if (right==top_wall) then
     mset(x,y,top_wall)
			  mutations +=1
    end
    -- add outer corner tile
    -- to make it look finished
			 if (left==empty and
			     mget(x-1,y-1)==right_hall) then
			  mutations +=1
			  mset(x-1,y,out_ll_corner)
			 end
			 if (below==empty and
			     mget(x+1,y+1)==left_wall) then
			  mutations +=1
			  mset(x,y+1,out_ll_corner2)
			 end
   end

   -- halls may need "double walls"
   -- meaning a tile that has both
   -- left and right on the same one
   if (tile == left_hall) then
    if (left == hall_v or left==hall_h) then
     mutations +=1
     mset(x,y,dbl_vert_hall)
    end
   end

   -- "double walls" cont..
   if (tile == right_hall) then
    if (right == hall_v or right==hall_h) then
     mset(x,y,dbl_vert_hall)
    end
   end

   -- bottom_wall fixes
   if (tile == bottom_wall) then
    -- wrap corners of bottom walls
    -- which are not surrounded by
    -- other tiles
    if (left==empty and
        right==empty) then
			  mutations +=1
			  mset(x-1,y,out_ll_corner)
     mset(x+1,y,out_lr_corner)
    end

    -- when diagonal piece is above and left
    -- we need to add corner to outer edge
    if (left==empty and
        mget(x-1,y-1)==up_inl_corner) then
     mutations += 1
     mset(x-1,y,out_ll_corner)
    end

    if (right==empty and
        mget(x+1,y-1)==up_inr_corner) then
     mutations += 1
     mset(x+1,y,out_lr_corner)
    end
   end

   --top_wall bullshit
   if (tile == top_wall) then
    -- make doors when the
    -- rest of the map is blocked off
    if (above==hall_v or above==hall_h) then
     if (below==hall_v or below==hall_h) then
      mutations += 1
      mset(x,y, top_door)
     end
    end
    -- remove orphan walls

    -- in the case where a wall
    -- is surrounded by nothing
    -- except south
    if (above==empty and
        right==empty and
        left==empty) then
     mutations += 1
     mset(x,y,empty)
     mset(x,y+1,top_wall)
    end

    -- wall is surrounded by empty
    -- except right has opposite facing
    -- wall
    if (above==empty and
        right==left_hall and
        left==empty) then
     mutations += 1
     mset(x,y,empty)
     mset(x,y+1,top_wall)
    end

 		 -- when a wall's lower left
 		 -- adjacent tile is a vert
 		 -- wall, it looks weird witouht
 		 -- that vert wall continuing
 		 if (left==empty and
 		     mget(x-1,y-1)==wall_right) then
     mutations += 1
     mset(x-1,y,wall_right)
 		 end
   end

   -- weird edge case where
   -- cooridoor ends to nothing
   if (tile==hall_h and
       left==empty) then
     mutations+=1
     mset(x,y,left_hall)
    if (above==top_wall) then
     mset(x,y-1,left_hall)
     mutations+=1
    end
    if (below==up_inl_corner) then
     mset(x,y+1,left_hall)
     mutations+=1
    end

   end

  end
 end

 if (mutations > 0) refine_edges()
end

function add_walls_and_doors ()
 local x = nil
 local y = nil
 local mutations = 0
 for x=0, map_width do
  for y=0, map_height do
   local tile=mget(x,y)
   local above=mget(x,y-1)
   local right=mget(x+1,y)
   local below=mget(x,y+1)
   local left=mget(x-1,y)
   if (tile == hall_v or tile == hall_h or tile == hall_floor) then

    if (left==top_wall and
        right==top_wall) then
     mset(x,y, top_door)
    end
    if (below==empty and
        mget(x,y+2) == hall_v) then
     mset(x,y,hall_v)
    end
    if (below==empty) then
     mset(x,y+1,bottom_wall)
    end

    if (above==empty or
        above==bottom_wall) then
     mset(x,y-1,top_wall)
    end

    if (left==bottom_wall and
        right==bottom_wall) then
     mset(x,y, top_door)
    end

    if (left~=empty and
        right~=empty and
        above==floor) then
      mset(x,y, top_door)
    end

    if (right==empty) then
      mset(x+1,y, right_hall)
    end

    if (left==empty) then
      mset(x-1,y, left_hall)
    end

    if (above==right_hall) then
      mset(x,y-1, top_wall)
    end

    if (below==right_hall) then
      mset(x,y+1,up_inr_corner)
    end

    if (left==bottom_wall) then
      mset(x-1,y,up_inl_corner)
    end

    if (right==bottom_hall) then
      mset(x+1,y,up_inr_corner)
    end

    if (left==up_inr_corner and
        right ~= hall_v and
        right ~= hall_h) then
      mset(x-1,y,top_narrow)
    end

    if (right==bottom_wall) then
      mset(x+1,y,up_inr_corner)
    end

    if (above==right_wall and
        below==right_wall) then
      mset(x,y,right_door)
    end

    if (above==right_wall and
        below==bottom_wall) then
      mset(x,y,right_door)
    end

    if (above==up_right_wall and
        below==right_wall) then
      mset(x,y,right_door)
    end

    if (above==right_wall and
        below==low_right_wall) then
				 mset(x,y,right_door)
    end

    if (above==left_wall and
        below==low_left_wall) then
     mset(x,y,left_door)
    end

    if (above==up_left_wall and
        below==left_wall) then
     mset(x,y,left_door)
    end

    if (above==left_wall and
        below==left_wall) then
      mset(x,y,left_door)
    end

    if (above==left_wall and
        below==bottom_wall) then
      mset(x,y,left_door)
    end
   end
  end
 end
end

function rint(a, b)
 return flr(rnd(b)) + a
end

