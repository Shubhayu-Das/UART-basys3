import serial           # import the module
import struct
import time

ComPort = serial.Serial('/dev/ttyUSB1') # open COM24
ComPort.baudrate = 115200 # set Baud rate to 9600
ComPort.bytesize = 8    # Number of data bits = 8
ComPort.parity   = 'N'  # No parity
ComPort.stopbits = 1    # Number of Stop bits = 1

print("Enter 2 sixteen bit numbers.\nThe sum will be printed")
print("Press 'q' to exit infinite loop at any time")

while True:
    x=input("Enter number 1: ")
    ot= ComPort.write(struct.pack('h', int(x)))    #for sending data to FPGA
    if x == 'q':
        break
   
    y=input("Enter number 2: ")
    ot= ComPort.write(struct.pack('h', int(y)))    #for sending data to FPGA

    it=(ComPort.read(2))                #for receiving data from FPGA

    print(f"{x}+{y} = {int.from_bytes(it, byteorder='big')}")

ComPort.close()         # Close the Com port
