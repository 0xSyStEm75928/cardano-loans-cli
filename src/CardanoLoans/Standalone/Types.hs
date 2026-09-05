{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module CardanoLoans.Types where

import Data.Aeson
import Data.Text (Text)
import GHC.Generics

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
    where
      catMaybes = foldr (\a b -> case a of Just x -> x : b; Nothing -> b) []

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
  { spiTxFile :: FilePath      -- ^ Path to unsigned transaction
  , spiSkeyFile :: FilePath    -- ^ Path to signing key
  , spiConfigFile :: FilePath
  } deriving (Show)

data SignPhaseOutput = SignPhaseOutput
  { spoSignedTxHex :: Text
  , spoSignatureCount :: Int
  } deriving (Show, Generic)

instance ToJSON SignPhaseOutput where
  toJSON SignPhaseOutput{..} = object
    [ "signed_tx" .= spoSignedTxHex
    , "signature_count" .= spoSignatureCount
    ]

-- ============================================================================
-- Submit Phase Types
-- ============================================================================

data SubmitPhaseInput = SubmitPhaseInput
  { supiTxFile :: FilePath     -- ^ Path to signed transaction
  , supiConfigFile :: FilePath
  } deriving (Show)

data SubmitPhaseOutput = SubmitPhaseOutput
  { supoTxId :: Text
  , supoNetwork :: NetworkType
  } deriving (Show, Generic)

instance ToJSON SubmitPhaseOutput where
  toJSON SubmitPhaseOutput{..} = object
    [ "txid" .= supoTxId
    , "network" .= supoNetwork
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
    where
      catMaybes = foldr (\a b -> case a of Just x -> x : b; Nothing -> b) []

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
