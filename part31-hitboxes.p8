pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

debug = true

function newapple(x,y)
 return newentity({
     -- create a position component
     position = newposition(x,y,4,5),
     -- sprite
     sprite = newsprite({ idle = { images = {{0,16}}, flip = false } }),
     -- item
     item = 'apple'
   })
end

database = {}
database.apple = {
 maxstack = 3,
 position = {w=4, h=5},
 sprite = { idle = { images = {{0,16}}, flip = false } },
 newfunction = newapple
}

cutscene = {}
cutscene.scene = {}
cutscene.step = 1
cutscene.timer = 0
cutscene.wait = function(t)
  cutscene.timer += 1
  if cutscene.timer > t then
    cutscene.advance()
  end
end
cutscene.advance = function()
  if #cutscene.scene > 0 then
    cutscene.step += 1
    cutscene.timer = 0
  end
end
cutscene.update = function()
  if #cutscene.scene > 0 then
    if cutscene.step > #cutscene.scene then
      -- reset
      cutscene.scene = {}
      cutscene.step = 1
      cutscene.timer = 0
    else
      -- run the next part of the scene
      local f = cutscene.scene[cutscene.step][1]
      local p1 = cutscene.scene[cutscene.step][2]
      local p2 = cutscene.scene[cutscene.step][3]
      local p3 = cutscene.scene[cutscene.step][4]
      f(p1,p2,p3)
    end
  end
end

curtain = {}
curtain.state = 'up'
curtain.height = 0
curtain.speed = 4
curtain.set = function(s)
 curtain.state = s
 cutscene.advance()
end
curtain.draw = function()
  -- top
  rectfill(0,-1,128,curtain.height-1,0)
  --bottom
  rectfill(0,129,128,129-curtain.height,0)
end
curtain.update = function()
 if curtain.state == 'up' then
   if curtain.height > 0 then
     curtain.height -= curtain.speed
   end
 end
 if curtain.state == 'down' then
   if curtain.height <= 64 then
     curtain.height += curtain.speed
   end
 end
end

outside = {}
outside.x = 0
outside.y = 0
outside.w = 22
outside.h = 11
outside.bg = 3

shop = {}
shop.x = 22
shop.y = 0
shop.w = 12
shop.h = 8
shop.bg = 2

currentroom = outside
function setcurrentroom(room)
 currentroom = room
 cutscene.advance()
end
function moveroom(room,entity,x,y)
 cutscene.scene = {
   {curtain.set,'down'},
   {cutscene.wait,20},
   {setcurrentroom,room},
   {entity.position.setposition,x,y},
   {curtain.set,'up'},
   {cutscene.wait,20}
 }
end

-- a table comtaining all game entities
entities = {}

function printoutline(t,x,y,c)
  -- draw the outline
  for xoff=-1,1 do
    for yoff=-1,1 do
      print(t,x+xoff,y+yoff,0)
    end
  end
  --draw the text
  print(t,x,y,c)
end

function ycomparison(a,b)
  if a.position == nil or b.position == nil then return false end
  return a.position.y + a.position.h >
         b.position.y + b.position.h
end

function sort(list, comparison)
  for i = 2,#list do
    local j = i
    while j > 1 and comparison(list[j-1], list[j]) do
      list[j],list[j-1] = list[j-1],list[j]
      j -= 1
    end
  end
end

function canwalk(x,y)
  return not fget(mget(x/8,y/8),7)
end

function touching(x1,y1,w1,h1,x2,y2,w2,h2)
  return x1+w1 > x2 and
  x1 < x2+w2 and
  y1+h1 > y2 and
  y1 < y2+h2
end

function newinventory(s,v,x,y,items)
 local i = {}
 i.size = s
 i.visible = v
 i.x = x
 i.y = y
 i.items = items
 -- fill up inventory space
 for x=i.size-#i.items,i.size do
  add(i.items,nil)
 end
 i.selected = 1
 return i
end

