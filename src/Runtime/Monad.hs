-- | Evaluation Monad

module Runtime.Monad where

import Runtime.Values
import Language.Syntax
import Error.RuntimeError

import Control.Monad.Reader
import Control.Monad.Except
import Control.Monad.State
import Control.Monad.Identity


-- | Eval Monad transformer
type Eval a = StateT Buffer (ExceptT Exception (ReaderT Env (Identity))) a

-- | Call-by-value semantics
data Env = Env {
  evalEnv :: MapEvalEnv,
  boardSize :: (Int, Int)
               }
  deriving Show

-- | Uses the StateT monad to request the typed board dimensions in the runtime environment
getBounds :: Eval (Int, Int)
getBounds = boardSize <$> ask

-- | Uses the StateT monad to get the evaluation environment in the runtime environment
getEnv :: Eval (MapEvalEnv)
getEnv = evalEnv <$> ask

-- | Produces an empty environment for testing, and for starting evaluations
emptyEnv :: (Int,Int) -> Env
emptyEnv x = Env emptyEvalEnv x

-- | Modifies the evaluation environment, producing a new environment
modifyEval :: (MapEvalEnv -> MapEvalEnv) -> Env -> Env
modifyEval f (Env e b) = Env (f e) b

-- | Input buffer and display buffer.
--   The display buffer stores all boards which are to be printed on the front end after
--   a board is updated
--   Additionally counts the number of evaluation iterations,
--   stopping after a fixed amount with a 'Error $ "Stack Overflow!"'
type Buffer = ([Val], [Val], Int)

-- | Exceptions
data Exception =
  NeedInput [Val] | -- ^ Ran out of input and here's the buffered display boards
  Error String -- ^ Encountered a runtime error
  deriving (Eq, Show)


-- | Take an expressions, and before evaluating it checks & updates evaluation iterations
-- If the count is less than the limit, continue evaluating,
-- otherwise return an error instead of evaluating further.
-- Prevents infinite loops via recursion, while, or
-- self referencing value equations, among other things
evalWithLimit :: Eval Val -> Eval Val
evalWithLimit e = do
  (tape,bord,iters) <- get
  put (tape,bord,iters+1)
  case iters < 5000 of -- hard limit of 5k iterations before stopping
    True  -> e
    False -> throwRuntimeError StackOverflow

-- | Evaluation occurs in the Identity monad with these side effects:
-- ReaderT: Evaluation enviroment, board size and content type, and input type
-- StateT: Input buffer, used for reading input

-- | Evaluate in the environment given, with a buffer.
runEval :: Env -> Buffer -> Eval a -> Either Exception a
runEval env buf x = runIdentity (runReaderT (runExceptT (evalStateT x buf)) env)

-- | Evaluate with an extended scope
extScope :: MapEvalEnv -> Eval a -> Eval a
extScope env = local $ modifyEval $ unionEvalEnv env

-- | Lookup a name in the environment FIXME
lookupName :: Name -> Eval (Maybe Val)
lookupName n = do
  env <- getEnv
  case lookupEvalEnv n env of
    Just v -> (return . Just) v
    Nothing -> return Nothing

-- | Ask for input, displaying a value to the user
waitForInput :: [Val] -> Eval a
waitForInput vs = throwError (NeedInput vs)

-- | Converts a runtime error into an evaluation error
throwRuntimeError :: RuntimeError -> Eval a
throwRuntimeError re = throwError (Error $ show re)

-- | Read input
readTape :: Eval Val
readTape = do
  (tape, boards, iters) <- get
  case tape of
    (x:xs) -> (put (xs, boards, iters)) >> return x
    [] -> waitForInput boards
