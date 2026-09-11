{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardanoLoans.Commands.Status
  ( executeStatus
  ) where

import Data.Text (Text)
import System.Environment (getEnv)
import Control.Exception (catch, SomeException)
import CardanoLoans.Types
import CardanoLoans.Config

-- | Execute the status/confirm phase
executeStatus :: ConfirmPhaseInput -> IO (Either String ConfirmPhaseOutput)
executeStatus input = do
  cfg <- loadConfigOrDie (cpiConfigFile input)
  case validateConfig cfg of
    Left err -> return $ Left err
    Right () -> checkTransactionStatus (cpiTxId input) cfg

-- | Check transaction status via Blockfrost or node
checkTransactionStatus :: Text -> Config -> IO (Either String ConfirmPhaseOutput)
checkTransactionStatus txId cfg
  | usesBlockfrost cfg = checkViaBlockfrost txId cfg
  | usesCardanoNode cfg = checkViaNode txId cfg
  | otherwise = return $ Left "No backend configured for status check"

-- | Check status via Blockfrost API
checkViaBlockfrost :: Text -> Config -> IO (Either String ConfirmPhaseOutput)
checkViaBlockfrost txId cfg = do
  let mUrl = getBlockfrostUrl cfg
  case mUrl of
    Nothing -> return $ Left "Blockfrost URL not configured"
    Just _url -> do
      -- In a real implementation, this would make an HTTP request to Blockfrost
      return $ Right ConfirmPhaseOutput
        { cpoTxId = txId
        , cpoStatus = Pending
        , cpoBlock = Nothing
        , cpoTimestamp = Nothing
        }

-- | Check status via local node
checkViaNode :: Text -> Config -> IO (Either String ConfirmPhaseOutput)
checkViaNode txId _cfg = do
  nodeSocket <- catch
    (getEnv "CARDANO_NODE_SOCKET_PATH")
    (\(_e :: SomeException) -> return "")
  if null nodeSocket
    then return $ Left "CARDANO_NODE_SOCKET_PATH not set"
    else do
      -- In a real implementation, this would query the local node
      return $ Right ConfirmPhaseOutput
        { cpoTxId = txId
        , cpoStatus = Pending
        , cpoBlock = Nothing
        , cpoTimestamp = Nothing
        }
