#!/bin/bash

GPIO_ADDRESS=86000000
SPI1_ADDRESS=84000000
SPI2_ADDRESS=84500000
I2C1_ADDRESS=83000000
I2C2_ADDRESS=83100000

GPIO_FIRST=`ls -l /sys/class/gpio/ | grep " gpiochip" | grep "$GPIO_ADDRESS" | grep -Eo '[0-9]+$'`

SPI1_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI1_ADDRESS" | grep -Eo '[0-9]+$'`
SPI2_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI2_ADDRESS" | grep -Eo '[0-9]+$'`
I2C1_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI1_ADDRESS" | grep -Eo '[0-9]+$'`
I2C2_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI2_ADDRESS" | grep -Eo '[0-9]+$'`

if [ -z $SPI1_DEVICE ]; then
	echo "AD5761_SPI1 not found."
	exit 1
else
	SPI1_DEVICE="iio:device${SPI1_DEVICE}"
	echo "SPI device 1: ${SPI1_DEVICE}"
fi

if [ -z $SPI2_DEVICE ]; then
	echo "AD5761_SPI12not found."
	exit 1
else
	SPI2_DEVICE="iio:device${SPI2_DEVICE}"
	echo "SPI device 2: ${SPI2_DEVICE}"
fi

if [ -z $I2C1_DEVICE ]; then
	echo "AD7291_I2C1 not found."
	exit 1
else
	I2C1_DEVICE="iio:device${I2C1_DEVICE}"
	echo "I2C device 2: ${I2C1_DEVICE}"
fi

if [ -z $I2C2_DEVICE ]; then
	echo "AD7291_I2C2 not found."
	exit 1
else
	I2C2_DEVICE="iio:device${I2C2_DEVICE}"
	echo "I2C device 2: ${I2C2_DEVICE}"
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
