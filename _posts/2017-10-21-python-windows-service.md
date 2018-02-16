---
layout: post
title:  "Python Windows service"
date:   2017-10-20 14:22:38 +0100
categories:
---

Create a windows service in python is quite easy.

first, install [pywin32](https://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/)
and [Microsoft Visual C++ Compiler for Python 2.7](https://www.microsoft.com/en-us/download/details.aspx?id=44266)

Then, use this boilerplate code to run your service.

```python
import servicemanager
import win32event
import win32service
import win32serviceutil

class PySvc(win32serviceutil.ServiceFramework):
    _svc_name_ = "YourService"
    _svc_display_name_ = "Your Service"
    _svc_description_ = "Your Service"

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        # create an event to listen for stop requests on
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)

    def SvcDoRun(self):
        """Run the windows service
        """
        rc = None

        self.main()

        # if the stop event hasn't been fired keep looping
        while rc != win32event.WAIT_OBJECT_0:
            # block for 5 seconds and listen for a stop event
            rc = win32event.WaitForSingleObject(self.hWaitStop, 5000)

    def SvcStop(self):
        """Stop the windows service and stop the scheduler instance
        """
        # tell the SCM we're shutting down
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)

        # fire the stop event
        servicemanager.LogInfoMsg("stop event")
        win32event.SetEvent(self.hWaitStop)

    def main(self):
        # do something here
        pass


if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(PySvc)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(PySvc)
```

Then install the service:

As a user:

```bash
python win_service.py --username $pc_name --password $plain_password install
```

As a background service:

```bash
python win_service.py install
```

Manipulate the service in python

```python
import win32serviceutil

# start the service
win32serviceutil.StartService("service_name")

# stop the service
win32serviceutil.StopService("service_name")
# or in case the stop functionality gets blocked like in this case...
"""
Stop the windows service by using sc queryex command, if we use
  win32serviceutil.StoptService(self.service_name) it never gets stopped
because freezer_scheduler.start() blocks the windows service and
prevents any new signal to reach the service.
"""
query = 'sc queryex {0}'.format("service_name")
out = utils.create_subprocess(query)[0]
pid = None
for line in out.split('\n'):
    if 'PID' in line:
        pid = line.split(':')[1].strip()

command = 'taskkill /f /pid {0}'.format(pid)
utils.create_subprocess(command)

# status of the service
"""Return running status of Freezer Service
by querying win32serviceutil.QueryServiceStatus()
possible running status:
    1 == stop
    4 == running
"""
if win32serviceutil.QueryServiceStatus("service_name")[1] == 4:
    print("{0} is running normally".format("service_name"))
else:
    print("{0} is *NOT* running".format("service_name"))
```
