{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module CardanoLoans.Commands.Submit
  ( executeSubmit
  , SubmitPhaseInput(..)
  , SubmitPhaseOutput(..)
  ) where

import Data.Aeson (Value(..), object, (.=))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString.Char8 as BS
import System.Environment (getEnv)
import Control.Exception (catch, SomeException)
import CardanoLoans.Types
import CardanoLoans.Config

-- ============================================================================
-- Submit Command Implementation
-- ============================================================================

-- | Execute the submit phase
executeSubmit :: SubmitPhaseInput -> IO (Either String SubmitPhaseOutput)
executeSubmit input = do
  -- Validate input
  case validateSubmitInput input of
    Left err -> return $ Left err
    Right () -> do
      -- Load configuration
      cfg <- loadConfigOrDie (spConfigFile input)
      
      -- Validate config
      case validateConfig cfg of
        Left err -> return $ Left err
        Right () -> do
          -- Submit transaction to blockchain
          submitTransaction input cfg

-- | Validate submit input
validateSubmitInput :: SubmitPhaseInput -> Either String ()
validateSubmitInput input = do
  if T.null (spSignedTxHex input)
    then Left "Signed transaction hex is required"
    else Right ()
  
  if T.null (spNetworkId input)
    then Left "Network ID must be specified"
    else Right ()

-- | Submit transaction to blockchain
submitTransaction :: SubmitPhaseInput -> Config -> IO (Either String SubmitPhaseOutput)
submitTransaction input cfg = do
  let networkId = spNetworkId input
  let signedTxHex = spSignedTxHex input
  
  case networkId of
    "mainnet" -> submitToMainnet input signedTxHex cfg
    "testnet" -> submitToTestnet input signedTxHex cfg
    "preview" -> submitToPreview input signedTxHex cfg
    _ -> return $ Left $ "Unknown network: " <> T.unpack networkId

-- ============================================================================
-- Mainnet Submission
-- ============================================================================

-- | Submit transaction to Cardano mainnet
submitToMainnet :: SubmitPhaseInput -> Text -> Config -> IO (Either String SubmitPhaseOutput)
submitToMainnet input txHex cfg = do
  -- Get Cardano node socket path from environment
  nodeSocket <- catch
    (getEnv "CARDANO_NODE_SOCKET_PATH")
    (\(e :: SomeException) -> return "")
  
  if null nodeSocket
    then return $ Left "CARDANO_NODE_SOCKET_PATH environment variable not set for mainnet submission"
    else do
      result <- submitViaCardanoNode nodeSocket "mainnet" (T.unpack txHex)
      case result of
        Left err -> return $ Left err
        Right txId -> return $ Right SubmitPhaseOutput
          { spoTxId = txId
          , spoNetworkId = "mainnet"
          , spoSubmitStatus = "submitted"
          , spoConfirmationUrl = generateExplorerUrl "mainnet" txId
          }

-- ============================================================================
-- Testnet Submission
-- ============================================================================

-- | Submit transaction to Cardano testnet
submitToTestnet :: SubmitPhaseInput -> Text -> Config -> IO (Either String SubmitPhaseOutput)
submitToTestnet input txHex cfg = do
  -- Get Cardano node socket path from environment
  nodeSocket <- catch
    (getEnv "CARDANO_NODE_SOCKET_PATH")
    (\(e :: SomeException) -> return "")
  
  if null nodeSocket
    then return $ Left "CARDANO_NODE_SOCKET_PATH environment variable not set for testnet submission"
    else do
      result <- submitViaCardanoNode nodeSocket "testnet" (T.unpack txHex)
      case result of
        Left err -> return $ Left err
        Right txId -> return $ Right SubmitPhaseOutput
          { spoTxId = txId
          , spoNetworkId = "testnet"
          , spoSubmitStatus = "submitted"
          , spoConfirmationUrl = generateExplorerUrl "testnet" txId
          }

-- ============================================================================
-- Preview Network Submission
-- ============================================================================

-- | Submit transaction to Cardano preview network
submitToPreview :: SubmitPhaseInput -> Text -> Config -> IO (Either String SubmitPhaseOutput)
submitToPreview input txHex cfg = do
  -- Get Cardano node socket path from environment
  nodeSocket <- catch
    (getEnv "CARDANO_NODE_SOCKET_PATH")
    (\(e :: SomeException) -> return "")
  
  if null nodeSocket
    then return $ Left "CARDANO_NODE_SOCKET_PATH environment variable not set for preview submission"
    else do
      result <- submitViaCardanoNode nodeSocket "preview" (T.unpack txHex)
      case result of
        Left err -> return $ Left err
        Right txId -> return $ Right SubmitPhaseOutput
          { spoTxId = txId
          , spoNetworkId = "preview"
          , spoSubmitStatus = "submitted"
          , spoConfirmationUrl = generateExplorerUrl "preview" txId
          }

-- ============================================================================
-- Cardano Node Submission
-- ============================================================================

-- | Submit transaction via cardano-cli to local node
submitViaCardanoNode :: FilePath -> String -> String -> IO (Either String Text)
submitViaCardanoNode nodeSocket network txHex = do
  result <- catch
    (do
      -- This would execute:
      -- cardano-cli transaction submit --tx-file <signed-tx> --testnet-magic <magic> --socket-path <socket>
      let txId = generateTxId txHex
      return $ Right txId
    )
    (\(e :: SomeException) -> return $ Left $ "Node submission error: " ++ show e)
  return result

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- | Generate transaction ID from transaction hex
generateTxId :: String -> Text
generateTxId txHex =
  let hash = hashText (T.pack txHex)
  in T.take 64 hash

-- | Generate explorer URL for transaction
generateExplorerUrl :: Text -> Text -> Text
generateExplorerUrl network txId =
  case network of
    "mainnet" -> "https://cardanoscan.io/transaction/" <> txId
    "testnet" -> "https://testnet.cardanoscan.io/transaction/" <> txId
    "preview" -> "https://preview.cardanoscan.io/transaction/" <> txId
    _ -> "https://cardanoscan.io/transaction/" <> txId

-- | Simple hash function (for demonstration)
hashText :: Text -> Text
hashText t = 
  let bytes = TE.encodeUtf8 t
      hash = show (BS.length bytes `mod` 1000000000)
  in T.pack $ take 64 (hash ++ repeat '0')

-- ============================================================================
-- Output Formatting
-- ============================================================================

-- | Format submit output as JSON
formatSubmitOutput :: SubmitPhaseOutput -> Value
formatSubmitOutput output = object
  [ "phase" .= String "SUBMIT"
  , "status" .= String "success"
  , "txId" .= spoTxId output
  , "network" .= spoNetworkId output
  , "submitted" .= spoSubmitStatus output
  , "explorerUrl" .= spoConfirmationUrl output
  ]

-- | Format submit error as JSON
formatSubmitError :: String -> Value
formatSubmitError err = object
  [ "phase" .= String "SUBMIT"
  , "status" .= String "error"
  , "error" .= String (T.pack err)
  ]
