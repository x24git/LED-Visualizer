LED-Visualizer
=====================

### See the it in action: [Youtube](https://youtu.be/qRO2x7tB3jM)

A processing sketch that performs an FFT (using the Minim library) to visualize music in real time on an LED strip (AdaFruit NeoPixel) controlled via Arduino.
It also displays a live spectrograph of the audio including the current primary color. The spectrograph is composed of multiple frequency buckets each assigned a hue which you can rotate in the GUI. The bucket that has the highest response is sent via UART to the Arduino. The Arduino is primarily set to perform an ambient seeking pattern until it recieves a signal over UART from the processing program. Once data is recieved, the arduino will start a ripple or wave effect where the color propogates through the strip over time.

Setup
=====================

1. Verify that `stripLength` in arduino.ino (under `Adafruit_NeoPixel()`), and the length of your actual LED strip are all in agreement.
2. Upload Reciever.ino to your Arduino; attach your LED strip to pin 7.
3. Make sure the correct serial port is selected in EQ.pde (under `setup()`). Currently it is set to `new Serial(this, Serial.list()[1],4800);`
    To determine what serial port your arduino is using click [here](https://www.startech.com/faq/change-com-port-number-windows)
4. Ensure that your prefered input device is made default. If you want to have the visualizer pull directly from the line output, then you will need to ensure that the `Stereo Mix` sound device is enabled in Recording devices and set as default (see option 1 in [this article](https://www.howtogeek.com/217348/how-to-record-the-sound-coming-from-your-pc-even-without-stereo-mix/))

> If you use the processing script .pde you will need to add the `minim` library to communicate with the arduino over UART

**If the sketch fails to connect to the specified serial port or the default `Line In` audio device is not setup, an error will be logged to the console. If using the exe, no error will be seen.**

Usage
=====================

For ease of use, I have encluded the exe for the processing script that does not require the instillation of processing and does not require you to build any program. You will simply need to upload the arduino.ino file (making any changes to the `Adafruit_NeoPixel()` function to match your light strip) and start using it. Alternatively you can run the program with processing and play with encoding and fft settings

The GUI is very intuitive with the arrow keys determining brightness (up and down) and hue shift (left and right). 

> Please note that since the controller uses the default `Line In` (most users this will be `Stereo Mix`) as the input for the FFT function, it is affected by volume. I have added correction logic to prevent FFT values from clipping and washing out the specturm, however at low volumes FFT computation may be inaccurate and may fail to pick up any sound at all. This is sadly a limitation of Java  as it can not listen directly to the outgoing audio bus and thus cannot read the normalized audio values.


# Licensing
Copyright (c) 2014 Christopher Makarem

LED-Visualizer is licensed under the MIT License.  To read the full terms, please see the LICENSE file that should have been provided with all copies or substantial portions of the Software. Alternatively, the generic MIT license text can be read [here](http://opensource.org/licenses/MIT)
