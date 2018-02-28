{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Binance.Types where

import           Types               (Balance (..), Currency (..), Error (..),
                                      MarketName (..), OrderId (..),
                                      Ticker (..))
import qualified Types               as T

import           Control.Applicative
import           Data.Aeson
import           Data.Aeson.Types    (Parser)
import           Data.Text           (Text)
import qualified Data.Text           as Text
import qualified Data.Vector         as V
import           GHC.Generics
import           Prelude             as P

import           Debug.Trace

class Binance a where
        toText :: a -> Text

instance Binance MarketName where
        toText = T.toText

instance Binance Currency where
        toText = T.toText

instance FromJSON Ticker where
        parseJSON = withObject "Ticker" $ \ o -> do
                bid    <- o .: "bidPrice"
                ask    <- o .: "askPrice"
                askVolume <- o .: "askQty"
                bidVolume <- o .: "bidQty"
                pure $ Ticker (read bid) (read ask) (read askVolume) (read bidVolume)

instance FromJSON Balance where
        parseJSON = withObject "Account" $ \ o -> do
                bal <- o .: "balances"
                Balance . filter (\(_,y) -> y /= 0) <$> mapM toBal (V.toList bal)
                        where
                                toBal :: Value -> Parser (Currency,Float)
                                toBal = withObject "Balances" $ \ o -> do
                                        cur <- o .: "asset"
                                        amount <- o .: "free"
                                        pure (T.fromText cur,read amount)


instance FromJSON Currency

newtype ServerTime = ServerTime Float
        deriving (Show,Generic)
instance FromJSON ServerTime where
        parseJSON = withObject "ServerTime" $ \o -> do
                time <- o .: "serverTime"
                pure $ ServerTime time

instance FromJSON OrderId where
        parseJSON = withObject "OrderId" $ \ o ->do
                oId <- o .: "orderId" <|> return "TEST"
                pure $ OrderId oId

instance FromJSON Error where
        parseJSON = withObject "Error" $ \ o -> do
                msg <- o .: "msg"
                pure $ parseError msg

--parseError :: Text -> Error
parseError t                 = traceShow t $ UnknownError t
