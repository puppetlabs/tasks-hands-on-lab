#! /usr/bin/python

import os
import json


def split_line(line):
    split = line.split()
    return { "name": split[1], "version": split[2], "arch": split[3] }

command = 'dpkg -l %s | grep "^ii"' % os.getenv("PT_package")

lines = os.popen(command).read().split('\n')

pkgs = [ split_line(line) for line in lines if len(line) > 0]
print json.dumps({ "result": pkgs})
