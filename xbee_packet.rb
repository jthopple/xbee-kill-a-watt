class XbeePacket
  
  START_IOPACKET   = 0x7e
  SERIES1_IOPACKET = 0x83
  
  def initialize(serial_port)
    if serial_port.getc == START_IOPACKET
      lengthMSB = serial_port.getc
      lengthLSB = serial_port.getc
      length = (lengthLSB + (lengthMSB << 8)) + 1
      @packet = Array.new(length){ serial_port.getc }
    end
    
    raise "Invalid Packet" unless @packet && app_id == SERIES1_IOPACKET
  end
  
  def app_id
    @app_id ||= @packet[0]
  end
  
  def addr_msb
    @addr_msb ||= @packet[1]
  end
  
  def addr_lsb 
    @addr_lsb ||= @packet[2]
  end
  
  def address_16
    @address_16 ||= (addr_msb << 8) + addr_lsb
  end
  
  def rssi
    @rssi ||= @packet[3]
  end
  
  def address_broadcast
    @address_broadcast ||= ((@packet[4] >> 1) & 0x01) == 1
  end
  
  def pan_broadcast
    @pan_broadcast ||= ((@packet[4] >> 2) & 0x01) == 1
  end
  
  def total_samples
    @total_samples ||= @packet[5]
  end
  
  def channel_indicator_high
    @channel_indicator_high ||= @packet[6]
  end
  
  def channel_indicator_low
    @channel_indicator_low ||= @packet[7]
  end
    
  def digital_samples
    @digital_samples ||= Array.new(total_samples) do |sample_number|
      load_digital_sample
    end
  end
  
  def analog_samples
    @analog_samples ||= Array.new(total_samples) do |sample_number|
      load_analog_sample(sample_number)
    end
  end
  
  def to_s
    "<xbee {app_id: #{app_id}, address_16: #{address_16}, rssi: #{rssi}, address_broadcast: #{address_broadcast}, pan_broadcast: #{pan_broadcast}, total_samples: #{total_samples}, digital: #{digital_samples.join(",")}, analog: #{analog_samples.join(",")}}>"
  end
  
  private
    
    def load_digital_sample
      dataD = Array.new(9, nil)
      digital_channels = channel_indicator_low
      digital = 0
    
      dataD.each_with_index do |d, i|
        if (digital_channels & 1) == 1
          dataD[i] = 0
          digital = 1
        end
      
        digital_channels = digital_channels >> 1
      end
    
      if (channel_indicator_high & 1) == 1
        dataD[8] = 0
        digital = 1
      end

      if digital
        digMSB = @packet[8]
        digLSB = @packet[9]
        dig = (digMSB << 8) + digLSB
        dataD.each_with_index do |d, i|
          if dataD[i] == 0:
            dataD[i] = dig & 1
          end
          dig = dig >> 1
        end
      end
    
      return dataD
    end
  
    def load_analog_sample(sample_number)
      analog_count = nil
      dataADC = Array.new(6, nil)
      analog_channels = channel_indicator_high >> 1
      validanalog = 0
      dataADC.each_with_index do |d, i|
        if ((analog_channels >> i) & 1) == 1
          validanalog += 1
        end
      end

      dataADC.each_with_index do |d, i|
        if (analog_channels & 1) == 1:
          analogchan = 0
          i.times do |j|
            if ((channel_indicator_high >> (j+1)) & 1) == 1:
              analogchan += 1
            end
          end
        
          dataADCMSB = @packet[8 + validanalog * sample_number * 2 + analogchan* 2]
          dataADCLSB = @packet[8 + validanalog * sample_number * 2 + analogchan* 2 + 1]
          dataADC[i] = ((dataADCMSB << 8) + dataADCLSB)# / 64

          analog_count = i
        end
        analog_channels = analog_channels >> 1
      end
    
      return dataADC
    end
  
end