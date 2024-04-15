pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
  state = 0
  shake = 0
  shakex = 0
  shakey = 0
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
        spr(1, i*8+ho, j*8+vo)
      elseif tile.flag == 1 do
        print(board.f[i+1][j+1].v, i*8+2+ho,j*8+2+vo, get_color(board.f[i+1][j+1].v))
      elseif tile.flag == 2 do
        spr(3, i*8+ho, j*8+vo)
      elseif tile.flag == 3 do
        spr(4, i*8+ho, j*8+vo)
      end
    end
  end
  spr(2, (selection.x-1)*8+ho, (selection.y-1)*8+vo)
  if winner do
    print("congratulations!",0,0,7)
  elseif playing == false do
    print("your head asplode!", 0, 0, 8)
  else
    print("number of mines: "..(num_mines-flags),0,0,7)
  end
  
  vo -= shakey
  ho -= shakex
end
-->8
function init_game(mines, width, height)
  num_mines = mines
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

function add_mines(board, mines)
  if mines > ((board.width*board.height)-1) do
    return
  end
  while mines > 0 do
    local added = add_mine(board)
    if added do
      mines-=1
    end
  end
end

function add_mine(board)
 x = flr(rnd(board.width))+1
 y = flr(rnd(board.height))+1
 if x == 1 or x == board.width do
   if y == 1 or y == board.height do
     return false
   end
 end
 if board.f[x][y].v != "x" do
    board.f[x][y].v = "x"
    return true
  else
    return false
  end
end

function set_numbers(board)
  for i=1, board.width do
    for j=1, board.height do
      if board.f[i][j].v != "x" do
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
  if btnp(❎) do
    local tile = board.f[selection.x][selection.y]
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
      init_game(12,8,8)
    elseif mstate.selection == 1 do
      init_game(30, 10, 10)
    elseif mstate.selection == 2 do
      init_game(60, 13, 13)
    elseif mstate.selection == 3 do
      customize()
    end
  end     
end

function customize()

end
function draw_menu(mstate)
  print("m i n e s w e e p e r", 12, 12, 7)
  
  print("easy", 8, 8*4, 7)
  print("medium", 8, 8*5, 7)
  print("hard", 8, 8*6, 7)
  print("custom", 8, 8*7, 7)
  print(">", 4, (8*4)+(mstate.selection*8), 6)
end
__gfx__
00000000000000000666666000000000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111006000000600588000050005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700010000106000000600588800050005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000010000106000000600588000000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000010000106000000600500000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700010000106000000600500000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111006000000600500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666000500000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
