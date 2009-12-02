require 'rubygems'
require 'serialport'
require 'xbee_packet'
require 'kill_a_watt'
sp = SerialPort.new("/dev/cu.usbserial-FTELSG4K")

#just read forever
while true do
  xbee_packet = XbeePacket.new(sp)
  kill_a_watt = KillAWatt.new(xbee_packet)
  puts %(#{Time.now}\n#{kill_a_watt}\n\n)
end

sp.close