/*
	SFE_BMP180.h
	Bosch BMP180 pressure sensor library for the Arduino microcontroller
	Mike Grusin, SparkFun Electronics

	Uses floating-point equations from the Weather Station Data Logger project
	http://wmrx00.sourceforge.net/
	http://wmrx00.sourceforge.net/Arduino/BMP085-Calcs.pdf

	Forked from BMP085 library by M.Grusin
    Ported to Esquilo by Leeland Heins

	version 1.0 2013/09/20 initial version
	Verison 1.1.2 - Updated for Arduino 1.6.4 5/2015
	
	Our example code uses the "beerware" license. You can do anything
	you like with this code. No really, anything. If you find it useful,
	buy me a (root) beer someday.
*/

const BMP180_ADDR = 0x77;  // 7-bit address

const BMP180_REG_CONTROL = 0xF4;
const BMP180_REG_RESULT = 0xF6;

const BMP180_COMMAND_TEMPERATURE = 0x2E;
const BMP180_COMMAND_PRESSURE0 = 0x34;
const BMP180_COMMAND_PRESSURE1 = 0x74;
const BMP180_COMMAND_PRESSURE2 = 0xB4;
const BMP180_COMMAND_PRESSURE3 = 0xF4;

class BMP180
{
    i2c = null;
    addr = null;
    
    AC1 = 0;
    AC2 = 0;
    AC3 = 0;
    AC4 = null;
    AC5 = null;
    AC6 = null;
    VB1 = 0;
    VB2 = 0;
    MB = 0;
    MC = 0;
    MD = 0;
    
    c3 = 0.0;
	c4 = 0.0;
	b1 = 0.0;
	c5 = null;
	c6 = null;
	mc = null;
	md = null;
	x0 = null;
	x1 = null;
	x2 = null;
	y0 = null;
	y1 = null;
	y2 = null;
	p0 = null;
	p1 = null;
	p2 = null;

    
    tu = 0.0;
    a = 0.0;
    T = 0.0;
        
    pu = 0.0;
    s = 0.0;
	x = 0.0;
	y = 0.0;
	z = 0.0;
    P = 0.0;
    
    constructor(_i2c, _addr)
    {
        i2c = _i2c;
        addr = _addr;
    }
};


// 16 bit  two's complement
// value: 16 bit integer
function BMP180::twoCompl(value)
{
    if (value > 32767) {
        value = -(65535 - value + 1);
    }
    return value;
}


// Initialize library for subsequent pressure measurements
function BMP180::begin() 
{
    i2c.address(addr);
    AC1 = twoCompl(i2c.read16(0xAA));
	AC2 = twoCompl(i2c.read16(0xAC));
	AC3 = twoCompl(i2c.read16(0xAE));
	AC4 = i2c.read16(0xB0);
	AC5 = i2c.read16(0xB2);
	AC6 = i2c.read16(0xB4);
	VB1 = twoCompl(i2c.read16(0xB6));
	VB2 = twoCompl(i2c.read16(0xB8));
	MB = twoCompl(i2c.read16(0xBA));
	MC = twoCompl(i2c.read16(0xBC));
	MD = twoCompl(i2c.read16(0xBE));
    
    /*
    print("AC1: " + AC1 + "\n");
	print("AC2: " + AC2 + "\n");
	print("AC3: " + AC3 + "\n");
	print("AC4: " + AC4 + "\n");
	print("AC5: " + AC5 + "\n");
	print("AC6: " + AC6 + "\n");
	print("VB1: " + VB1 + "\n");
	print("VB2: " + VB2 + "\n");
	print("MB: " + MB + "\n");
	print("MC: " + MC + "\n");
	print("MD: " + MD + "\n");
    */
    
    // Compute floating-point polynominals:

	c3 = 160.0 * pow(2, -15) * AC3;
	c4 = pow(10, -3) * pow(2, -15) * AC4;
	b1 = pow(160, 2) * pow(2, -30) * VB1;
	c5 = (pow(2, -15) / 160) * AC5;
	c6 = AC6;
	mc = (pow(2, 11) / pow(160, 2)) * MC;
	md = MD / 160.0;
	x0 = AC1;
	x1 = 160.0 * pow(2, -13) * AC2;
	x2 = pow(160 ,2) * pow(2, -25) * VB2;
	y0 = c4 * pow(2, 15);
	y1 = c4 * c3;
	y2 = c4 * b1;
	p0 = (3791.0 - 8.0) / 1600.0;
	p1 = 1.0 - 7357.0 * pow(2, -20);
	p2 = 3038.0 * 100.0 * pow(2, -36);

    /*
	print("c3: " + c3 + "\n");
	print("c4: " + c4 + "\n");
	print("c5: " + c5 + "\n");
	print("c6: " + c6 + "\n");
	print("b1: " + b1 + "\n");
	print("mc: " + mc + "\n");
	print("md: " + md + "\n");
	print("x0: " + x0 + "\n");
	print("x1: " + x1 + "\n");
	print("x2: " + x2 + "\n");
	print("y0: " + y0 + "\n");
	print("y1: " + y1 + "\n");
	print("y2: " + y2 + "\n");
	print("p0: " + p0 + "\n");
	print("p1: " + p1 + "\n");
	print("p2: " + p2 + "\n");
    */
}


