import socket
import numpy as np

UDP_IP = '127.0.0.1'
UDP_PORT = 3000

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind((UDP_IP, UDP_PORT))
s.setblocking(False)

buttons = 'udlrabs' # Up, Down, Left, Right, A, B, Start
num_input = 19
num_hidden = 50
num_output = 7

addr_size = {}

while True:
	try:
		raw_data, addr = s.recvfrom(256)
		data = raw_data.decode()
		values = map(float, data.split(','))
		array = np.fromiter(values, float)
		if addr not in addr_size:
			addr_size[addr] = array.shape
			print(array.shape)
			print(array)

		s.sendto(b'received', addr)
	except socket.timeout as err:
		continue
	except BlockingIOError as err:
		continue
	except KeyboardInterrupt:
		break

s.close()