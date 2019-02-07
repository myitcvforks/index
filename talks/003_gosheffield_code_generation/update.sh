#!/usr/bin/env bash

set -e

gobin -m -run myitcv.io/cmd/mdreplace -long -online source.md | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba' > ~/gostuff/src/github.com/myitcv/talks/2019-02-07-code-generation/main.slide
rsync -i -a --exclude .DS_Store /home/myitcv/MacHomeDir/Desktop/code-generation/ /home/myitcv/gostuff/src/github.com/myitcv/talks/2019-02-07-code-generation/images/
