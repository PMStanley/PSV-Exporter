# PSV Exporter

PSV Exporter allows you to extract files from the virtual PS1/PS2 saves that are created when playing a PS1 or PS2 game on the Playstation 3.

This is the source code for PSV Exporter 1.1, available as a Windows executable at [PS2 Save Tools](http://www.ps2savetools.com/wpfb-file/psvexporter11-zip/)

## Usage for PS2 files
Load the PSV file to display a list of the files contained within.
You can extract individual files or all files at once.

When you extract all files you will be prompted to choose a location to save to. In this location a folder will created containing all the files, this maintains compatibility with uLaunchELF and PS2 save Builder (hint: The Root/ID should be named the same as this directory.)

On extraction any 'illegal' characters which Windows does not support in filenames will be removed.  These will need renaming to the correct filename if rebuilding in PS2SaveBuilder or another utility.

## Usage for PS1 files
Simply load the PSV file containing the PS1 save and press the PS1 button (or 'Extract PS1 save' menu item/popup menu item) and choose a name for the file.

PS1 saves are extracted as .mcs files, these are a single save (as opposed to a card image such as Dexdrive).  Should you need a different save format a utility such as [PSXGameEdit](http://moberg-dybdal.dk/psxge/) should be of use.

## Known issues
The function to remove invalid or 'illegal' characters from filenames is not working on Windows 10

## Acknowledgements

Thanks to the following people who made PSV Exporter possible

* Angie
* Jay FNG Philbrook
* Jesse Toth
* Alvaro Santillana
* Jide Alabi
* Robert Fox II
* Kaspar
* everyone else who offered or provided files to help build this tool.
