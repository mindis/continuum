{-# LANGUAGE DeriveGeneric #-}

module Continuum.Common.Types where

import           Data.ByteString                ( ByteString )
import           GHC.Generics                   ( Generic )
import           Data.Maybe                     ( fromMaybe )

import qualified Data.Serialize                 as S
import qualified Data.Map                       as Map

-- |
-- | ALIASES
-- |

type DbName        = ByteString
type FieldName     = ByteString

type Decoder       = (ByteString, ByteString) -> DbErrorMonad DbResult

-- |
-- | INTERNAL DB TYPES
-- |

data DbType =
  DbtInt
  | DbtDouble
  | DbtString
  deriving(Show, Generic, Eq)

instance S.Serialize DbType

-- |
-- | DB Error
-- |

data DbError =
  IndexesDecodeError        String
  | FieldDecodeError        String ByteString
  | ValuesDecodeError       String
  | ValueDecodeError        String
  | KeyDecodeError          String
  | DecodeFieldByIndexError String [Int]
  | FieldNotFoundError
  | NoSuchDatabaseError
  | NoAggregatorAvailable
  | SchemaDecodingError     String
  | OtherError

  | NotEnoughInput
  deriving (Show, Eq, Ord, Generic)

instance S.Serialize DbError

type DbErrorMonad  = Either  DbError


-- |
-- | DB VALUE
-- |

data DbValue =
  EmptyValue
  | DbInt                   Integer
  | DbString                ByteString
  | DbFloat                 Float
  | DbDouble                Double
  -- DbList [DbValue]
  -- DbMap [Map.Map DbValue DbValue]
  deriving (Eq, Ord, Generic)

instance Show DbValue where
  show EmptyValue   = ""
  show (DbInt v)    = show v
  show (DbString v) = sq $ show v
  show (DbFloat v)  = show v
  show (DbDouble v) = show v

instance S.Serialize DbValue

data DbRecord =
  DbRecord Integer (Map.Map ByteString DbValue)
  deriving(Generic, Show, Eq)

instance S.Serialize DbRecord

getValue :: FieldName -> DbRecord -> DbValue
getValue fieldName (DbRecord _ fields) =
  fromMaybe EmptyValue (Map.lookup fieldName fields)


-- | Creates a DbRecord from Timestamp and Key/Value pairs
--
makeRecord :: Integer -> [(ByteString, DbValue)] -> DbRecord
makeRecord timestamp vals = DbRecord timestamp (Map.fromList vals)

-- |
-- | DB RESULT
-- |

data DbResult =
  EmptyRes
  | ErrorRes               DbError
  | KeyRes                 Integer
  | ValueRes               DbValue
  | RecordRes              DbRecord
  -- TODO: Ok, these two make no sense
  -- | FieldRes               (Integer, DbValue)
  -- | FieldsRes              (Integer, [DbValue])
  -- It looks like in the end, we can only get an empty result, error result,
  -- "raw" result (that covers things like key res and all other special cases),
  -- and record result (which overs both single and multi-field scenarios).

  -- TODO: Split Step and Res ??
  | CountStep              Integer
  | GroupRes               (Map.Map DbValue DbResult)

  | DbResults              [DbResult]
  | DbSchemaResult         (DbName, DbSchema)
  deriving(Generic, Show, Eq)

-- data StepResult =
--   CountStep                Integer
--   | GroupRes               (Map.Map DbValue DbResult)
--   deriving(Generic, Show, Eq)

-- toDbResult :: StepResult -> DbResult
-- toDbResult (CountStep i) = CountRes i
-- toDbResult _ = ErrorRes $ OtherError

instance S.Serialize DbResult

-- |
-- | RANGE
-- |

-- Maybe someday we'll need a ByteBuffer scan ranges. For now all keys are always
-- integers. Maybe iterators for something like indexes should be done somehow
-- differently not to make that stuff even more complex.
data ScanRange =
  OpenEnd                  Integer
  | SingleKey              Integer
  | KeyRange               Integer Integer
  | EntireKeyspace
  deriving(Show, Generic)

instance S.Serialize ScanRange

-- |
-- | AGGREGATES
-- |

data Decoding =
  Field                    ByteString
  | Fields                 [ByteString]
  | Key
  | Record
  deriving(Generic, Show)

instance S.Serialize Decoding

-- |
-- | DB SCHEMA
-- |

data DbSchema = DbSchema
    { fieldMappings  :: Map.Map ByteString Int
    , fields         :: [ByteString]
    , indexMappings  :: Map.Map Int ByteString
    , schemaMappings :: Map.Map ByteString DbType
    , schemaTypes    :: [DbType]
    } deriving (Generic, Show, Eq)

instance S.Serialize DbSchema

-- | Creates a DbSchema out of Schema Definition (name/type pairs)
--
makeSchema :: [(ByteString, DbType)] -> DbSchema
makeSchema stringTypeList =
  DbSchema { fieldMappings  = fMappings
           , fields         = fields'
           , schemaMappings = Map.fromList stringTypeList
           , indexMappings  = iMappings
           , schemaTypes    = schemaTypes'}
  where fields'      = fmap fst stringTypeList
        schemaTypes' = fmap snd stringTypeList
        fMappings    = Map.fromList $ zip fields' iterateFrom0
        iMappings    = Map.fromList $ zip iterateFrom0 fields'
        iterateFrom0 = (iterate (1+) 0)

-- |
-- | QUERIES
-- |

data SelectQuery =
  Count
  -- | Distinct
  -- | Min
  -- | Max
  | Group                  FieldName SelectQuery
  | FetchAll
  deriving (Generic, Show)

instance S.Serialize SelectQuery

-- |
-- | External Protocol Specification
-- |

-- TODO: Split client and server requests

data Node = Node String String
          deriving(Generic, Show, Eq, Ord)

instance S.Serialize Node

data Request =
  Shutdown
  | Insert                DbName DbRecord
  | CreateDb              DbName DbSchema
  -- TODO: Add ByteString here, never encode it inside of SelectQuery itself
  | Select                DbName SelectQuery
  deriving(Generic, Show)

instance S.Serialize Request

sq :: String -> String
sq s@[c]                     = s
sq ('"':s)  | last s == '"'  = init s
	    | otherwise	     = s
sq ('\'':s) | last s == '\'' = init s
	    | otherwise	     = s
sq s                         = s
