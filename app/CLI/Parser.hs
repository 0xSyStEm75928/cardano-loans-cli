{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module CLI.Parser
  ( Command(..)
  , parseCommand
  ) where

import Options.Applicative
import Data.Text (Text)
import qualified Data.Text as T

-- | All supported CLI commands
data Command
  = BuildCmd
      { cmdPrincipal :: Integer
      , cmdTermDays :: Int
      , cmdCollateral :: [Text]
      , cmdBorrowerAddress :: Text
      , cmdLenderAddress :: Text
      , cmdInterestRate :: Double
      , cmdConfigFile :: FilePath
      }
  | SignCmd
      { cmdTxBodyHex :: Text
      , cmdSigningMechanism :: Text
      , cmdSigningKeysPath :: Text
      , cmdConfigFile :: FilePath
      }
  | SubmitCmd
      { cmdSignedTxHex :: Text
      , cmdNetworkId :: Text
      , cmdConfigFile :: FilePath
      }
  | StatusCmd
      { cmdTxId :: Text
      , cmdConfigFile :: FilePath
      }
  deriving (Show)

-- | Parse CLI arguments into a Command
parseCommand :: IO Command
parseCommand = execParser commandInfo

commandInfo :: ParserInfo Command
commandInfo = info (helper <*> commandParser) $
  fullDesc
    <> progDesc "Cardano Loans CLI - Build, sign, and submit loan transactions"
    <> header "cardano-loans - standalone Cardano loan CLI"

commandParser :: Parser Command
commandParser = hsubparser
  ( command "build" (info buildParser (progDesc "Build a loan transaction"))
 <> command "sign" (info signParser (progDesc "Sign a transaction"))
 <> command "submit" (info submitParser (progDesc "Submit a signed transaction"))
 <> command "status" (info statusParser (progDesc "Check transaction status"))
  )

buildParser :: Parser Command
buildParser = BuildCmd
  <$> option auto (long "principal" <> short 'p' <> metavar "LOVELACE" <> help "Loan principal in lovelace")
  <*> option auto (long "term-days" <> short 't' <> metavar "DAYS" <> help "Loan term in days")
  <*> many (T.pack <$> strOption (long "collateral" <> short 'c' <> metavar "ASSET" <> help "Collateral asset (repeatable)"))
  <*> (T.pack <$> strOption (long "borrower" <> short 'b' <> metavar "ADDRESS" <> help "Borrower Cardano address"))
  <*> (T.pack <$> strOption (long "lender" <> short 'l' <> metavar "ADDRESS" <> help "Lender Cardano address"))
  <*> option auto (long "interest" <> short 'i' <> metavar "PERCENT" <> help "Interest rate as percentage")
  <*> strOption (long "config" <> short 'C' <> metavar "FILE" <> help "Path to config JSON file")

signParser :: Parser Command
signParser = SignCmd
  <$> (T.pack <$> strOption (long "tx-body" <> short 't' <> metavar "HEX" <> help "Hex-encoded unsigned transaction body"))
  <*> (T.pack <$> strOption (long "mechanism" <> short 'm' <> metavar "MECHANISM" <> help "Signing mechanism (cardano-cli, external, hardware-wallet)"))
  <*> (T.pack <$> strOption (long "keys-path" <> short 'k' <> metavar "PATH" <> help "Path or derivation path for signing keys"))
  <*> strOption (long "config" <> short 'C' <> metavar "FILE" <> help "Path to config JSON file")

submitParser :: Parser Command
submitParser = SubmitCmd
  <$> (T.pack <$> strOption (long "signed-tx" <> short 't' <> metavar "HEX" <> help "Hex-encoded signed transaction"))
  <*> (T.pack <$> strOption (long "network" <> short 'n' <> metavar "NETWORK" <> help "Network (mainnet, testnet, preview)"))
  <*> strOption (long "config" <> short 'C' <> metavar "FILE" <> help "Path to config JSON file")

statusParser :: Parser Command
statusParser = StatusCmd
  <$> (T.pack <$> strOption (long "tx-id" <> short 't' <> metavar "TXID" <> help "Transaction ID to check"))
  <*> strOption (long "config" <> short 'C' <> metavar "FILE" <> help "Path to config JSON file")
