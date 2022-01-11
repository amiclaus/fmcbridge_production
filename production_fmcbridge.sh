#!/bin/bash

echo_red() { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }

SCRIPT_DIR="$(readlink -f $(dirname $0))"

if [ $(id -u) -ne 0 ] ; then
	echo "Please run as root"
	exit 1
fi

console_ascii_passed() {
	echo_green "$(cat $SCRIPT_DIR/lib/passed.ascii)"
}

console_ascii_failed() {
	echo_red "$(cat $SCRIPT_DIR/lib/failed.ascii)"
}

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

STATUS=0

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~Device Initialization~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

if [ -z $SPI1_DEVICE ]; then
	echo_red "AD5761_SPI1 not found."
	exit 1
else
	SPI1_DEVICE="iio:device${SPI1_DEVICE}"
	echo "SPI device 1 found: ${SPI1_DEVICE}"
fi

if [ -z $SPI2_DEVICE ]; then
	echo_red "AD5761_SPI12 not found."
	exit 1
else
	SPI2_DEVICE="iio:device${SPI2_DEVICE}"
	echo "SPI device 2 found: ${SPI2_DEVICE}"
fi

if [ -z $I2C1_DEVICE ]; then
	echo_red "AD7291_I2C1 not found."
	exit 1
else
	I2C1_DEVICE="iio:device${I2C1_DEVICE}"
	echo "I2C device 2 found: ${I2C1_DEVICE}"
fi

if [ -z $I2C2_DEVICE ]; then
	echo_red "AD7291_I2C2 not found."
	exit 1
else
	I2C2_DEVICE="iio:device${I2C2_DEVICE}"
	echo "I2C device 2 found: ${I2C2_DEVICE}"
fi

if [ -z $GPIO_FIRST ]; then
	echo_red "No GPIO node found. Exiting test script.."
	exit 1
else
	echo "GPIO initial offset found: $GPIO_FIRST"
fi

GPIO_LAST=$(($GPIO_FIRST + 21))

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Initializing GPIOs~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
for ((i=$GPIO_FIRST;i<=$GPIO_LAST;i++))
do
	echo "$i" > /sys/class/gpio/export 2>&1
done
echo "GPIO initialization done."

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing ADC1~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

ADC1_RANGES=(2000 3000 1000 2000 500 2000 1000 2000 200 3000 1500 3500 100 200)

for ((i=0;i<=6;i++))
do
	echo ""
	MIN_VAL=$i*2
	MAX_VAL=$i*2+1
	echo "Reading VIN${i}"
	ADC_VAL=`cat /sys/bus/iio/devices/${I2C1_DEVICE}/in_voltage${i}_raw`
	echo "VIN$1 RANGE: ${ADC1_RANGES[$MIN_VAL]} ${ADC1_RANGES[$MAX_VAL]}"
	if (( ($ADC_VAL > ${ADC1_RANGES[$MIN_VAL]}) && ($ADC_VAL < ${ADC1_RANGES[$MAX_VAL]}) ))
	then
		echo_green "ADC1 VIN$i test PASSED with value:$ADC_VAL"
	else
		echo_red "ADC1 VIN$i test FAILED with value:$ADC_VAL"
		STATUS=1
	fi
done

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing ADC2~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

for ((i=0;i<=5;i++))
do
	echo ""

	GPIO=$(($GPIO_FIRST+$i))
	if (( $i > 2 ))
	then
		GPIO=$(($GPIO + 2))
	fi

	GPIO_INDEX=$(($GPIO - $GPIO_FIRST))

	echo out > /sys/class/gpio/gpio$GPIO/direction

	echo "Set GPIO${GPIO_INDEX} high"
	echo 1 > /sys/class/gpio/gpio$GPIO/value

	echo "Reading VIN${i}"
	ADC_VAL=`cat /sys/bus/iio/devices/${I2C2_DEVICE}/in_voltage${i}_raw`
	if (( $ADC_VAL > 2000 ))
	then
		echo_green "ADC2 test PASSED with value:$ADC_VAL"
	else
		echo_red "ADC2 test FAILED with value:$ADC_VAL"
		STATUS=1
	fi

	echo "Set GPIO${GPIO_INDEX} low"
	echo 0 > /sys/class/gpio/gpio$GPIO/value

	echo "Reading VIN${i}"
	ADC_VAL=`cat /sys/bus/iio/devices/${I2C2_DEVICE}/in_voltage${i}_raw`
	if (( $ADC_VAL < 2000 ))
	then
		echo_green "ADC2 test PASSED with value:$ADC_VAL"
	else
		echo_red "ADC2 test FAILED with value:$ADC_VAL"
		STATUS=1
	fi
done

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing DAC1~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

echo "Writing raw value 2000 to DAC1"
echo 2000 > /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw

echo "Reading raw value from DAC1:"
DAC1_VAL=`cat /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw`

