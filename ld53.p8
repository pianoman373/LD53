pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--[ld53]--
-- ludum dare 53
-- by pianoman373

function _init()
	
end

function _update60()
	
end

function _draw()
	
end
-->8
--[utilities]--

function col_list(hb, list)
	local r = {}
	for e in all(list) do
		if col(hb, e) then
			add(r, e)
		end
	end
	return r
end

function find_nearest(x, y, list, range)
	local ldist = -1
	local le = nil
	local range = range or 10000000
	for i in all(list) do
		
		local dx = abs(x-(i.x+i.w/2))/8
		local dy = abs(y-(i.y+i.h/2))/8
		local dist = sqrt(dx*dx) + sqrt(dy*dy)
		
		if le then
			if dist < ldist then
				le = i
				ldist = dist
			end
		else
			le = i
			ldist = dist
		end
	end
	
	if ldist < range then
		return le
	end
end

function draw_hb(o, col)
	rect(o.x, o.y, o.x+o.w-1, 
		o.y+o.h-1, col or 15)
end

function move(e)
	local col_x = false
	local col_y = false
	
	e.x += e.dx
	if map_col(e) then
		e.x -= e.dx
		e.dx = 0
		col_x = true
	end
	
	e.y += e.dy
	if map_col(e) then
		e.y -= e.dy
		e.dy = 0
		col_y = true
	end
	
	return col_x, col_y
end

function col(a, b)
	return a.x < b.x+b.w-1
		and a.x+a.w-1 > b.x
		and a.y < b.y+b.h-1
		and a.y+a.h-1 > b.y
end

function map_col(o, f)
	local f = f or 0
	local x1 = o.x/8
	local x2 = (o.x+o.w-1)/8
	local y1 = o.y/8
	local y2 = (o.y+o.h-1)/8

	local a = mget(x1, y1)
	local b = mget(x1, y2)
	local c = mget(x2, y1)
	local d = mget(x2, y2)
	
	return fget(a, f) or fget(b, f)
		or fget(c, f) or fget(d, f)
		or x1 < 0 or y1 < 0
end

function dist(dx,dy)
  local ang=atan2(dx,dy)
  return dx*cos(ang)+dy*sin(ang)
end

function nrm(x, y)
	local a = atan2(x, y)
	return cos(a), sin(a)
end

function tlerp(t, x)
	local x = mid(0.0001, x, 0.9999)
	return t[flr(x*#t)+1]	
end

function flash(c)
	if cos(t()*4) > 0 then
		pal({[0]=c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,c}, 0)
	end
end

function unflash()
	pal(0)
end

function print_otl(str, x, y, col, otl_col)
		print(str, x-1, y, otl_col or 0)
		print(str, x+1, y, otl_col or 0)
		print(str, x, y-1, otl_col or 0)
		print(str, x, y+1, otl_col or 0)
		
		print(str, x-1, y-1, otl_col or 0)
		print(str, x+1, y+1, otl_col or 0)
		print(str, x+1, y-1, otl_col or 0)
		print(str, x-1, y+1, otl_col or 0)
		
		
		print(str, x, y, col or 7)
end

function spr_otl(c, n, x, y, w, h, flip_x, flip_y)
	w = w or 1
	h = h or 1
	flip_x = flip_x or false
	flip_y = flip_y or false
	
	pal({[0]=c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,c}, 0)
	
	spr(n, x-1, y, w, h, flip_x, flip_y)
	spr(n, x+1, y, w, h, flip_x, flip_y)
	spr(n, x, y-1, w, h, flip_x, flip_y)
	spr(n, x, y+1, w, h, flip_x, flip_y)

	pal(0)
	
	spr(n, x, y, w, h, flip_x, flip_y)
end

-- from https://www.lexaloffle.com/bbs/?tid=38548
function pd_rotate(x,y,rot,mx,my,w,flip,scale)
  local step = 1/32
  scale=scale or 1
  rot=rot\step * step
  local halfw, cx=scale*-w/2, mx + .5
  local cy,cs,ss=my-halfw/scale,cos(rot)/scale,sin(rot)/scale
  local sx, sy, hx, hy=cx+cs*halfw, cy+ss*halfw, w*(flip and -4 or 4)*scale, w*4*scale
  for py=y-hy, y+hy do
  tline(x-hx, py, x+hx, py, sx -ss*halfw, sy + cs*halfw, cs/8, ss/8)
  halfw+=.125
  end
end

function onscreen(e, pad)
	local hb = {
		x=camx-pad,
		y=camy-pad,
		w=128+pad,
		h=128+pad
	}
	
	return col(e, hb)
end

debug_log = ""

dbg = {}
function dbg.tstr(t, indent)
 indent = indent or 0
 local indentstr = ''
 for i=0,indent do
  indentstr = indentstr .. ' '
 end
 local str = ''
 for k, v in pairs(t) do
  if type(v) == 'table' then
   str = str .. indentstr .. k .. '\n' .. debug.tstr(v, indent + 1) .. '\n'
  else
   str = str .. indentstr .. tostr(k) .. ': ' .. tostr(v) .. '\n'
  end
 end
  str = sub(str, 1, -2)
 return str
end

function dbg.draw(col)
	print(debug_log, 1, 1, 0)
	print(debug_log, 0, 0, col)
end

function dbg.log(msg)
	debug_log = debug_log..tostr(msg).."\n"
end

function dbg.clear()
	debug_log = ""
end

function arr3d(i, j, k, val)
	local t1 = {}
	
	for x=1,i do
		local t2 = {}
		
		for y=1,j do
			local t3 = {}
			
			for z=1,k do
				add(t3, val)
			end
			
			add(t2, t3)
		end
		
		add(t1,t2)
	end
	return t1
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
