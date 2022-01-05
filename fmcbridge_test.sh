#!/bin/bash

GPIO_ADDRESS=86000000
SPI1_ADDRESS=84000000
SPI2_ADDRESS=84500000
I2C1_ADDRESS=83000000
I2C2_ADDRESS=83100000

GPIO_FIRST=`ls -l /sys/class/gpio/ | grep " gpiochip" | grep "$GPIO_ADDRESS" | grep -Eo '[0-9]+$'`

SPI1_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI1_ADDRESS" | grep -Eo '[0-9]+$'`
SPI2_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$SPI2_ADDRESS" | grep -Eo '[0-9]+$'`
I2C1_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$I2C1_ADDRESS" | grep -Eo '[0-9]+$'`
I2C2_DEVICE=`ls -l /sys/bus/iio/devices/ | grep "$I2C2_ADDRESS" | grep -Eo '[0-9]+$'`

if [ -z $SPI1_DEVICE ]; then
	echo "AD5761_SPI1 not found."
	exit 1
else
	SPI1_DEVICE="iio:device${SPI1_DEVICE}"
	echo "SPI device 1 found: ${SPI1_DEVICE}"
fi

if [ -z $SPI2_DEVICE ]; then
	echo "AD5761_SPI12 not found."
	exit 1
else
	SPI2_DEVICE="iio:device${SPI2_DEVICE}"
	echo "SPI device 2 found: ${SPI2_DEVICE}"
fi

if [ -z $I2C1_DEVICE ]; then
	echo "AD7291_I2C1 not found."
	exit 1
else
	I2C1_DEVICE="iio:device${I2C1_DEVICE}"
	echo "I2C device 2 found: ${I2C1_DEVICE}"
fi

if [ -z $I2C2_DEVICE ]; then
	echo "AD7291_I2C2 not found."
	exit 1
else
	I2C2_DEVICE="iio:device${I2C2_DEVICE}"
	echo "I2C device 2 found: ${I2C2_DEVICE}"
fi

if [ -z $GPIO_FIRST ]; then
	echo "No GPIO node found. Exiting test script.."
	exit 1
else
	echo "GPIO initial offset found: $GPIO_FIRST"
fi

GPIO_LAST=$(($GPIO_FIRST + 20))

echo "Initializing GPIOs"
for ((i=$GPIO_FIRST;i<=$GPIO_LAST;i++))
do
	echo "$i" > /sys/class/gpio/export 2>&1
done
echo "GPIO initialization done."

echo "SPI device 1 scale ${SPI1_SCALE}"

echo "~~~~~~~~~Start testing ADC2~~~~~~~~~~~"
for ((i=0;i<=5;i++))
do
	GPIO=$(($GPIO_FIRST+$i))
	if [[ $i > 2 ]]; then
		GPIO=$(($GPIO + 2))
	fi

	GPIO_INDEX=$(($GPIO - $GPIO_FIRST))

	echo out > /sys/class/gpio/gpio$GPIO/direction
	echo "Set GPIO${GPIO_INDEX} high"
	echo 1 > /sys/class/gpio/gpio$GPIO/value
	echo "Reading VIN${i}"
	echo `cat /sys/bus/iio/devices/${I2C2_DEVICE}/in_voltage${i}_raw`
done

echo "~~~~~~~~~Start testing DAC1~~~~~~~~~~~"
#Test DAC1
echo "Writing raw value 2000 to DAC1"
echo 2000 > /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw
echo "Reading raw value from DAC1:"
echo `cat /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw`

echo "~~~~~~~~~Start testing DAC2~~~~~~~~~~~"
#Test DAC2
echo "Writing raw value 2000 to DAC2"
echo 2000 > /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw
echo "Reading raw value from DAC2:"
echo `cat /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw`

echo "~~~~~~~~~Start testing SPI1 GPIOS~~~~~~~~~~~"
SPI1_GPIO_FIRST=$(($GPIO_FIRST + 7))
GPIO_INPUT=$(($GPIO_FIRST + 3))

echo in > /sys/class/gpio/gpio$GPIO_INPUT/direction

GPIO0=$(($GPIO_FIRST))
GPIO1=$(($GPIO_FIRST+1))
GPIO2=$(($GPIO_FIRST+2))
for ((i=1;i<8;i++))
do
	A0=$((($i>>0) & 1))
	A1=$((($i>>1) & 1))
	A2=$((($i>>2) & 1))
	echo "Testing SPI1_CS${i}"
	echo "A2:${A2} A1:${A1} A0:${A0}"
	echo $A2 > /sys/class/gpio/gpio$GPIO0/value
	echo $A1 > /sys/class/gpio/gpio$GPIO1/value
	echo $A0 > /sys/class/gpio/gpio$GPIO2/value
	SPI1_CS_GPIO=$(($SPI1_GPIO_FIRST + $i))
	echo "SPI_CS_GPIO: $SPI1_CS_GPIO"
	echo out > /sys/class/gpio/gpio$SPI1_CS_GPIO/direction
	echo "SPI1_CS${i} set high"
	echo "${GPIO_INPUT}"
	echo 1 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value
	echo "Reading GPIO INPUT:"
	echo `cat /sys/class/gpio/gpio$GPIO_INPUT/value`
	echo "SPI1_CS${i} set low"
	echo 0 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value
	echo "Reading GPIO INPUT:"
	echo `cat /sys/class/gpio/gpio$GPIO_INPUT/value`
done
