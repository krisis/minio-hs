#!/usr/bin/env stack
-- stack --resolver lts-6.27 runghc --package minio-hs --package optparse-applicative --package filepath

--
-- Minio Haskell SDK, (C) 2017 Minio, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--


{-# Language OverloadedStrings, ScopedTypeVariables #-}
import Network.Minio

import Control.Monad.Catch (catch)
import Control.Monad.IO.Class (liftIO)
import Options.Applicative
import Prelude
import System.FilePath.Posix
import Data.Text (pack)

-- | The following example uses minio's play server at
-- https://play.minio.io:9000.  The endpoint and associated
-- credentials are provided via the libary constant,
--
-- > minioPlayCI :: ConnectInfo
--

-- optparse-applicative package based command-line parsing.
fileNameOpts :: Parser FilePath
fileNameOpts = strOption
               (long "filename"
                <> metavar "FILENAME"
                <> help "Name of file to upload to AWS S3 or a Minio server")

cmdParser = info
            (helper <*> fileNameOpts)
            (fullDesc
             <> progDesc "FileUploader"
             <> header
             "FileUploader - a simple file-uploader program using minio-hs")


main :: IO ()
main = do
  let bucket = "my-bucket"

  -- Parse command line argument, namely --filename.
  filepath <- execParser cmdParser
  let object = pack $ takeBaseName filepath

  res <- runResourceT $ runMinio minioPlayCI $ do
    -- Make a bucket; catch bucket already exists exception if thrown.
    catch
      (makeBucket bucket Nothing)
      (\(_ :: MError) -> liftIO $ putStrLn "Bucket already exists, proceeding with upload file.")

    -- Upload filepath to bucket; object is derived from filepath.
    fPutObject bucket object filepath

  case res of
    Left e -> putStrLn $ "file upload failed due to " ++ (show e)
    Right () -> putStrLn "file upload succeeded."
