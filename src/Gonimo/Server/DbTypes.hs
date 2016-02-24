{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
-- Needed for toText, fromText for BackendKey:
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Gonimo.Server.DbTypes where


import           Control.Error.Safe (rightMay, rightZ)
import           Data.Aeson.Types       (FromJSON (..), ToJSON (..), Value (String), defaultOptions, genericToJSON)
import           Data.ByteString (ByteString)

import qualified Data.ByteString.Base64 as Base64
import           Data.Text (Text)
import           Data.Text.Encoding (decodeUtf8, encodeUtf8)
import           Database.Persist
import           Database.Persist.Sql
import           Database.Persist.TH
import           GHC.Generics (Generic)
import           Servant.Common.Text (FromText (..), ToText (..))

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

newtype Secret = Secret ByteString deriving (Generic, Show, Read)

instance FromJSON Secret where
  parseJSON (String t) = Secret <$> (rightZ . Base64.decode . encodeUtf8 $ t)
  parseJSON _ = fail "Expecting a string when parsing a secret."

instance ToJSON Secret where
  toJSON (Secret bs) = String . decodeUtf8 . Base64.encode $ bs

instance FromText Secret where
  fromText = fmap Secret . rightMay . Base64.decode . encodeUtf8

derivePersistField "Secret"
--------------------------------------------------

-- Orphan instances to make our life easier:
instance ToText (BackendKey SqlBackend) where
  toText = toText . unSqlBackendKey

instance FromText (BackendKey SqlBackend) where
  fromText = fmap SqlBackendKey . fromText
