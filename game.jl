using GameZero
using Colors
using Random
using FixedPointNumbers

WIDTH = 640
HEIGHT = 754
BACKGROUND = colorant"#F5624D"

# Struct to store the parameters for a snowflake
mutable struct Snowflake
    x ; y ; vy ;  vx ; r ; o ; 
end

# Construct a snowflake 
function Snowflake()
    s = Snowflake(0,0,0,0,0,0)
    reset(s)
end

# Initialize a single snowflake
function reset(s::Snowflake)
    s.x = rand() * WIDTH
    s.y = -1*rand() * HEIGHT
    s.vy = 1+rand() * 3     # Velocity in y direction
    s.vx = 0.5-rand()       # Velocity in x direction
    s.r = 1+rand() * 2      # Radius of the snowflake
    s.o = 0.5 +rand() * 0.5 # Alpha channel
    return s
end

snowflakes = [Snowflake() for i in 1:100] # Create a hundred snowflakes

@enum GameState alldown oneup twoup lost won # all states of the game 


# Load the cover image
cover = Actor("cover")
cover.scale = [1/4, 1/4]
cards = repeat([cover], 8)

# Load all the card images
images = Actor[]
for i in 1:16
    img = Actor("c$i")
    img.scale = [1/4, 1/4]
    push!(images, img)
end

playAgainTxt = TextActor("Click to Play Again!", "blomberg"; font_size=36)
playAgainTxt.pos = 150, 250

# Initialize the game state
function resetBoard()
    
    # select 8 cards to play with 
    global imgSelect = shuffle(images)[1:8]
    
    # position 8 cards over 16 places
    global board = reshape(shuffle(repeat(collect(1:8),2)), (4,4))
    
    # 0->face down; 1->face up on selection; 2->face up when found;
    global boardState = reshape(repeat([0], 16), (4,4))
    
    # total number of chances allowed
    global chances = 15
    global chancesTxt = TextActor(string(chances), "blomberg"; font_size=64)
    chancesTxt.pos = (575, 650)

    # Game starts will all cards face down
    global state = alldown

end


# The main update loop for the Game
# This function is called once each frame by the framework
function update(g::Game)
    global state
    if state == lost || state == won
        updateSnowflakes()
    end 
end

# The main draw loop for the Game
# This function is called once each frame by the framework
function draw(g::Game)
    drawboard()
    draw(chancesTxt)
    if state == won 
        drawWon()
        draw(playAgainTxt)
    elseif state == lost 
        drawLost()
        draw(playAgainTxt)
    end
    if state == lost || state == won
        drawSnowflakes()
    end
end

# Animate the snowflakes
function updateSnowflakes()
    for s in snowflakes
        s.y += s.vy
        s.x += s.vx
        if s.y > HEIGHT
            reset(s)
        end
    end

end

# Draw the cards
# Decide if its face up or down based on board state
function drawboard()
    for r in 1:4
        for c in 1:4
            px = 10*c + (c-1)*128
            py = 10*r + (r-1)*176
            if boardState[r, c] == 0
                img = cover
            else 
                img = imgSelect[board[r,c]]
            end
            img.pos = (px, py)
            draw(img)
        end
    end
end

function drawSnowflakes()
    for s in snowflakes
        draw(Circle(round(s.x), round(s.y), round(s.r)), parse(RGBA{N0f8}, "rgba(255,255, 255, $(s.o))"), fill=true )
    end
end

loseTxt=Actor[]
for (i,x) in enumerate("You Lose!")
    t=TextActor(string(x), "blomberg", font_size=32)
    t.x = 585
    t.y = 10*i+(i-1)*32
    push!(loseTxt, t)
end
winTxt=Actor[]
for (i,x) in enumerate("You Win!")
    t=TextActor(string(x), "blomberg", font_size=32)
    t.x = 585
    t.y = 10*i+(i-1)*32
    push!(winTxt, t)
end

function drawWon()
    for t in winTxt
        draw(t)
    end
end

function drawLost()
    for t in loseTxt
        draw(t)
    end
end

# Most of the game logic runs when the user clicks the mouse
function on_mouse_down(g::Game, pos, button) 
    global state
    if state == won || state == lost
        resetBoard()
        state = alldown
        return
    end
    x = pos[1]
    y = pos[2]
    # Calculate the card selected based on the click position
    c = div(x, 138) + 1
    if rem(x, 138) < 10 || c > 4
        return
    end
    r = div(y, 186) + 1 
    if rem(y, 186) < 10 || r > 4
        return
    end
    if state == twoup
        return
    end
    boardState[r, c] = 1

    if state == alldown
        state = oneup
    elseif state == oneup
        state = twoup
        f = findfirst(x->x==1, boardState)
        l = findlast(x->x==1, boardState) 
        if board[f] == board[l]
            boardState[f] = 2
            boardState[l] = 2
            state = alldown
        else 
            schedule_once(hideup, 1)
            global chances = chances - 1 
            global chancesTxt = TextActor(string(chances), "blomberg"; font_size=64)
            chancesTxt.pos = (575, 650)
        end
    end
    if chances < 1
        state = lost
    end
    if all(x->x==2, boardState)
        state = won
        play_sound("win")
    end
end

function hideup()
    f = findfirst(x->x==1, boardState)
    l = findlast(x->x==1, boardState) 
    boardState[f] = 0
    boardState[l] = 0
    global state = alldown
end

play_music("iv-vi-vi7-bvii7")
resetBoard()
# @show board