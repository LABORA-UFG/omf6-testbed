defApplication('otr2') do |a|

  a.binary_path = "/usr/bin/otr2"
  a.description = <<TEXT
otr is a configurable traffic sink. It contains port to receive
packet streams via various transport options, such as TCP and UDP.
This version 2 is compatible with OMLv2.
TEXT

  a.defProperty('udp_local_host', 'IP address of this Destination node', '--udp:local_host', {:type => :string, :dynamic => false})
  a.defProperty('udp_local_port', 'Receiving Port of this Destination node', '--udp:local_port', {:type => :integer, :dynamic => false})
  a.defMeasurement('udp_in') do |m|
    m.defMetric('ts',:float)
    m.defMetric('flow_id',:long)
    m.defMetric('seq_no',:long)
    m.defMetric('pkt_length',:long)
    m.defMetric('dst_host',:string)
    m.defMetric('dst_port',:long)
  end
end

defApplication('otg2') do |a|

  a.binary_path = "/usr/bin/otg2"
  a.description = <<TEXT
OTG is a configurable traffic generator. It contains generators
producing various forms of packet streams and port for sending
these packets via various transports, such as TCP and UDP.
This version 2 is compatible with OMLv2
TEXT

  a.defProperty('generator', 'Type of packet generator to use (cbr or expo)', '-g', {:type => :string, :dynamic => false})
  a.defProperty('udp_broadcast', 'Broadcast', '--udp:broadcast', {:type => :integer, :dynamic => false})
  a.defProperty('udp_dst_host', 'IP address of the Destination', '--udp:dst_host', {:type => :string, :dynamic => false})
  a.defProperty('udp_dst_port', 'Destination Port to send to', '--udp:dst_port', {:type => :integer, :dynamic => false})
  a.defProperty('udp_local_host', 'IP address of this Source node', '--udp:local_host', {:type => :string, :dynamic => false})
  a.defProperty('udp_local_port', 'Local Port of this source node', '--udp:local_port', {:type => :integer, :dynamic => false})
  a.defProperty("cbr_size", "Size of packet [bytes]", '--cbr:size', {:dynamic => true, :type => :integer})
  a.defProperty("cbr_rate", "Data rate of the flow [kbps]", '--cbr:rate', {:dynamic => true, :type => :integer})
  a.defProperty("exp_size", "Size of packet [bytes]", '--exp:size', {:dynamic => true, :type => :integer})
  a.defProperty("exp_rate", "Data rate of the flow [kbps]", '--exp:rate', {:dynamic => true, :type => :integer})
  a.defProperty("exp_ontime", "Average length of burst [msec]", '--exp:ontime', {:dynamic => true, :type => :integer})
  a.defProperty("exp_offtime", "Average length of idle time [msec]", '--exp:offtime', {:dynamic => true, :type => :integer})
  a.defMeasurement('udp_out') do |m|
    m.defMetric('ts',:float)
    m.defMetric('flow_id',:long)
    m.defMetric('seq_no',:long)
    m.defMetric('pkt_length',:long)
    m.defMetric('dst_host',:string)
    m.defMetric('dst_port',:long)
  end
end

defGroup('Sender', "icarus5") do |node|
  node.addApplication("otg2") do |app|
    app.setProperty('udp_local_host', '192.16.0.2')
    app.setProperty('udp_dst_host', '192.16.0.3')
    app.setProperty('udp_dst_port', 3000)
    app.measure('udp_out', :interval => 3)
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = "6"
  node.net.w0.essid = "helloworld"
  node.net.w0.ip = "192.16.0.2/24"
end

defGroup('Receiver', "icarus6") do |node|
  node.addApplication("otr2") do |app|
    app.setProperty('udp_local_host', '192.16.0.3')
    app.setProperty('udp_local_port', 3000)
    app.measure('udp_in', :interval => 3)
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = "6"
  node.net.w0.essid = "helloworld"
  node.net.w0.ip = "192.16.0.3/24"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  info "This is my first OMF experiment"
  after 10 do
    allGroups.startApplications
    info "All my Applications are started now..."
  end
  after 40 do
    allGroups.stopApplications
    info "All my Applications are stopped now."
    Experiment.done
  end
end
