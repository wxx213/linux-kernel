#!/bin/bash

# exit with "control + q"
console=$(pwd)/out/serial.sock
sudo socat "stdin,raw,echo=0,escape=0x11" "unix-connect:${console}"
