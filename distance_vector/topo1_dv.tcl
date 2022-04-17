puts "TOPOLOGIA1_DISTANCE_VECTOR"

# Creates a procedure
proc finish {} {
  global ns nf f
  $ns flush-trace
    
	# Closes nam tracing
  close $nf

  # Closes the file
  close $f

  # Executes NAM and uses generated file
  exec nam topologia1_distance_vector.nam &
  exit 0
}

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

# UDP Connection
set udp [new Agent/UDP]
$ns attach-agent $n(0) $udp
$udp set class_ 1

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
$ns rtmodel-at 2.0 down $n(0) $n(1)
$ns rtmodel-at 5.0 up $n(0) $n(1)

# Event assignment (CBR)
$ns at 0.5 "$cbr start"
$ns at 4.5 "$cbr stop"

# Sets timeout after 5.0 secs
$ns at 5.0 "finish"

# Run project/script
$ns run