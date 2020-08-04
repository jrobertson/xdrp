# Introducing the Xdrp gem


## Recording a Macro

Usage:

    require 'xdrp'

    xr = Xdrp::Recorder.new
    xr.start

    # use alt+z to stop the recorder

    xr.save '/tmp/test2.xml'



## Replaying a Macro

Usage:

    require 'xdrp'

    sleep 2
    Xdrp::Player.new('/tmp/test2.xml').play

Note: A sleep statement before the macro plays can be helpful to give time to switch to the target window.

The above examples demonstrate how to record a macro and replay it on a GNU/Linux based Windowing system.

## Resources

* xdrp https://rubygems.org/gems/xdrp
* RMPR/atbswp: A minimalist macro recorder https://github.com/RMPR/atbswp

xdrp gem macro recorder player xinput sendkeys automation mouse mousemove keystrokes logger
