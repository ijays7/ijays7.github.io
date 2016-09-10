#!/bin/bash

ps aux |grep jekyll |awk '{print $2}' | xargs kill -9
cd /path/to/blog
jekyll serve --watch &