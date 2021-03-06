{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE OverloadedStrings       #-}

module Gonimo.Server.Types where




import           Control.Error.Safe     (rightZ)
import           Data.Aeson.Types       (FromJSON (..), FromJSON, ToJSON (..), ToJSON (..), defaultOptions, genericToJSON, Value (String)) 

import           Data.Bifunctor
import           Data.ByteString        (ByteString)
import qualified Data.ByteString.Base64 as Base64
import           Data.Text              as T
import           Data.Text.Encoding     (decodeUtf8, encodeUtf8)
import           Database.Persist.TH

import           GHC.Generics           (Generic)
{-import           Servant.Common.Text (FromText (..), ToText (..))-}
import           Web.HttpApiData        (FromHttpApiData (..), parseUrlPieceWithPrefix)

type SenderName = Text


newtype Secret = Secret ByteString deriving (Generic, Show, Read)

instance FromJSON Secret where
  parseJSON (String t) = Secret <$> (rightZ . Base64.decode . encodeUtf8 $ t)
  parseJSON _ = fail "Expecting a string when parsing a secret."

instance ToJSON Secret where
  toJSON (Secret bs) = String . decodeUtf8 . Base64.encode $ bs

instance FromHttpApiData Secret where
    parseUrlPiece = bimap T.pack Secret . Base64.decode . encodeUtf8

derivePersistField "Secret"

-- Other auth methods might be added later on, like oauth bearer tokens:
data AuthToken = GonimoSecret Secret
               deriving (Read, Show, Generic)

derivePersistField "AuthToken"

instance FromJSON AuthToken
instance ToJSON AuthToken where
  toJSON = genericToJSON defaultOptions
--  toEncoding = genericToEncoding defaultOptions

instance FromHttpApiData AuthToken where
    parseUrlPiece :: Text -> Either Text AuthToken
    parseUrlPiece x = do gsecret :: Text <- parseUrlPieceWithPrefix "GonimoSecret " x
                         GonimoSecret <$> parseUrlPiece gsecret

data Coffee = Tea deriving Generic
instance FromJSON Coffee
instance ToJSON Coffee where
  toJSON = genericToJSON defaultOptions
--  toEncoding = genericToEncoding defaultOptions



type FamilyName = Text

type EmailAddress = Text


--------------------------------------------------
data InvitationDelivery = EmailInvitation EmailAddress
                        | OtherDelivery
                        deriving (Read, Show, Generic)

instance FromJSON InvitationDelivery

instance ToJSON InvitationDelivery where
  toJSON = genericToJSON defaultOptions
  -- toEncoding = genericToEncoding defaultOptions

derivePersistField "InvitationDelivery"
--------------------------------------------------

