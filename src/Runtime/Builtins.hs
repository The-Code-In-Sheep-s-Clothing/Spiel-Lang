-- | Language builtins/Prelude

module Runtime.Builtins where

import Language.Syntax
import Language.Types

import Runtime.Monad
import Runtime.Values

import qualified Data.Set as S
import Data.Array


single x = Tup [x]
builtinT :: Xtype -> [(String, Type)]
builtinT = \i -> [
  ("input", Function (Ft (single (X Board S.empty)) i)),
  ("positions", Plain (X Positions S.empty)),
  ("place", Function (Ft (Tup [(X AnySymbol S.empty), (X Board S.empty), (X Position S.empty)]) (X Board S.empty))),
  ("remove", Function (Ft (Tup [(X Board S.empty), (X Position S.empty)]) (X Board S.empty))),
  ("inARow", Function (Ft (Tup [X Itype S.empty, X AnySymbol S.empty, X Board S.empty]) (X Booltype S.empty))),
  ("isFull", Function (Ft (single (X Board S.empty)) (X Booltype S.empty))),
  ("next", Function (Ft (single (X Top (S.fromList ["X", "O"]))) (X Top (S.fromList ["X", "O"])))),
  ("not", Function (Ft (single (X Booltype S.empty)) (X Booltype S.empty))), 
  ("or", Function (Ft (Tup [X Booltype S.empty, X Booltype S.empty]) (X Booltype S.empty)))
  -- This should be polymorphic over all types instead of over all symbols.
           ]

builtins :: [(Name, [Val] -> Eval Val)]
builtins = [
  ("input", \[v] -> readTape v),
  ("place", \[v, Vboard arr, Vpos (x,y)] -> return $ Vboard $ arr // [((x,y), v)]),
  ("remove", \[Vboard arr, Vpos (x,y)] -> return $ Vboard $ arr // pure ((x,y), Vs "Empty")),
  ("isFull", \[Vboard arr] -> return $ Vb $ all (/= Vs "Empty") $ elems arr),
  ("inARow", \[Vi i, v, Vboard arr] -> return $ Vb $ line v (assocs arr) (i)),
  ("next", \[Vs s] -> return $ if s == "X" then Vs "O" else Vs "X"),
  ("not", \[Vb b] -> return $ Vb (not b)),
  ("or", \[Vb a, Vb b] -> return $ Vb (a || b))
  ]

builtinRefs :: [(Name, Eval Val)]
builtinRefs = [("positions", (getBounds) >>= \(szx, szy) -> return $ Vt [Vpos (x,y) | x <- [1..szx], y <- [1..szy]])]

inARow :: Val -> [((Int, Int), Val)] -> [((Int, Int), Val)] -> (Int, Int) -> Int -> Bool
inARow v state (s:st) d n = (inARow' state s d n) || inARow v state st d n
  where
    inARow' :: [((Int, Int), Val)] -> ((Int, Int), Val) -> (Int, Int) -> Int -> Bool
    inARow' _ _ _ 1 = True
    inARow' st ((x, y), c) (dx, dy) n = if v /= c then False else case lookup (x+dx, y+dy) st of
      Nothing -> False
      Just c' -> if v == c' then inARow' state ((x+dx, y+dy), c) (dx, dy) (n-1) else False
inARow _ _ _ _ _ = False

line :: Val -> [((Int, Int), Val)] -> Int -> Bool
line v acc n = (inARow v acc acc (1,1) n) ||  (inARow v acc acc (0,1) n) ||  (inARow v acc acc (1,0) n)
