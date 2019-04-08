{-# LANGUAGE DeriveGeneric #-}

module Logger
  ( initLogger
  , createWriter
  , LogLevel(..)
  , Logger
  , LogWriter
  ) where

import           Control.Exception
import           Data.Aeson
import           GHC.Generics
import           System.IO

data Logger =
  Logger (LogLevel -> String -> String)
         Handle

type LogWriter = (LogLevel, String) -> IO ()

type LoggerOrError = Either String Logger

data LogLevel
  = Debug
  | Warnings
  | Errors
  deriving (Eq, Ord, Generic)

instance Show LogLevel where
  show Debug    = "[ DEBUG ]: "
  show Warnings = "[WARNING]: "
  show Errors   = "[ ERROR ]: "

instance FromJSON LogLevel

instance ToJSON LogLevel

initLogger :: FilePath -> LogLevel -> IO LoggerOrError
initLogger "STDOUT" logLvl = return . pure $ createLogger stdout logLvl
initLogger path logLvl = io `catch` handler
  where
    handler :: IOError -> IO LoggerOrError
    handler e = return $ Left $ show e
    io = do
      h <- openFile path AppendMode
      return . Right $ createLogger h logLvl

createWriter :: Logger -> LogWriter
createWriter (Logger lgr handle) (lvl, msg) = hPutStr handle $ lgr lvl msg

createLogger :: Handle -> LogLevel -> Logger
createLogger out loggerLevel = Logger logger out
  where
    logger logLevel message
      | logLevel >= loggerLevel = show logLevel ++ message ++ "\n"
      | otherwise = []
