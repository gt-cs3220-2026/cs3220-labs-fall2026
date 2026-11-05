from pynq import Overlay

# change to the path where you save the bistream
overlay = Overlay('./riscv.bit')

comm_ip = overlay.comm_0
# Dispatch Instructions
# Refer to this manual to learn how to read / write the ports: https://pynq.readthedocs.io/en/v2.6.1/overlay_design_methodology/overlay_tutorial.html#Developing-a-Single-IP 
