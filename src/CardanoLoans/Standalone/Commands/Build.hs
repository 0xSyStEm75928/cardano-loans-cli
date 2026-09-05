{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module CardanoLoans.Standalone.Commands.Build where

import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString.Char8 as BS
import System.Process
import System.Exit
import GHC.Generics
import CardanoLoans.Standalone.Types
import CardanoLoans.Standalone.Config

-- ============================================================================
-- Build Command Implementation
-- ============================================================================

-- | Execute the build phase
executeBuild :: BuildPhaseInput -> IO (Either String BuildPhaseOutput)
executeBuild input = do
  -- Validate input
  case validateBuildInput input of
    Left err -> return $ Left err
    Right () -> do
      -- Load configuration
      cfg <- loadConfigOrDie (bpiConfigFile input)
      
      -- Validate config
      case validateConfig cfg of
        Left err -> return $ Left err
        Right () -> do
          -- Build transaction
          buildTransaction input cfg

-- | Validate build input
validateBuildInput :: BuildPhaseInput -> Either String ()
validateBuildInput input = do
  if bpiPrincipal input <= 0
    then Left "Principal must be positive"
    else Right ()
  
  if bpiTermDays input <= 0
    then Left "Term days must be positive"
    else Right ()
  
  if bpiInterestRate input < 0 || bpiInterestRate input > 100
    then Left "Interest rate must be between 0 and 100"
    else Right ()

-- | Build transaction body
buildTransaction :: BuildPhaseInput -> Config -> IO (Either String BuildPhaseOutput)
buildTransaction input cfg = do
  -- In a real implementation, this would call cardano-cli or use a library
  -- For now, we'll simulate it
  
  let txHash = generateTxHash input
  let txFee = calculateFee cfg input
  let txBodyHex = generateTxBodyHex input cfg
  
  return $ Right BuildPhaseOutput
    { bpoTxBodyHex = txBodyHex
    , bpoTxHash = txHash
    , bpoFee = txFee
    }

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- | Generate a mock transaction hash
generateTxHash :: BuildPhaseInput -> Text
generateTxHash input = 
  let principal = T.pack $ show (bpiPrincipal input)
      term = T.pack $ show (bpiTermDays input)
  in hashText (principal <> term <> T.pack (show (bpiInterestRate input)))

-- | Generate mock transaction body hex
generateTxBodyHex :: BuildPhaseInput -> Config -> Text
generateTxBodyHex input cfg =
  let borrower = bpiBorrowerAddress input
      lender = bpiLenderAddress input
      principal = T.pack $ show (bpiPrincipal input)
  in "0x" <> hashText (borrower <> lender <> principal)

-- | Calculate transaction fee
calculateFee :: Config -> BuildPhaseInput -> Integer
calculateFee cfg input =
  let pp = cfgProtocolParams cfg
      baseSize = 500  -- estimated tx size in bytes
      fee = (ppMinFeeA pp) * baseSize + (ppMinFeeB pp)
  in fee

-- | Simple hash function (for demonstration)
hashText :: Text -> Text
hashText t = 
  let bytes = TE.encodeUtf8 t
      hash = show (BS.length bytes `mod` 1000000)
  in T.pack $ take 64 (hash ++ repeat '0')

-- ============================================================================
-- Output Formatting
-- ============================================================================

-- | Format build output as JSON
formatBuildOutput :: BuildPhaseOutput -> Value
formatBuildOutput output = object
  [ "phase" .= String "BUILD"
  , "status" .= String "success"
  , "txBody" .= bpoTxBodyHex output
  , "txHash" .= bpoTxHash output
  , "fee" .= bpoFee output
  ]

-- | Format build error as JSON
formatBuildError :: String -> Value
formatBuildError err = object
  [ "phase" .= String "BUILD"
  , "status" .= String "error"
  , "error" .= String (T.pack err)
  ]
