{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}

module Graphics.Formats.STL.Parser where

import           Prelude                          hiding (takeWhile)

import           Data.Attoparsec.ByteString.Char8 (Parser, inClass, many',
                                                   rational, skipSpace, string,
                                                   takeWhile)
import qualified Data.Attoparsec.ByteString.Char8 as P
import qualified Data.ByteString                  as BS

import           Graphics.Formats.STL.Types       (STL (STL),
                                                   Triangle (Triangle), Vector,
                                                   triple)

loadSTL :: FilePath -> IO (Either String STL)
loadSTL f = P.parseOnly stlParser <$> BS.readFile f

mustLoadSTL :: FilePath -> IO STL
mustLoadSTL f = loadSTL f >>= \case
    Left err -> fail err
    Right ok -> return ok

-- | A parser from 'Text' to the @STL@ type.  The parser should be
-- fairly permissive about whitespace, but has not been tested enough
-- against STL files in the wild.
stlParser :: Parser STL
stlParser = STL <$> nameParser <*> many' triangle

nameParser :: Parser BS.ByteString
nameParser = text "solid" *> takeWhile (inClass " -~") <* skipSpace

triangle :: Parser Triangle
triangle = Triangle <$> ss normalParser <*> loop <* text "endfacet"

loop :: Parser (Vector, Vector, Vector)
loop = triple <$> (text "outer loop" *> ss vertex) <*> ss vertex <*> ss vertex <* text "endloop"

normalParser :: Parser (Maybe Vector)
normalParser = text "facet" *> text "normal" *> do
    n <- v3
    return $ case n of
        (0, 0, 0) -> Nothing
        _         -> Just n

vertex :: Parser Vector
vertex = text "vertex" *> v3

v3 :: Parser Vector
v3 = triple <$> ss float <*> ss float <*> ss float

ss :: Parser a -> Parser a
ss p = p <* skipSpace

text :: BS.ByteString -> Parser BS.ByteString
text t = string t <* skipSpace

float :: Parser Float
float = rational
