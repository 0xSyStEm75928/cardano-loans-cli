{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module CLI.Runner
  ( runCommand
  ) where

import Data.Aeson (encode)
import qualified Data.ByteString.Lazy.Char8 as LBS
import Data.Text (Text)
import qualified Data.Text as T
import System.Exit (exitFailure)

import CLI.Parser (Command(..))
import CardanoLoans.Types
import CardanoLoans.Commands.Build (executeBuild)
import CardanoLoans.Commands.Sign (executeSign)
import CardanoLoans.Commands.Submit (executeSubmit)
import CardanoLoans.Commands.Status (executeStatus)

-- | Dispatch a parsed command to the appropriate handler
runCommand :: Command -> IO ()
runCommand (BuildCmd{..}) = do
  let input = BuildPhaseInput
        { bpiPrincipal = cmdPrincipal
        , bpiTermDays = cmdTermDays
        , bpiCollateral = cmdCollateral
        , bpiBorrowerAddress = cmdBorrowerAddress
        , bpiLenderAddress = cmdLenderAddress
        , bpiInterestRate = cmdInterestRate
        , bpiConfigFile = cmdConfigFile
        }
  result <- executeBuild input
  handleResult "BUILD" result

runCommand (SignCmd{..}) = do
  let input = SignPhaseInput
        { spiTxBodyHex = cmdTxBodyHex
        , spiSigningMechanism = cmdSigningMechanism
        , spiSigningKeysPath = cmdSigningKeysPath
        , spiConfigFile = cmdConfigFile
        }
  result <- executeSign input
  handleResult "SIGN" result

runCommand (SubmitCmd{..}) = do
  let input = SubmitPhaseInput
        { spSignedTxHex = cmdSignedTxHex
        , spNetworkId = cmdNetworkId
        , spConfigFile = cmdConfigFile
        }
  result <- executeSubmit input
  handleResult "SUBMIT" result

runCommand (StatusCmd{..}) = do
  let input = ConfirmPhaseInput
        { cpiTxId = cmdTxId
        , cpiConfigFile = cmdConfigFile
        }
  result <- executeStatus input
  handleResult "STATUS" result

-- | Handle a command result by printing JSON output
handleResult :: Text -> Either String a -> IO ()
handleResult phase (Left err) = do
  let result = CommandResult
        { command = phase
        , phase = phase
        , status = Error
        , txId = Nothing
        , block = Nothing
        , timestamp = Nothing
        , errorMsg = Just (T.pack err)
        , data_ = Nothing
        }
  LBS.putStrLn (encode result)
  exitFailure

handleResult _phase (Right _output) = do
  -- Success output is handled by the command-specific formatters
  -- For now, print a simple success message
  putStrLn $ "{\"status\":\"success\"}"
