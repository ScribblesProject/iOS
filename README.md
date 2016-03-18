# TAMS iOS App

## Compile Requirements

1. XCode
2. Cocoapods - This project uses Cocoapods for better dependency management. For more information, see the CocoaPods section below.

## Compile Instructions

1. Open `TAMS.xcworkspace`
2. Things should compile at this point, however to get the app working properly, an api endpoint is necessary. So modify the api `BASE` url at the top of `BackendAPI.swift` to reflect the current api url host. 

If you have issues with the compiling the pods, see below.

## CocoaPods

To install: In terminal, type  `brew install cocoapods`

**NOTE**: I have included the pods folder in the repo, so things *should* just compile without any additional work. 

If you have issues compiling, you may want to update the pods. To do this, navigate to the project folder in terminal and type `pod install`