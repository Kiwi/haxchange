{-# LANGUAGE InstanceSigs        #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Binance.Types where

import           Types                (Balance (..), Currency (..), Error (..),
                                       Market (..), Markets (..), OrderId (..),
                                       ServerTime (..), Ticker (..),
                                       Tickers (..))
import qualified Types                as T

import           Control.Applicative
import           Data.Aeson
import           Data.Aeson.Types     (Parser)
import qualified Data.Attoparsec.Text as Atto
import           Data.List            (intersperse)
import qualified Data.Map             as Map
import           Data.Text            (Text)
import qualified Data.Vector          as V
import           Prelude              as P

import           Debug.Trace

class BinanceText a where
        toText :: a -> Text

instance BinanceText Markets where
        toText m = mconcat $ intersperse "," $ toText <$> unMarkets m

parseMarket :: Atto.Parser Market
parseMarket = Market <$> ((T.fromText <$> Atto.take 3) <|> (T.fromText <$> Atto.take 4))
                     <*> (T.fromText <$> ("BTC" <|> "ETH" <|> "BNB" <|> "USDT"))

instance BinanceText Market where
        toText = T.toText

instance BinanceText Currency where
        toText = T.toText

instance FromJSON Tickers where
        parseJSON (Array a) = Tickers <$> mapM parseJSON (V.toList a)
        parseJSON o         = Tickers . pure <$> parseJSON o

instance FromJSON Ticker where
        parseJSON = withObject "Ticker" $ \ o -> do
                mrkt <- o .: "symbol"
                bid    <- o .: "bidPrice"
                ask    <- o .: "askPrice"
                askVolume <- o .: "askQty"
                bidVolume <- o .: "bidQty"
                case Atto.parseOnly parseMarket mrkt of
                  Left _ -> fail "Failed parsing Market"
                  Right s -> pure $ Ticker s (read bid) (read ask) (read askVolume) (read bidVolume)

instance FromJSON Market where
        parseJSON = withObject "Market" $ \o -> do
                mrkt <- o .: "symbol"
                case Atto.parseOnly parseMarket mrkt of
                  Left _  -> pure $ Market (T.fromText "Failed Parse") (T.fromText "Failed Parse")
                  Right s -> pure s

unParsedMarket :: Market
unParsedMarket = Market (NA "Failed Parse") (NA "Failed Parse")

instance FromJSON Markets where
        parseJSON = withArray "Markets" $ \a -> Markets . P.filter ((/=) unParsedMarket) <$> mapM parseJSON (V.toList a)

instance FromJSON Balance where
        parseJSON = withObject "Account" $ \ o -> do
                bal <- o .: "balances"
                Balance . Map.fromList . filter ((/=) 0 . snd) <$> mapM toBal (V.toList bal)
                        where
                                toBal :: Value -> Parser (Currency,Float)
                                toBal = withObject "Balances" $ \ o -> do
                                        cur <- o .: "asset"
                                        amount <- o .: "free"
                                        pure (T.fromText cur,read amount)


instance FromJSON Currency

instance FromJSON ServerTime where
        parseJSON = withObject "ServerTime" $ \o ->
                ServerTime <$> o .: "serverTime"

instance FromJSON OrderId where
        parseJSON = withObject "OrderId" $ \ o ->do
                oId <- o .: "orderId" <|> pure "TEST"
                pure $ OrderId oId

instance FromJSON Error where
        parseJSON = withObject "Error" $ \ o -> do
                msg <- o .: "msg"
                pure $ parseError msg

parseError :: String -> Error
parseError t = traceShow t $ UnknownError t
