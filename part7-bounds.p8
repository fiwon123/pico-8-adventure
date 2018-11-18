pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

debug = true

-- a table comtaining all game entities
entities = {}

function canwalk(x,y)
 return not fget(mget(x/8,y/8),7)
end

function touching(x1,y1,w1,h1,x2,y2,w2,h2)
 return x1+w1 > x2 and
 x1 < x2+w2 and
 y1+h1 > y2 and
 y1 < y2+h2
end

function newbounds(xoff,yoff,w,h)
 local b = {}
 b.xoff = xoff
 b.yoff = yoff
 b.w = w
 b.h = h
 return b
end

-- creates and returns a new control component
function newcontrol(left,right,up,down,input)
 local c = {}
 c.left = left
 c.right = right
 c.up = up
 c.down = down
 c.input = input
 return c
end

-- creates and returns a new intention component
function newintention()
 local i = {}
 i.left = false
 i.right = false
 i.up = false
 i.down = false
 return i
end

-- creates and returns a new position
function newposition(x,y,w,h)
 local p = {}
 p.x = x
 p.y = y
 p.w = w
 p.h = h
 return p
end

-- creates and returns a new sprite
function newsprite(x,y)
 local s = {}
 s.x = x
 s.y = y
 return s
end

-- creates and returns a new entity
function newentity(position,sprite,control,intention,bounds)
 local e = {}
 e.position = position
 e.sprite = sprite
 e.control = control
 e.intention = intention
 e.bounds = bounds
 return e
end

function playerinput(ent)
  ent.intention.left = btn(ent.control.left)
  ent.intention.right = btn(ent.control.right)
  ent.intention.up = btn(ent.control.up)
  ent.intention.down = btn(ent.control.down)
end

function npcinput(ent)
  ent.intention.left = true
end

controlsystem = {}
controlsystem.update = function()
 for ent in all(entities) do
  if ent.control ~= nil and ent.intention ~= nil then
   ent.control.input(ent)
  end
 end
end

physicssystem = {}
physicssystem.update = function()
 for ent in all(entities) do

  local newx = ent.position.x
  local newy = ent.position.y

  if ent.position ~= nil and ent.intention ~= nil then
   if ent.intention.left then newx -= 1 end
   if ent.intention.right then newx += 1 end
   if ent.intention.up then newy -= 1 end
   if ent.intention.down then newy += 1 end
  end

  local canmovex = true
  local canmovey = true

  --
  -- map collision
  --

  -- update x position if allowed to move
  if not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
     not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) or
     not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
     not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) then
   canmovex = false
  end
  -- update y position if allowed to move
  if not canwalk(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) then
   canmovey = false
  end

  --
  -- entity collision
  --

  -- check x
  for o in all(entities) do
   if o ~= ent and
      touching(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
          o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
    canmovex = false
   end
  end

  -- check y
  for o in all(entities) do
   if o ~= ent and
    touching(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
       o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
     canmovey = false
   end
  end

  if canmovex then ent.position.x = newx end
  if canmovey then ent.position.y = newy end

 end
end

gs = {}
gs.update = function()
  cls()
  --centre camera on player
  camera(-64+player.position.x+(player.position.w/2),
         -64+player.position.y+(player.position.h/2))
  map()

  -- draw all entities with sprites and positions
  for ent in all(entities) do
   if ent.sprite ~= nil and ent.position ~= nil then
    sspr(ent.sprite.x, ent.sprite.y,
         ent.position.w, ent.position.h,
         ent.position.x, ent.position.y)
   end

   -- draw bounding boxes
   if debug then
    rect(ent.position.x+ent.bounds.xoff,
        ent.position.y+ent.bounds.yoff,
        ent.position.x+ent.bounds.xoff+ent.bounds.w-1,
        ent.position.y+ent.bounds.yoff+ent.bounds.h-1,9)
   end
  end

  camera()
  --crosshair sprite
  --spr(16,64-4,64-4)

end

function _init()
  -- create a player entity
  player = newentity(
   -- create a position component
   newposition(10,10,8,8),
   -- create a sprite component
   newsprite(8,0),
   -- create a control component
   newcontrol(0,1,2,3,playerinput),
   -- create an intention component
   newintention(),
   -- create a new bounding box
   newbounds(0,6,8,2)
  )
  add(entities,player)

  -- create a tree entity
  add(entities,
    newentity(
      -- create a position component
      newposition(30,30,16,16),
      -- create a sprite component
      newsprite(8,8),
      -- create a control component
      nil,
      -- create an intention component
      nil,
      -- create a new bounding box
      newbounds(6,12,4,4)
    )
  )

end

function _update()
 --check player input
 controlsystem.update()
 -- move entities
 physicssystem.update()
end

function _draw()
 gs.update()
end


__gfx__
0000000000aaaa005555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa05555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aa5aa5aa5555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa5555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa5555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aa5555aa5555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa05555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa005555555533333333cccccccc6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
0008800000000bbb0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000880000000bbbbbb0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b0b0bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8800008800b00b0b00b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8800008800bbbb00bbb0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b0b0b0bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000880000000bb0b0000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000880000000bbb00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000bb4bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000004b4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030303030303020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030304040403020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030303040403020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030303030403020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030303030403020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020203030303030303030303020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0502020202020202020202020202020500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
