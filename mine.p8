pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
  state = 0
  mstate = init_menu()
end

function _update()
  if state == 0 do
    update_menu(mstate)
    return
  end
  if playing do
    inputs()
  else
    endgame_input()
  end
end

function _draw()
  cls()
  if state == 0 do
    draw_menu(mstate)
  elseif state == 1 do
    draw_board(board)
  end
end

function draw_board(board)
  if shake > 0 do
    shakex = rnd(shake)-(shake/2)
    shakey = rnd(shake)-(shake/2)
    shake -= 2
    vo += shakey
    ho += shakex
  else
    shake = 0
    shakex = 0
    shakey = 0
  end

  for i=0,board.width-1 do
    for j=0,board.height-1 do
      local tile = board.f[i+1][j+1]
      if tile.flag == 0 do
        spr(10, i*8+ho, j*8+vo)
      elseif tile.flag == 1 do
        print(board.f[i+1][j+1].v, i*8+2+ho,j*8+2+vo, get_color(board.f[i+1][j+1].v))
      elseif tile.flag == 2 do
        spr(12, i*8+ho, j*8+vo)
      elseif tile.flag == 3 do
        spr(13, i*8+ho, j*8+vo)
      end
    end
  end
  spr(11, (selection.x-1)*8+ho, (selection.y-1)*8+vo)
  if winner do
    print("congratulations!",0,0,7)
  elseif playing == false do
    print("your head asplode!", 0, 0, 8)
  else
    print("number of mines: "..(num_mines-flags),0,0,7)
    print("❎ to reveal tile, 🅾️ to flag", 0, 120, 13)
  end
  print(seconds, 0, 8, 6)
  
  vo -= shakey
  ho -= shakex
end
-->8
function init_game(mines, width, height)
  num_mines = mines
  clicked = false
  flags = 0
  board_width = width
  board_height = height
  ho = (128-(width*8))/2
  vo = (128-(height*8))/2
  safe_tiles = (board_width * board_height) - num_mines
  board = init_board(board_width,board_height)
  add_mines(board,num_mines)
  set_numbers(board)
  selection = {}
  selection.x = 1
  selection.y = 1
  playing=true
  winner = false
  state = 1
  shake = 0
  shakex = 0
  shakey = 0
  ticks = 0
  seconds = 0
end

function init_board(width, height)
  board = {}
  board.width = width
  board.height = height
  board.f = {}
  for i=1,width do
    board.f[i] = {}
    for j=1,height do
      board.f[i][j] = {}
      board.f[i][j].flag = 0
      -- 0 is unrevealed
      -- 1 is revealed
      -- 2 is flagged
      -- 3 is question marked
      board.f[i][j].v = 0
    end
  end
  return board
end

function add_mines(board, startmines)
  local mines = startmines
  if mines > ((board.width*board.height)-9) do
    return
  end
  local fails = 0
  ::mineplacement::
  mines = startmines
  fails = 0
  while mines > 0 do
    local added = add_mine(board)
    if added do
      mines-=1
    else
      fails += 1
    end
    if fails > 50 do
      init_board(board.width, board.height)
      goto mineplacement
    end
  end
end

function add_mine(board)
  local x = flr(rnd(board.width))+1
  local y = flr(rnd(board.height))+1
  if board.f[x][y].v == "x" do
    return
  end
  local adj = 0
  for x2=x-1,x+1 do
    for y2=y-1,y+1 do
      if x2 > 0 and y2 > 0 and x < board.width and y < board.height do
        if board.f[x2][y2].v == "x" do
          adj += 1
        end
      end
    end
  end
  if adj > 4 do
    return false
  end
  board.f[x][y].v = "x"
  return true
end

function move_mines(board, x, y)
  local minecount = region_clear_mines(board, x, y)
  while minecount != 0 do
    add_mines(board, minecount)
    minecount = region_clear_mines(board, x, y)
  end
  set_numbers(board)
end

