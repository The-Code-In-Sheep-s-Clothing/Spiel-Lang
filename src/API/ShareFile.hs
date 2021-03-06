{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE TypeOperators   #-}

{-|
Module      : API.ShareFile
Description : Endpoint to handle saving of a file
Copyright   : (c)
License     : BSD-3
-}

module API.ShareFile (handleShareFile,genUniqueFilename) where

import API.JSONData
import Servant
import Control.Monad.IO.Class
import Control.Exception hiding (Handler)
import System.Directory
import Test.RandomStrings

-- | Generates a unique filename for the shared directory
genUniqueFilename :: IO String
genUniqueFilename = do
  _       <- createDirectoryIfMissing False "shared"
  word    <- randomWord randomASCII 30
  exists  <- doesFileExist ("shared/"++word ++ ".bglp")
  case exists of
    -- try again
    True  -> genUniqueFilename
    -- this is valid, return it
    False -> return (word)


-- | Handles sharing files to the server space
handleShareFile :: SpielShare -> Handler SpielResponses
handleShareFile (SpielShare prlude gamefile) = liftIO $ do
    -- generates a unique filename for both the prelude & gamefile
    fn <- genUniqueFilename
    -- verifies the files are able to be written to
    success1 <- try $ writeFile ("shared/"++ fn ++ ".bglp") prlude :: IO (Either IOException ())
    success2 <- try $ writeFile ("shared/"++ fn ++ ".bgl") gamefile :: IO (Either IOException ())
    case success1 of
      Right _ -> case success2 of
        -- both files saved successfully, return success
        Right _ -> return [(SpielSuccess fn)]
        Left e2  -> return [(Log ("Failed to share gamefile: " ++ displayException e2))]
      Left e1 -> return [(Log ("Failed to share prelude: " ++ displayException e1))]
