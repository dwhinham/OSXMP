## OSXMP (working title) [![Build Status](https://travis-ci.org/dwhinham/OSXMP.svg?branch=master)](https://travis-ci.org/dwhinham/OSXMP)
Scenemusic player for Macintosh.

Currently in very early stages.
It plays, it stops, it has a rudimentary playlist and a PatternScope. Nothing else yet.

### Supported file formats
  * Any tracker format [libxmp](http://xmp.sourceforge.net) supports (most common ProTracker/FastTracker/ImpulseTracker etc.)
  * [DigiBooster](http://www.digibooster.de)
  * [AHX/HivelyTracker](http://www.hivelytracker.co.uk)

### Building OSXMP
OSXMP depends on the following libraries:
  * libdigibooster3 (included as a submodule)
  * freetype2
  * glm
  * libxmp
  * TPCircularBuffer (included as a submodule)
  * yaml-cpp

After cloning this repo, pull the submodules like so:

    git submodule init
    git submodule update

For the remaining libraries, the easiest way to get them is via [Homebrew](http://brew.sh):

    brew install freetype libxmp yaml-cpp

You should then be able to build the provided Xcode project.
