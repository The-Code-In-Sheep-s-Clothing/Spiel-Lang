game TicTacToe

type Player = {X, O}
type Position = (Int,Int) 

-- Board and input type definitions
--
type Board = Grid (3,3) of {X, O, Empty}
type Input = Position

-- Game setup
--
initialBoard : Board
initialBoard!(x,y) = Empty

goFirst : Player
goFirst = X

outcome : (Player, Board) -> Player & {Tie}
outcome(p, b) = if inARow(3,X,b) then X else
                if inARow(3,O,b) then O else Tie

threeInARow : Board -> Bool
threeInARow(b) = or(inARow(3,X,b), inARow(3,O,b))

gameOver : Board -> Bool
gameOver(b) = or(threeInARow(b), isFull(b))

-- Predefined operations
--
isValid : (Board,Position) -> Bool
isValid(b,p) = if b ! p == Empty then True else False

-- Game loop
--
tryMove : (Player,Board) -> (Player, Board)
tryMove(p,b) = let pos = input(b) in
                   if isValid(b,pos) then (next(p), place(p,b,pos))
                                     else (p, b)

loop : (Player,Board) -> (Player ,Board)
loop(p,b) = while not(gameOver(b)) do tryMove(p,b)

play : (Player,Board) -> Player & {Tie}
play(a,b) = outcome(loop(a,b))

result : Player & {Tie}
result = play(goFirst, initialBoard)

