{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import           Data.ByteString.Char8 (pack)
import Data.Time.Clock.POSIX
import System.Process(system)
import           Data.List (elemIndex)
import Control.Applicative ((<$>), (<*>), empty)
import Data.Aeson
import Data.Maybe
import Control.Monad
import qualified Data.ByteString.Lazy.Char8 as BL
import Control.Monad.IO.Class

import Continuum.Storage
import Continuum.Serialization
import Continuum.Actions
import Continuum.Types
import Continuum.Aggregation


data Entry = Entry { request_ip :: String
                   , status :: String
                   , host :: String
                   , uri :: String
                   , date :: Integer }
             deriving (Show)

prodSchema = makeSchema [ ("request_ip", DbtString)
                        , ("host", DbtString)
                        , ("uri", DbtString)
                        , ("status", DbtString)]

instance FromJSON Entry where
    parseJSON (Object v) = Entry <$>
                             v .: "request-ip" <*>
                             v .: "status"     <*>
                             v .: "host"       <*>
                             v .: "uri"        <*>
                             v .: "date"
    parseJSON _          = empty

decodeStr :: String -> Entry
decodeStr = (fromJust . decode . BL.pack)

testDBPath :: String
testDBPath = "/tmp/production-data"


main2 :: IO ()
main2 = do

  liftIO $ cleanup

  content <- readFile "/Users/ifesdjeen/hackage/continuum/data.json"
  line <- return $ take 100000 $ lines content
  decoded <- return $ (map decodeStr line)

  -- putStrLn $ show decoded

  runApp testDBPath prodSchema $ do
    forM_ decoded $ \x ->

      putRecord (makeRecord (date x)
                 [("request_ip", DbString (pack (request_ip x))),
                  ("host",       DbString (pack (host x))),
                  ("uri",        DbString (pack (uri x))),
                  ("status",     DbString (pack (status x)))
                 ])

  return ()
  -- print decoded
  -- putStrLn $ show linesOfFile

    -- let req = decode "{\"x\":3.0,\"y\":-1.0}" :: Maybe Coord
    -- print req
    -- let reply = Coord 123.4 20
    -- BL.putStrLn (encode reply)

main = runApp testDBPath prodSchema $ do
  -- records <- scanAll id
  --              (:)
  --              []
               -- Set.empty

  -- liftIO $ putStrLn "===== ALL ===== "
  -- liftIO $ putStrLn (show $ take 5 records)

  -- let count _ acc = acc + 1
  --     a = foldGroup count 0 $ groupBy records (byFieldMaybe "status")
  -- liftIO $ putStrLn (show $ a)

  --a <- scanRaw Nothing (decodeFieldByName "status") alwaysTrue gradualGroupBy (Map.empty)
  --liftIO $ putStrLn (show $ a)

  -- before <- liftIO $ getPOSIXTime
  -- let a = map (\x -> S.encode "some string") [0..100000]
  -- after <- liftIO $ getPOSIXTime
  -- liftIO $ putStrLn $ show (after - before)

  -- a <- scanAll id (:) []
  -- liftIO $ putStrLn (show $ a >>= (\x -> return $ take 5 x))

  -- before <- liftIO $ getPOSIXTime
  -- a <- aggregateAllByField "status" snd gradualGroupBy (Map.empty)
  -- after <- liftIO $ getPOSIXTime

  -- liftIO $ putStrLn $ show a
  -- liftIO $ putStrLn $ show (after - before)

  -- before <- liftIO $ getPOSIXTime
  -- a <- aggregateAllByField "status" snd gradualGroupBy (Map.empty)
  -- after <- liftIO $ getPOSIXTime

  -- liftIO $ putStrLn $ show a
  -- liftIO $ putStrLn $ show (after - before)

  -- before <- liftIO $ getPOSIXTime
  -- a <- aggregateAllByField "status" snd gradualGroupBy (Map.empty)
  -- after <- liftIO $ getPOSIXTime

  -- liftIO $ putStrLn $ show a
  -- liftIO $ putStrLn $ show (after - before)


  -- before <- liftIO $ getPOSIXTime
  -- a <- aggregateAllByField "status" snd gradualGroupBy (Map.empty)
  -- after <- liftIO $ getPOSIXTime

  -- liftIO $ putStrLn $ show a
  -- liftIO $ putStrLn $ show (after - before)

  -- (0.89 secs, 1124496080 bytes)

  -- a <- aggregateAllByRecord (getFieldByName "status") gradualGroupBy (Map.empty)
  -- liftIO $ putStrLn $ show a
  -- (1.13 secs, 2398191368 bytes)
  return ()

  -- liftIO $ putStrLn (show $ foldl Set.insert Set.empty (extractField "status") <$> c)

cleanup :: IO ()
cleanup = system ("rm -fr " ++ testDBPath) >> return ()