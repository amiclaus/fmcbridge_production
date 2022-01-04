#!/bin/bash

GPIO_ADDRESS=86000000
SPI1_ADDRESS=84000000
SPI2_ADDRESS=84500000
I2C1_ADDRESS=83000000
I2C2_ADDRESS=83100000

GPIO_FIRST=`ls -l /sys/class/gpio/ | grep " gpiochip" | grep "$GPIO_ADDRESS" | grep -Eo '[0-9]+$'`

SPI1_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI1_ADDRESS" | grep -Eo '[0-9]+$'`

if [ -z $SPI1_DEVICE ]; then
	echo "SPI device 1 not found"
	exit 1
else
	SPI1_DEVICE="iio:device${SPI1_DEVICE}"
	echo "SPI device 1: ${SPI1_DEVICE}"
fi

if [ -z $GPIO_FIRST ]; then
	echo "No GPIO node found. Exiting test script.."
	exit 1
else
	echo "GPIO initial offset found: $GPIO_FIRST"
fi

GPIO_LAST=$(($GPIO_FIRST + 21))

for ((i=$GPIO_FIRST;i<=$GPIO_LAST;i++))
do
	echo "$i" > /sys/class/gpio/export 2>&1
done	

SPI1_SCALE=`cat /sys/bus/iio/devices/$SPI1_DEVICE/out_voltage_scale`

echo "SPI device 1 scale ${SPI1_SCALE}"
