{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module CardanoLoans.Config
  ( Config(..)
  , NetworkMode(..)
  , ProtocolParams(..)
  , defaultProtocolParams
  , defaultConfig
  , loadConfig
  , loadConfigOrDie
  , validateConfig
  , getNetworkId
  , getNetworkName
  , usesBlockfrost
  , usesCardanoNode
  , getBlockfrostUrl
  ) where

import Data.Aeson
import Data.Text (Text)
import qualified Data.ByteString.Lazy as BL
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Control.Exception (try)
import GHC.Generics

-- ============================================================================
-- Configuration Types
-- ============================================================================

data Config = Config
  { cfgNetwork :: NetworkMode
  , cfgCardanoNodeSocket :: Maybe FilePath
  , cfgCardanoNetworkId :: Int
  , cfgBlockfrostApiKey :: Maybe Text
  , cfgBlockfrostEndpoint :: Maybe Text
  , cfgLoanAsset :: Text
  , cfgProtocolParams :: ProtocolParams
  } deriving (Show, Generic)

instance FromJSON Config where
  parseJSON = withObject "Config" $ \v -> Config
    <$> v .: "network"
    <*> v .:? "cardano_node_socket"
    <*> v .:? "cardano_network_id" .!= 0
    <*> v .:? "blockfrost_api_key"
    <*> v .:? "blockfrost_endpoint"
    <*> v .:? "loan_asset" .!= "lovelace"
    <*> v .:? "protocol_params" .!= defaultProtocolParams

instance ToJSON Config where
  toJSON Config{..} = object
    [ "network" .= cfgNetwork
    , "cardano_node_socket" .= cfgCardanoNodeSocket
    , "cardano_network_id" .= cfgCardanoNetworkId
    , "blockfrost_api_key" .= cfgBlockfrostApiKey
    , "blockfrost_endpoint" .= cfgBlockfrostEndpoint
    , "loan_asset" .= cfgLoanAsset
    , "protocol_params" .= cfgProtocolParams
    ]

data NetworkMode = Testnet | Mainnet
  deriving (Show, Generic, Eq)

instance FromJSON NetworkMode where
  parseJSON (String "testnet") = pure Testnet
  parseJSON (String "mainnet") = pure Mainnet
  parseJSON _ = fail "network must be 'testnet' or 'mainnet'"

instance ToJSON NetworkMode where
  toJSON Testnet = String "testnet"
  toJSON Mainnet = String "mainnet"

data ProtocolParams = ProtocolParams
  { ppUtxoCostPerWord :: Integer
  , ppMinFeeA :: Integer
  , ppMinFeeB :: Integer
  } deriving (Show, Generic)

instance FromJSON ProtocolParams where
  parseJSON = withObject "ProtocolParams" $ \v -> ProtocolParams
    <$> v .:? "utxo_cost_per_word" .!= 4310
    <*> v .:? "min_fee_a" .!= 44
    <*> v .:? "min_fee_b" .!= 155381

instance ToJSON ProtocolParams where
  toJSON ProtocolParams{..} = object
    [ "utxo_cost_per_word" .= ppUtxoCostPerWord
    , "min_fee_a" .= ppMinFeeA
    , "min_fee_b" .= ppMinFeeB
    ]

-- ============================================================================
-- Default Configuration
-- ============================================================================

defaultProtocolParams :: ProtocolParams
defaultProtocolParams = ProtocolParams
  { ppUtxoCostPerWord = 4310
  , ppMinFeeA = 44
  , ppMinFeeB = 155381
  }

defaultConfig :: Config
defaultConfig = Config
  { cfgNetwork = Testnet
  , cfgCardanoNodeSocket = Nothing
  , cfgCardanoNetworkId = 0  -- testnet
  , cfgBlockfrostApiKey = Nothing
  , cfgBlockfrostEndpoint = Nothing
  , cfgLoanAsset = "lovelace"
  , cfgProtocolParams = defaultProtocolParams
  }

-- ============================================================================
-- Configuration Loading
-- ============================================================================

-- | Load configuration from JSON file
loadConfig :: FilePath -> IO (Either String Config)
loadConfig configFile = do
  result <- try @IOError $ BL.readFile configFile
  case result of
    Left err -> return $ Left $ "Failed to read config file: " ++ show err
    Right content ->
      case eitherDecode content of
        Left err -> return $ Left $ "Failed to parse config: " ++ err
        Right cfg -> return $ Right cfg

-- | Load configuration and exit on error
loadConfigOrDie :: FilePath -> IO Config
loadConfigOrDie configFile = do
  result <- loadConfig configFile
  case result of
    Left err -> do
      hPutStrLn stderr $ "Config Error: " ++ err
      exitFailure
    Right cfg -> return cfg

-- ============================================================================
-- Configuration Validation
-- ============================================================================

-- | Validate configuration
validateConfig :: Config -> Either String ()
validateConfig cfg = do
  case cfgNetwork cfg of
    Testnet -> case cfgCardanoNetworkId cfg of
      0 -> Right ()
      n -> Left $ "Network is testnet but network_id is " ++ show n ++ " (expected 0)"
    Mainnet -> case cfgCardanoNetworkId cfg of
      1 -> Right ()
      n -> Left $ "Network is mainnet but network_id is " ++ show n ++ " (expected 1)"

  -- Validate that at least one backend is configured
  case (cfgCardanoNodeSocket cfg, cfgBlockfrostApiKey cfg) of
    (Nothing, Nothing) ->
      Left "Either 'cardano_node_socket' or 'blockfrost_api_key' must be configured"
    _ -> Right ()

  -- Validate protocol params
  let pp = cfgProtocolParams cfg
  if ppUtxoCostPerWord pp > 0 && ppMinFeeA pp > 0 && ppMinFeeB pp > 0
    then Right ()
    else Left "Protocol params must be positive"

-- ============================================================================
-- Configuration Access Helpers
-- ============================================================================

-- | Get network ID from config
getNetworkId :: Config -> Int
getNetworkId = cfgCardanoNetworkId

-- | Get network name
getNetworkName :: Config -> String
getNetworkName cfg = case cfgNetwork cfg of
  Testnet -> "testnet"
  Mainnet -> "mainnet"

-- | Check if configuration uses Blockfrost
usesBlockfrost :: Config -> Bool
usesBlockfrost cfg = case cfgBlockfrostApiKey cfg of
  Just _ -> True
  Nothing -> False

-- | Check if configuration uses Cardano Node
usesCardanoNode :: Config -> Bool
usesCardanoNode cfg = case cfgCardanoNodeSocket cfg of
  Just _ -> True
  Nothing -> False

-- | Get Blockfrost endpoint with API key
getBlockfrostUrl :: Config -> Maybe Text
getBlockfrostUrl cfg = do
  endpoint <- cfgBlockfrostEndpoint cfg
  apiKey <- cfgBlockfrostApiKey cfg
  return $ endpoint <> "?project_id=" <> apiKey
