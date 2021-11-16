#!/usr/bin/env ruby

# file: xdrp.rb

# description: A basic macro recorder for GNU/Linux which uses 
#              program xinput to capture input events.

require 'wmctrl'
require 'rxfhelper'
require 'keystroker'
require "xdo/mouse"
require "xdo/xwindow"
require "xdo/keyboard"
require 'xinput_wrapper'



MOUSE = 1
KEYBOARD = 2
KEYBOARD_MOUSE = 3


module Xdrp

  class Recorder

    attr_reader :xml

    # level:
    #    1 = mouse
    #    2 = keyboard
    #    3 = keyboard + mouse

    def initialize(levelx=KEYBOARD_MOUSE, level: levelx, debug: false)

      @mouse, @keyboard = false, false

      case level
      when 1
        @mouse = true
      when 2
        @keyboard = true
      when 3
        @mouse, @keyboard = true, true
      end


      @xiw = XInputWrapper.new(verbose: true, debug: debug, callback: self)

      @wm = WMCtrl.display
      @win_title = ''

    end

    def on_keypress(key, keycode, modifier=nil)

      if @debug then
        puts 'key: ' + key.inspect
        puts 'keycode: ' + keycode.inspect
        puts 'modifier: ' + modifier.inspect
      end

      stop() if modifier and modifier[0] == :alt and key == :z

      return unless @keyboard

      add_sleep() if Time.now > (@t1 + 2)


      if @a.length >= 1 and @a[-1][0] == :type then

        if modifier.nil? or (modifier and modifier.empty?) then
          @a[-1][2] += key.to_s.sub('{space}', ' ')
        else

          if modifier.length < 2  then

            if modifier.first == :shift and (keycode.between?(10,21) \
                                             or keycode.between?(24,35) \
                                             or keycode.between?(38,48)) then

              char = if key.to_s =~ /[a-z]/ then
                key.to_s.upcase
              elsif key.to_s =~ /[0-9]/
                %w[) ! " £ $ % ^ & * ( ][key.to_s.to_i]
              else

                lsym = %i(` - = [ ] ; ' # \ , . /)

                if lsym.include? key then

                  usym = %w(¬ _ + { } : @ ~ | < > ?)
                  lsym.zip(usym).to_h[key]

                end

              end

              @a[-1][2] += char

            else
              @a << [modifier.first, {key: key}]
            end
          end
        end

      else

        a = case key.to_s[/^\{(\w+)\}$/,1]
        when 'enter'
          [:enter]
        when 'tab'
          [:tab]
        else
          [:type, {}, key.to_s.sub(/\{space\}/, ' ')]
        end

        @a << a

      end

    end

    def on_mousedown(button, x, y)

      return unless @mouse
      monitor_app()

      puts "mouse %s button down at %s, %s" % [button, x, y] if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mouse, {click: button, x: x, y: y}]

    end

    def on_mouseup(button, x, y)

      return unless @mouse
      puts "mouse %s button up at %s, %s" % [button, x, y] if @debug
    end

    def on_mousemove(x, y)

      return unless @mouse

      puts 'mouse is moving at ' + x.to_s + ' y ' + y.to_s if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousemove, {x: x, y: y}]

    end

    def on_mouse_scrolldown()

      return unless @mouse

      puts 'mouse is scrolling down' if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousewheel, {scroll: 'down'}]

    end

    def on_mouse_scrollup()

      return unless @mouse

      puts 'mouse is scrolling up ' if @debug
      add_sleep() if Time.now > (@t1 + 2)
      @a << [:mousewheel, {scroll: 'up'}]

    end

    def save(filepath)
      File.write filepath, xml()
    end

    def start()

      @a = []
      Thread.new { @xiw.listen }
      puts 'recording ...'
      @t1 = Time.now

    end

    def stop()

      @xiw.stop = true
      @doc = Rexle.new(['xdrp', {}, '', *@a])
      puts 'recording stopped'

    end

    def xml()
      @doc.xml(pretty: true)
    end

    private

    def add_sleep()
      @a << [:sleep, {duration: (Time.now - @t1).round}]
      @t1 = Time.now
    end

    def monitor_app()

      win = @wm.windows.find {|x| x.active}

      if win.title != @win_title then
        @win_title = win.title
        @a << [:window, {activate: win.title}]
      end

    end

  end

  class Player
    using ColouredText

    def initialize(src, debug: false)

      @debug = debug
      @doc = Keystroker.new(src, debug: debug).to_doc
      puts '@doc.xml: ' + @doc.xml if @debug

    end

    def play()

      @doc.root.elements.each do |e|

        if @debug then
          puts ('e: ' + e.xml.inspect).debug
          puts 'e.class: ' + e.class.inspect.debug
        end

        if e.attributes.any? then
          method('xdo_' + e.name.to_s).call(**(e.attributes))
        else
          method('xdo_' + e.name.to_s).call(e.text)
        end
      end

    end

    private

    def xdo_enter(h={})
      XDo::Keyboard.return
    end

    def xdo_mouse(click: 'left', x: 0, y: 0)
      XDo::Mouse.click(x.to_i, y.to_i,
                       Object.const_get('XDo::Mouse::' + click.upcase))
    end

    def xdo_mousemove(x: 0, y: 0)
      XDo::Mouse.move(x.to_i, y.to_i)
    end

    def xdo_mousewheel(scroll: 'down')
      XDo::Mouse.wheel(Object.const_get('XDo::Mouse::' + scroll.upcase, 4))
    end

    def xdo_sleep(duration: 0)
      sleep duration.to_f
    end

    def xdo_tab(times: 1)
      times.to_i.times.each { XDo::Keyboard.tab }
    end

    def xdo_type(s)
      XDo::Keyboard.simulate(s.gsub('{enter}', "\n"))
    end

    def xdo_window(activate: '')

      if @debug then
        puts 'inside xdo_window'
        puts 'activate: ' + activate.inspect
      end

      wm = WMCtrl.display
      window = wm.windows.find {|x| x.title == activate}
      window.activate

    end


  end

end
