# Distance-estimation-along-a-line

The main objective of this project is to track the location of a target mote along a straight line between two anchor motes placed 100m apart,using RSSI measurements.

This project is divided into two parts

Part-1: 
Obtain the path loss factor in the environment of your choice (e.g. open area, such as a parking lot):
The first mote will be set as a base station for packet reception and computations. 
The second mote will be a transmitter that will be placed at different distances from the receiver transmitting according to a certain schedule of your choice.
At each location, the transmitter mote will transmit a certain number of packets (e.g. 10) before being moved to the next location (e.g. 10 ft apart). After a certain number of repeated measurements, you should calculate the path loss exponent from average received signal strength (RSS) measurements from the different known distances, and also record the rate of successful packet reception at each distance.

Part-2:
Two Anchors will be placed at a distance of 100m sending periodic beacon messages including their nodeID. 
A Target mote will be placed at an unknown distance x meters from one end to receive these beacons, estimate the received RSSI values of the beacons, and transmit to the base-station. 
The base station will estimate the distance x of the target mote along the line (0-100m) and display it on the screen.
