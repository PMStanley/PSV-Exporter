# PSV Exporter

This is the source code for PSV Exporter 1.3, available as a Windows executable at [PS2 Save Tools](https://www.ps2savetools.com/download/psv-exporter/)

PSV Exporter allows you to manage the virtual PS1/PS2 saves (PSV files) that are created when playing a PS1 or PS2 game on the Playstation 3.

Import and export is available for the following formats:
* PS2 saves – Action Replay Max (\*.max)
* PS1 saves – single save format (\*.mcs)
* PSV Format – PS1 & PS2 (\*.psv)

## Important Note
My intention was to go back over this code, mainly written in 2006/2007, and bring it in-line with something I could call half-way decent.  _This did not happen._

The source code contained here is terrible, even the new PSV signature update, which is just a badly implemented version of the C code dots_tb created. **But it works.**
I will happily accept pull requests refactoring the code into something more readable and aligned to MVC.

## Usage for PS2 files
Load a .psv or .max file to display a list of the files contained within.
You can export as a PS2 save, a PSV file, extract individual files or extract all files at once.

If you extract all files you will be prompted to choose a location to save to. In this location a folder will created containing all the files, this maintains compatibility with uLaunchELF and PS2 save Builder (hint: The Root/ID should be named the same as this directory.)

On extraction any 'illegal' characters which Windows does not support in filenames will be removed.  These will need renaming to the correct filename if rebuilding in [PS2 Save Builder](https://www.ps2savetools.com/download/ps2-save-builder/) or another utility.

Exporting to .psv or .max file will create a save in the appropriate format.


## Usage for PS1 files
Simply load a .psv or .mcs file containing the PS1 save and press the PS1 button (or 'Extract PS1 save' menu item/popup menu item) to create a new single PS1 save.

Note: PS1 saves are extracted as .mcs files, these are a single save (as opposed to a card image such as Dexdrive).  Should you need a different save format a utility such as [PSXGameEdit](http://moberg-dybdal.dk/psxge/) should be of use.

Exporting to a PSV file will create a new save in the Playstation 3 PSV format.


## Specific file credits and licences
The following files were used in the creation of PSV Exporter.  Most of these were sourced around 2006/2007 and I have identified a licence where possible.
Some components have updated versions available, the original versions used in PSV Exporter 1.1 have been maintained in this release.
* BrowseForFolderU.aps
  * https://www.cryer.co.uk/brian/delphi/howto_browseforfolder.htm
  * No licence requirement listed
* ElAES.pas
  * http://www.eldos.org
  * Mozilla Public License Version 1.1
* myLZAri.pas
  * Unknown author & licence
* TFileDrag (v1.1)
  * Erik C. Nielsen ( 72233.1314@compuserve.com )
  * https://torry.net/authorsmore.php?id=810
  * Freeware licence

## Acknowledgements

Thanks to the following people who made PSV Exporter possible

* Angie
* Jay FNG Philbrook
* Jesse Toth
* Alvaro Santillana
* Jide Alabi
* Robert Fox II
* Kaspar
* [dots_tb](https://github.com/dots-tb) and crew ([AnalogMan151](https://github.com/AnalogMan151), [teakhanirons](https://github.com/teakhanirons), notzecoxao and nyaaasen)
* everyone else who offered or provided files to help build this tool.
