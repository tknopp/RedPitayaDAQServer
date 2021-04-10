# Development Tips

On this slide some development hints are summarized. These might change regularely if things
are properly integrated into the framework.

## Alpine Linux

* The Alpine linux as currently a root folder with only 185.8M free space, which disallows installing more
applications. To change this one can do
```
mount -o remount,size=1G /
```
* Right now no debugger is installed. This can be change after increasing / using:
```
apk add gdb
```
