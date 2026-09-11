{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module CardanoLoans.Types
  ( -- * Loan Request Types
    LoanRequest(..)
    -- * Transaction Types
  , TransactionBody(..)
  , SignedTransaction(..)
    -- * Command Results
  , CommandResult(..)
  , Status(..)
    -- * Network Types
  , NetworkType(..)
    -- * Build Phase Types
  , BuildPhaseInput(..)
  , BuildPhaseOutput(..)
    -- * Sign Phase Types
  , SignPhaseInput(..)
  , SignPhaseOutput(..)
    -- * Submit Phase Types
  , SubmitPhaseInput(..)
  , SubmitPhaseOutput(..)
    -- * Status/Confirm Phase Types
  , ConfirmPhaseInput(..)
  , ConfirmPhaseOutput(..)
  , ConfirmStatus(..)
    -- * Error Types
  , LoanError(..)
  ) where

import Data.Aeson
import Data.Text (Text)
import GHC.Generics
import Data.Maybe (catMaybes)

-- ============================================================================
-- Loan Request Types
-- ============================================================================

data LoanRequest = LoanRequest
  { principal :: Integer       -- ^ Principal amount in lovelace
  , termDays :: Int            -- ^ Loan term in days
  , collateral :: [Text]       -- ^ Collateral asset IDs (empty for unsecured)
  , borrowerAddress :: Text    -- ^ Borrower's Cardano address
  , lenderAddress :: Text      -- ^ Lender's Cardano address
  , interestRate :: Double     -- ^ Interest rate as percentage
  } deriving (Show, Generic)

instance FromJSON LoanRequest
instance ToJSON LoanRequest

-- ============================================================================
-- Transaction Types
-- ============================================================================

data TransactionBody = TransactionBody
  { txBodyHex :: Text          -- ^ Hex-encoded transaction body
  , txHash :: Text             -- ^ Transaction hash
  , txFee :: Integer           -- ^ Transaction fee in lovelace
  } deriving (Show, Generic)

instance FromJSON TransactionBody
instance ToJSON TransactionBody

data SignedTransaction = SignedTransaction
  { signedTxHex :: Text        -- ^ Hex-encoded signed transaction
  , signatureCount :: Int      -- ^ Number of signatures
  } deriving (Show, Generic)

instance FromJSON SignedTransaction
instance ToJSON SignedTransaction

-- ============================================================================
-- Command Results
-- ============================================================================

data CommandResult = CommandResult
  { command :: Text            -- ^ Command name (build, sign, submit, status, confirm)
  , phase :: Text              -- ^ Phase name (BUILD, SIGN, SUBMIT, CONFIRMED)
  , status :: Status           -- ^ success or error
  , txId :: Maybe Text         -- ^ Transaction ID (only after SUBMIT)
  , block :: Maybe Integer     -- ^ Block height (only after CONFIRMED)
  , timestamp :: Maybe Text    -- ^ ISO 8601 timestamp
  , errorMsg :: Maybe Text     -- ^ Error message if status = error
  , data_ :: Maybe Object      -- ^ Additional data (arbitrary JSON object)
  } deriving (Show, Generic)

instance FromJSON CommandResult where
  parseJSON = withObject "CommandResult" $ \v -> CommandResult
    <$> v .: "command"
    <*> v .: "phase"
    <*> v .: "status"
    <*> v .:? "txid"
    <*> v .:? "block"
    <*> v .:? "timestamp"
    <*> v .:? "error"
    <*> v .:? "data"

instance ToJSON CommandResult where
  toJSON CommandResult{..} = object $
    [ "command" .= command
    , "phase" .= phase
    , "status" .= status
    ] ++ catMaybes
    [ ("txid" .=) <$> txId
    , ("block" .=) <$> block
    , ("timestamp" .=) <$> timestamp
    , ("error" .=) <$> errorMsg
    , ("data" .=) <$> data_
    ]

data Status = Success | Error
  deriving (Show, Generic, Eq)

instance FromJSON Status where
  parseJSON (String "success") = pure Success
  parseJSON (String "error") = pure Error
  parseJSON _ = fail "Invalid status"

instance ToJSON Status where
  toJSON Success = String "success"
  toJSON Error = String "error"

-- ============================================================================
-- Network Types
-- ============================================================================

data NetworkType = Testnet | Mainnet
  deriving (Show, Generic, Eq)

instance FromJSON NetworkType where
  parseJSON (String "testnet") = pure Testnet
  parseJSON (String "mainnet") = pure Mainnet
  parseJSON _ = fail "Invalid network"

instance ToJSON NetworkType where
  toJSON Testnet = String "testnet"
  toJSON Mainnet = String "mainnet"

-- ============================================================================
-- Build Phase Types
-- ============================================================================

data BuildPhaseInput = BuildPhaseInput
  { bpiPrincipal :: Integer
  , bpiTermDays :: Int
  , bpiCollateral :: [Text]
  , bpiBorrowerAddress :: Text
  , bpiLenderAddress :: Text
  , bpiInterestRate :: Double
  , bpiConfigFile :: FilePath
  } deriving (Show)

data BuildPhaseOutput = BuildPhaseOutput
  { bpoTxBodyHex :: Text
  , bpoTxHash :: Text
  , bpoFee :: Integer
  } deriving (Show, Generic)

instance ToJSON BuildPhaseOutput where
  toJSON BuildPhaseOutput{..} = object
    [ "txBody" .= bpoTxBodyHex
    , "txHash" .= bpoTxHash
    , "fee" .= bpoFee
    ]

-- ============================================================================
-- Sign Phase Types
-- ============================================================================

data SignPhaseInput = SignPhaseInput
  { spiTxBodyHex :: Text           -- ^ Hex-encoded unsigned transaction body
  , spiSigningMechanism :: Text    -- ^ Signing mechanism (cardano-cli, external, hardware-wallet)
  , spiSigningKeysPath :: Text     -- ^ Path or key derivation path for signing keys
  , spiConfigFile :: FilePath     -- ^ Path to configuration file
  } deriving (Show)

data SignPhaseOutput = SignPhaseOutput
  { spoSignature :: Text           -- ^ Hex-encoded transaction witness
  , spoSigningMechanism :: Text    -- ^ Mechanism used for signing
  , spoStatus :: Text              -- ^ Status (signed)
  } deriving (Show, Generic)

instance ToJSON SignPhaseOutput where
  toJSON SignPhaseOutput{..} = object
    [ "signature" .= spoSignature
    , "mechanism" .= spoSigningMechanism
    , "signed" .= spoStatus
    ]

-- ============================================================================
-- Submit Phase Types
-- ============================================================================

data SubmitPhaseInput = SubmitPhaseInput
  { spSignedTxHex :: Text      -- ^ Hex-encoded signed transaction
  , spNetworkId :: Text         -- ^ Network ID (mainnet, testnet, preview)
  , spConfigFile :: FilePath   -- ^ Path to configuration file
  } deriving (Show)

data SubmitPhaseOutput = SubmitPhaseOutput
  { spoTxId :: Text             -- ^ Transaction ID after submission
  , spoNetworkId :: Text        -- ^ Network the tx was submitted to
  , spoStatus :: Text           -- ^ Submission status
  , spoConfirmationUrl :: Text  -- ^ URL to view the transaction on an explorer
  } deriving (Show, Generic)

instance ToJSON SubmitPhaseOutput where
  toJSON SubmitPhaseOutput{..} = object
    [ "txid" .= spoTxId
    , "network" .= spoNetworkId
    , "status" .= spoStatus
    , "explorer_url" .= spoConfirmationUrl
    ]

-- ============================================================================
-- Status/Confirm Phase Types
-- ============================================================================

data ConfirmPhaseInput = ConfirmPhaseInput
  { cpiTxId :: Text
  , cpiConfigFile :: FilePath
  } deriving (Show)

data ConfirmPhaseOutput = ConfirmPhaseOutput
  { cpoTxId :: Text
  , cpoStatus :: ConfirmStatus
  , cpoBlock :: Maybe Integer
  , cpoTimestamp :: Maybe Text
  } deriving (Show, Generic)

data ConfirmStatus = Pending | Confirmed | Failed
  deriving (Show, Generic, Eq)

instance FromJSON ConfirmStatus where
  parseJSON (String "pending") = pure Pending
  parseJSON (String "confirmed") = pure Confirmed
  parseJSON (String "failed") = pure Failed
  parseJSON _ = fail "Invalid confirm status"

instance ToJSON ConfirmStatus where
  toJSON Pending = String "pending"
  toJSON Confirmed = String "confirmed"
  toJSON Failed = String "failed"

instance ToJSON ConfirmPhaseOutput where
  toJSON ConfirmPhaseOutput{..} = object $
    [ "txid" .= cpoTxId
    , "status" .= cpoStatus
    ] ++ catMaybes
    [ ("block" .=) <$> cpoBlock
    , ("timestamp" .=) <$> cpoTimestamp
    ]

-- ============================================================================
-- Error Types
-- ============================================================================

data LoanError
  = ConfigError String
  | BuildError String
  | SignError String
  | SubmitError String
  | StatusError String
  | NetworkError String
  | ValidationError String
  deriving (Show)

instance ToJSON LoanError where
  toJSON err = object
    [ "error_type" .= errorType err
    , "message" .= errorMessage err
    ]
    where
      errorType ConfigError{} = String "config_error"
      errorType BuildError{} = String "build_error"
      errorType SignError{} = String "sign_error"
      errorType SubmitError{} = String "submit_error"
      errorType StatusError{} = String "status_error"
      errorType NetworkError{} = String "network_error"
      errorType ValidationError{} = String "validation_error"

      errorMessage (ConfigError msg) = msg
      errorMessage (BuildError msg) = msg
      errorMessage (SignError msg) = msg
      errorMessage (SubmitError msg) = msg
      errorMessage (StatusError msg) = msg
      errorMessage (NetworkError msg) = msg
      errorMessage (ValidationError msg) = msg
