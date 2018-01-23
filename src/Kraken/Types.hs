{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module Kraken.Types where

import Types

import Data.Map
import Data.Maybe
import Data.Text hiding (read,head,init)
import Data.Time
import Data.Time.ISO8601
import Data.Aeson
import Data.List (init)
import Data.HashMap.Lazy as HM
import Text.Read
import Network.Wreq (FormParam)


type Price = String
type Volume = String
type Order = String

type Params = [(Text,Text)]

data Opts = Opts {
                   optPath       :: String
                 , optParams     :: Params 
                 , optApiType    :: String
                 , optApiPubKey  :: String
                 , optApiPrivKey :: String
                 , optPost       :: [(String,String)]
                 }


instance FromJSON Ticker where
        parseJSON = withObject "Ticker" $ \o -> do
                bid <- o .: "b"
                ask <- o .: "a"
                last <- o .: "c"
                pure $ Ticker (t bid) (t ask) (t last) 
                        where t = read . head

instance FromJSON Balance where
        parseJSON = withObject "Balance" $ \o -> pure $ Balance $ toBal <$> HM.toList o
                
toBal :: (Text,Value) -> (Currency,Float)
toBal (cur,val) = (cur',val')
        where cur' = read $ Prelude.tail $ unpack cur
              val' = fromResult $ fromJSON val 
              fromResult r = case r of
                               Error _ -> 0.00
                               Success v -> read v
