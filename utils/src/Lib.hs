{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}

module Lib
  ( releaseInfo
  , Uptime(..)
  , parseUptime
  , uptimeInfo
  , DiskInfo
  , spaceInfo
  , uncompress_
  , compress
  , navigateParent
  , deployFish
  , syncFish
  , syncEmacs
  , deployEmacs
  , initializeSystem
  , syncXMonad
  , deployXMonad
  , deployBash
  ) where

import Data.Conduit.Shell hiding (strip)
import qualified Data.Conduit.Shell as S
import Data.Conduit.Shell.Segments (strings, texts)
import Data.List.Split (splitOn)
import Data.String.Utils (strip)
import Data.Bits.Utils (c2w8)
import Data.Monoid ((<>))
import Data.Char (isAlpha, isSpace, isPunctuation, digitToInt)
import qualified Data.Text.IO as TIO
import Data.Text (Text, pack)
import Data.Attoparsec.Text hiding (take)
import Data.Word
import Data.List (isSuffixOf, intersperse)
import System.Directory
       (doesDirectoryExist, getHomeDirectory, doesFileExist,
        createDirectoryIfMissing)
import System.FilePath
import Data.Conduit (await)
import Data.Conduit.Binary (sourceFile)
import qualified Data.Conduit.Binary as C
import Control.Monad.Trans.Resource
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8
import Control.Monad.IO.Class (liftIO)

releaseInfo :: IO ()
releaseInfo = do
  (val1 :: [String]) <- run $ strings $ lsbRelease ["-i"]
  let distro = getData val1
  (val2 :: [String]) <- run $ strings $ lsbRelease "-r"
  let version = getData val2
  putStrLn (distro <> " " <> version)
  where
    getData val =
      let xs = splitOn ":" (head val)
      in strip $ last xs

data Uptime = Uptime
  { hour :: Word8
  , mins :: Word8
  } deriving (Show, Eq)

parseUptime :: Parser Uptime
parseUptime = do
  skipWhile (\x -> isAlpha x || isSpace x)
  hour <- decimal
  skipWhile (\x -> isAlpha x || isSpace x || isPunctuation x)
  min <- decimal
  return $ Uptime hour min

uptimeInfo :: IO ()
uptimeInfo = do
  (val :: [Text]) <- run $ texts $ uptime "-p"
  case maybeResult (parse parseUptime (head val)) of
    Nothing -> putStrLn ""
    Just inf -> putStrLn (show (hour inf) <> "h" <> show (mins inf) <> "m")

data DiskInfo = DiskInfo
  { fsystem :: Text
  , diSize :: Text
  , diUsed :: Text
  , diAvail :: Text
  , diUse :: Text
  , diMountPoint :: Text
  } deriving (Show, Eq)

parseDiskInfo :: Parser DiskInfo
parseDiskInfo = do
  fsystem <- takeTill isSpace
  skipSpace
  diSize <- takeTill isSpace
  skipSpace
  diUsed <- takeTill isSpace
  skipSpace
  diAvail <- takeTill isSpace
  skipSpace
  diUse <- takeTill isSpace
  skipSpace
  diMountPoint <- takeText
  return
    DiskInfo
    { ..
    }

spaceInfo :: IO ()
spaceInfo = do
  (val :: [Text]) <- run $ texts $ df "-h" ["/home"]
  case parseOnly parseDiskInfo (last val) of
    Left _ -> putStrLn ""
    Right inf -> TIO.putStrLn $ (diAvail inf) <> (pack " ") <> (diUse inf)

getExtension :: FilePath -> Maybe String
getExtension fname =
  case (filter (\x -> isSuffixOf x fname) (doubleExts <> singleExts)) of
    [] -> Nothing
    (x:_) -> Just x
  where
    doubleExts = ["tar.bz2", "tar.gz"]
    singleExts = ["rar", "gz", "tar", "tbz2", "bz2", "tgz", "zip"]

uncompress_ :: FilePath -> IO ()
uncompress_ fname =
  case (getExtension fname) of
    Nothing -> putStrLn "file format not supported"
    Just xs ->
      run $
      case xs of
        "tar.bz2" -> tar "xvjf" fname
        "tar.gz" -> tar "xvzf" fname
        "rar" -> unrar "x" fname
        "gz" -> gunzip fname
        "tar" -> tar "xvf" fname
        "tbz2" -> tar "xvjf" fname
        "tgz" -> tar "xvzf" fname
        "zip" -> S.unzip' fname

compress :: FilePath -> IO ()
compress fname = run $ tar "-czvf" (fname <> ".tar.gz") fname

