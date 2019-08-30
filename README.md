# Zebra [![Build Status](https://travis-ci.org/wstyres/Zebra.svg?branch=master)](https://travis-ci.org/wstyres/Zebra)
Zebra (neé AUPM) is a Package Manager for jailbroken iOS devices. It is built to support iOS 9 up to iOS 12 and for iPhones and iPads alike.

## Bug Reports
The best way to report a bug with Zebra is to open an issue [here](https://github.com/wstyres/Zebra/issues/new?assignees=wstyres&labels=bug&template=bug_report.md&title=).

Fill out the required fields as best that you can in order to have a better chance at getting your issue fixed.

I may require some additional information in order to isolate the issue in question and may ask for your response. Your help is appreciated.

You must create a GitHub account to create an issue. If you do not have one, it is free to create one by signing up or you can email me.

## Feature Requests
Feature request are welcome as well and are also tracked through GitHub issues [here](https://github.com/wstyres/Zebra/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=).

Fill out the required fields to the best of your ability (mockups, screenshots, descriptions, etc.).

You must create a GitHub account to create an issue. If you do not have one, it is free to create one by signing up or you can email me.

## Pull Requests
Pull requests to fix bugs, add new features, and fix awful code (I'm sure there is a lot) are also very welcome and I'm happy to work with you in order to get your PR into Zebra.

## Installation
#### From an APT Repo
Zebra is available from my personal APT repo for iOS located [here](https://xtm3x.github.io/repo).

This source can be added to Cydia on your iPhone or iPad and it is included by default with Zebra to provide future updates.

#### Pre-compiled debs
Pre-compiled debs are available via GitHub [releases](https://github.com/wstyres/Zebra/releases), if that is your fancy.

#### Using Xcode & theos
If you want to compile Zebra yourself, you can use the following steps. A computer running macOS is _required_ and must have Xcode installed.

1. Clone this repository using `git clone https://github.com/wstyres/Zebra.git`
2. `cd` into the `Zebra` folder
3. run `make do`
   1. If you don't have `theos` already installed on your computer, follow the steps located [here](https://github.com/theos/theos/wiki/Installation).
4. Done!
