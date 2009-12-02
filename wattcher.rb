require 'rubygems'
require 'serialport'
require 'xbee_packet'
require 'kill_a_watt'

sp = SerialPort.new("/dev/cu.usbserial-FTELSG4K")

last_summary_at = nil

#read forever...
while true do
  #read an xbee packet from the serial port
  xbee = XbeePacket.new(sp)
  
  puts xbee.to_kill_a_watt.summary(last_summary_at)
  
  last_summary_at = Time.now
end

sp.close