function newdialogue()
  local d = {}
  d.text = {nil,nil}
  d.timed = false
  d.timeremaining = 0
  d.cursor = 0
  d.set = function(text,timed)
    -- split text into 2 lines
    if #text > 15 then

      local splitpos = 15
      local spacefound = false

      while splitpos < #text and spacefound == false do
        if sub(text,splitpos,splitpos) == ' ' then
          spacefound = true
        end
        splitpos += 1
      end
      d.text[0] = sub(text,0,splitpos-1)
      d.text[1] = sub(text,splitpos,#text)
    else
      d.text[0] = text
      d.text[1] = nil
    end
    d.timed = timed
    d.cursor = 0
    if timed then d.timeremaining = 100 end
    cutscene.advance()
  end
  return d
end

function newstate(initialstate,r)
  local s = {}
  s.current = initialstate
  s.previous = initialstate
  s.rules = r
  return s
end

function newbounds(xoff,yoff,w,h)
  local b = {}
  b.xoff = xoff
  b.yoff = yoff
  b.w = w
  b.h = h
  return b
end

function newtrigger(xoff,yoff,w,h,f,type)
  local t = {}
  t.xoff = xoff
  t.yoff = yoff
  t.w = w
  t.h = h
  t.f = f
  -- type = 'once', 'always' and 'wait'
  t.type = type
  t.active = false
  return t
end

-- creates and returns a new control component
function newcontrol(left,right,up,down,o,x,input)
  local c = {}
  c.left = left
  c.right = right
  c.up = up
  c.down = down
  c.o = o
  c.x = x
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
  i.moving = false
  i.o = false
  i.x = false
  return i
end

-- creates and returns a new position
function newposition(x,y,w,h)
  local p = {}
  p.x = x
  p.y = y
  p.w = w
  p.h = h
  p.setposition = function(x,y)
    p.x = x
    p.y = y
    cutscene.advance()
  end
  return p
end

-- creates and returns a new sprite
function newsprite(sl)
  local s = {}
  s.spritelist = sl
  s.index = 1
  --s.flip = false
  return s
end

function newanimation(l)
  local a = {}
  a.timer = 0
  a.delay = 3
  a.list = l
  return a
end

function newbattle(hitboxes)
 local b = {}
 b.hitboxes = hitboxes
 return b
end

-- creates and returns a new entity
function newentity(componenttable)
  local e = {}
  e.position = componenttable.position or nil
  e.sprite = componenttable.sprite or nil
  e.control = componenttable.control or nil
  e.intention = componenttable.intention or nil
  e.bounds = componenttable.bounds or nil
  e.animation = componenttable.animation or nil
  e.trigger = componenttable.trigger or nil
  e.dialogue = componenttable.dialogue or nil
  e.state = componenttable.state or {current='idle'}
  e.inventory = componenttable.inventory or nil
  e.item = componenttable.item or false
  e.battle = componenttable.battle or nil
  e.gamestate = 'playing'
  return e
end

function playerinput(ent)

  if #cutscene.scene > 0 then
    ent.intention.left = false
    ent.intention.right = false
    ent.intention.up = false
    ent.intention.down = false
    ent.intention.o = false
    ent.intention.x = false
  else
    if ent.gamestate then
     if ent.gamestate == 'playing' then
      ent.intention.left = btn(ent.control.left)
      ent.intention.right = btn(ent.control.right)
      ent.intention.up = btn(ent.control.up)
      ent.intention.down = btn(ent.control.down)
      ent.intention.o = btnp(ent.control.o)
      ent.intention.x = btnp(ent.control.x)
     elseif ent.gamestate == 'inventory' then
      ent.intention.left = btnp(ent.control.left)
      ent.intention.right = btnp(ent.control.right)
      ent.intention.up = btnp(ent.control.up)
      ent.intention.down = btnp(ent.control.down)
      ent.intention.o = btnp(ent.control.o)
      ent.intention.x = btnp(ent.control.x)
     end
    end
  end
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
   if ent.gamestate and ent.gamestate == 'playing' then
    if ent.position and ent.bounds then

      local newx = ent.position.x
      local newy = ent.position.y

      if ent.intention then
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
        if o.position and o.bounds then
          if o ~= ent and
             touching(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            canmovex = false
          end
        end
      end

      -- check y
      for o in all(entities) do
        if o.position and o.bounds then
          if o ~= ent and
             touching(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            canmovey = false
          end
        end
      end

      if canmovex then ent.position.x = newx end
      if canmovey then ent.position.y = newy end
    end
   end
  end
end

animationsystem = {}
animationsystem.update = function()
  for ent in all(entities) do
   if ent.gamestate and ent.gamestate == 'playing' then
    if ent.sprite and ent.animation and ent.state then

      if ent.animation.list[ent.state.current] then
       -- increment timer
       ent.animation.timer += 1
       -- if timer is higher than the delay
       if ent.animation.timer > ent.animation.delay then
        -- increment the index and reset the timer
        ent.sprite.index += 1
        if ent.sprite.index > #ent.sprite.spritelist[ent.state.current]['images'] then
         ent.sprite.index = 1
        end
        ent.animation.timer = 0
       end
      end

    end
  end
 end
end

triggersystem = {}
triggersystem.update = function()
  for ent in all(entities) do
    if ent.trigger and ent.position then
      local triggered = false
      for o in all(entities) do
        if ent ~= o and o.bounds and o.position then
          if touching(ent.position.x+ent.trigger.xoff,ent.position.y+ent.trigger.yoff,ent.trigger.w,ent.trigger.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            -- trigger is activated
            triggered = true
            if ent.trigger.type == 'once' then
              ent.trigger.f(ent,o)
              ent.trigger = nil
              break
            end
            if ent.trigger.type == 'always' then
              ent.trigger.f(ent,o)
              ent.trigger.active = true
            end
            if ent.trigger.type == 'wait' then
              if ent.trigger.active == false then
                ent.trigger.f(ent,o)
                ent.trigger.active = true
              end
            end
          end
        end
      end

      if triggered == false then
        ent.trigger.active = false
      end

    end
  end
end

dialoguesystem = {}
dialoguesystem.update = function()
  for ent in all(entities) do
    if ent.dialogue then
      if ent.dialogue.text[0] then

        -- calculate length of text
        local len = #ent.dialogue.text[0]
        if ent.dialogue.text[1] and #ent.dialogue.text[1] > 0 then
          len += #ent.dialogue.text[1]
        end

        if ent.dialogue.cursor < len then
          ent.dialogue.cursor += 1
        end
        if ent.dialogue.timed and
           ent.dialogue.timeremaining > 0 then
          ent.dialogue.timeremaining -= 1
        end
      end
    end
  end
end

statesystem = {}
statesystem.update = function()
 for ent in all(entities) do
  if ent.gamestate and ent.gamestate == 'playing' then
  if ent.state and ent.state.rules then

   ent.state.previous = ent.state.current

   for s,r in pairs(ent.state.rules) do
    if r() then ent.state.current = s end
   end

  end
  end
 end
end

itemsystem = {}
itemsystem.update = function()
 for ent in all(entities) do
  if ent.item then

   for o in all(entities) do
    if o ~= ent and o.position and o.bounds and ent.position then

     if touching(ent.position.x,ent.position.y,ent.position.w,ent.position.h,
                 o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
      if o.inventory then
       if o.intention and o.intention.x then

        local found = false
        -- is there an existing place to stack the item?
        for p=1,o.inventory.size do
         if o.inventory.items[p] ~= nil then
          if o.inventory.items[p]['id'] == ent.item then
           if o.inventory.items[p]['num'] < database[ent.item]['maxstack'] then
            o.inventory.items[p]['num'] += 1
            del(entities,ent)
            found = true
            break
           end
          end
         end
        end

        -- is there a spare inventory slot?
        if found == false then
         for p=1,o.inventory.size do
          if o.inventory.items[p] == nil then
           o.inventory.items[p] = { id=ent.item, num=1 }
           del(entities,ent)
           break
          end
         end
        end

       end
      end
     end

    end
   end

  end
 end
end

gamestatesystem = {}
gamestatesystem.update = function()
 for ent in all(entities) do
  if ent.gamestate and ent.intention then
   if ent.intention.o and ent.intention.x then
    if ent.gamestate == 'playing' then
     ent.gamestate = 'inventory'
    else
     if ent.gamestate == 'inventory' then
      ent.gamestate = 'playing'
     end
    end
   end
  end
 end
end

inventorysystem = {}
inventorysystem.update = function()
 for ent in all(entities) do
  if ent.inventory and ent.inventory.visible then
   if ent.gamestate and ent.gamestate == 'inventory' then
    if ent.intention.left then
     ent.inventory.selected = max(1,ent.inventory.selected-1)
    elseif ent.intention.right then
     ent.inventory.selected = min(ent.inventory.selected+1,ent.inventory.size)
    elseif ent.intention.down then
     -- drop item
     -- if item exists at selected position
     if ent.inventory.items[ent.inventory.selected] then
      --local i = ent.inventory.items[ent.inventory.selected]
      --if i.position then
       -- update position
       --i.position.x = ent.position.x
       --i.position.y = ent.position.y
       --add(entities,i)
       --del(ent.inventory.items,i)
       --ent.inventory.items[ent.inventory.selected] = nil
      --end

      local id = ent.inventory.items[ent.inventory.selected]['id']
      local num = ent.inventory.items[ent.inventory.selected]['num']
      local f = database[id]['newfunction']

      add(entities,f(ent.position.x,ent.position.y))
      ent.inventory.items[ent.inventory.selected]['num'] -= 1
      if ent.inventory.items[ent.inventory.selected]['num'] < 1 then
       ent.inventory.items[ent.inventory.selected] = nil
      end

     end
    end
   end
  end
 end
end

gs = {}
gs.update = function()
  cls()
  sort(entities, ycomparison)

  local camerax = -64+player.position.x+(player.position.w/2)
  local cameray = -64+player.position.y+(player.position.h/2)

  --centre camera on player
  camera(camerax,cameray)
  map()

  -- draw all entities with sprites and positions
  for ent in all(entities) do

    -- draw entity
    if ent.sprite and ent.position and ent.state then

     -- reset sprite index if state has changed
     if ent.state.current != ent.state.previous then
      ent.sprite.index = 1
     end

      sspr(ent.sprite.spritelist[ent.state.current]['images'][ent.sprite.index][1],
           ent.sprite.spritelist[ent.state.current]['images'][ent.sprite.index][2],
           ent.position.w, ent.position.h,
           ent.position.x, ent.position.y,
           ent.position.w, ent.position.h,
           ent.sprite.spritelist[ent.state.current]['flip'],false)
    end

    -- draw bounding boxes
    if debug then
      -- bounding boxes
      if ent.position and ent.bounds then
        rect(ent.position.x+ent.bounds.xoff,
             ent.position.y+ent.bounds.yoff,
             ent.position.x+ent.bounds.xoff+ent.bounds.w-1,
             ent.position.y+ent.bounds.yoff+ent.bounds.h-1,9)
      end
      -- trigger boxes
      if ent.position and ent.trigger then
        local colour
        if ent.trigger.active then colour = 11 else colour = 10 end
        rect(ent.position.x+ent.trigger.xoff,
             ent.position.y+ent.trigger.yoff,
             ent.position.x+ent.trigger.xoff+ent.trigger.w-1,
             ent.position.y+ent.trigger.yoff+ent.trigger.h-1,colour)
      end
      if ent.battle and ent.position and ent.state then
       local s = ent.state.current
       local hb = ent.battle.hitboxes[s]
       if hb then
        rect(ent.position.x+hb.xoff,
             ent.position.y+hb.yoff,
             ent.position.x+hb.xoff+hb.w-1,
             ent.position.y+hb.yoff+hb.h-1,12)
       end
      end
    end
  end

  camera()
  --crosshair sprite
  --spr(16,64-4,64-4)

  -- draw room border
  -- top border
  rectfill(-1,-1,128,(currentroom.y*8)-cameray-1,currentroom.bg)
  -- left border
  rectfill(-1,-1,(currentroom.x*8)-camerax-1,128,currentroom.bg)
  -- right border
  rectfill((currentroom.x+currentroom.w)*8-camerax,-1,128,128,currentroom.bg)
  -- bottom border
  rectfill(-1,(currentroom.y+currentroom.h)*8-cameray,128,128,currentroom.bg)

  camera(camerax,cameray)

  -- draw dialogue boxes
  for ent in all(entities) do
    if ent.dialogue and ent.position then
      if ent.dialogue.text[0] then
        if (ent.dialogue.timed == false) or
           (ent.dialogue.timed and ent.dialogue.timeremaining > 0) then

          -- move text up if there are 2 lines
          local offset = 0
          if ent.dialogue.text[1] then
            if #ent.dialogue.text[1] > 0 then
              offset -= 8
            end
          end

          -- draw line 1
          local texttodraw = sub(ent.dialogue.text[0],0,ent.dialogue.cursor)
          printoutline(texttodraw,ent.position.x-10,ent.position.y+offset-8,7)

          -- draw line 2
          if ent.dialogue.text[1] then
            texttodraw = sub(ent.dialogue.text[1],0,max(0,ent.dialogue.cursor - #ent.dialogue.text[0]))
            printoutline(texttodraw,ent.position.x-10,ent.position.y+offset,7)
          end

        end
      end
    end
  end

  camera()

  -- draw inventories
  for ent in all(entities) do
   if ent.inventory and ent.inventory.visible then
    rectfill(ent.inventory.x,ent.inventory.y,ent.inventory.x+(ent.inventory.size*9),ent.inventory.y+9,0)
    for i=1,ent.inventory.size do
     -- draw inventory slot
     rectfill(ent.inventory.x+1+(i-1)*9,ent.inventory.y+1,ent.inventory.x+1+(i-1)*9+7,ent.inventory.y+8,6)
     -- draw item if one exists
     if ent.inventory.items[i] then
      --local e = ent.inventory.items[i]
      --sspr(e.sprite.spritelist[e.state.current]['images'][e.sprite.index][1],
      --     e.sprite.spritelist[e.state.current]['images'][e.sprite.index][2],
      --     e.position.w, e.position.h,
      --     ent.inventory.x + 1 + (i-1)*9 + ((8-e.position.w) / 2), ent.inventory.y + 1 + ((8-e.position.h) / 2),
      --     e.position.w, e.position.h,
      --     e.sprite.spritelist[e.state.current]['flip'],false)

      local id = ent.inventory.items[i]['id']
      local num = ent.inventory.items[i]['num']

      sspr(database[id]['sprite']['idle']['images'][1][1],
           database[id]['sprite']['idle']['images'][1][2],
           database[id]['position'].w, database[id]['position'].h,
           ent.inventory.x + 1 + (i-1)*9 + ((8-database[id]['position'].w) / 2), ent.inventory.y + 1 + ((8-database[id]['position'].h) / 2),
           database[id]['position'].w, database[id]['position'].h,
           database[id]['sprite']['idle']['flip'],false)

      -- number of stacked items
      if num > 1 then
       print(num,ent.inventory.x + 1 + (i-1)*9 , ent.inventory.y + 1,7)
      end

     end
    end
    if ent.gamestate and ent.gamestate == 'inventory' then
     rect(ent.inventory.x+((ent.inventory.selected-1)*9),ent.inventory.y,ent.inventory.x+((ent.inventory.selected-1)*9)+9,ent.inventory.y+9,10)
    end
   end
  end

  curtain.draw()

end

function _init()

  -- create a player entity
  player = newentity({
    -- create a position component
    position = newposition(10,10,4,8),
    -- create a sprite component
    --sprite = newsprite({{8,0},{12,0},{16,0},{20,0}},1),
    sprite = newsprite({
                         standleft  = { images = {{8,0}}, flip = true },
                         moveleft   = { images = {{8,0},{12,0},{16,0},{20,0}}, flip = true },
                         standright = { images = {{8,0}}, flip = false },
                         moveright  = { images = {{8,0},{12,0},{16,0},{20,0}}, flip = false },
                         standup    = { images = {{24,0}}, flip = true },
                         moveup     = { images = {{24,0},{28,0},{32,0},{36,0}}, flip = true },
                         standdown  = { images = {{24,8}}, flip = false },
                         movedown   = { images = {{24,8},{28,8},{32,8},{36,8}}, flip = false },
                         hitleft    = { images = {{24,16},{28,16},{32,16},{36,16}}, flip = true },
                         hitright   = { images = {{24,16},{28,16},{32,16},{36,16}}, flip = false },
                         hitdown    = { images = {{40,16},{44,16},{48,16},{52,16}}, flip = false },
                         hitup      = { images = {{56,16},{60,16},{64,16},{68,16}}, flip = false }
                      }),
    -- create a control component
    control = newcontrol(0,1,2,3,4,5,playerinput),
    -- create an intention component
    intention = newintention(),
    -- create a new bounding box
    bounds = newbounds(0,6,4,2),
    -- create a new animation component
    animation = newanimation({moveleft=true,moveright=true,moveup=true,movedown=true,hitleft=true,hitright=true,hitdown=true,hitup=true}),
    -- dialogue component
    dialogue = newdialogue(),
    -- state component
    state = newstate('standright',{ moveup = function() return player.intention.up end,
                                    movedown = function() return player.intention.down end,
                                    moveleft = function() return player.intention.left end,
                                    moveright = function() return player.intention.right end,
                                    standup = function() return (not player.intention.up and player.state.current == 'moveup') or (player.state.current == 'hitup' and player.sprite.index > 3) end,
                                    standdown = function() return (not player.intention.down and player.state.current == 'movedown') or (player.state.current == 'hitdown' and player.sprite.index > 3) end,
                                    standleft = function() return (not player.intention.left and player.state.current == 'moveleft') or (player.state.current == 'hitleft' and player.sprite.index > 3) end,
                                    standright = function() return (not player.intention.right and player.state.current == 'moveright') or (player.state.current == 'hitright' and player.sprite.index > 3) end,
                                    hitright = function() return (player.state.current == 'standright' or player.state.current == 'moveright') and (player.intention.o and not player.intention.x) and (not player.intention.right) end,
                                    hitleft = function() return (player.state.current == 'standleft' or player.state.current == 'moveleft') and (player.intention.o and not player.intention.x) and (not player.intention.left) end,
                                    hitup = function() return (player.state.current == 'standup' or player.state.current == 'moveup') and (player.intention.o and not player.intention.x) and (not player.intention.up) end,
                                    hitdown = function() return (player.state.current == 'standdown' or player.state.current == 'movedown') and (player.intention.o and not player.intention.x) and (not player.intention.down) end,
                                  }),
    -- inventory component
    inventory = newinventory(3,true,(128 - (3*9+1)) / 2,115,{}),
    -- battle component
    battle = newbattle({ hitleft = {xoff=-4,yoff=0,w=4,h=8},
                         hitright = {xoff=4,yoff=0,w=4,h=8},
                         hitdown = {xoff=0,yoff=6,w=4,h=6},
                         hitup = {xoff=0,yoff=-6,w=4,h=6}})
  })
  add(entities,player)

  -- create a tree entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(30,30,16,16),
      -- create a sprite component
      sprite = newsprite({ idle = { images = {{8,8}}, flip = false } }),
      -- create a new bounding box
      bounds = newbounds(6,12,4,4),
      -- trigger component
      trigger = newtrigger(4,10,8,8,
        function(self,other)
          if other == player then
            -- cutscene
            cutscene.scene = {
              {other.dialogue.set,'oh look, a tree. how beautiful!',true},
              {cutscene.wait,100},
              {other.dialogue.set,'some more text!',true},
              {cutscene.wait,100}
            }

          end
        end,'wait')
    })
  )

  -- create a shop entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(60,40,16,16),
      -- create a sprite component
      sprite = newsprite({ idle = { images = {{40,0}}, flip = false } }),
      -- create a new bounding box
      bounds = newbounds(0,8,16,8),
      -- create a new trigger component
      trigger = newtrigger(10,16,5,3,
        function(self,other)
          if other == player then
            moveroom(shop,other,242,44)
          end
        end,'wait')
    })
  )

  -- create a shop door exit trigger
  add(entities,
    newentity({
      -- create a position component
      position = newposition(240,55,16,3),
      -- create a new trigger component
      trigger = newtrigger(0,0,8,3,
        function(self,other)
          if other == player then
            moveroom(outside,other,70,55)
          end
        end,'wait')
    })
  )

  -- create an apple
  add(entities,newapple(20,20))
  add(entities,newapple(40,20))
  add(entities,newapple(60,20))
  add(entities,newapple(80,20))

end

function _update()
  --check player input
  controlsystem.update()
  -- move entities
  physicssystem.update()
  -- animate entities
  animationsystem.update()
  -- check triggers
  triggersystem.update()
  -- item system
  itemsystem.update()
  -- state system
  statesystem.update()
  -- update dialogue
  dialoguesystem.update()
  -- update cutscene
  cutscene.update()
  -- update game state
  gamestatesystem.update()
  -- update inventories
  inventorysystem.update()
  -- update curtain
  curtain.update()
end

function _draw()
  gs.update()
end


__gfx__
0000000088888888000000008888888800000000000000555500000033333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333333333
000000008fff8fff888888888888888888888888000005555550000033333333cccccccccc333333333333cc33cccccccccccc33333443333334433333344333
007007008fff8fff8fff8fff8888888888888888000055555555000033333333ccccccccc33333333333333c3cccccccccccccc3334554333345543333455433
00077000811181118fff8fff1811181188888888000555555555500033333333ccccccccc33333333333333c3cccccccccccccc3345445444454454344544544
0007700011111111811181111181118111811181005555555555550033333333cccccccc3333333333333333cccccccccccccccc345445444454454344544544
0070070011f1111f11f11f11f11f111ff81ff811055555555555555033333333cccccccc3333333333333333cccccccccccccccc334554333345543333455433
0000000011111111111111111111121111111121555555555555555533333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000002202020020000020220002002200200444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333333333
000880000000000bb00000008888888800000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0008800000000bbbbbbb00008ff88ff888888888446666666455555433733333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000000000bbbbbbb00008ff88ff88ff88ff8446676666456665437773333cc7ccccc3333333333333333cccccccccccccccc334554333345543333455433
88000088000bbbbbbbbbbb00811881188ff88ff8446766666456665433733333c7c7cccc3333333333333333cccccccccccccccc345445444454454334544543
88000088000bbbbbbbbbbbb01111111181188118446666666455555433333333ccccccccc33333333333333c3cccccccccccccc3345445444454454334544543
0000000000bbbbbbbbbbbbb0f11ff1f1f11f1f1f4466666664555654333333a3cccccc7cc33333333333333c3cccccccccccccc3334554333345543333455433
0008800000bbbbbbbbbbbbb0111111111111111144444444445555543333a333ccccc7c7cc333333333333cc33cccccccccccc33333443333334433333344333
00088000000bbbbbbbbbb0000220020002200020444444444455555433333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333344333
0004000000000bb40bb4000088888888888888888888888888888888888888888888888800000000000000000000000000000000000000000000000056555555
0840000000000004004000008fff8fff8fff8fff8ff88ff88ff88ff8888888888888888800000000000000000000000000000000000000000000000056555555
8888000000000004440000008fff8fff8fff8fff8ff88ff88ff88ff8888888888888888800000000000000000000000000000000000000004444444456555555
8888000000000004400000008ccc8ccc8ccc8ccc8cc88cc88cc88cc8c8ccc8ccc8ccc8cc00000000000000000000000000000000000000004444444466666666
088000000000004440000000cccccccccccccccccccccccccccccccccc8ccc8ccc8ccc8c00000000000000000000000000000000000000004444444455555655
000000000000000440000000ccfcccfcccfcccfcfccffccffccffccffccffccffccffccf00000000000000000000000000000000000000004444444455555655
000000000000000440000000cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000055555655
00000000000000044000000002200220022002200220022002200220022002200220022000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
__gff__
0000000000800000800000808080808000000000000000008000008080808080000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707070b080c070707070717071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707080808070707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07071707070707070707081808190707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707081808080c07070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707071b0808081c17070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f2f2f2f2f2f2f2f2f2e2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707071707070707070707070707071f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
