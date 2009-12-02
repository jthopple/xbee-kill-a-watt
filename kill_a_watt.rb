class KillAWatt
  CURRENTSENSE = 4       # which XBee ADC has current draw data
  VOLTSENSE = 0          # which XBee ADC has mains voltage data
  MAINSVPP = 170 * 2     # +-170V is what 120Vrms ends up being (= 120*2sqrt(2))
  VREF_CALIBRATION = [492,  # Calibration for sensor #0
                      498,  # Calibration for sensor #1
                      489,  # Calibration for sensor #2
                      492,  # Calibration for sensor #3
                      501,  # Calibration for sensor #4
                      493]  # etc... approx ((2.4v * (10Ko/14.7Ko)) / 3
  CURRENTNORM = 15.5  # conversion to amperes from ADC
  NUMWATTDATASAMPLES = 1800 # how many samples to watch in the plot window, 1 hr @ 2s samples
  
  def initialize(xbee)
    @xbee = xbee
    
    # we'll only store n-1 samples since the first one is usually messed up
    @analog_samples = @xbee.analog_samples[1..(xbee.analog_samples.size-1)]
  end
  
  def voltage_data
    @voltage_data ||= @analog_samples.collect{ |sample| sample[VOLTSENSE] }
  end
  
  def amp_data
    @amp_data ||= @analog_samples.collect{ |sample| sample[CURRENTSENSE] }
  end
  
  def min_voltage
    unless @min_voltage
      min = voltage_data.min
      @min_voltage = min < 0 ? 0 : min
    end
    return @min_voltage
  end
  
  def max_voltage
    unless @max_voltage
      max = voltage_data.max
      @max_voltage = max > 1024 ? 1024 : max
    end
    return @max_voltage
  end
  
  def avg_voltage
    # figure out the 'average' of the max and min readings
    @avg_voltage ||= (max_voltage + min_voltage) / 2
  end
  
  def peak_to_peak_voltage
    # also calculate the peak to peak measurements
    @peak_to_peak_voltage ||= max_voltage - min_voltage
  end
  
  def normalized_voltage_data
    @normalized_voltage_data ||= voltage_data.collect do |vd|
      #remove 'dc bias', which we call the average read
      unbiased = (vd - avg_voltage)
      
      # We know that the mains voltage is 120Vrms = +-170Vpp
      unbiased * MAINSVPP / peak_to_peak_voltage
    end
  end
  
  def normalized_amp_data
    # normalize current readings to amperes
    @normalized_amp_data ||= amp_data.collect do |ad|
      # VREF is the hardcoded 'DC bias' value, its
      # about 492 but would be nice if we could somehow
      # get this data once in a while maybe using xbeeAPI
      calibrated = ad - VREF_CALIBRATION[0]
      if VREF_CALIBRATION[@xbee.address_16]
        calibrated = ad - VREF_CALIBRATION[@xbee.address_16]
      end
      
      # the CURRENTNORM is our normalizing constant
      # that converts the ADC reading to Amperes
      calibrated /= CURRENTNORM
    end
  end
  
  def watt_data
    # calculate instant. watts, by multiplying V*I for each sample point
    unless @watt_data
      @watt_data = []
      normalized_voltage_data.each_with_index do |vd, i|
        @watt_data << vd * normalized_amp_data[i]
      end
    end
    
    return @watt_data
  end
  
  def amp_draw
    unless @amp_draw
      # sum up the current drawn over one 1/60hz cycle
      @amp_draw = 0
    
      # 16.6 samples per second, one cycle = ~17 samples
      # close enough for govt work :(
      17.times{ |i| @amp_draw += normalized_amp_data[i].abs }

      @amp_draw /= 17.0
    end
    
    return @amp_draw
  end
  
  def watt_draw
    unless @watt_draw
      # sum up power drawn over one 1/60hz cycle
      @watt_draw = 0
      # 16.6 samples per second, one cycle = ~17 samples
      17.times{ |i| @watt_draw += watt_data[i].abs }
        
      @watt_draw /= 17.0
    end
    
    return @watt_draw
  end
  
  def watt_hour(elapsed_seconds)
    @watt_hour ||= watt_draw * elapsed_seconds / 60.0 * 60.0  # 60 seconds in 60 minutes = 1 hr
  end
  
  def summary(last_summary_at)
    # Most recent measurement summary
    amp_summary = %(\tCurrent drawn, in amperes: #{amp_draw})
    watt_summary = %(\n\tWatt draw, in VA: #{watt_draw})
    
    wh_summary = nil
    if last_summary_at
      elapsed_seconds = Time.now - last_summary_at
      wh_summary = %(\n\t\tWh used in last #{elapsed_seconds} seconds #{watt_hour(elapsed_seconds)})
    end
    
    %(#{@xbee.address_16}#{amp_summary}#{watt_summary}#{wh_summary}\n\n)
  end
end