function region_clear_mines(board, x, y)
  local minecount = 0
  for x2=x-1,x+1 do
    for y2=y-1,y+1 do
      if x2 > 0 and y2 > 0 and x < board.width and y < board.height do
        if board.f[x2][y2].v == "x" do
          board.f[x2][y2].v = 0
          minecount+=1
        end
      end
    end
  end
  return minecount
end

function set_numbers(board)
  for i=1, board.width do
    for j=1, board.height do
      if board.f[i][j].v != "x" do
        board.f[i][j].v = 0
        for x=i-1,i+1 do
          for y=j-1,j+1 do
            if x > 0 and y > 0 and x <= board.width and y <= board.height do
              if board.f[x][y].v == "x" do
                board.f[i][j].v += 1
              end
            end
          end
        end
      end
    end
  end
end

function get_color(value)
  if value == "x" do
    return 8
  elseif value == 0 do
    return 1
  elseif value == 1 do
    return 12
  elseif value == 2 do
    return 11
  elseif value == 3 do
    return 9
  elseif value == 4 do
    return 10
  elseif value == 5 do
    return 13
  elseif value == 6 do
    return 4
  elseif value == 7 do
    return 14
  else
    return 2
  end
end

function reveal(board, x, y)
  if x > board.width or y > board.height or x < 1 or y < 1 do
    return
  end
  if board.f[x][y].flag == 1 do 
    return
  end
  if board.f[x][y].flag == 2 do
    flags -= 1
  end
  board.f[x][y].flag = 1
  if board.f[x][y].v == "x" do
    game_over(board)
    return
  else
    safe_tiles -= 1
  end
  if board.f[x][y].v == 0 do
    for x2=x-1,x+1 do
      for y2=y-1,y+1 do
        reveal(board, x2, y2)
      end
    end
  end
  if safe_tiles == 0 do
    win_game()
  end
end

function win_game()
  winner = true
  playing = false
end

function game_over(board)
  playing = false
  shake = 30
  for x=1,board.width do
    for y=1, board.height do
      if board.f[x][y].v == "x" do
        board.f[x][y].flag = 1
      end
    end
  end
end
-->8
function inputs()
  ticks += 1
  if ticks > 30 do
    ticks = 0
    seconds += 1
  end
  if btnp(❎) do
    local tile = board.f[selection.x][selection.y]
    if not clicked do
      clicked = true
      move_mines(board, selection.x, selection.y)
    end
    if tile.flag == 0 do
      reveal(board, selection.x, selection.y)
    end
  end
  if btnp(🅾️) do
    local tile = board.f[selection.x][selection.y]
    if tile.flag == 0 do
      flags += 1
      tile.flag = 2
      return
    end
    if tile.flag == 2 do
      flags -= 1
      tile.flag = 3
      return
    end
    if tile.flag == 3 do
      tile.flag = 0
      return
    end
  end
  if btnp(⬇️) and selection.y < board.height do
    selection.y += 1
  elseif btnp(⬆️) and selection.y > 1 do
    selection.y -= 1
  elseif btnp(➡️) and selection.x < board.width do
    selection.x += 1
  elseif btnp(⬅️) and selection.x > 1 do
    selection.x -= 1
  end
end

function endgame_input()
  if btnp(❎) or btnp(🅾️) do
    state=0
  end
end
-->8
function init_menu()
  mstate = {}
  mstate.customizing = false
  mstate.selection = 0
  mstate.maxselection = 3
  return mstate
end

function update_menu(mstate)
  if btnp(⬇️) and mstate.selection < mstate.maxselection do
    mstate.selection += 1
  elseif btnp(⬆️) and mstate.selection > 0 do
    mstate.selection -= 1
  end
  if btnp(❎) and not mstate.customizing do
    if mstate.selection == 0 do
      -- easy game
      init_game(9,8,8)
    elseif mstate.selection == 1 do
      init_game(20, 10, 10)
    elseif mstate.selection == 2 do
      init_game(45, 13, 13)
    elseif mstate.selection == 3 do
      customize()
    end
  end     