navigateParent :: Int -> IO ()
navigateParent level =
  if (level <= 2)
    then return ()
    else cd dir
  where
    dots = take (level - 1) $ repeat ".."
    dir = concat $ intersperse "/" dots

dotfilesDir :: IO FilePath
dotfilesDir = do
  hdir <- getHomeDirectory
  return $ hdir </> "github/dotfiles"

deployFish :: IO ()
deployFish = do
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  exist <- doesDirectoryExist dotDir
  let filesDep = [dotDir </> ".config" </> "fish" </> "config.fish"]
      dirsDep = [dotDir </> ".config" </> "fish" </> "functions"]
      fishDir = hdir </> ".config" </> "fish"
  case exist of
    True ->
      run $
      do mapM_ (\x -> cp "-v" x fishDir) filesDep
         mapM_ (\x -> cp "-rv" x fishDir) dirsDep
    False -> putStrLn "Error: dotfiles in invalid location"

syncFish :: IO ()
syncFish = do
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  exists <- doesDirectoryExist dotDir
  let files = ["config.fish"]
      dirs = ["functions"]
      fishDir = hdir </> ".config" </> "fish"
      fishDotDir = dotDir </> ".config" </> "fish"
  case exists of
    True ->
      run $
      do mapM_ (\x -> cp "-v" (fishDir </> x) fishDotDir) files
         mapM_ (\x -> cp "-vr" (fishDir </> x) fishDotDir) dirs
    False -> putStrLn "Error: dotfiles in invalid location"

removeFileIfExists :: FilePath -> IO ()
removeFileIfExists fname = do
  exist <- doesFileExist fname
  case exist of
    True -> run $ rm "-v" fname
    False -> return ()

removeDirectoryIfExists :: FilePath -> IO ()
removeDirectoryIfExists fname = do
  exist <- doesDirectoryExist fname
  case exist of
    True -> run $ rm "-vr" fname
    False -> return ()

initializeSystem :: IO ()
initializeSystem = do
  let files =
        [ ".alias"
        , ".global_ignore"
        , ".screenrc"
        , ".ghci"
        , ".Xmodmap"
        , ".Xresources"
        , ".xmobarrc"
        , ".xsession"
        ]
  hdir <- getHomeDirectory
  dotDir <- dotfilesDir
  mapM_ (\x -> removeFileIfExists (hdir </> x)) files
  mapM_ (\x -> run $ cp "-v" (dotDir </> x) hdir) files

deployEmacs :: IO ()
deployEmacs = do
  let files =
        [ "haskell.el"
        , "python.el"
        , "web.el"
        , "init.el"
        , "sibi-utils.el"
        , "sml.el"
        ]
  let emacsDir = ".emacs.d"
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  createDirectoryIfMissing False emacsDir
  mapM_ (\x -> run $ cp "-v" (dotDir </> emacsDir </> x) (hdir </> emacsDir)) files

syncEmacs :: IO ()
syncEmacs = do
  let files =
        [ "haskell.el"
        , "python.el"
        , "web.el"
        , "init.el"
        , "sibi-utils.el"
        , "sml.el"
        ]
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  mapM_
    (\x -> run $ cp "-v" (hdir </> ".emacs.d" </> x) (dotDir </> ".emacs.d"))
    files

deployXMonad :: IO ()
deployXMonad = do
  let xmonadDir = ".xmonad"
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  createDirectoryIfMissing False (hdir </> xmonadDir)
  run $ cp "-v" (dotDir </> xmonadDir </> "*") (hdir </> xmonadDir)

syncXMonad :: IO ()
syncXMonad = do
  let xmonadDir = ".xmonad"
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  run $ cp "-v" (hdir </> xmonadDir </> "*") (dotDir </> xmonadDir)

contentInFile :: (MonadResource m) => Consumer BS.ByteString m Bool
contentInFile = do
  (bs :: Maybe BS.ByteString) <- await
  let match = B8.pack "source ~/github/dotfiles/.bashrc"
  case bs of
    Nothing -> return False
    Just bs' -> case (BS.isSuffixOf match bs') of
                  True -> return True
                  False -> contentInFile

deployBash :: IO ()
deployBash = do
  dotDir <- dotfilesDir
  hdir <- getHomeDirectory
  let bashFile = ".bashrc"
  val <- runConduitRes $ sourceFile (hdir </> bashFile) .| C.lines .| contentInFile
  case val of
    True -> return ()
    False -> do
             appendFile (hdir </> bashFile) "source ~/github/dotfiles/.bashrc"
             putStrLn (bashFile <> " modified")

