from pynq import Overlay

# change to the path where you save the bistream
overlay = Overlay('./riscv.bit')
help(overlay)
overlay.ip_dict
comm_ip = overlay.comm_0
help(comm_ip)
print(comm_ip.read(0x30))
print(comm_ip.read(0x20))