// Begin a temperature reading.
// Will return delay in ms to wait, or 0 if I2C error
function BMP180::startTemperature()
{
    i2c.address(addr);
    i2c.write8(BMP180_REG_CONTROL, BMP180_COMMAND_TEMPERATURE);
    delay(5);
}


// Retrieve a previously-started temperature reading.
// Requires begin() to be called once prior to retrieve calibration parameters.
// Requires startTemperature() to have been called prior and sufficient time elapsed.
// T: external variable to hold result.
// Returns 1 if successful, 0 if I2C error.
function BMP180::getTemperature()
{
    local data = array(2);
    
    i2c.address(addr);
    data[0] = i2c.read8(BMP180_REG_RESULT);
    data[1] = i2c.read8(BMP180_REG_RESULT + 1);
    /*
    print("data0=" + data[0] + "\n");
    print("data1=" + data[1] + "\n");
    */
    tu = (data[0] * 256.0) + data[1];
	//example from Bosch datasheet
	//tu = 27898;

	//example from http://wmrx00.sourceforge.net/Arduino/BMP085-Calcs.pdf
	//tu = 0x69EC;
		
	a = c5 * (tu - c6);
	T = a + (mc / (a + md));

    /*
	print("tu: " + tu + "\n");
    print("a: " + a + "\n");
	print("T: " + T + "\n");
    */
    
    return T;
}


// Begin a pressure reading.
// Oversampling: 0 to 3, higher numbers are slower, higher-res outputs.
// Will return delay in ms to wait, or 0 if I2C error.
function BMP180::startPressure(oversampling)
{
    i2c.address(addr);
    if (oversampling == 0) {
        i2c.write8(BMP180_REG_CONTROL, BMP180_COMMAND_PRESSURE0);
        delay(5);
    } else if (oversampling == 1) {
        i2c.write8(BMP180_REG_CONTROL, BMP180_COMMAND_PRESSURE1);
        delay(8);
    } else if (oversampling == 2) {
        i2c.write8(BMP180_REG_CONTROL, BMP180_COMMAND_PRESSURE2);
        delay(14);
    } else if (oversampling == 3) {
        i2c.write8(BMP180_REG_CONTROL, BMP180_COMMAND_PRESSURE3);
        delay(26);
    }
}


// Retrieve a previously started pressure reading, calculate abolute pressure in mbars.
// Requires begin() to be called once prior to retrieve calibration parameters.
// Requires startPressure() to have been called prior and sufficient time elapsed.
// Requires recent temperature reading to accurately calculate pressure.

// P: external variable to hold pressure.
// T: previously-calculated temperature.
// Returns 1 for success, 0 for I2C error.

// Note that calculated pressure value is absolute mbars, to compensate for altitude call sealevel().
function BMP180::getPressure()  
{
    local data = array(3);
    i2c.address(addr);
    data[0] = i2c.read8(BMP180_REG_RESULT);
    data[1] = i2c.read8(BMP180_REG_RESULT + 1);
    data[2] = i2c.read8(BMP180_REG_RESULT + 2);
    /*
    print("data0=" + data[0] + "\n");
    print("data1=" + data[1] + "\n");
    print("data2=" + data[2] + "\n");
    */
    pu = (data[0] * 256.0) + data[1] + (data[2] / 256.0);
    /*
    print("pu=" + pu + "\n");
    */
    
    s = T - 25.0;
	x = (x2 * pow(s, 2)) + (x1 * s) + x0;
	y = (y2 * pow(s, 2)) + (y1 * s) + y0;
	z = (pu - x) / y;
	P = (p2 * pow(z, 2)) + (p1 * z) + p0;
    
    /*
    print("pu: " + pu + "\n");
	print("T: " + T + "\n");
	print("s: " + s + "\n");
	print("x: " + x + "\n");
	print("y: " + y + "\n");
	print("z: " + z + "\n");
	print("P: " + P + "\n");
    */
    
    return P;
}


// Given a pressure P (mb) taken at a specific altitude (meters),
// return the equivalent pressure (mb) at sea level.
// This produces pressure readings that can be used for weather measurements.
function BMP180::sealevel(_P, _A)  
{
	return(_P / pow(1 - (_A / 44330.0), 5.255));
}


// Given a pressure measurement P (mb) and the pressure at a baseline P0 (mb),
// return altitude (meters) above baseline.
function BMP180::altitude(_P, _P0)
{
	return(44330.0 * (1 - pow(_P / _P0, 1 / 5.255)));
}


function BMP180::celsius_to_fahrenheit(celsius)
{
    local fahrenheit;
    
    fahrenheit = (1.8 * celsius) + 32;
    
    return fahrenheit;
}

