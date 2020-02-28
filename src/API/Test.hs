--
-- Test.hs
--
-- Endpoint for testing that the server is running
--

module API.Test (handleTest) where

import API.JSONData
import Servant

-- returns a test reponse to the GET test endpoint, to ensure this is running
handleTest :: Handler SpielResponses
handleTest = return (SpielResponses [(SpielOK "Spiel is Running!")])
