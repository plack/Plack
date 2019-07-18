#!/usr/bin/python
from __future__ import print_function
import os

print("Content-Type: text/plain")
print
for item in ([ "foo", "bar" ]):
    print("Hello " + item + ". ")

print("QUERY_STRING is " + os.environ['QUERY_STRING'])
