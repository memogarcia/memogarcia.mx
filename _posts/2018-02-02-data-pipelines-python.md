---
layout: post
title:  "Creating data pipelines with python"
date:   2018-02-02 14:22:38 +0100
categories:
---

While continuing exploring python's simplicity we came across with `generators`, python's way to process data "on the fly".

The conventional way of processing data in python is by using `iterators`, python objects that can be iterated, a list, a string, etc. The downsize of iterators is that it has to hold its elements in memory and thus, is restricted by the physical amount of memory in your system.

This is an iterator example that returns a list of files.

```python
import os


def list_files(path):
    files = []
    for root, dirs, files in os.walk(".", topdown=False):
        for name in files:
            files.append(os.path.join(root, name))
    return files
```

Notice 2 behaviors here: To consume the list of files you have to wait until the functions returns and the list of files is being held in memory.

This is where generators come handy, it allows python to work with data in chunks of data rather than with the whole and gives you the ability to develop data pipelines where your data can be processed as is being read.

```python
import os


def list_files(path):
    for root, dirs, files in os.walk(".", topdown=False):
        for name in files:
            yield os.path.join(root, name)


def consume_files():
    for file in list_files('/tmp'):
        # do something with a single element
        print(file)
```

With this example, we can start to consume data as soon as available with one restriction, once the data is consumed python will forget about it while consuming less memory it might be an issue if some of the data is not processed correctly.

Here is a more complex example of data processing using generators where we find for a keyword is a list of files.

```python
import bz2
import fnmatch
import gzip
import os
import re


def find():
    '''
    Find all filenames in a directory tree that match a shell wildcard pattern
    '''
    for path, dirlist, filelist in os.walk(top):
        for name in fnmatch.filter(filelist, filepat):
            yield os.path.join(path,name)


def opener(filenames):
    '''
    Open a sequence of filenames one at a time producing a file object.
    The file is closed immediately when proceeding to the next iteration.
    '''
    for filename in filenames:
        if filename.endswith('.gz'):
            f = gzip.open(filename, 'rt')
        elif filename.endswith('.bz2'):
            f = bz2.open(filename, 'rt')
        else:
            f = open(filename, 'rt')
        yield f
        f.close()


def concatenate(iterators):
    '''
    Chain a sequence of iterators together into a single sequence.
    '''
    for it in iterators:
        yield from it


def grep(pattern, lines):
    '''
    Look for a regex pattern in a sequence of lines
    '''
    pat = re.compile(pattern)
    for line in lines:
        if pat.search(line):
            yield line


if __name__ == '__main__':
    lognames = find('*.log*', '/var/log/')
    files = opener(lognames)
    lines = concatenate(files)
    pylines = grep('(?i)python', lines)
    for line in pylines:
        print(line)
```