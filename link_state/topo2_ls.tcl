puts "TOPOLOGIA2_LINK_STATE"

# Creates a procedure (runs on 5.0 end)
proc finish {} {
  global ns nf f
  $ns flush-trace
    
	# Closes nam tracing
  close $nf

  # Closes the file
  close $f

  # Executes NAM and uses generated file
  exec nam topologia2_link_state.nam &
  exit 0
}

# Creates a new object (simulator)
set ns [new Simulator]

# Sets a protocol (Distance-Vector)
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
$ns at 0.5 "$cbr start"
$ns at 4.5 "$cbr stop"

# Sets timeout after 5.0 secs
$ns at 5.0 "finish"

# Run project/script
$ns run