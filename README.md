# Zebra [![Build Status](https://travis-ci.org/wstyres/Zebra.svg?branch=master)](https://travis-ci.org/wstyres/Zebra) [![Crowdin](https://badges.crowdin.net/zebra/localized.svg)](https://translate.getzbra.com/project/zebra) [![Latest release](https://badge.fury.io/gh/wstyres%2FZebra.svg)](https://github.com/wstyres/Zebra)
Zebra (née AUPM) is a Package Manager for jailbroken iOS devices. It is built to support iOS 9 up to iOS 13 and for iPhones and iPads alike.

## Translations

Zebra supports localization, but help is needed in order to translate Zebra!

If you are familiar with a language that is not currently supported by Zebra (you can check out a list of currently supported languages on [Crowdin](https://translate.getzbra.com/)), you can help us out by translating Zebra into your language. There are three ways to do this:

1. The easiest and preferred method is by using Crowdin.
   1. If you want to add support for a new language to Zebra. First, file an issue [here](https://github.com/wstyres/Zebra/issues/new?assignees=&labels=localization&template=localization-support.md&title=%5BLocalize%5D) and tell us for which language you'd like to add support. Once we add it to Crowdin, you can start translating strings at [https://translate.getzbra.com/](https://translate.getzbra.com/)
   2. If you want to update a language already in Zebra and correct some issues, head over to [https://translate.getzbra.com/](https://translate.getzbra.com/), select your language, and update the new translations.

2. If you do not know how to use Xcode or are not able to use Xcode, you can download Zebra's strings from [here](https://raw.githubusercontent.com/wstyres/Zebra/master/Zebra/Base.lproj/Localizable.strings) and translate them one-by-one. The English strings are on the left side while the strings that needed to be translated are placed on the right side. Once you are done, you can [file an issue](https://github.com/wstyres/Zebra/issues/new?assignees=&labels=localization&template=localization-support.md&title=%5BLocalize%5D) with a link to your translated Localizable.strings, and we will review it for inclusion in Zebra.

3. If you are comfortable using Xcode, you can add a new language to the Zebra project, translate all of the strings (located in the Base.lproj folder), and then submit a [Pull Request](https://github.com/wstyres/Zebra/compare) with your translated .strings file and we will review it for inclusion in Zebra.

If there is a language that has an inaccurate translation that is already supported by Zebra, you can [locate the .strings file](https://github.com/wstyres/Zebra/tree/master/Zebra/Base.lproj) and edit it directly from GitHub and create a new Pull Request. It will be reviewed for inclusion in Zebra.

New strings may be added in future Zebra versions from time to time, so it is important to keep a lookout for modified strings!

## Bug Reports
The best way to report a bug with Zebra is to open an issue [here](https://github.com/wstyres/Zebra/issues/new?assignees=wstyres&labels=bug&template=bug_report.md&title=).

Fill out the required fields to the best of your ability in order to have a better chance of getting your issue fixed.

I may require some additional information in order to isolate the issue in question and may ask for your response. Your help is appreciated.

You must create a GitHub account to create an issue. If you do not have one, it is free to create one by signing up, or you can email me your bug report from within Zebra.

## Feature Requests
Feature requests are welcome as well and are also tracked through GitHub issues [here](https://github.com/wstyres/Zebra/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=).

Fill out the required fields to the best of your ability (mockups, screenshots, descriptions, etc.).

You must create a GitHub account to create an issue. If you do not have one, it is free to create one by signing, up or you can email me your feature request from within Zebra.

## Pull Requests
Pull requests to fix bugs, add new features, and fix awful code (I'm sure there is a lot) are also very welcome, and I'm happy to work with you in order to get your PR into Zebra.

## Installation
#### From an APT Repo
Zebra is available from Zebra's APT repo for iOS located [here](https://getzbra.com/repo).

This source can be added to any package manager on your iPhone or iPad, and it is included by default with Zebra to provide future updates.

Zebra also has a beta repository that contains builds for beta testers to try out new features and report potential problems you can add Zebra's beta APT repo for iOS located [here](https://getzbra.com/beta).

#### Pre-compiled debs
Pre-compiled debs are available via [GitHub releases](https://github.com/wstyres/Zebra/releases) if that is your fancy.

#### Using Xcode & theos
If you want to compile Zebra yourself, you can use the following steps. A computer running macOS is _required_ and must have Xcode installed.

1. Clone this repository using `git clone --recursive https://github.com/wstyres/Zebra.git`
2. `cd` into the `Zebra` folder
3. (One time only) Install `xcpretty` if you haven't already via `sudo gem install xcpretty`
4. run `make do` (If you don't have `theos` already installed on your computer, follow the steps located [here](https://github.com/theos/theos/wiki/Installation))
5. Done!
