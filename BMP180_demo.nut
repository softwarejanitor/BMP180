require("I2C");
require("math");

// Create an I2C instance
i2c <- I2C(0);

// Load the library.
dofile("sd:/BMP180.nut");

// Create the object.
local bmp180 = BMP180(i2c, 0x77);

// Initialize the sensor.
bmp180.begin();

// Give the sensor a chance to become ready.
delay(50);

local temp;
local press;

// Start a temperature reading.
bmp180.startTemperature();

// Get temperature reading from sensor.
temp = bmp180.getTemperature();

// Start a pressure reading.
bmp180.startPressure(0);

// Get pressure reading from sensor.
press = bmp180.getPressure();

// Output temperature in degrees celsius.
print("temp=" + temp + " degrees C\n");

local fahr;

// Convert celsius to fahrenheight.
fahr = bmp180.celsius_to_fahrenheit(temp);

// Output temperature in degrees fahrenheit.
print("temp=" + fahr + "degrees F\n");

// Output pressure adjusted for sealevel.
print("press=" + press + " millibars\n");

local sealvl;

// Adjust pressure to sealevel, Austin is 149 meters above.
sealvl = bmp180.sealevel(press, 149.0);

// Output pressure adjusted for sealevel.
print("sealevel=" + sealvl + " millibars\n");

