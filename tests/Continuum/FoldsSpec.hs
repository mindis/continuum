{-# LANGUAGE OverloadedStrings #-}

module Continuum.FoldsSpec where

import Continuum.Folds

import Test.Hspec
import Test.QuickCheck
import Data.List (nubBy, groupBy)

import Debug.Trace

import qualified Data.Map as Map

-- prop_MinFold :: (Ord a, Show a) => [a] -> Bool
prop_MinFold :: [Integer] -> Bool
prop_MinFold a@[] = MinNone == runFold op_min a
prop_MinFold a = (Min $ minimum a) == runFold op_min a

prop_CountFold :: [Integer] -> Bool
prop_CountFold a = (Count $ length a ) == runFold op_count a

prop_CollectFold :: [Integer] -> Bool
prop_CollectFold a = reverse a == runFold op_collect a

prop_GroupByFold :: [(Integer, [Integer])] -> Bool
prop_GroupByFold a =
  let -- List has to be a non-empty list with unique "key" elements
      a'        = nubBy (\a b -> fst a == fst b) $ filter null a
      expected  = Map.fromList $ fmap (\(k,v) -> (k, runFold op_count v)) a'
      plainList = concat $ fmap (\(k,v) -> fmap ((,) k) v) a'
      result    = runFold (op_groupBy (\i -> Just $ fst i) op_count) plainList
  in expected == result

spec :: Spec
spec = do

  describe "Property Test" $ do
    it "passes Min Fold test" $ do
      property $ prop_MinFold

    it "passes Count Fold test" $ do
      property $ prop_CountFold

    it "passes Collect Fold test" $ do
      property $ prop_CollectFold

    it "passes Group Fold test" $ do
      property $ prop_GroupByFold
