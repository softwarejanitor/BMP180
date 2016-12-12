require("I2C");
require("math");

// Create an I2C instance
i2c <- I2C(0);

dofile("sd:/BMP180.nut");

local bmp180 = BMP180(i2c, 0x77);

bmp180.begin();

delay(50);

local temp;
local press;

bmp180.startTemperature();

temp = bmp180.getTemperature();

bmp180.startPressure(0);

press = bmp180.getPressure();

print("temp=" + temp + " degrees C\n");

local fahr;

fahr = bmp180.celsius_to_fahrenheit(temp);

print("temp=" + fahr + "degrees F\n");

print("press=" + press + " millibars\n");

local sealvl;

sealvl = bmp180.sealevel(press, 149.0);

print("sealevel=" + sealvl + " millibars\n");

