{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Continuum.Serialization where

-- import           Control.Monad (liftM)
import qualified Data.Map as Map
-- import           Data.Serialize (Serialize, encode, decode)
import           Data.Serialize as S
import           GHC.Generics
import qualified Data.ByteString as B

data Success = Success

data DbType = DbtInt | DbtString

-- data DbTimestamp = Integer
--                  deriving (Show, Eq, Ord, Generic)

-- type DbTimestamp = Integer
-- type DbSequenceId = Maybe Integer
-- newtype DbSequenceId = DbSequenceId (Maybe Integer)
--                      deriving (Show, Eq, Ord, Generic)

-- data DbSequenceId = DbSequenceId (Maybe Integer)
--                   deriving (Show, Eq, Ord, Generic)

data DbValue = DbInt Int
             | DbString String
             | DbTimestamp Integer
             | DbSequenceId Integer
             | DbList [DbValue]
             | DbMap [(DbValue, DbValue)]
             deriving (Show, Eq, Ord, Generic)

-- instance Serialize DbTimestamp
-- instance Serialize DbSequenceId
instance Serialize DbValue

data DbRecord = DbRecord Integer (Map.Map String DbValue) |
                DbPlaceholder Integer
                deriving(Show)

data DbSchema = DbSchema { fieldMappings :: (Map.Map String Int)
                           , fields :: [String]
                           , indexMappings :: (Map.Map Int String)
                           , schemaMappings :: (Map.Map String DbType) }

makeSchema :: [(String, DbType)] -> DbSchema

makeSchema stringTypeList = DbSchema { fieldMappings = fMappings
                                     , fields = fields'
                                     , schemaMappings = Map.fromList stringTypeList
                                     , indexMappings = iMappings }
  where fields' = fmap fst stringTypeList
        fMappings = Map.fromList $ zip fields' iterateFrom0
        iMappings = Map.fromList $ zip iterateFrom0 fields'
        iterateFrom0 = (iterate (1+) 0)



validate :: DbSchema -> DbRecord -> Either String Success
validate = error "Not Implemented"

removePlaceholder :: DbRecord -> Bool
removePlaceholder (DbRecord _ _) = True
removePlaceholder (DbPlaceholder _) = False

makeDbRecord' :: DbSchema -> (Integer, Integer) -> B.ByteString -> DbRecord
makeDbRecord' schema (timestamp, 0) _ =
  DbPlaceholder timestamp

makeDbRecord' schema (timestamp, _) v =
  DbRecord timestamp (Map.fromList $ zip (fields schema) values) -- values
  where values = decodeValue v

makeDbRecord :: DbSchema ->  (B.ByteString, B.ByteString) -> DbRecord
makeDbRecord schema (k, v) =
  makeDbRecord' schema (decodeKey k) v
  -- where (timestamp, _) =
  -- DbRecord timestamp (Map.fromList $ zip (fields schema) values) -- values
  -- where (timestamp, _) = decodeKey k
  --       values = decodeValue v

makeDbRecords :: DbSchema -> [(B.ByteString, B.ByteString)] -> [DbRecord]
makeDbRecords schema items = filter removePlaceholder (fmap (makeDbRecord schema) items)
-- makeDbRecords = error "asd"

decodeKey :: B.ByteString -> (Integer, Integer)
decodeKey k = case (decode k) of
              (Left a)  -> error a
              (Right x) -> x

decodeValue :: B.ByteString -> [DbValue]
decodeValue k = case (decode k) of
              (Left a)  -> error a
              (Right x) -> x

-- makeDbRecord schema k v = DbRecord timestamp sequenceId [] -- values
--                           where (timestamp, sequenceId) = decode k :: Either String DbValue
--                                 values = decode v :: Either String DbValue
-- decode (encode $ DbString "asdasdasdasdasdasdasdasdasdasdasdasd") :: Either String DbValue


-- decode (encode $ [DbString "abc", DbString "cde", DbInt 1]) :: Either String DbValue

-- serializeDbRecord :: Schema




-- instance Serialize [(String, DbValue)] where
--   encode [] = B.empty
--   encode [(_, v):xs] = (encode v) ++ (encode xs)

-- instance Serialize DbValue where
--   put (DbString s) = put ((B.length bs), bs)
--     where bs = (encode s)



--- We have a map, but problem with maps is random key order
--- how do we fix that?
--- We need to take a hashmap and record order?
--- Basically, everything should be done through the lists??
--- decode (encode $ [(DbString "asd"), (DbInt 1)]) :: Either String [DbValue]
--- How to construct these lists though? We take schema, schema has index mappings


-- instance Serialize [(String, DbValue)] where
--   encode [] = B.empty
--   encode [(_, v):xs] = (encode v) ++ (encode xs)

-- encodeValues :: DbRecord -> ByteString
-- encodeValues record = foldl serializeOne B.empty

-- encoding values takes schema and returns a serialized value


-- Map.fromList [("key1", (DbInt 1)), ("key2", (DbString "asd"))]
