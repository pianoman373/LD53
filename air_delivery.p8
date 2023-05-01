pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--[ld53]--
-- ludum dare 53
-- by pianoman373

camx=2*128
camy=128
pause=false
state="menu"

states={}
states.over={
	update=function()
	end,
	draw=function()
		camera(0, 0)
		--sky
		map(0,0,0,0,16,16)
		
		camera(0, 32)
		draw_clouds()
		camera(0,0)
		rectfill(0, 96, 128, 128, 10)
		map(0,16,0,0,16,16)
		local x=32
		local y=64+isin3(0.25)
		
		filt(14)
		spr(27, x, y, 1, 3)
		spr(27, x-8, y, 1, 3, true)
		reset_pal()
		
		local s="the end"
		oprint(s, 64-(#s*2), 120, 7, 0)
	end
}
states.menu={
	update=function()
		if btnp(❎) or btnp(🅾️) then
			state = "game"
			music(0)
		end
	end,
	draw=function()
		camera(0, 0)
		--sky
		map(0,0,0,0,16,16)
		draw_clouds()
		
		local s="press ❎/🅾️ to start"
		oprint(s, 60-(#s*2), 70, 7, 0)
		
		local s="air delivery"
		oprint(s, 64-(#s*2), 20, 7, 0)
		
		print("a game by pianoman373", 2, 122, 0)
		
	
	end
}
states.game={
	update=function()
		update_particles()
		if (p.dead==0) update_camera()
		if not pause and not in_dialogue then
			update_p()
		end
		if in_dialogue then
		 update_dialogue()
		 p.moving=false
		end
	end,
	draw=function()
		camera(0, 0)
		--sky
		map(0,0,0,0,16,16)
		draw_clouds()
		
		--level
		camera(camx, camy)
		map(0,0,0,0,128,128)
		
		airship:draw()
		
		--npcs
		for k,v in pairs(npcs) do
			draw_npc(v)
		end
		
		--packages
		foreach(packages, draw_package)
		--mailboxes
		foreach(mailboxes, draw_mailbox)
		
		draw_particles()
		
		draw_p()
		
		camera(0, 0)
		if (in_dialogue) draw_dialogue()
	
		draw_ingame_ui()
		dbg.draw(7)
	end
}


function draw_clouds()
	--clouds
	local x=(t*2)%128
	--camera(x, 0)
	
	--copy extended ram into spritesheet
	memcpy(0,0x8000,0x1000)
	spr(0,-x,64,16,8)
	spr(0,128-x,64,16,8)
	--map(16,0,0,0,16,16)
	
	--reset spritesheet
	memcpy(0,0x9000,0x1000)
end

cam_tx=camx
cam_ty=camy

function isin2(p,o)
	return flr(sin(t*p+(o or 0))*0.5+1)
end

function isin3(p,o)
	return flr(sin(t*p+(o or 0))+0.5)
end

function update_camera()
	if p.x+4 > camx+128 then
		pause=true
		cam_tx+=128
	end
	if p.x+4 < camx then
		pause=true
		cam_tx-=128
	end
	if p.y+4 > camy+128 then
		pause=true
		cam_ty+=128
	end
	if p.y+4 < camy and p.y+4>0 then
		pause=true
		cam_ty-=128
	end
	
	if (cam_tx > camx) camx+=4
	if (cam_tx < camx) camx-=4
	if (cam_ty > camy) camy+=4
	if (cam_ty < camy) camy-=4
	
	if pause and cam_tx==camx and cam_ty==camy then
		pause = false
	end
end

function reset_pal()
	pal()
	pal(11, 128+11, 1)
	pal(12, 128+12, 1)
	pal(14, 128+14, 1)
	pal(15, 128+15, 1)
	pal(10, 15, 1)
	pal(6, 128+6, 1)
	pal(4, 128+4, 1)
	pal(2, 128+2, 1)
end

function _init()
	--hide death block
	for x=72,79 do
		for y=0,7 do
			sset(x, y, 0)
		end
	end

	music(8)
	camx=flr(p.x/128)*128
	camy=flr(p.y/128)*128
	cam_tx=camx
	cam_ty=camy

	reset_pal()
	
	reload(0x8000, 0, 0x2000, "clouds.p8")
	
	--copy top half spritesheet to bottom half ram
	memcpy(0x9000, 0, 0x1000)
	
	-- keep palette 
 poke(0x5f2e,1)
 -- disable btnp autorepeat
 poke(0x5f5c,-1)
end

function _update60()
	t=time()
	states[state].update()
end

function _draw()
	cls()
	
	states[state].draw()
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

function col_dict(hb, dict)
	local r = {}
	for k,e in pairs(dict) do
		if col(hb, e) then
			add(r, {k, e})
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
	return a.x < b.x+(b.w or 8)-1
		and a.x+(a.w or 8)-1 > b.x
		and a.y < b.y+(b.h or 8)-1
		and a.y+a.h-1 > (b.y or 8)
end

function map_col(o, f)
	local f = f or 0
	local x1 = o.x/8
	local x2 = (o.x+o.w-1)/8
	local y1 = o.y/8
	local y2 = (o.y+o.h-1)/8
	x1=mid(0,x1,128)
	x2=mid(0,x2,128)
	y1=mid(0,y1,128)
	y2=mid(0,y2,128)

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

function filt(c)
	pal({[0]=c,c,c,c,c,c,c,c,c,c,c,c,c,c,c,c}, 0)
end

function unflash()
	pal(0)
end

function oprint(str, x, y, col, otl_col)
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

function ospr(c, n, x, y, w, h, flip_x, flip_y)
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
-->8
--[player]--

p = {
	x=38*8,
	y=19*8,
	--x=47*8,
	--y=45*8,
	w=7,
	h=8,
	dx=0,
	dy=0,
	left=false,
	grounded=false,
	moving=false,
	interact=nil,
	gliding=false,
	climbing=false,
	displaying=nil,
	rdy_drill=false,
	dead=0,
	items={
		glider={
			unlocked=false,
			sp=91
		},
		drill={
			unlocked=false,
			sp=88
		},
		gear={
			unlocked=false,
			sp=103
		},
		key={
			unlocked=false,
			sp=117
		}
	},
	packages={}
}

friction = 0.7
jump_boost = 3.4
max_speed_x = 4
max_speed_y = 4
move_acc = 1
cheats=false

running_sp={2,3,4}
climbing_sp={2,4}

function carrying_pkg_for(npc)
	for pkg in all(p.packages) do
		if pkg.dest == npc then
			return pkg
		end
	end
	return nil
end

function drill_rock(tag)
	sfx(12)
	
	local x = (p.x/8) - 2
	local y = (p.y/8) - 2
	
	for tx=0,4 do
		for ty=0,4 do
			local t = mget(x+tx, y+ty)
			if fget(t, tag) then
				mset(x+tx, y+ty, 0)
			end
		end
	end
end

function give_item(id)
	sfx(11)
	p.items[id].unlocked=true
	p.displaying=id
end

function has_item(id)
	return p.items[id].unlocked
end

function respawn()
	p.x=current_mailbox.x
	p.y=current_mailbox.y
	p.dx=0
	p.dy=0
	
	camx=flr(p.x/128)*128
	camy=flr(p.y/128)*128
	cam_tx=camx
	cam_ty=camy
end

function update_p()
	
	local gravity = 0.2

	--death check
	if p.dead > 0 then
		p.dead-=1
		p.dy += gravity
		move(p)
		
		if (p.dead==1) respawn()
		return
	end
	
	if map_col(p, 4) and not cheats then
		p.dead=100
		sfx(14)
	end

	if p.displaying then
		if btnp(❎) or btnp(🅾️) then
			p.displaying = nil
		end
	
		return
	end
	
	--movement input
	if (btn(⬅️)) then
		p.dx = -move_acc
		p.left = true
	end
	if (btn(➡️)) then
		p.dx = move_acc
		p.left = false
	end
	if btn(⬆️) and p.climbing then
		p.dy = -move_acc
	end
	if btn(⬇️) and p.climbing then
		p.dy = move_acc
	end
	
	--jumping
	if btnp(🅾️) and (p.grounded or p.climbing) then
		p.dy = -jump_boost
		p.climbing=false
		sfx(35)--jump
		jump(p.x+4,p.y+6)
	end
	
	--physics
	if (not p.climbing) p.dy += gravity
	if (p.climbing) p.dy*= friction
	p.dx *= friction
	
	--fly hack
	if btn(⬆️) and cheats then
		p.dy = -1
	end
	
	--gliding
	if btnp(🅾️) and not p.grounded and has_item("glider") then
		if (not p.gliding) sfx(36)
		
		p.gliding=true
	end	
	if p.gliding then
		if not btn(🅾️) or p.grounded then
			p.gliding=false
		end
	
		p.dy = min(p.dy, 1/3)
	end
	
	--climbing
	if map_col(p, 1) or (map_col(p, 3) and has_item("gear")) then
		if btnp(⬆️) then
			p.climbing=true
		end
	elseif p.climbing then
		p.climbing=false
	end
	
	p.dx = mid(-max_speed_x, p.dx, max_speed_x)
	p.dy = mid(-max_speed_y, p.dy, max_speed_y)
	local falling = p.dy > 0
	
	col_x, col_y = move(p)
	p.grounded = falling and col_y
	p.moving = abs(p.dx)>0.1 or abs(p.dy)>0.1

	p.x = mid(0, p.x, 128*8-7)

	--check for npcs
	p.interact=nil
	local hb={x=p.x-4,y=p.y-4,w=16,h=16}
	local hits=col_dict(hb,npcs)
	if #hits > 0 then
		local e=hits[1][2]
		p.interact=e
		
		if btnp(❎) then
			local pkg = carrying_pkg_for(hits[1][1])
			
			if pkg then
				deliver_pkg(pkg)
				del(p.packages, pkg)
			else
				trigger_dialogue(e)
			end
		end
	end
	
	--airship
	if col(p, airship) then
		p.interact=airship
		
		if btnp(❎) then
			state="over"
			music(22)
		end
	end
	
	--drill
	p.rdy_drill=false
	if has_item("drill") then
		if map_col(hb, 2) then
			p.rdy_drill=true
			
			if btnp(❎) then
				drill_rock(2)
			end
		end
	end
	--key
	if has_item("key") then
		if map_col(hb, 7) then
			p.rdy_drill=true
			
			if btnp(❎) then
				drill_rock(7)
			end
		end
	end
	
	--mailbox
	local mbs = col_list(p, mailboxes)
	if #mbs > 0 then
		if current_mailbox~=mbs[1] then
			current_mailbox=mbs[1]
			sfx(13)
		end
	end
	
	--packages
	local pkgs = col_list(p, packages)
	
	if #pkgs > 0 then
		sfx(15)
		del(packages,pkgs[1])
		
		add(p.packages, pkgs[1])
		explode(pkgs[1].x+4,pkgs[1].y+4)
	end
end

local last_anim=0
function draw_p()
	local c=0
	local hs=1
	
	local x=p.x
	local y=p.y
	
	--footsteps
	local anim=isin3(2)
	if (abs(anim)==0 and last_anim==1) and p.moving and p.grounded then
		sfx(34) --footstep
		footstep(p.x+4,p.y+6)
	end
	last_anim=abs(anim)
	
	local s=running_sp[2]
	if p.moving and p.grounded then
		s=running_sp[anim+2]
		y-=abs(anim)
	end
	if not p.grounded then
		s=17
	end
	
	if (p.gliding) s=18
	if p.displaying then
		s=19
		hs=20
	end 
	
	if p.climbing then
		hs=35
		if p.moving then
			s=climbing_sp[isin2(4)+1]
		end
	end
	
	local hy=y-3
	if (not p.moving and p.grounded) hy+=isin2(0.5)
	
	clip(x-camx-8, y-camy-8, 20, 16)
	--rect(x-8, y-8, (x-8)+16, (y-8)+12, 7)
	--body
	ospr(0, s, x, y, 1, 1, p.left)
	--head
	ospr(0, hs, x, hy, 1, 1, p.left)
	--glider
	if p.gliding then
		if p.left then
			trail(x+4,y)
			trail(x,y-4)
		else
			trail(x+4,y)
			trail(x+8,y-4)
		end
		ospr(0, 32, x-3, y-6, 2, 1, p.left)
	end
	
	--redraw color sprites
	spr(s, x, y, 1, 1, p.left) --body
	spr(hs, x, hy, 1, 1, p.left) --head
	if p.gliding then
		ospr(0, 32, x-3, y-7, 2, 1, p.left)
	end
	
	clip()

	--interact
	if p.interact and not in_dialogue and not p.displaying then
		oprint("❎",x, y-10, 7, 0) 
	end
	
	--drill
	if p.rdy_drill then
		oprint("❎",x, y-10, 7, 0) 
	end
	
	--display item
	if p.displaying then
		local i = p.items[p.displaying]
		
		ospr(0, i.sp, x, y-10)
	end
end
-->8
-- px9 decompress

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function
	px9_decomp(x0,y0,src,vget,vset)

	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
--]]

--[[ 7 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return
			end
		end
--]]
	end

	-- bit cache is between 8 and
	-- 15 bits long with the next
	-- bits in these positions:
	--   0b0000.12345678...
	-- (1 is the next bit in the
	--   stream, 2 is the next bit
	--   after that, etc.
	--  0 is a literal zero)
	local cache,cache_bits=0,0
	function getval(bits)
		if cache_bits<8 then
			-- cache next 8 bits
			cache_bits+=8
			cache+=@src>>cache_bits
			src+=1
		end

		-- shift requested bits up
		-- into the integer slots
		cache<<=bits
		local val=cache&0xffff
		-- remove the integer bits
		cache^^=val
		cache_bits-=bits
		return val
	end

	-- get number plus n
	function gnp(n)
		local bits=0
		repeat
			bits+=1
			local vv=getval(bits)
			n+=vv
		until vv<(1<<bits)-1
		return n
	end

	-- header

	local
		w,h_1,      -- w,h-1
		eb,el,pr,
		x,y,
		splen,
		predict
		=
		gnp"1",gnp"0",
		gnp"1",{},{},
		0,0,
		0
		--,nil

	for i=1,gnp"1" do
		add(el,getval(eb))
	end
	for y=y0,y0+h_1 do
		for x=x0,x0+w-1 do
			splen-=1

			if(splen<1) then
				splen,predict=gnp"1",not predict
			end

			local a=y>y0 and vget(x,y-1) or 0

			-- create vlist if needed
			local l=pr[a] or {unpack(el)}
			pr[a]=l

			-- grab index from stream
			-- iff predicted, always 1

			local v=l[predict and 1 or gnp"2"]

			-- update predictions
			vlist_val(l, v)
			vlist_val(el, v)

			-- set
			vset(x,y,v)
		end
	end
end

-->8
--[npcs]--

npcs={
	gear_npc={
		x=84*8,y=29*8,w=8,h=8,
		sp={41,42},
		fx=10,
		t=function(self, d)
			if (d) return {"wow you got it!","oh what's this...?","it looks like\nthere's a spare","i think you should\nhave it","this gear will let\nyou climb certain cliffs","press ⬆️ to grab onto\na cliff"}
			
			if self.delivered then
				return {"go try to find\na cliff to climb"}
			end
			return {
				"darn, my order of\nbrand new climbing gear\narrives today","i think i might have\nseen it fly east"
			}
		end,
		f=function(self)
			if (not has_item("gear") and self.delivered) give_item("gear")
		end
	},
	--first npc you meet
	guide={
		x=43*8,y=19*8,w=8,h=8,
		sp={21,22},
		fx=10,
		intro=true,
		t=function(self, d)
			if (d) return {"thanks!"}
			
			if self.intro then
				return {
					"ah you're here...",
					"we're in a bit\nof a mess here",
					"all of the automated\nair delivery packages\nhave gone missing",
					"they seem to have\nflown off on their own",
					"you need to find\nthem all and deliver\nthem to their recipients"
				}
			else
				return {
					"go get those packages!"
				}
			end
		end,
		f=function(self)
			self.intro=false
		end
	},
	--child below the envelope
	town1_child={
		x=62*8,y=23*8,w=8,h=8,
		sp={5,6},
		fx=10,
		t=function(self, d)
			if (d) return {"wow that was\namazing. thanks!", "looks like the letter\nis from my friend\non another island!"}
			
			if self.delivered then
				return {"since airships are too\nexpensive, sending letters\nis the best way to keep\nin touch"}
			end
			return {
				"my letter is all the\nway up there!","how am i supposed\nto get it?"
			}
		end
	},
	--npc in town1 that gives the key
	key_npc={
		x=52*8,y=23*8,w=8,h=8,
		sp={7,8},
		fx=10,
		t=function(self, d)
			if (d) return {"you found it!","you can have this key\nit opens the gate\nto underville below"}
			
			if self.delivered then
				return {"go visit underville\nwhen you get the chance"}
			end
			return {
				"i think i saw my\npackage fly down\ninto a cave"
			}
		end,
		f=function(self)
			if (not has_item("key") and self.delivered) give_item("key")
		end
	},
	--npc in underville that gives drill
	drill_npc={
		x=56*8,y=45*8,w=8,h=8,
		sp={23,24},
		fx=10,
		t=function(self, d)
			if (d) return {"hiki thankfull...","hiki give old drill"}
				
			if self.delivered then
				return {"drill good, yes?"}
			end
			return {
				"hiki missing drill","hiki saw drill\ngo far north-east"
			}
		end,
		f=function(self)
			if (not has_item("drill") and self.delivered) give_item("drill")
		end
	},
	--npc in the underhang
	underhang_npc={
		x=72*8,y=57*8,w=8,h=8,
		sp={39,40},
		fx=10,
		t=function(self, d)
			if (d) return {"..."}
			
			if carrying_pkg_for("glider_npc") then
				return {
					"wow that was amazing!","looks like the package\nis just a box of\npaper though","i bet this was\nfor hilda","she lives in underville\nto the west"
				}
			end
			
			if has_item("glider") then
				return {
					"i wonder if anyone\nknows what happened to\nthe world below"
				}
			end
			
			return {
				"i saw a package\nfly down that way","looks like reaching it\nwould be very dangerous\nthough","one wrong step and you'll\nfall all the way\ndown to the surface","or what's left\nof the surface that is"
			}
		end
	},
	--npc in underville that gives the glider
	glider_npc={
		x=60*8,y=35*8,w=8,h=8,
		sp={55,56},
		fx=10,
		t=function(self, d)
			if (d) return {"wow you got\nmy package!","i'm gonna make\na huuuge airplane!","...",".....","done!","it's so big,\ni bet you could\nglide with it!","try pressing 🅾️\nwhile in mid-air"}
			
			if self.delivered then
				return {
					"i heard there's\na cliff that goes\nreeaaly high up\nin the north-east","i bet with that\nglider you can see\nwhat's past it"
				}
			end
			
			return {
				"making paper airplanes\nis so fun!","i ordered lots of\npaper to make a huge\npaper airplane","i wish it would get\nhere soon..."
			}
		end,
		f=function(self)
			if (not has_item("glider") and self.delivered) give_item("glider")
		end
	},
	--week
	week_week={
		x=40*8,y=36*8,w=8,h=8,
		sp={57,58},
		fx=10,
		t=function(self, d)
			return {
				"week week!","week week week\nweek week?"
			}
		end
	},
	week_week_mom={
		x=45*8,y=36*8,w=8,h=8,
		sp={25,26},
		fx=10,
		t=function(self, d)
			if (d) return {"oh it's our food\ndelivery!","the food we eat\ndoesn't grow on this\nisland","so we have to\norder it from another","now i can feed\nmy family!"}
			
			
			return {
				"we just moved here\nfrom a faraway island","the airship ride was\nreally scary"
			}
		end
	},
	letter_woman={
		x=52*8,y=45*8,w=8,h=8,
		sp={44,45},
		fx=10,
		t=function(self, d)
			if (d) return {"this is a letter\nfrom my husband!","he's been away doing\nresearch on another island","the letter says that\nhis team unearthed a\nmajor archeological\ndiscovery!","wow! i hope this\nmeans he can visit\nhome soon"}
			
			
			return {
				"it's been awhile\nsince i've visited\ntopside town"
			}
		end
	},
	lore_guy={
		x=34*8,y=45*8,w=8,h=8,
		sp={38,38},
		fx=10,
		t=function(self, d)
			if (d) return {"..."}
			
			return {
				"they say that people\nused to live on the\nsurface below", "i can't imagine what\nlife must have been like\nback then","whenever i get a\nglimpse of the surface\nthrough the clouds\nall i see is barren\nnothingness"
			}
		end
	},
	old_man={
		x=55*8,y=3*8,w=8,h=8,
		sp={60,60},
		fx=10,
		intro=true,
		t=function(self, d)
			if (d) return {"..."}
			
			if not self.intro then
				return {"i'm sure you have\nmore islands to deliver to","your airship is wating\nup ahead"}
			end
			
			return {
				"leaving so\nsoon are you?",
				"i suppose you have\nmany more islands to\ndeliver to",
				"do not think that\nwhat you have done\nis isnignificant",
				"deliverymen like you\nare one of the few things\nkeeping this fractured\nworld connected",
				"you have the gratitude\nof all the people on\nthis island",
				"go now and continue\nonto the vast sea of sky",
				"your airship awaits\nyou up ahead"
			}
		end,
		f=function(self)
			self.intro=false
		end
	},
}

packages={
	{
		x=62*8,y=18*8,
		dest="town1_child"
	},
	{
		x=78*8,y=33*8+6,
		dest="key_npc"
	},
	{
		x=123*8,y=24*8+3,
		dest="gear_npc"
	},
	{
		x=123*8,y=12*8+3,
		dest="drill_npc"
	},
	{
		x=104*8,y=53*8,
		dest="glider_npc"
	},
	{
		x=66*8,y=29*8,
		dest="week_week_mom"
	},
	{
		x=69*8,y=37*8,
		dest="letter_woman"
	},
}

mailboxes={
	{x=41*8,y=19*8},
	{x=94*8,y=30*8},
	{x=76*8,y=43*8},
	{x=110*8,y=2*8},
}
current_mailbox=mailboxes[1]

airship={
	x=37*8,y=5*8,
	w=16,h=24,
	
	draw=function(self)
		ospr(0, 27, self.x, self.y, 1, 3)
		ospr(0, 27, self.x-8, self.y, 1, 3, true)
		
		spr(27, self.x, self.y, 1, 3)
	end
}

function draw_npc(n)
	local sp = n.sp[isin2(1,n.x/64)+1]

	ospr(0, sp, n.x, n.y)
end

function draw_package(p)
	local b=isin2(1)
	local s=36+b
	
	ospr(0, s, p.x+4, p.y+b-5)
	ospr(0, s, p.x-5, p.y+b-5, 1, 1, true)

	ospr(0, 71, p.x, p.y+b-2)
end

function draw_mailbox(m)
	if m == current_mailbox then
		ospr(0, 11, m.x, m.y)
	else
		ospr(0, 10, m.x, m.y)
	end
end
-->8
--[dialogue]--

in_dialogue=false
local d_npc=nil
local d_index=1
local just_triggered=false
local is_delivery=false

function trigger_dialogue(npc)
	in_dialogue=true
	d_npc=npc
	just_triggered=true
end

function rrect(x0, y0, x1, y1, r, col)
	--corners
	circfill(x0+r, y0+r, r, col)
	circfill(x1-r, y0+r, r, col)
	circfill(x0+r, y1-r, r, col)
	circfill(x1-r, y1-r, r, col)
	
	--edges
	rectfill(x0, y0+r, x0+r, y1-r, col)
	rectfill(x1-r, y0+r, x1, y1-r, col)
	
	rectfill(x0+r, y0, x1-r, y0+r, col)
	rectfill(x0+r, y1, x1-r, y1-r, col)

	--center
	rectfill(x0+r, y0+r, x1-r, y1-r, col)
end

function tri(x, y, w, dy, col)
	for i=1,w do
		line(x-(i-1), y, x+(i-1), y, col)
		y += dy
	end
	rectfill(x-w, y, x+w, y+(dy*4), col)
end

function dbox(s, x, y, w, h)
	lines = split(s, "\n")
	lwid = 0
	for i in all(lines) do
		lwid = max(#i, lwid)
	end
	
	w = lwid*4 + 5
	h = #lines*6 + 2
	

	x = mid(0, x, 128)
	y = mid(-14, y, 128)
	local dir = 1
	if y < h+8 then
		dir = -1
		y += 15
	end 
	
	local rx = x-8
	local rx = mid(0, rx, 128-w-1)
	ry = y-(h+4)
	if (dir == -1) ry = y+4
	tri(x+1, y+1, 5, -dir, 6)
	rrect(rx+1, ry+1, rx+w+1, ry+h+1, 3, 6)
	tri(x, y, 4, -dir, 7)
	rrect(rx, ry, rx+w, ry+h, 3, 7)
	
	local tx = rx+2
	local ty = ry+2
	print(s, tx, ty, 0)
	
	oprint("❎", rx+w-8, ry+h+1+isin3(1), 7, 0)
end

local fx={5, 6,7,8,10}

function update_dialogue()
	local text = d_npc:t(is_delivery)
	
	if just_triggered then
		just_triggered = false
		sfx(rnd(fx))
	else
		if btnp(❎) then
			d_index += 1
			if d_index > #text then
				--done with dialogue
				if (d_npc.f) d_npc:f()
				in_dialogue=false
				d_index=1
				d_npc=nil
				is_delivery=false
			else
				sfx(rnd(fx))
			end
		end
	end
end

function draw_dialogue()
	local text = d_npc:t(is_delivery)

	local x=d_npc.x-camx
	local y=d_npc.y-camy
	
	local s = text[d_index]
	dbox(s, x+4, y-4, 256, 16)
end

function deliver_pkg(pkg)
	local d_npc=npcs[pkg.dest]
	
	d_npc.delivered=true
	is_delivery=true
	trigger_dialogue(d_npc)
end
-->8
--[ui]--

function draw_ingame_ui()
	local x=2
	for i in all(p.packages) do
		dnpc = npcs[i.dest]
		ospr(0, dnpc.sp[1], x, 2)
		
		ospr(0, 71, x+3, 5)
		x += 12
	end
end
-->8
--[particles]--


particles = {}


function footstep(x, y)
	add_particle({
			id=1,
			x = x,
			y = y,
			dx = 0,
			dy = -0.1,
			fx=0,
			fy=0,
			life = 15,
			col = 7,
			bgcol = 6,
		})
end

function jump(x, y)
	add_particle({
			id=1,
			x = x,
			y = y,
			dx = -0.1,
			dy = -0.1,
			fx=0,
			fy=0,
			life = 15,
			col = 7,
			bgcol = 6,
		})
		add_particle({
			id=1,
			x = x,
			y = y,
			dx = 0.1,
			dy = -0.1,
			fx=0,
			fy=0,
			life = 15,
			col = 7,
			bgcol = 6,
		})
end

function trail(x, y)
	add_particle({
			id=2,
			x = x,
			y = y,
			dx = rnd(0.1)-0.05,
			dy = rnd(0.1)-0.05,
			fx=0,
			fy=0,
			life = 15,
			col = 7,
			bgcol = 6,
		})
end

function explode(x, y)
	for i=1,20 do
		local dx=rnd(1)-0.5
		local dy=rnd(1)-0.5
	
		add_particle({
				id=2,
				x = x,
				y = y,
				dx = dx,
				dy = dy,
				fx=-dx*0.05,
				fy=-dy*0.05,
				life = 60,
				col = 7,
				bgcol = 6,
			})
		end
end

function add_particle(p)
	p.start_life = p.life
	add(particles, p)
end

function update_particles()
	for i in all(particles) do
		i.dx += i.fx
		i.dy += i.fy
	
		i.x += i.dx
		i.y += i.dy
		
		i.life-=1
		
		if (i.life < 0) del(particles, i)
	end
end

function draw_particles()
	for i in all(particles) do
		local t = i.life/i.start_life
		t = mid(0, t, 1)
		
		if i.id == 1 then
			circfill(i.x, i.y, t*2+1, i.col)
		end
		
		if i.id == 2 then
			pset(i.x, i.y, i.col)
			--circfill(i.x, i.y, t*2+1, i.col)
		end
	end
end
__gfx__
000000000000000000000000000000000000000000ddd00000000000004444000000000000088008000000000000000055555555aaaaaaaaffffffffeeeeeeee
000000000000000000000000000000000000000001dd110000ddd000007a74400044440000880088000556000ff5560056666665aaaaaaaaffffffffeeeeeeee
007007000ccc77000000000000000000000000000111110001dd110000aaaa40007a744008800880005566600085666056666665aaaaaaaaffffffffeeeeeeee
000770000cccccc00445540004455400044554a0007a700001111100000ccc4000aaaa4088008800005566600085666056666665aaaaaaaaffffffffeeeeeeee
000770000ce7a700a4ccca000a44ca000accc40000afa000007a700000acc14000accc4080088008005566600055666056666665aaaaaaaaffffffffeeeeeeee
007007000eaaaa000ccc40000c4c40000ccc400000eee00000afa000000c11a0000cc1a000880088000040000000400056666665aaaaaaaaffffffffeeeeeeee
0000000000000000005220000cc22000002225000aeeea000aeeea0000cc111000cc111008800880000040000000400056666665aaaaaaaaffffffffeeeeeeee
000000000000000000005000005050000050000000d0d00000d0d00000c5151000c5151088008800000040000000400055555555aaaaaaaaffffffffeeeeeeee
4444400000000000000000000000000000000000004444000000000000444444000000006600006600000000aaa000002222222225255552fffffffffeeeeeee
4466464400000000a00000a0000000a00000000000aa44000044440004222244004444446a6666a666000066aaaaa0002222222222222222efefefefeeeeeeee
464466440000000040000040000000400ccccc000044400000aa44000472724004222244006262006a6666a6aaaaaa002222222222552252ffffffffeeeeeeee
44464464044554a004455400044554000cc7c7c0062526000044500004222240047272400066f60000626200aaaaaa002222222222222222efefefefeeeeeeee
00244444a044c4000044c000a044c0000ce7a70006222600062526000055540004222240004554000066f600aaaaaaa02222222225552552fffffffffeeefeee
002220000c4c40000c4c40000c4c40000eaaaa00062226000622260000454400005554000544445005444450aaaaaaa02222222222222222ffefffefeeeeeeee
004200000cc225000cc225000cc2200000000000005550000655560004444400044444000044440000444400aaaaaaa02222222225555522ffffffffeefeeefe
0444400000500000005000000500500000000000005050000050500004454440044544400054450000544500aaa6aaa02222222222222222efefefffeeeeeeee
0000000770000000000000000000000000000000000000000000000000044440000000000099990000999900aa66aaa00001100000011000fffffffffeeefeee
000000777700000000000000000000000000000000000000001111000044fff400044444007a7900007a7900aa66a6600011110000111110ffefffefeeeeeeee
0000076777700000000120000ccccc00000667000000000000aa11000044f2f00044fff00222222002222222aa666660007a7110007a7110ffffffffeefeeefe
0000776667770000022111200ccccc000066760000000600002a2a00004fffe00044f2f00222242002222422a666660000aaa11000aaa110efffefffeeeeeeee
0007777766677000222211110eccce00066767000006667000aaa40000222200204fffe00242242202422420666666000025211000252111fffffffffefefefe
00077777777760004aaaa4aa0eeeee00066767000667676700666400002121f0022222f00024250200424500666660000522250005222500ffefffffeeeeeeee
00000000666660004aaaa4aa00000000000670000660067705544440021f1100001f11000044400000444000666660000052500000525000ffffffffeefefefe
0000000000000000444444440000000000070000000000005555404400151500001515000040400000404000666600000050500000505000efffefffeeeeeeee
0000000000eee000000000000000000000eeee00000000000000000000099000000000000000000000000000000500000066660000000000fffffffffefefefe
00000000eeeeeeeeeeeeeeee000000000eeeeeee000000000000000000999900000990000660006600000000005000000062a20000000000ffffffffeeeeeeee
000ee000eeeeeeeeeeeeeeee000eeeee0eeeeee00000000000000000009999000099990006a666a606600066005000000066660000000000fffffffffefefefe
00eeeee00eeeeee00eeeeee000eeeeee00eeeee000eeeeee0000ee00007a7990009999000002620006a666a6005000000d4666d000000000ffffefffeeeeeeee
000000000eeeee0000eeeee000eeeeee00eeee00000eeee00000000000afa990007a79900006f60000026200004200000444644000000000fffffffffefefefe
00000000000e0000000eeee000eeeeee000eee000000e0000000000000eee99000afa990005444500056f650442400000a4dd4a000000000ffffffffefeeefee
00000000000e0000000eee00000eeee0000ee00000000000000000000aeeea000aeeea0000044400000444002224000000d55d0000000000fffffffffefefefe
0000000000000000000ee00000000e000000e000000000000000000000d0d00000d0d0000005450000054500424000000050050000000000ffffffffeeeeeeef
0000000000000000000000000000000024000044aa6bbbbbbbbbbb660000000000000030000033000bb3003322556a656666555226666655556a6662fefefefe
0000000000000000000000000000000024442442a666bbbbb3bbba65000000000000bb30000003b0bbb3000326aaa655a6a555522255a6555aa6a552efeeefee
000000000000000000000000000000002422224265566b33b33b36550aaaaa000000b0030b0003000003bb032a666665655555222255aa6556665552fefefefe
000000000000000000000000000000002200004255666b3a3363665a07aca70000000003bb00000000300b0326a6555555555552225a666555555522eeefeeef
000000000000000000000000000000004200004456a666aa63a666aa077a7700000000003000000000300003255555565555555222a6665565555522fefefefe
0b300b0000b00b0000000b0000000000244444445555566a5555566a00000000000000000300000003b0000322555556665555222a6a556665555522efeeefef
03b30b0303300bb003000b00b000b000442222245555665555556655000000000000000000330000330000032225555555555222266555655a6a6652fefefefe
bbb333033b3bb3b03bb0bb0030b0bb0b24000042666556556665565500000000000000000b303333030000b3222222555552222226665555aaa65552eeefeeef
0bbbbbbbbbbbbb3bbbbbbbbbb3bb3330555555550bbb33300666a66006a6555a0000000056aa55500300000300070000000000000000000000066656fefefefe
3bbb3bbb3b333bbbb3bbbbbbbbbbb3b355555555bbbbb3b3055556606a6656a600000aa05a66a5a603b0000300677000000000022112222210065555efefefef
b3bb33b333333333b33b3b33b33b3bb3055555a6b33b3bb30a655550aa6555a60000a660666555660300000006667700000000221121211111006650fefefefe
3333a366a6a336333363bb3a6a6633b306a65666bb6633b306555a606655a56650a6a6006a665a660300000007666700000002222112121211106550efefeeef
33a36a656a655a6a63a633aaa65555300a6655505b6556360055666056a56a6502a66000a65556a00000000077776670000022222211211121125660fefefefe
0aa6a665a65555a65555566a6a555530065556606a555535005555000aa6a665552560006a5566500000000007777670000222aa2221121112112550efefefef
066a555a655555555555665566555550005555506655665500665500066a555a2225000066555550000000000000777000222aaaa222111211211150fefefefe
0a6556a6555555aa66655655555aa660005a6660055aa660000650000a6556a605500000555aa66000000000000000000222aa44aa22211121112110efefefef
0666665555555aa6a6555555556a66600006650026255652444444440000000000000002200000000000222222200000222442222442221111111211fffefefe
0065a655aaa66a6a6656a6655aa6a550000655002aa266264442444400005555000000222200000000022222222222004aaa2aaaa2aaa2aaa4a4aaa2efefefef
0055aa656a6a6666655aa6a65666555000055500a62662254442224400050600000022222200000000222222222200004aa4aaaaaa4aa4aa4aaa4aa4fefefefe
005a66656665665556a66a665555550000005500256222624242422400606055000222222220000002222222222222222a2aaaaaaaa4a4a4aa1112a2efefefef
00a666555655556a6aa6566a655555000000500022a62a6242422244011605000002222222222000000022222222222222aaaaaaaaaa242aa111a122fffefffe
0a6a556655556555555555a66555550000000000a62226664222222401116000000022222220000022222222222222222aaaaaaaaaaaa2aa111aaa12efefefef
0665556555666555566655555a6a665000000000626a62564222222400110000022222222222220022222222222222222aaaaaaaaaaaa2a111aaaaa1fefffeff
0666555556a6655566655555aaa6555000000000266566524222225400000000222222222222222222222222222222224aaaaa22aaaaa2a662aa2aa2efefefef
00556a656a6aa6a656a6a5556666555055555555000999004222256544444444222222222222222222222222222222224aaaa2442aaaa2a664a222a2fffefffe
06aaa65555666a55565a6555a6a5555055555555000960004444445424222242002222222222222022222222222222224aaaa4444aaaa2a664a222a4efefefef
0a666665555566555556655a65555500555555550009990042424424000000000000002222200220222222222222222226aa64244aa6a4a664a222a4fefffeff
06a6555555555555555a65555555555055555555000960004242422400000000000002222222000022222222222222222aaaa42446aa64a664aa2aa4efefefef
0555555665555556665655665555555055555555000960004222222400000000000000022222000000222222222222222a6aa4444a6664aa62aaaaa2ffffffff
005555566555556665555566665555005555555500999600422222240000000000000002222000000222222222222000466a64424a6662aa64aaaaa4efefefef
000555556555555565555556555550005555555500999600422222240000000000000000222000000022222222222200466664424a66626aa26a6aa2feffffff
000000555555555555555555555000005555555500066000444444440000000000000000220000000000022222220000466662222666626662a66662efefefef
000000000000000000000000000000000000000000000000000000000000009027172717271717172727171717172727171727171727171727172727271726e4
d1d41626262616271717271717172717172727264747161637004406472647263707379090909090909090909090909090909090909090909090909090909090
00000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000044c5d5e5007526
d1c1c1c1c1c1c1c1c1d1c116e4c1c1c1c1c1d1d4e400440000004406264747360000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000000000c5d5e522000000000000000000000044c6d6e60075e4
d1c1c1c1c1c1c1c1c1d1c147e4c1c1c1c1c1d1b4c400440000004475174726360000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000000000c6d6e6e6000000000000000000000044c7d7e7040626
2627161627172616e4d1c11726162726e4c1d1c19700447516262616274747470000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000042404c7d7e7e704240000000000c5d5e50044051525156447
26d1c1c1c1c1c1d4e4d1c1b416272617e4c1d1c10000440726261727164747470000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090000000000000000525151525152525352400000000c6d6e6004465a6c1d1d427
e4d1c1c1c1c1c126e4d1c1c1c1c1c1c156b787c10000440006174747274747470000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090000000000000000717164717264726473500000000c7d7e7004400a7c1d1d426
e4d1c1c1c1c1c1d4e4d1c1c1c1c1c1c156b686c1b600440006472747474747470000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000006507271727262737a40000000005152515256416e4d12617
26d1c1c1c187c1b4261627262627162617272617e400440075172647474747260000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000000000654565073600a50000000084940717471717e4d11717
e4d1c1c197a6c1c1c1c1c1b786c1c1d426c487c1c100440007174747261616470000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000000000464600006500000000000000a4000000000000440075
26d1c1c1b7c1c1c1c1c1c1b687c1c1b4e49700c1c100440086c1c1b4271727179000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000c5d5e5a5000000000000440006
47e4c1c100c1c1c1c1c1c187c1c1c1c1660000c197004400c1c1c1b7000000009000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090000000c5d5e500000000000000000000c5d5d5c6e6e6000000c5d5e500440007
27c4c1c1a6c1d4c4c1c1c196c1c1c1c1670086c196004486c1c19700000000009000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090000000c6d6e600000000000000000000c6d6e6c6e7e7000000c6d6e600440086
c1c1c1c1c1c1d1c1c1c1c1d42616261616172626172726e4c1b70000000000009000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090000004c7d7e700000000000434241404c7d7e7c6e7e7340424c7d7e734440487
c1c1c1c1c1c1d1c1c1c1c1d41627472726950065458494a400000000000000009000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000900000051515152535777777051525251525251515152515151525252515152526
161626162616d126162626271616162737650000460000a500000000000000009000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000009000008407471737a4000000a40727471717472747174727471747472747174716
472627471626d1274726271647274727000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000909090909090909090909090909047474747474747474747474747474747474727
271626172616d1171616262616261727909090909090909090909090909090909090909090909090909090909090909090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
172737a4450044a4072716261737a445000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
456500a446004400006507374500a546000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
460000a5000044000000000046000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
000000000000440000000000000000000000000000000000000000000000000000000000000000a6c1c1b6000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
000000000000440000000000000000000000000000000000000000000000000000000000000000c1c1c1c1000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
000000000000440000000000000000000000000000000000000000000000000000000000000086c1c1c1c1960000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
0000000000004400000000000000000000000000042424340000000424042434a6b6000000072616262726163700000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000444243400000000000000000000000515253500000005251525642695000000001716274717370000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000515253500000024240414043400000727269500000006262616261637000000000747164737000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000616263600000005152515253500008494a4450000000727163794a400000000000007163700000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000717273700000007272617263700000000a54600000000a5a40000a500000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000084a4000000000045072737000000000000000000000000a500000000000000000000000000000000000090000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090
00000000000000a50000000000460065000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000
90909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090
90909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090
__label__
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0000000000000uuu00000000000u000000000000000000000uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0777077707770uuu07700777070u077707070777077707070uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0707007007070uuu07070700070u007007070700070707070uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0777007007700uuu07070770070uu07007070770077007770uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0707007007070uuu070707000700007007770700070700070uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0707077707070uuu077707770777077700700777070707770uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu0000000000000uuu000000000000000000000000000000000uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
uuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuvuuuuuuuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuu
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuvuuuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuv77777777uvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu
uvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuv77777777777777uvuvuvuvuvuvuvuvuvuvuvuvuvuvuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu777f777777ffff777777vuvuvuvuvuvuvuvuvuvuvuvuvu
uvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuvuvuuuvuv77fffffffffffffff77777777vuuuvuvuvuuuvuvuvuuuv
vuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuv77ffffffffffffffffff7777777vuvuvuvuvuvuvuvuvuvu
uvuvuvuvuvuvuvuvuvuvuvu000000000000000000000uvuv0000000770000000000vuvu000000000u77f0000000000000000000077777vuvuvuvuvuvuvuvuvuv
vuvuvuvuvuvuvuvuvuvuvuv077707770777007700770vuv007777700007007777700vuv077700770v77007707770777077707770777777vuvuvuvuvuvuvuvuvu
uvuvuvuvuvuvuvuvuvuvuvu070707070700070007000uvu077070770070077000770uvu007007070u77070000700707070700700fffffffvuvuvuvuvuvuvuvuv
vvvuvuvuvvvuvuvuvvvuvuv077707700770077707770vu7077707770070077070770vuvu07007070vff07770070077707700070ffffff777vvvuvuvuvvvuvuvu
uvuvuvuvuvuvuvuvuvuvuvu070007070700000700070u77077070770070077000770uvuv07007070uff00070070070707070070f7777777fuvuvuvuvuvuvuvuv
vuvuvuvuvuvuvuvuvuvuvuv070v0707077707700770077f007777700700007777700vuvu07007700vff077000700707070700707777fffffvuvuvuvuvuvuvuvu
uvuvuvuvuvuvuvuvuvuvuvu000u000000000000000077fff0000000000ff0000000vuvuv0000000vuff0000f00000000000000077fffffffuvuvuvuvuvuvuvuv
vvvuvvvuvvvuvvvuvvvuvvvuvvvuvvvuvv7777777777777ffffffffffffffffuvvvuvvvuvvvuvvvuvfffffffffff7777fffff777ffffffffvvvuvvvuvvvuvvvu
uvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuvu7777f77777777777ffffffffffffffvuvuvuvuvuvuvuvuvuvfffffff77777ffffffffffffffffffuvuvuvuvuvuvuvuv
vuvvvuvvvuvvvuvvvuvvvuvvvuvvvuvvv77ffffff777f7777ffffffffffffffvvuvvvuvvvuvvvuvvvuvfff777777ffffffffffffffffffffvuvvvuvvvuvvvuvv
uvuvuvuvuvuvuvuvuvuvuvuvuvuvuvuv77ffffff777ffff77ffffffffffffffvuvuvuvuvuvuvuvuvuvuvu77777fffffffffffffffffffffvuvuvuvuvuvuvuvuv
vvvuvvvuvvvuvvvuvvvuvvvuvvvuvvv77ffffff777ffffff77fffffffffffffuvvvuvvvuvvvuvvvuvvvuv77777fffffffffffffffffffffuvvvuvvvuvvvuvvvu
uvuvuvuvuvuvuvuvuvuvuvuvuvuv77777ffff777ffffffffffffffffffffffuvuvuvuvuvuvuvuvuvuvuvu77777ffffffffffffffffffffuvuvuvuvuvuvuvuvuv
vuvvvuvvvuvvvuvvvuvvvuvvvuv77ff7fffff7ffffffffffffffffffffffffvvvuvvvuvvvuvvvuvvvuvvv7777fffffffffffffffffffffvvvuvvvuvvvuvvvuvv
uvuvuvuvuvuvuvuvuvuvuvuvuv77ffffffffffffffffffffffffff7777777fuvuvuvuvuvuvuvuvuvuvuvu777ffffffffffffffffffffffuvuvuvuvuvuvuvuvuv
vvvvvvvvvvvvvvvvvvvvvvvvv777ffffffffffffffffffffffff77777777777vvvvvvvvvvvvvvvvvvvvvv77fffffffffffffffffffff7vvvvvvvvvvvvvvvvvvv
uvuvuvuvuvuvuvuvuvuvuvuvu77ffffffffffffffffffffffff777777777f777uvuvuvuvuvuvuvuvuvuvu77fffffffffffffff7ffff777uvuvuvuvuvuvuvuvuv
vuvvvvvvvuvvvvvvvuvvvvvv777ffffffffffffffffffff777777777fffff777vuvvvvvvvuvvvvvvvuvvv77ffffffffffff7777fff77777vvuvvvvvvvuvvvvvv
uvuvuvuvuvuvuvuvuvuvuvuv77777ffffffffffffffff777777777ffffff77777vuvuvuvuvuvuvuvuvuvu77ffffffffff777777ff777777vuvuvuvuvuvuvuvuv
vv77777777vvvvvv777777vv777777fffffffffffff77777777ffffffff777777vvvvvvvvvvvvvvvvvvvv77fffffffff7777777ff777ff77vvvvvvvvvvvvvvvv
77777777777vu7777777777v7777777fffffffffff7777777fffffffff777fff77uvuvuvuvuvuvuvuvuvu777fffff777777777ff77fffff777uvuvuvuvuvuvu7
77777777777777777777777777777777fffffffff777777ffffffff77777fffff7vvvvvvvvvvvvvvvvvv77777777777777777ff777fff777777vvvvvvvvvvv77
fffffff77777777fffff777777777777fffffffffffffffffff777777ffffffff77vuvuvuvuvuvuvuvu777777777777f7777ff777fff77777777uvuvuvuvu777
fffffff7777777fffffff77777777777ffffffffffffffffffffffffffffffffff7vvvvvvvvvvvvvv7777ff77777ffff777ff777ffffff777777vvvvvvvv77ff
fffffff777777fffffffff77777777777ffffffffffffffffffffffffffffffff77vvvuvvvuvvvuv7777fffffffffff77777777ffffff7777777vvuvvvuv777f
fffffff777777ffffffffffff7777777777fffffffffffffffffffffffffffff7vvvvvvvvvvvvvvv7777ffffffffff7777777ffffffff7777777vvvvvvv777ff
fffff77777777fffffffffff7777777777777fffffffffffffffffffffffffffuvuvu777uvuvuvvv77ffffffffffffffffffffffffff7777fff7uvvvuvu777ff
fff777777777fffffffff777777ffff77777777fffffffffffffffffffff7777vvvv777fffvvvvv7fffffffffffffffffffffffffff777ffffff7vvvvv77ffff
f7777777f7777ffffffff777ffffffffff777777fffffffffffffffff77777777v7777ffffffvv77fffffffffffffffffffffffff777ffffffffffuvv777ffff
777777ffff777fffffff77ffffffffffffff777fffffffffffffff7777777f77777777ffffff7v77fffffffffffffffffffffffffffffffffffffffvv77fffff
7fffffffff777fffffff7ffffffffffffffffffffffffffffff7777ff77fff7777777fffffff7777ffffffffffffffffffffffffffffffffffffffffu77ffff7
7fffffffff777ffffffffffffffffffffffffffffffffffffff7fffffffff777ff777fffffff7777ffffffffffffffffffffffffffffffffffffffff777fff77
ffffffffff777ffffffffffffffffffffffffffffffffffffffffffffff7777fff777fffffff777fffffffffffffffffffff77fffffffffffffffff777ffff77
fffffffffff7fffffffffffffffffffffffffffffffffffffffffffff777777fff77ffffffff777ffffffffffffffffff77777ffffffffffffffff7777ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff77777777ffff7ffffffff777ffffffffffffffffff77777ffffff77ffff777ffff77ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff7f77777fffff7fffffff777ffffffffffffff777777777fffffff7777777777fffffffffff
ffffffffffffffffffffffffff777ffffffffffffffffffffffff77f777ffffff77ffffff77ffffffffffffff7777777ffffffffff777777777777ffffffffff
fff77fffffffffffffffffffff7777fffffffffffffffffffffff77fffffffff777fffffffffffffffffffffff77777fffffffff777777777777ffffffffffff
7777ffffffffffffffffffffffff777777ffffffffffffffffff77ffffffffff777fffffffffffffffffffff77777ffffffffff7777777ffffffffffffffffff
777ffffffffffffffffffffffffffff77777777777fffffffff777ffffffffff777fffffffffffffff7fffff77fffffffffffff77777ffffffffffffffffff77
77ffffffffffffffffffffff7777777777777777777ffffffff77fffffffffff777ffffffffffffff77ffffffffffffffffffff777fffffffffffffffffff777
fffffffff7777fffffffff77777777777777777777ffffffff77ffffffffffff777ffffffffffff7777777ffffffffffffffff7777ffffffffffffffffff7777
fffff777777777ffffff7777777777777777777fffffffffff77fffffffffff7777ffffffffff7777777777fffffffffffffff777ffffffffffffffffff77777
ffff777777777fffff7777777f777777777fffffffffffffff7ffffffffffff7777fffffff7777777777777777ffffffffffff777fffffffffffffffff7777ff
fff77777777777ff777777ffffff7777777ffffffffffffffffffffffffffff777ffffff7777777777ff777777777fffffffff777fffffffffffffff7777ffff
ff7777777777777777777ffffffffff777fffffffffffffffffffffffff7777777ffffff777777fffffffffff7f77fffffffff77fffffffffffffff777777fff
f77777777ff777777777fffffffffff77fffffffffffffffffffff777777777777ffffff77777ffffffffffffffffffffffff777fffff7777fffff77777777ff
f777777ffffff7777777fffffffffff77fffffffffffffffffffff7777777777777fffff7777ffffffffffffffffffffffff7777ff7777777fffff77777777ff
77777ffffffff777777ffffffffffff7fffffffffffffffffffff777777ffff7777fffff7777fffffffffffffffffffffff7777777777777fffff7777777ffff
7777ffffffffff77777ffffffffffffffffffffffffffffff7777777ffffffff7777ffff7777fffffffffffffffffffff77777777777f7fffffff7777ffffff7
777ffffffffffff77fffffffffffffffffffffffffffffff7777777fffffffffff777ffff77fffffffffffffffffffff7777f7777ffffffffffff77fffffffff
fffffffffffffffffffffffffffffffffffffffffffffff77777777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffff777777f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff000ffffff00f000f000f000fffff000f0f0fffff00070007000f00fff00f000f000f00ff000f000f000fffffffffffffffffffffffffffffffffffffffffff
ff0f0fffff0fff0f0f000f0fffffff0f0f0f0fffff0f07707f0f0f0f0f0f0f000f0f0f0f0fff0fff0fff0fffffffffffffffffffffffffffffffffffffffffff
ff000fffff0fff000f0f0f00ffffff00ff000fffff000ff0ff000f0f0f0f0f0f0f000f0f0ff00fff0ff00fffffffffffffffffffffffffffffffffffffffffff
ff0f0fffff0f0f0f0f0f0f0fffffff0f0fff0fffff0ffff0ff0f0f0f0f0f0f0f0f0f0f0f0fff0fff0fff0fffffffffffffffffffffffffffffffffffffffffff
ff0f0fffff000f0f0f0f0f000fffff000f000fffff0fff000f0f0f0f0f00ff0f0f0f0f0f0f000fff0f000fffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__gff__
0000000000000000001000000100000000000000000000000000000000080000010000000000000000000000000000000000000000000000000000000000000000000000020101000000000101010100010101010101000100010000000000000101010100058100000000000000000001010101010081010000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7474740000000000000000000000007474590000000000000000000000000000000000781c1c1c1c1c1c1c1c7900781c1c1c1c1c1c7900000000000000000000000000000000000000000000000000000000000000000000000000000000007072727272627272627272726272616272
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7474740000000000000000000000007474630000000000000000000000000000000000681c1c1c1c1c1c1c1c0000001c1c1c1c1c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000065000000000044000000000000606262
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f747474000000000000000000000000747459000000000000000000000000000000006a1c1c1c1c1c1c1c1c1c0000001c1c1c1c1c1c0000000000000000000043400000000000000000000000000000404200000000000000000000000000000065000000000044000000000000607261
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f747474000000000000000000000000747463410000000000000000000000000000681c1c1c1c1c1c1c1c1c1c6900681c1c1c1c1c1c6900000000000000000050530000000000000000000000000000505300000000004042000000000070717262590000000044000000000000606274
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f74747474000000000000000000000074744553000000000000000000000057626261616161626262616161616262616161616261626300000000000000000070630000004000000000000000000000707300000000005053000000000000546061725900000044000000000000606172
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f747474740000000000000000000000747471590000000000000000000000706274627461627274626172746274616261616262726259000000000000000000004a0000005500000000000000000000000000000000006073000000000000647074726300000044000000000000606262
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f747474740000000000000000000000747461630000000000000000000000005772746274616261717471626161747262747262746163000000000000000000005a0000005600000000000000000000000000000000006400000000000000000062746300000044000000000000607262
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f74747474740000000000000000000074747163414043414300000000000000607474717174727461747474727474747461617474746300000000000000000000000000000000000000000000000000000000000000000000000000000000000061727300000044005762616262726274
5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f747474747474747474747474747474747462455151525253000000000000007062727474747462717471747474617474717474747459000000000000000000000000000000000000000000000000000000000000000000000000000000000000711d0000000044007072727272714d62
6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f74747474747474747474747474747474747474747462734a0000000000000000747174747471747474747474747174747474747474730000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d00000000440000007a79781c4d72
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f74747474747474747474747474747474747474747463005a0000000000000000747474747474747474747474747474747474747459000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d00000000440000000000001c4d72
1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e1e7474747474747474747474747474747474747474627300000000000000000000747474747474747474747474747474747474747463000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d0000000000000000000000784b62
2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e7474747474747474747474747474747474747262630000000000000000000000747474747474747474747474747474747474747459000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d0000000000000000000000001d4d
3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e7474747474747474747474747474747474626261630000000000000000000000747474747474747474747474747474747474747473000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d0000000000000000000000001d4d
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e7474747474747474747474747474747462727472630000000000000000000000747474747474747474747474747474747474745900000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e1d0000000000000000000000001d4d
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e74747474747474747474747474747474727461746300000000000000000000007474747474747474747474747474747474747463090909090909090909090909090909090909090909090909090909090909090909090909090909090909090961616100000000000000616261621d4d
000000000000000000000000000000000000000000000000000000000000000062627461630000000000000000000000000000000000000000000000000000784b72724c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007071714c1d4d
00000000000000000000000000000000000000000000000000000000000000007171626163005c5d5e00000000000000000000000000000000000000000000001c1d1c7900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000781c1c1d4d
00000000000000000000000000000000000000000000000000000000000000007162727463006c6d6e00000000000000000000000000000000000000000000001c1d1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000781c1d4d
00000000000000000000000000000000000000000000000000000000000000006271747259407c7d7e42424300000000000000000000000000000000000000004b1d4c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1d4d
00000000000000000000000000000000000000000000000000000000000000006274726145515252515252530000404200000000000000004100005c5d5e00007a1d1c000000000000000000000000000000000000000000000000004100000000000000000000000000000000000000000000000000000000000000001c1d4d
00000000000000000000000000000000000000000000000000000000000000007262717172616172747162630000505300000000225c5d5e5540006c6d6e0000681d790000000000000000000000000000000000000000000000000051000000000000000000000000000000000000000000000000000000000000006a1c1d4d
000000000000000000000000000000000000000000000000000000000000000074626272717471746171616300001c79000000007d6c6d6e4b55006c6d7e00001c1d690000000000000000000000000000000000000000000041000054000000000000000000000000000000000000000000000000000000000000001c1c1d4d
000000000000000000000000000000000000000000000000000000000000000074627172627172726274716342681c6b404243407d7c7d7e1c1c697c7d7e42681c1d1c6b43404240400000000040430000000000000000000051000064000000000000000000000000000000000000000000000000000000000000007a1c1d4d
00000000000000000000000000000000000000000000000000000000000000006274627472747172726262455146724552525151515251525151525251525246627161455152525252530000005053000000000000000000005400000000000000000000000000000000000000000000000000000000000000000000681c1d4d
000000000000000000000000000000000000000000000000000000000000000074617471717272727471727272716272627174717272626271617462727471627172627162616162616300000070730000000000000000000064000000000000000000000000000000000000000000000000000000000000000000001c1c1d4d
000000000030003600003000003600003600000000000000000000000000000062746271746174727172747462747274627162746162727462747171746262727172726271617471626300410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000681c1c1d4d
00300000363036003600003000363000003600000000000000000000000000007462747162747474747462727461727474717471747161746162617474747472624c1c1c4b7161746163005053000000000000000000000000000000000000000000000000000000000000000000004341434143000000000000005762616172
000000000000000000343500300035003100000000000000000000000000000074717461747474747461716172746174727161746162747471747474747471724c1c1c1c1c4d7261726300004a000000000000000000000000004300000000000000000000404142000000404243005051515253000000000000007071746274
0000000000000000000000330034003200000000000000000000000000000000746262627474747474716174627174747474747161747474716161747474614e1d1c1c1c1c6174726163434243424042434041414000000000005500000000000000000000505253000000505253007071727273000050525300000054717262
000000000000000000000000000000000000000000000000000000000000000074746171627174627471747472746171727462747174746271627162747174621d1c1c1c1c4d72616151525152525152515252525253404340004440404242424000000000645473000000607273000048494a000000607273000000644a4960
0000000000000000000000000000000000000000000000000000000000000000747462747474747474617474746174747474747161747474747474617474744e1d4d6261626161747272617461617461747461617461525253004450525251525252530000006400000000564a00000000005a000000645600000000005a0060
__sfx__
000100002c050000002c050000002c050000002c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480400000f15200102001021015200102001021d1022b1020010213102001021115211102001021b1522a1022a1021f1522315200102131020010200102151520010200102001020010200102001020010200102
480400002315200102001022315200102001021d1022b1520010213102001022515211102001021e1522a1022a1022a1520010200102131020010200102001020010200102001020010200102001020010200102
480400002315200102001022b15200102001021d1520010200102131520010219152111020010222152001021d152001020010200102131520010200102001020010200102001020010200102001020010200102
480400002315200102001021e15200102001021d15200102001021d15200102001021e15200102221520010226152001020010200102001020010200102001020010200102001020010200102001020010200102
000400002e75100701007012e75100701007012e75100701007012e75100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
48040000231520010200102251520010200102231520010200102231520010200102261520010222152001021d152001020010200102001020010200102001020010200102001020010200102001020010200102
1d0700001d75011700237501e7001a7500d7002775027750277502773027720277100070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000100002465024650236502365023650236502365024650246602466024660246602365023650226502265022640226402664022640256302263022620246202362023620256102461024610246002460024600
000800001d75010700297512b75000700337500070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
000100002c6502e650306502c6502665026650256500060000600176502065027650286502765025650226501b65019650006000060000600006000f650146501665016650166501565013650116501165000600
15041800271502e1500010000100271302e1300010000100271202e1200010025100271102e110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
a9201800215550050000500005001f555215552455500500005002155500500005001f5550050000500005001d555005001f55500500005000050000500005000050000500005000050000500005000050000000
a92018001d5550050000500005001c5551d5552155500500005001d55500500005001c5550050000500005001a555005001c55500500005000050000500005000050000500005000050000500005000050000000
012018001171011710117101171011710117101171011710117101171011710117101071010710107101071010710107101071010710107101071010710107100070000700007000070000700007000070000700
012018000e7100e7100e7100e7100e7100e7100e7100e7100e7100e7100e7100e7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100070000700007000070000700007000070000700
012018000c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100c7100070000700007000070000700007000070000700
012018001111515115181151d11518115151151111515115181151d11518115151151011513115171151c11517115131151011513115171151c11517115131150000000000000000000000000000000000000000
012018000e11511115151151a11515115111150e11511115151151a11515115111150c11510115131151811513115101150c11510115131151811513115101150000000000000000000000000000000000000000
a9201800215550050000500005001f555215552455500500005002855500500005002855500500005000050026555005002655500500005000050000500005000050000500005000050000500000000000000000
012018001171011710117101171011710117101171011710117101171011710117101571015710157101571015710157101571015710157101571015710157100070000700007000070000700007000070000700
a92018002855500500005000050029555285552655500500005002155500000245552455500500005000050000500000000000000000000000000000000000000000000000000000000000000000000000000000
012018001871018710187101871018710187101371013710137101371013710137101171011710117101171011710117101071010710107101071010710107100c7000c7000c7000c7000c700007000000000000
012018001111515115181151d11518115151151111515115181151d115181151511515115181151c115211151c1151811515115181151c115211151c115181150000000000000000000000000000000000000000
012018000c115101151311518115131151011513115171151a1151f1151a115171151111515115181151d11518115151151011513115171151c11517115131150000000000000000000000000000000000000000
3120180011114111150c10011114111150c10011114111150c1050c1001311413115111141111510114101150c1050e11010114101150c1000c10000100001000010000100001000010000100001000010000100
192018000e1140e115000000e1140e115000000e1140e115000050000010114101150e1140e1150c1140c115000050c1100c1140c115000000000000000000000000000000000000000000000000000000000000
a91c18002d7550070500705007052b7552d7553075500705007052d75500705007053075534755377553b7553c755007050070500705007050070500705007050070500705007050000000000000000000000000
001000001e7001e7001e7001e7001e7001e7201e7401e7501e7501e7501e7501e7401e7401e7401e7301e7301e7301e7301e7301e7201e7101e7101e7101e7101e7101e7101e7101e7101e7001e7000000000000
001000002370023700237002370023700237202374023750237502375023750237402374023740237302373023730237302373023720237102371023710237102371023710237102371023700237002370023700
9201000005710057100571004710037100f7000e7000c7000c7000c7001270011700107000e700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
91010000107511275116751197511d751217512875100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
9001000008630096400a6600c6700c6700d6600e6500f6500f6300e6300d6200c6100b610056102b6002a60028600276000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002018001111515115181151d11518115151151110515105181051d10518105151051011513115171151c11517115131151010513105171051c10517105131050000000000000000000000000000000000000000
002018000e11511115151151a11515115111150e10511105151051a10515105111050c11510115131151811513115101150c10510105131051810513105101050000000000000000000000000000000000000000
__music__
01 10121544
00 11131644
00 17181b44
00 191a1c44
00 5d121544
00 5e131644
00 1d121544
02 1e131644
01 50122944
02 50132a44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
04 1f424344
04 60614344

