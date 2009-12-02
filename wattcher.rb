require 'rubygems'
require 'serialport'
require 'xbee_packet'
require 'kill_a_watt'
sp = SerialPort.new("/dev/cu.usbserial-FTELSG4K")

#just read forever
last_at = nil
while true do
  xbee_packet = XbeePacket.new(sp)
  kill_a_watt = KillAWatt.new(xbee_packet)
  puts kill_a_watt.summary(last_at)
  last_at = Time.now
end

sp.close