end

function customize()

end
function draw_menu(mstate)
  print("m i n e", 12, 12, 7)
  print("s w e e p e r", 24, 20, 6)
 
  sspr(0,0,10*8,16*8, 48, 0) 
  print("easy", 8, 8*4, 7)
  print("medium", 8, 8*5, 7)
  print("hard", 8, 8*6, 7)
  print("custom", 8, 8*7, 7)
  print(">", 4, (8*4)+(mstate.selection*8), 6)
  print("v 0.9", 0, 120, 13)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666000000000005555000000000000000000
00000000000000000000000000000000000000000000000000006600000000000000000000000000001111006000000600588000055000500000000000000000
00000000000000000000000000000000000000000000000066666666000000000000000000000000010000106000000600588800050000500000000000000000
0000000000000000000000000000000000000000000000066dddd666600000000000000000000000010000106000000600588000000005000000000000000000
00000000000000000000000000000000000000000000006ddd6d6ddd660000000000000000000000010000106000000600500000000050000000000000000000
000000000000000000000000000000000000000000000666dddddd6d666000000000000000000000010000106000000600500000000050000000000000000000
0000000000000000000000000000000000000000000066dddddddddddd6600000000000000000000001111006000000600500000000000000000000000000000
00000000000000000000000000000000000000000000d6dddddddddddd6660000000000000000000000000000666666000000000000050000000000000000000
0000000000000000000000000000000000000000006dddddddddddd5ddddd0000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000dddddd5d5d555d5dddd0000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000dddd555555555d5d5d60000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006d5d5d5555555555d666000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006dd55555555555556666000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000666655555555555d6666000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666d55555555d66666660000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006666666dd555d6666666d6d666600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000066666666666666666666d6ddddd00000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000666666666666666666666dd6ddd6d00000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000666dd666666666666666666ddddd5dd00000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000066dddd66666666666666666d5dddd5d600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066ddd5d5666666666666666655dddd5d600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066ddd5d5d66666666666666555d555d6000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ddd5d55555d66666666666d5555555dd000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000006ddddd555555dd6666666d55555555555000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000006ddd5d55555555555d5d55d5555555555600000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000dddddd555555555555555d5555555555d00000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000dd5ddd555555555555555d5555555555560000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ddddd555555555555555dd55555555555d0000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000dd5d5555d55555555555555555555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000dd5555555555555555555555555555555556000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000d55555555555555555555dd5d5555555555d000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000dd555555555555d5555d5dddd55555555555000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000d55555555555d5555555d5dddd5555555555d00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000006d55555555555d55555555dddd5555555555d00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006655555555555555555555555555555555555560000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000dd555555555555555555555555d55555555555d0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000d555555555555555555555555dd55555555555d0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006555555555555555555555555555555555ddddd5d000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000d5555555555555555555555555555555555555ddd600000000000000000000000000000000000000000000000000000
000000000000000000000000000000000555555555555555555555555555555555555d555d600000000000000000000000000000000000000000000000000000
00000000000000000000000000000000dd555555555555555555555555555555555555555dd00000000000000000000000000000000000000000000000000000
00000000000000000000000000000000d555555555555555555555555555555555555ddd5dd00000000000000000000000000000000000000000000000000000
00000000000000000000000000000006d55555555555555555555555555555d5555555dd5dd60000000000000000000000000000000000000000000000000000
0000000000000000000000000000000d55555555555555555555555555555dd55555555d5dd60000000000000000000000000000000000000000000000000000
0000000000000000000000000000000d55555555555555555555555555555dd55555555555dd0000000000000000000000000000000000000000000000000000
0000000000000000000000000000006555555d5005555555555555555555555555555555dddd0000000000000000000000000000000000000000000000000000
000000000000000000000000000000d55d5d5550055555555555555555555d5d5555555555500000000000000000000000000000000000000000000000000000
000000000000000000000000000000d5dd5d55500d55555555555555555555555555555555d00000000000000000000000000000000000000000000000000000
000000000000000000000000000000dddd5555d00dd5555555555555555555555555555555d00000000000000000000000000000000000000000000000000000
000000000000000000000000000000ddddd5550005d5555555555555555555555555555555d00000000000000000000000000000000000000000000000000000
000000000000000000000000000000ddd5555d000555555555555555555555555555555555d00000000000000000000000000000000000000000000000000000
000000000000000000000000000000d555555000055555555555555555555ddddd5555555d000000000000000000000000000000000000000000000000000000
00000000000000000000000000000ddd5555500005555555555555555555dddddd5555555d000000000000000000000000000000000000000000000000000000
00000000000000000000000000000ddd55550000055555555555555555555ddddd5555555d000000000000000000000000000000000000000000000000000000
00000000000000000000000000006ddd555500006dd555555555555555d555d5dd5555555d000000000000000000000000000000000000000000000000000000
0000000000000000000000000000d6dd5dd00000ddd55555555d55555555d5ddd555555555600000000000000000000000000000000000000000000000000000
0000000000000000000000000000ddd55d000000d55555555ddd5555555555dd5555555555600000000000000000000000000000000000000000000000000000
000000000000000000000000000055555d00d00d5555555555d55555555555d5ddd555555dd00000000000000000000000000000000000000000000000000000
000000000000000000000000000005555555000d555555555555555555555d5d5d55d55555d00000000000000000000000000000000000000000000000000000
00000000000000000000000000000d555555500d55555555555555555555d5555d5d555555d00000000000000000000000000000000000000000000000000000
0000000000000000000000000000005555555d0d55555555555555555555555dd55d555555000000000000000000000000000000000000000000000000000000
000000000000000000000000000000d555555d0d555555555555555555555555555555555d000000000000000000000000000000000000000000000000000000
000000000000000000000000000000ddd555550d55555555555555555555555d55d5555550000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000d55555d0d55555555555555555555555d5d55555550000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000d55555d0d5555555555555555555555d5d5d5d55500000000000000000000000000000000000000000000000000000000
0000000000000000000000000000006d5d55500d5555555555555555555555d55555555d00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000655d55600d555555555555555d5555555555d5555500000000000000000000000000000000000000000000000000000000
000000000000000000000000000000d5d555000d55555555555555d0555d555555d5555500000000000000000000000000000000000000000000000000000000
000000000000000000000000000006d5d55d000d5555555555555500d55555555555555550000000000000000000000000000000000000000000000000000000
000000000000000000000000000006555550000d5555555555555500055555555555555550000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d555550000d5555555555555500d555dd5555dd55d5d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000005555500000555555555555555000555d5d5555d5555d0000000000000000000000000000000000000000000000000000000
00000000000000000000000000006dd5550000005555555555555500055555d5555d5d5dd0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000d000000000005555555555555500055555d5555555dd00000000000000000000000000000000000000000000000000000000
0000000000000000000000000006d00000000000d555555555d555d00d555555d5d555d000000000000000000000000000000000000000000000000000000000
0000000000000000000000000006d0000000000005555555555555d0055555ddd5d5dd0000000000000000000000000000000000000000000000000000000000
000000000000000000000000000d600000000000065555555555550000d555d55555d60000000000000000000000000000000000000000000000000000000000
000000000000000000000000006d0000000000000055555555555500000555555555500000000000000000000000000000000000000000000000000000000000
000000000000000000000000006d00000000000000d5555555555500000555555555500000000000000000000000000000000000000000000000000000000000
00000000000000000000000000d60000000000000065555555555500000555555555560000000000000000000000000000000000000000000000000000000000
00000000000000000000000006d0000000000000000d555555555500000555555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000000006d0000000000000000055555555550000055555555555d000000000000000000000000000000000000000000000000000000000
0000000000000000000000000dd00000000000000000d55555555500000d55555555555000000000000000000000000000000000000000000000000000000000
0000000000000000000000006d000000000000000000d55555555d00000d55555555555000000000000000000000000000000000000000000000000000000000
000000000000000000000000dd00000000000000000065555555550000005555555555d000000000000000000000000000000000000000000000000000000000
000000000000000000000000dd000000000000000000055555555d00000055555555550000000000000000000000000000000000000000000000000000000000
000000000000000000000006dd000000000000000000055555555500000005555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000000dd6000000000000000000055555555d00000005555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000006dd000000000000000000005555555550000000d555555550000000000000000000000000000000000000000000000000000000000
0000000000000000000000ddd0000000000000000000d5555555550000000d555555550000000000000000000000000000000000000000000000000000000000
00000000000000000000006d00000000000000000000dd555555550000000d555555550000000000000000000000000000000000000000000000000000000000
0000000000000000000000d600000000000000000000ddd55555550000000d555555556000000000000000000000000000000000000000000000000000000000
0000000000000000000000d000000000000000000000dd555555550000000d555555556000000000000000000000000000000000000000000000000000000000
0000000000000000000006d0000000000000000000000dd555555560000000555555555550000000000000000000000000000000000000000000000000000000
000000000000000000000d60000000000000000000000d55555555d0000000555555555550000000000000000000000000000000000000000000000000000000
000000000000000000006d000000000000000000000005555555556000000055555555ddd0000000000000000000000000000000000000000000000000000000
000000000000000000006d0000000000000000000000055555555500000000d555555dddd0000000000000000000000000000000000000000000000000000000
00000000000000000000600000000000000000000000655555555500000000d555dddd5dd0000000000000000000000000000000000000000000000000000000
00000000000000000006d00000000000000000000000d55555555500000000d55555555560000000000000000000000000000000000000000000000000000000
00000000000000000006d00000000000000000000000d555555555000000000555555555d0000000000000000000000000000000000000000000000000000000
0000000000000000000d600000000000000000000000d55d5d5555000000000555555555d0000000000000000000000000000000000000000000000000000000
0000000000000000000d000000000000000000000000d555555555000000000555d55555d0000000000000000000000000000000000000000000000000000000
0000000000000000006d000000000000000000000000d55555d555000000000555d55555d0000000000000000000000000000000000000000000000000000000
000000000000000000660000000000000000000000005555555555d0000000055555555560000000000000000000000000000000000000000000000000000000
000000000000000000d00000000000000000000000005555555555d00000000d5555555000000000000000000000000000000000000000000000000000000000
000000000000000006d0000000000000000000000000d555555555d00000000055555d0000000000000000000000000000000000000000000000000000000000
00000000000000000dd0000000000000000000000000000555555550000000005555550000000000000000000000000000000000000000000000000000000000
00000000000000006d600000000000000000000000000000555555d00000000055555d0000000000000000000000000000000000000000000000000000000000
00000000000000006d000000000000000000000000000000555555d00000000055555d6000000000000000000000000000000000000000000000000000000000
0000000000000000dd0000000000000000000000000000005d55550000000000555d5dd000000000000000000000000000000000000000000000000000000000
0000000000000006dd00000000000000000000000000000dd555550000000000d5dd5ddd00000000000000000000000000000000000000000000000000000000
0000000000000006d000000000000000000000000000000d5d55550000000000055dddd660000000000000000000000000000000000000000000000000000000
000000000000000dd00000000000000000000000000000dddd55550000000000055dd5ddd0000000000000000000000000000000000000000000000000000000
000000000000006d600000000000000000000000000005ddd55550000000000005555555d0000000000000000000000000000000000000000000000000000000
000000000000006d00000000000000000000000000005555555550000000000000ddddddd0000000000000000000000000000000000000000000000000000000
00000000000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000d6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000006d6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006ddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000666666dd555dd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000666d5dddd555ddd66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd66ddd6dddddd5dd660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5ddddd6dddddddd66d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000d555d5d5dddddd55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000dd5555d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
