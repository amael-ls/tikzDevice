#!/usr/bin/env runghc
{-
A simple script to reformat Markdown into an Rdoc NEWS file. Written in Haskell
because... well just because.

WARNING: Prolonged exposure to Haskell can cause your head to explode.
-}

import System.Environment -- For accessing program arguments
import Data.Maybe         -- For handling values that may or may not be values

import Text.Pandoc
import Text.Pandoc.Readers.Markdown


{-
This function takes the result of a Pandoc parser, extracts the contents,
formats them into Rd strings and returns a list of the results.
-}
pandocToRd :: Pandoc -> [String]
-- mapMaybe is like a regular functional mapping except it throws out Nothing
-- values and unpacks Just values.
pandocToRd parsed = mapMaybe blockToRd (getBlocks parsed)


{-
This function extracts the "block list" from the Pandoc object returned by
Pandoc readers such as `readMarkdown`.

More information about the structure of the block list can be found in the
documentation of the pandoc-types package:

  http://hackage.haskell.org/packages/archive/pandoc-types/1.8/doc/html/Text-Pandoc-Definition.html
-}
getBlocks :: Pandoc -> [Block]
getBlocks (Pandoc meta blocks) = blocks

{-
This function is responsible for possibly formatting each block element into a
string. Some block types are ignored and so the value Nothing is returned.
-}
blockToRd :: Block -> Maybe String
-- Individual block types
blockToRd (Plain elements) = Just $ concat $ inlineListToRd elements
blockToRd (Para elements) = Just $ concat $ inlineListToRd elements
blockToRd (Header level elements) = case level of
  1 -> Just $ "\\section{" ++ (concat $ inlineListToRd elements) ++ "}"
  2 -> Just $ "\\subsection{" ++ (concat $ inlineListToRd elements) ++ "}"
  _ -> Nothing -- Rdoc only has 2 header levels. Silently ignoring anything else
blockToRd (BulletList blocks) = do
  let makeListItem list = "\n\t\\item{\n\t\t" : list ++ ["\n\t}"]
  Just $ "\\itemize{" ++ (concat $ map (concat . makeListItem . blockListToRd) blocks) ++ "\n}"
blockToRd HorizontalRule = Nothing
blockToRd Null = Nothing
-- Passed through uninterpreted for now
blockToRd other = Just $ show other

blockListToRd :: [Block] -> [String]
blockListToRd blocks = mapMaybe blockToRd blocks

inlineListToRd :: [Inline] -> [String]
inlineListToRd elements = mapMaybe inlineToRd elements

{-
This function is responsible for possibly formatting inline elements into a
string
-}
inlineToRd :: Inline -> Maybe String
inlineToRd (Str string) = Just string
inlineToRd (Code attr string) = Just $ "\\code{" ++ string ++ "}"
inlineToRd Space = Just " "
inlineToRd other = Just $ show other


{- Main Script -}
main :: IO()
main = do
  input_file <- fmap (!! 0) (getArgs)
  parsed_markdown <- fmap (readMarkdown defaultParserState) (readFile input_file)
  let results = pandocToRd parsed_markdown
  -- The unlines function joins a list of strings into one big string using
  -- newlines
  writeFile "NEWS.Rd" $ unlines results
  putStrLn "Output written to NEWS.Rd"

