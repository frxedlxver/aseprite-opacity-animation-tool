# aseprite-opacity-animation-tool

Generate fade animations in Aseprite using keyframes (via cel opacity).


## Installation
	1. Download .zip
	2. Open Aseprite's scripts folder (File>Scripts>Open Scripts Folder)
	3. Extract "opacity animation.lua" to root of scripts folder

## Usage
### How to run:
	1. Run script in Aseprite (file>scripts>opacity animation)
	2. Select any layer(s) you want to generate an animation for
	3. Select frame to start animation on
	4. Choose animation duration (in frames)
	5. set inital opacity (0 - 255)
	6. Set target opacity (0 - 255)
	7. Choose animation mode (linear or cycle)

### Notes:
	* animation direction can be changed by swapping inital and target opacity
	* limits on duration and opacity can be changed by editing respective slider.max values in OpacityDialog:Show()
