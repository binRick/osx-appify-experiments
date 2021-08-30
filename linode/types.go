package main

import "net"

type LinodeVM struct {
	ID        int
	Region    string
	Image     string
	IP        *net.IP
	PrivateIP *net.IP
	Type      string
	Hostname  string
	Label     string
}
