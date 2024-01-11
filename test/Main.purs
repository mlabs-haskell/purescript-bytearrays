module Test.Main where

import Prelude

import Data.ByteArray
  ( ByteArray
  , byteArrayFromIntArray
  , byteArrayFromIntArrayUnsafe
  , byteArrayToHex
  , byteArrayToIntArray
  , hexToByteArray
  )
import Data.Maybe (Maybe(Just))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Test.QuickCheck (quickCheck, (===))
import Test.QuickCheck.Laws.Data.Eq (checkEq)
import Test.QuickCheck.Laws.Data.Monoid (checkMonoid)
import Test.QuickCheck.Laws.Data.Ord (checkOrd)
import Test.QuickCheck.Laws.Data.Semigroup (checkSemigroup)
import Test.Spec (describe, it)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)
import Type.Proxy (Proxy(Proxy))

main :: Effect Unit
main = do
  launchAff_ $ runSpec [ consoleReporter ] do
    describe "ByteArray" do
      it "Eq instance" $ liftEffect do
        checkEq (Proxy :: Proxy ByteArray)
      it "Ord instance" $ liftEffect do
        checkOrd (Proxy :: Proxy ByteArray)
      it "Semigroup instance" $ liftEffect do
        checkSemigroup (Proxy :: Proxy ByteArray)
      it "Monoid instance" $ liftEffect do
        checkMonoid (Proxy :: Proxy ByteArray)
      it "hexToByteArray <<< byteArrayToHex = Just" $ liftEffect do
        quickCheck \bytes ->
          hexToByteArray (byteArrayToHex bytes) === Just bytes
      it "byteArrayFromIntArrayUnsafe <<< byteArrayToIntArray = id" $ liftEffect
        do
          quickCheck \bytes ->
            byteArrayFromIntArrayUnsafe (byteArrayToIntArray bytes) === bytes
      it "byteArrayFromIntArray <<< byteArrayToIntArray = Just" $ liftEffect do
        quickCheck \bytes ->
          byteArrayFromIntArray (byteArrayToIntArray bytes) === Just bytes
