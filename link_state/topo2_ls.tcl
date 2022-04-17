puts "TOPOLOGIA2_LINK_STATE"

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
  # exec nam topologia2_link_state.nam &
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

# Sets a protocol (Link-State)
$ns rtproto LS

# Set a data-logging graph color (NAM uses)
$ns color 1 Green

# Writes a exit point for nam usage
set nf [open topologia2_link_state.nam w]
$ns namtrace-all $nf

# Opens created file
set f [open topologia2_link_state.tr w]
$ns trace-all $f

# Creates 6 node (requirement)
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
# for {set i 0} {$i < 5} {incr i} { set n($i) [$ns node] }

# Create links (manually, due requirement)
$ns duplex-link $n0 $n1 1Mb 10ms DropTail
$ns duplex-link $n0 $n2 1Mb 10ms DropTail
$ns duplex-link $n1 $n4 1Mb 10ms DropTail
$ns duplex-link $n1 $n3 1Mb 10ms DropTail
$ns duplex-link $n2 $n3 1Mb 10ms DropTail
$ns duplex-link $n3 $n5 1Mb 10ms DropTail
$ns duplex-link $n4 $n2 1Mb 10ms DropTail
$ns duplex-link $n4 $n5 1Mb 10ms DropTail

# NAM positioning (manually, due requirement)
$ns duplex-link-op $n0 $n1 orient right-up
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n4 orient right-down
$ns duplex-link-op $n1 $n3 orient right
$ns duplex-link-op $n2 $n3 orient right-up
$ns duplex-link-op $n2 $n4 orient right
$ns duplex-link-op $n3 $n5 orient right-down
$ns duplex-link-op $n4 $n5 orient right-up

# Set vert weight
$ns cost $n0 $n1 1
$ns cost $n0 $n2 1
$ns cost $n1 $n3 1
$ns cost $n1 $n4 2
$ns cost $n2 $n3 2
$ns cost $n2 $n4 1
$ns cost $n3 $n5 1
$ns cost $n4 $n5 1

# UDP Connection
set udp [new Agent/UDP]
$ns attach-agent $n0 $udp
# $ns attach-agent $n(0) $udp
$udp set class_ 1

$ns attach-agent $n5 $sink0
$ns attach-agent $n5 $sink1
$ns attach-agent $n5 $sink2

set source0 [attach-expoo-traffic $n0 $sink0 200 2s 1s 100k]
set source1 [attach-expoo-traffic $n1 $sink1 200 2s 1s 200k]
set source2 [attach-expoo-traffic $n2 $sink2 200 2s 1s 300k]

set f0 [open topologia2_link_state0.tr w]
set f1 [open topologia2_link_state1.tr w]
set f2 [open topologia2_link_state2.tr w]

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
# $ns attach-agent $n(5) $null
$ns attach-agent $n5 $null

# UDP association (to null agent)
$ns connect $udp $null
$ns rtmodel-at 2.5 down $n1 $n3
$ns rtmodel-at 2.5 down $n2 $n4
$ns rtmodel-at 5.0 up $n1 $n3
$ns rtmodel-at 5.0 up $n2 $n4

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