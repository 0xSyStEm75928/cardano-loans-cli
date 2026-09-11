{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import CLI.Parser (parseCommand)
import CLI.Runner (runCommand)

main :: IO ()
main = do
  cmd <- parseCommand
  runCommand cmd
