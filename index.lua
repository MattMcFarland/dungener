-- DunGener v0.1.1
-- generates a dungeon using the BSP algorithm
-- the width and height are arbitrary units
-- that can be used for pixels, the pico8 map, or
-- something of your own creation.
-- @see http://www.roguebasin.com/index.php?title=Basic_BSP_Dungeon_generation
-- @see https://eskerda.com/bsp-dungeon-generation/
-- @param {int} width Map width - see above for more info
-- @param {int} height Map Height - see above for more info
-- @param {int} max_depth - how deep the BSP tree gets
--				the greater the number, the more and smaller rooms
--				are generated. For large maps, a higher number is useful,
--				smaller maps, a lower number works better.
--				The program will begin to decrease depth automatically
--				if the process is taking too long. (decreases every second)
-- @param {fn} pathfn - path connection function
-- 				it is called with (x0,y0,x1,y1)
--        where the coordinates make a line
--        from two points, the line is always
--        vertical, and horizontal. it always goes
--        from center of a container to another center
--        of another container. It is guaranteed to
--        go from left to right, or top to bottom.
--				you can use this to render tiles
--        to the map, or to pixels.
-- @param {fn} renderfn - room rendering function
-- 				it is called with (x0,y0,x1,y1)
--        where the coordinates make a rectangle
--				called on your own by iterating
--				over rooms and calling room.render() on each
--				used to render tiles to the map, or to pixels.
-- @param {int} min_size - minimum room size before
--				the room is not added to the rooms array, default is 8.
--				The program will decrease the minimum size if it is taking
--				too long to process, which is usually only the case when
--				the minimum size is too high.
-- @returns {table} rooms, {table} tree
--				tuple of tables, rooms and tree.
--				rooms contains data about each room in the map
--				tree contains traversable tree of containing cells
--				primarily used for calling rendering functions

function genesis(width, height, max_depth, pathfn, renderfn, min_size)
	local fail = false
	if (__retries == 500) then
		if (max_depth > 2) max_depth -= 1
	end
	if (__retries == 1000) then
		if (min_size > 4) min_size -= 1
		__retries = 0
	end
	if (nil == min_size) min_size = 8
	local rooms = {}
	function new_tree(leaf)
		if (fail) return
		return {
			leaf=leaf,
			lchild=nil,
			rchild=nil
		}
	end

	function new_container(x, y, w, h)
		if (fail) return
		-- create a container cell
		local c = {
			x=flr(x), y=flr(y),
			w=flr(w), h=flr(h),
		}
		-- calculate center coordinates
		c.cx=c.x+flr(c.w/2)
		c.cy=c.y+flr(c.h/2)
		-- render path fn
		function c:render_path(o)
			local x0 = min(self.cx, o.cx)
			local y0 = min(self.cy, o.cy)
			local x1 = max(self.cx, o.cx)
			local y1 = max(self.cy, o.cy)
			pathfn(x0,y0,x1,y1)
		end
		return c
	end
	-- divide container into two
	-- smaller "sub" containers
	function split_container(cont, tries)
		if (fail) return
		if (nil == tries) tries = 0

		local r1 = nil
		local r2 = nil

		tries += 1

		if (rint(1, 2) == 1) then
			r1 = new_container(
				cont.x, cont.y,
				rint(1, cont.w), cont.h,
			tries
			)
			r2 = new_container(
				cont.x + r1.w, cont.y,
				cont.w - r1.w, cont.h,
				tries
			)
			if (tries < 60) then

				local r1_w_ratio=r1.w/r1.h
				local r2_w_ratio=r2.w/r2.h

				if (r1_w_ratio < 0.45 or r2_w_ratio < 0.45) split_container(cont, tries)
			end

		else
			r1 = new_container(
				cont.x, cont.y,
				cont.w, rint(1, cont.h),
				tries
			)
			r2 = new_container(
				cont.x, cont.y + r1.h,
				cont.w, cont.h - r1.h,
				tries
			)

			if (tries < 60) then
				local r1_h_ratio=r1.h/r1.w
				local r2_h_ratio=r2.h/r2.w
				if (r1_h_ratio < 0.45 or r2_h_ratio < 0.45) split_container(cont, tries)
			end
		end
		if (tries >= 60) fail = true
		return r1, r2
	end

	function add_children(c, depth)
		if (fail) return
		depth -= 1
		local root = new_tree(c)
		if (depth >= 0) then
			if (c.w > min_size*2.5 and c.h > min_size*2.5) then

				local sr1, sr2 = split_container(c)
				if (sr1.w > min_size and sr2.w > min_size and
				 		sr1.h > min_size and sr2.h > min_size) then

					root.lchild = add_children(sr1, depth)
					root.rchild = add_children(sr2, depth)
					-- when we reach the end,
					-- add rooms to the containers
					if (depth == 0) then
						make_room(sr1)
						make_room(sr2)
					end
				else
					if (__retries) fail = true
				end

			else
			 fail = true
			end
		end
		return root
	end

	function make_room(c)
		if (nil == c or fail) return
		-- create and add room from
		-- the given container's info
		local r = {}

		local w_padding = rint(flr(c.w*.15), flr(c.w*.25))
		local h_padding = rint(flr(c.h*.20), flr(c.h*.25))
		r.x = c.x + w_padding
		r.y = c.y + h_padding
		r.w = c.w - (w_padding * 2)
		r.h = c.h - (h_padding * 2)
		if (r.h > r.w*1.6) then
		  local cap = rint(r.w, r.w*1.25)
			local difference = r.h-cap
			r.h=cap
			r.y += flr(difference/2)
		end
		if (r.w > r.h*1.6) then
		  local cap = rint(r.h, r.h*1.25)
			local difference = r.w-cap
			r.w=cap
			r.x += flr(difference/2)
		end
		function r:render()
			renderfn(
				self.x,  self.y,
				self.x + self.w,
				self.y + self.h
			)
		end
		add(rooms, r)
	end

	local root = new_container(0, 0, width, height)
	local tree = add_children(root, max_depth)

	if (fail == false) then
		return rooms, tree
	else
		__retries +=1
		root=nil
		tree=nil
		return genesis(width, height, max_depth, pathfn, renderfn, min_size)
	end
end

function rint(a, b)
 return flr(rnd(b)) + a
end

__retries = 0