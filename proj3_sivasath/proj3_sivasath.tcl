set val(chan)           Channel/WirelessChannel    ;#Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/Simple                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             1                          ;# number of mobilenodes
set val(tnn)                        2
set val(end_time)    11
set val(interval) 0.02

Mac/Simple set repeatTx_ 5
Mac/Simple set interval_ 0.02

# routing protocol
set val(rp)              DumbAgent 
#set val(rp)             DSDV                    
#set val(rp)             DSR                     
#set val(rp)             AODV                    

set val(x)        50
set val(y)        50

# Initialize Global Variables
set ns_        [new Simulator]
set tracefd     [open wireless-simple-mac.tr w]
$ns_ trace-all $tracefd

#set namtrace [open wireless-simple-mac.nam w]
#$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]

$topo load_flatgrid $val(x) $val(y)

# Create God
create-god $val(tnn)

# Create channel
set chan_ [new $val(chan)]

# Create node(0) and node(1)

# configure node, please note the change below.
$ns_ node-config -adhocRouting $val(rp) \
        -llType $val(ll) \
        -macType $val(mac) \
        -ifqType $val(ifq) \
        -ifqLen $val(ifqlen) \
        -antType $val(ant) \
        -propType $val(prop) \
        -phyType $val(netif) \
        -topoInstance $topo \
        -agentTrace OFF \
        -routerTrace OFF \
        -macTrace ON \
        -movementTrace OFF \
        -channel $chan_

for {set i 0} {$i < $val(tnn)} {incr i} {
    set node_($i) [$ns_ node]
        set xx [expr rand()*$val(x)]
      set yy [expr rand()*$val(y)]
      $node_($i) set X_ $xx
        $node_($i) set Y_ $yy                                                                                                         
    $node_($i) random-motion 0
    $ns_ initial_node_pos $node_($i) 5

}

set sink [new Agent/Null]
$ns_ attach-agent $node_($val(nn)) $sink

set rng [new RNG]
$rng seed 10


set rndnum [new RandomVariable/Uniform]
$rndnum use-rng $rng
$rndnum set min_ 0
$rndnum set max_ $val(interval)

for {set i 0} {$i < $val(nn)} {incr i} {
    set audp($i) [new Agent/UDP]
    $ns_ attach-agent $node_($i) $audp($i)
    set acbr($i) [new Application/Traffic/CBR]
    $acbr($i) attach-agent $audp($i)
    $ns_ connect $audp($i) $sink
    $acbr($i) set interval_ 0.02
    $acbr($i) set packetSize_ 16
    set start_time [$rndnum value]
    puts "$start_time time"
    $ns_ at $start_time "$acbr($i) start"
    $ns_ at $val(end_time) "$acbr($i) stop"
}

#
# Tell nodes when the simulation ends
#
for {set i 0} {$i < $val(tnn) } {incr i} {
    $ns_ at $val(end_time) "$node_($i) reset"
}
#$ns_ at 6.0 "stop"
$ns_ at $val(end_time) "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    close $tracefd
}

puts "Starting Simulation..."
$ns_ at $val(end_time) "stop"
$ns_ run
