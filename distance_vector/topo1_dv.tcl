puts "TOPOLOGIA1_DISTANCE_VECTOR"

# Creates a procedure (runs on 5.0 end)
proc finish {} {
  global ns nf f
	global f0 f1 f2
  
  close $f0
  close $f1
  close $f2
	
  $ns flush-trace
    
	# Closes nam tracing
  close $nf

  # Closes the file
  close $f

  # Executes NAM and uses generated file
  # exec nam topologia1_distance_vector.nam &

	exit 0
}

# Font: https://www.isi.edu/nsnam/ https://www.isi.edu/nsnam/ns/tutorial/nsscript4.html
proc attach-expoo-traffic { node sink size burst idle rate } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/UDP]
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/Exponential]
	$traffic set packetSize_ $size
	$traffic set burst_time_ $burst
	$traffic set idle_time_ $idle
	$traffic set rate_ $rate
        
  # Attach traffic source to the traffic generator
  $traffic attach-agent $source
	
	#Connect the source and the sink
	$ns connect $source $sink
	return $traffic
}

proc record {} {
  global sink0 sink1 sink2 f0 f1 f2
	#Get an instance of the simulator
	
	set ns [Simulator instance]
	
	#Set the time after which the procedure should be called again
	set time 0.5
	
	#How many bytes have been received by the traffic sinks?
  set bw0 [$sink0 set bytes_]
  set bw1 [$sink1 set bytes_]
  set bw2 [$sink2 set bytes_]
	
	#Get the current time
  set now [$ns now]
	
	#Calculate the bandwidth (in MBit/s) and write it to the files
  puts $f0 "$now [expr $bw0/$time*8/1000000]"
  puts $f1 "$now [expr $bw1/$time*8/1000000]"
  puts $f2 "$now [expr $bw2/$time*8/1000000]"
	
	#Reset the bytes_ values on the traffic sinks
  $sink0 set bytes_ 0
  $sink1 set bytes_ 0
  $sink2 set bytes_ 0
	
	#Re-schedule the procedure
  $ns at [expr $now+$time] "record"
}

# Traffic sinks to attach them to the node n4
set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
set sink2 [new Agent/LossMonitor]

# Creates a new object (simulator)
set ns [new Simulator]

# Sets a protocol (Distance-Vector)
$ns rtproto DV

# Set a data-logging graph color (NAM uses)
$ns color 1 Green

# Writes a exit point for nam usage
set nf [open topologia1_distance_vector.nam w]
$ns namtrace-all $nf

# Opens created file
set f [open topologia1_distance_vector.tr w]
$ns trace-all $f

# Creates 5 node (requirement)
for {set i 0} {$i < 5} {incr i} { set n($i) [$ns node] }

# Set links
for {set i 0} {$i < 4} {incr i} {
  # set link to a "neighbor" node
	$ns duplex-link $n($i) $n([expr ($i + 1) % 5]) 1Mb 10ms DropTail
}

# NAM COnfig
for {set i 0} {$i < 3} {incr i} { $ns duplex-link-op $n($i) $n([expr $i + 1]) orient right }

# Set a vert weight (with same neighbor config)
for {set i 0} {$i < 3} {incr i} { $ns cost $n($i) $n([expr $i + 1]) 1 }

# UDP Connection (source)
set udp [new Agent/UDP]
$ns attach-agent $n(0) $udp
$udp set class_ 1

$ns attach-agent $n(4) $sink0
$ns attach-agent $n(4) $sink1
$ns attach-agent $n(4) $sink2

set source0 [attach-expoo-traffic $n(0) $sink0 200 2s 1s 100k]
set source1 [attach-expoo-traffic $n(1) $sink1 200 2s 1s 200k]
set source2 [attach-expoo-traffic $n(2) $sink2 200 2s 1s 300k]

set f0 [open topologia1_distance_vector0.tr w]
set f1 [open topologia1_distance_vector1.tr w]
set f2 [open topologia1_distance_vector2.tr w]

# CBR (UDP) config
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set interval_ 0.01
$cbr set rate_ 1mb
$cbr set random_ false

# Defines a null agent to the last node
set null [new Agent/Null]
$ns attach-agent $n(4) $null

# UDP association (to null agent)
$ns connect $udp $null
$ns rtmodel-at 2.5 down $n(0) $n(1)
$ns rtmodel-at 5.0 up $n(0) $n(1)

# Event assignment (CBR)
$ns at 0.0 "record"
$ns at 1.0 "$cbr start"
$ns at 1.0 "$source0 start"
$ns at 1.0 "$source1 start"
$ns at 1.0 "$source2 start"
$ns at 8.0 "$source0 stop"
$ns at 8.0 "$source1 stop"
$ns at 8.0 "$source2 stop"
$ns at 8.0 "$cbr stop"
$ns at 8.5 "finish"

# Run project/script
$ns run