if (( ($DAC1_VAL < 1500) || ($DAC1_VAL > 2500) ))
then
	echo_red "DAC1 test FAILED with value: $DAC1_VAL"
	STATUS=1
else
	echo_green "DAC1 test PASSED with value: $DAC1_VAL"
fi

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing DAC2~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

echo "Writing raw value 2000 to DAC2"
echo 2000 > /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw

echo "Reading raw value from DAC2:"
DAC2_VAL=`cat /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw`
if (( ($DAC2_VAL < 1500) || ($DAC2_VAL > 2500) ))
then
	echo_red "DAC1 test FAILED with value: $DAC2_VAL"
	STATUS=1
else
	echo_green "DAC1 test PASSED with value: $DAC2_VAL"
fi

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing SPI1 GPIOS~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
SPI1_GPIO_FIRST=$(($GPIO_FIRST + 7))
GPIO_INPUT_SPI1=$(($GPIO_FIRST + 3))

echo in > /sys/class/gpio/gpio$GPIO_INPUT_SPI1/direction

GPIO0=$(($GPIO_FIRST))
GPIO1=$(($GPIO_FIRST+1))
GPIO2=$(($GPIO_FIRST+2))

for ((i=1;i<8;i++))
do
	echo ""

	A0=$((($i>>0) & 1))
	A1=$((($i>>1) & 1))
	A2=$((($i>>2) & 1))

	echo "Testing SPI1_CS${i}"
	echo "A2:${A2} A1:${A1} A0:${A0}"

	echo $A2 > /sys/class/gpio/gpio$GPIO0/value
	echo $A1 > /sys/class/gpio/gpio$GPIO1/value
	echo $A0 > /sys/class/gpio/gpio$GPIO2/value

	SPI1_CS_GPIO=$(($SPI1_GPIO_FIRST + $i))

	echo out > /sys/class/gpio/gpio$SPI1_CS_GPIO/direction

	echo "SPI1_CS${i} set high"
	echo 1 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value

	echo "Reading GPIO INPUT:"
	GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI1/value`
	if (( $GPIOIN_VAL == 1 ))
	then
		echo_green "SPI1_CS${i} test PASSED with value $GPIOIN_VAL"
	else
		echo_red "SPI1_CS${i} test FAILED."
		STATUS=1
	fi

	echo "SPI1_CS${i} set low"
	echo 0 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value

	echo "Reading GPIO INPUT:"
	GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI1/value`
	if (( $GPIOIN_VAL == 0 ))
	then
		echo_green "SPI1_CS${i} test PASSED with value $GPIOIN_VAL"
	else
		echo_red "SPI1_CS${i} test FAILED."
		STATUS=1
	fi
done

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~Start testing SPI2 GPIOS~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

SPI2_GPIO_FIRST=$(($SPI1_GPIO_FIRST + 7))
GPIO_INPUT_SPI2=$(($GPIO_INPUT_SPI1 + 1))

echo in > /sys/class/gpio/gpio$GPIO_INPUT_SPI2/direction

GPIO5=$(($GPIO_FIRST+5))
GPIO6=$(($GPIO_FIRST+6))
GPIO7=$(($GPIO_FIRST+7))

for ((i=1;i<8;i++))
do
	echo ""

	A0=$((($i>>0) & 1))
	A1=$((($i>>1) & 1))
	A2=$((($i>>2) & 1))

	echo "Testing SPI2_CS${i}"
	echo "A2:${A2} A1:${A1} A0:${A0}"

	echo $A2 > /sys/class/gpio/gpio$GPIO5/value
	echo $A1 > /sys/class/gpio/gpio$GPIO6/value
	echo $A0 > /sys/class/gpio/gpio$GPIO7/value

	SPI2_CS_GPIO=$(($SPI2_GPIO_FIRST + $i))

	echo out > /sys/class/gpio/gpio$SPI2_CS_GPIO/direction

	echo "SPI2_CS${i} set high"
	echo 1 > /sys/class/gpio/gpio$SPI2_CS_GPIO/value

	echo "Reading GPIO INPUT"
	GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI2/value`
	if (( $GPIOIN_VAL == 1 ))
	then
		echo_green "SPI2_CS${i} test PASSED with value $GPIOIN_VAL"
	else
		echo_red "SPI2_CS${i} test FAILED."
		STATUS=1
	fi

	echo "SPI2_CS${i} set low"
	echo 0 > /sys/class/gpio/gpio$SPI2_CS_GPIO/value

	echo "Reading GPIO INPUT:"
	GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI2/value`
	if (( $GPIOIN_VAL == 0 ))
	then
		echo_green "SPI2_CS${i} test PASSED with value $GPIOIN_VAL"
	else
		echo_red "SPI2_CS${i} test FAILED."
		STATUS=1
	fi
done

if [ -z "$STATUS" ]
then
	echo_green "ALL TESTS HAVE PASSED"
	console_ascii_passed
else
	echo_red "TESTS HAVE FAILED"
	console_ascii_failed
fi

while true; do
done