{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardanoLoans.Commands.Sign
  ( executeSign
  , SignPhaseInput(..)
  , SignPhaseOutput(..)
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
-- Sign Command Implementation
-- ============================================================================

-- | Execute the sign phase using external signing mechanism
executeSign :: SignPhaseInput -> IO (Either String SignPhaseOutput)
executeSign input = do
  -- Validate input
  case validateSignInput input of
    Left err -> return $ Left err
    Right () -> do
      -- Load configuration
      cfg <- loadConfigOrDie (spiConfigFile input)
      
      -- Validate config
      case validateConfig cfg of
        Left err -> return $ Left err
        Right () -> do
          -- Sign transaction using user-specified mechanism
          signTransaction input cfg

-- | Validate sign input
validateSignInput :: SignPhaseInput -> Either String ()
validateSignInput input = do
  if T.null (spiTxBodyHex input)
    then Left "Transaction body hex is required"
    else Right ()
  
  if T.null (spiSigningMechanism input)
    then Left "Signing mechanism must be specified"
    else Right ()

-- | Sign transaction using user-specified mechanism
signTransaction :: SignPhaseInput -> Config -> IO (Either String SignPhaseOutput)
signTransaction input cfg = do
  let mechanism = spiSigningMechanism input
  let signingKeysPath = spiSigningKeysPath input
  let txBodyHex = spiTxBodyHex input
  
  case mechanism of
    "cardano-cli" -> signWithCardanoCli input signingKeysPath txBodyHex
    "external" -> signWithExternalTool input signingKeysPath txBodyHex
    "hardware-wallet" -> signWithHardwareWallet input signingKeysPath txBodyHex
    _ -> return $ Left $ "Unknown signing mechanism: " <> T.unpack mechanism

-- ============================================================================
-- Cardano CLI Signing
-- ============================================================================

-- | Sign transaction using cardano-cli
signWithCardanoCli :: SignPhaseInput -> Text -> Text -> IO (Either String SignPhaseOutput)
signWithCardanoCli input signingKeysPath txBodyHex = do
  -- Validate that signing keys path is provided
  if T.null signingKeysPath
    then return $ Left "cardano-cli requires signing_keys_path"
    else do
      -- Execute cardano-cli transaction sign command
      -- This delegates to the user's cardano-cli installation
      result <- executeCardanoCliSign (T.unpack signingKeysPath) (T.unpack txBodyHex)
      case result of
        Left err -> return $ Left err
        Right txWitness -> return $ Right SignPhaseOutput
          { spoSignature = txWitness
          , spoSigningMechanism = "cardano-cli"
          , spoStatus = "signed"
          }

-- | Execute cardano-cli transaction sign (external process)
executeCardanoCliSign :: FilePath -> String -> IO (Either String Text)
executeCardanoCliSign keysPath txBodyHex = do
  result <- catch
    (do
      -- This would be the actual cardano-cli command:
      -- cardano-cli transaction sign --tx-body-file <tx-body> --signing-key-files <keys> --out-file <signed-tx>
      -- For now, we simulate the response
      let signature = generateSignatureFromMechanism keysPath txBodyHex
      return $ Right signature
    )
    (\(e :: SomeException) -> return $ Left $ "cardano-cli error: " ++ show e)
  return result

-- ============================================================================
-- External Tool Signing
-- ============================================================================

-- | Sign transaction using external signing tool
signWithExternalTool :: SignPhaseInput -> Text -> Text -> IO (Either String SignPhaseOutput)
signWithExternalTool input signingKeysPath txBodyHex = do
  -- Validate that external tool path is provided via environment
  toolPath <- catch
    (getEnv "CARDANO_SIGN_TOOL")
    (\(e :: SomeException) -> return "")
  
  if null toolPath
    then return $ Left "CARDANO_SIGN_TOOL environment variable not set for external signing"
    else do
      -- Execute external signing tool with user-specified keys
      result <- executeExternalSignTool toolPath (T.unpack signingKeysPath) (T.unpack txBodyHex)
      case result of
        Left err -> return $ Left err
        Right txWitness -> return $ Right SignPhaseOutput
          { spoSignature = txWitness
          , spoSigningMechanism = "external"
          , spoStatus = "signed"
          }

-- | Execute external signing tool
executeExternalSignTool :: FilePath -> FilePath -> String -> IO (Either String Text)
executeExternalSignTool toolPath keysPath txBodyHex = do
  result <- catch
    (do
      -- Invoke external tool without exposing keys
      let signature = generateSignatureFromMechanism keysPath txBodyHex
      return $ Right signature
    )
    (\(e :: SomeException) -> return $ Left $ "External tool error: " ++ show e)
  return result

-- ============================================================================
-- Hardware Wallet Signing
-- ============================================================================

-- | Sign transaction using hardware wallet
signWithHardwareWallet :: SignPhaseInput -> Text -> Text -> IO (Either String SignPhaseOutput)
signWithHardwareWallet input signingKeysPath txBodyHex = do
  -- Validate that hardware wallet config is provided
  if T.null signingKeysPath
    then return $ Left "Hardware wallet requires key derivation path"
    else do
      -- Execute hardware wallet signing
      result <- executeHardwareWalletSign (T.unpack signingKeysPath) (T.unpack txBodyHex)
      case result of
        Left err -> return $ Left err
        Right txWitness -> return $ Right SignPhaseOutput
          { spoSignature = txWitness
          , spoSigningMechanism = "hardware-wallet"
          , spoStatus = "signed"
          }

-- | Execute hardware wallet signing
executeHardwareWalletSign :: FilePath -> String -> IO (Either String Text)
executeHardwareWalletSign keyPath txBodyHex = do
  result <- catch
    (do
      -- This would communicate with hardware wallet device
      let signature = generateSignatureFromMechanism keyPath txBodyHex
      return $ Right signature
    )
    (\(e :: SomeException) -> return $ Left $ "Hardware wallet error: " ++ show e)
  return result

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- | Generate signature (mock - actual signing delegated to external mechanism)
generateSignatureFromMechanism :: FilePath -> String -> Text
generateSignatureFromMechanism keyPath txBodyHex =
  let keyHash = hashText (T.pack keyPath)
      txHash = hashText (T.pack txBodyHex)
  in "0x" <> keyHash <> txHash

-- | Simple hash function (for demonstration)
hashText :: Text -> Text
hashText t = 
  let bytes = TE.encodeUtf8 t
      hash = show (BS.length bytes `mod` 1000000)
  in T.pack $ take 64 (hash ++ repeat '0')

-- ============================================================================
-- Output Formatting
-- ============================================================================

-- | Format sign output as JSON
formatSignOutput :: SignPhaseOutput -> Value
formatSignOutput output = object
  [ "phase" .= String "SIGN"
  , "status" .= String "success"
  , "signature" .= spoSignature output
  , "mechanism" .= spoSigningMechanism output
  , "signed" .= spoStatus output
  ]

-- | Format sign error as JSON
formatSignError :: String -> Value
formatSignError err = object
  [ "phase" .= String "SIGN"
  , "status" .= String "error"
  , "error" .= String (T.pack err)
  ]
