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
    # we'll only store n-1 samples since the first one is usually messed up
    @analog_samples = xbee.analog_samples[1..(xbee.analog_samples.size-1)]
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
    (max_voltage + min_voltage) / 2
  end
  
  def peak_to_peak_voltage
    # also calculate the peak to peak measurements
    max_voltage - min_voltage
  end
  
  def current_draw
    
  end
  
  def to_s
    %(Summary Voltage Data -> min: #{min_voltage} max: #{max_voltage} avg: #{avg_voltage} peak2peak: #{peak_to_peak_voltage}\nVoltage Data: #{voltage_data.join(",")}\nAmp Data: #{amp_data.join(",")})
  end
end