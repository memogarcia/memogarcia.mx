---
layout: post
title:  "Using python to glue everything"
date:   2017-10-21 14:22:38 +0100
categories:
---

Bash is powerful but so is Python. And sometimes you need the best of both.

In order to do that, Python allows you to pipe in and out data from stdin which is quite powerful and elegant.

This is a very basic example but it demostrates the capabilities you can get by combining both.

First, create a `python` script that will read data from stdin.

```python
#!/usr/bin/env python3
import fileinput

with fileinput.input() as f_input:
    for line in f_input:
        print(line, end='')
```

Save it as `piping.py` and give it execution permissions.

```bash
chmod +x piping.py
```

By using fileinput you get for "free" the following functionality:

```bash
ls | ./piping.py | wc -l
```