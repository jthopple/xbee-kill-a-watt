require 'rubygems'
require 'serialport'
require 'xbee'
require 'kill_a_watt'
sp = SerialPort.new("/dev/cu.usbserial-FTELSG4K")

#just read forever
while true do
  packet = Xbee.find_packet(sp)
  puts KillAWatt.new(Xbee.new(packet))
  puts "\n"
end

sp.close