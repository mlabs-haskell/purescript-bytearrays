-- | A wrapper over `Uint8Array` with extra utility functions
module Data.ByteArray
  ( ByteArray(ByteArray)
  , byteArrayFromIntArray
  , byteArrayFromIntArrayUnsafe
  , byteArrayFromInt16ArrayUnsafe
  , byteArrayFromAscii
  , byteArrayToHex
  , byteArrayToIntArray
  , byteLength
  , hexToByteArray
  , hexToByteArrayUnsafe
  , byteArrayToUTF16le
  , subarray
  ) where

import Prelude

import Data.ArrayBuffer.Types (Uint8Array)
import Data.Char (toCharCode)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Newtype (class Newtype)
import Data.String.CodeUnits (toCharArray)
import Data.Traversable (for)
import Test.QuickCheck.Arbitrary
  ( class Arbitrary
  , class Coarbitrary
  , arbitrary
  , coarbitrary
  )

newtype ByteArray = ByteArray Uint8Array

derive instance Newtype ByteArray _

instance Show ByteArray where
  show arr = "(hexToByteArrayUnsafe " <> show (byteArrayToHex arr)
    <> ")"

instance Eq ByteArray where
  eq a b = compare a b == EQ

instance Ord ByteArray where
  compare = \xs ys -> compare 0 (ord_ toDelta xs ys)
    where
    toDelta x y =
      case compare x y of
        EQ -> 0
        LT -> 1
        GT -> -1

instance Semigroup ByteArray where
  append = concat_

instance Monoid ByteArray where
  mempty = byteArrayFromIntArrayUnsafe []

foreign import ord_ :: (Int -> Int -> Int) -> ByteArray -> ByteArray -> Int

foreign import concat_ :: ByteArray -> ByteArray -> ByteArray

foreign import byteArrayToHex :: ByteArray -> String

foreign import hexToByteArray_
  :: (forall (a :: Type). Maybe a)
  -> (forall (a :: Type). a -> Maybe a)
  -> String
  -> Maybe ByteArray

-- | Input string must consist of hexadecimal numbers.
-- | Length of the input string must be even (2 characters per byte).
hexToByteArray :: String -> Maybe ByteArray
hexToByteArray = hexToByteArray_ Nothing Just

-- | Characters not in range will be converted to zero.
foreign import hexToByteArrayUnsafe :: String -> ByteArray

-- | Overflowing integers will be silently accepted modulo 256.
foreign import byteArrayFromIntArrayUnsafe :: Array Int -> ByteArray

foreign import byteArrayFromIntArray_
  :: (forall (a :: Type). Maybe a)
  -> (forall (a :: Type). a -> Maybe a)
  -> Array Int
  -> Maybe ByteArray

-- | A safer version of `byteArrayFromIntArrayUnsafe` that checks that elements are in range 0-255.
byteArrayFromIntArray :: Array Int -> Maybe ByteArray
byteArrayFromIntArray = byteArrayFromIntArray_ Nothing Just

foreign import byteArrayToIntArray :: ByteArray -> Array Int

foreign import byteLength :: ByteArray -> Int

-- | Given a begin offset (inclusive) and end offset (exclusive), efficiently
-- | create a new `ByteArray` backed by the same underlying buffer.
foreign import subarray :: Int -> Int -> ByteArray -> ByteArray

instance Arbitrary ByteArray where
  arbitrary = byteArrayFromIntArrayUnsafe <$> arbitrary

instance Coarbitrary ByteArray where
  coarbitrary bytes generator = coarbitrary (byteArrayToIntArray bytes)
    generator

-- | Convert characters in range `0-255` into a `ByteArray`.
-- | Fails with `Nothing` if there are characters out of this range in a string.
byteArrayFromAscii :: String -> Maybe ByteArray
byteArrayFromAscii str = do
  byteArrayFromIntArrayUnsafe <$> for (toCharArray str) \cp -> do
    let charCode = toCharCode cp
    if charCode <= 255 && charCode >= 0 then pure charCode
    else Nothing

foreign import byteArrayFromInt16ArrayUnsafe :: Array Int -> ByteArray

foreign import byteArrayToUTF16le :: ByteArray -> String
