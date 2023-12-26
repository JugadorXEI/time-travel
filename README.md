
# Time Travel
This is the code-only repository for the Time Travel mechanic for Sonic Robo Blast 2 Kart. This mechanic allows players to move between two different versions of the level seamlessly.

See [ChronoShift Track Pack](https://mb.srb2.org/addons/chronoshift-track-pack.5339/)'s ChronoShift Zone as an example on this gimmick.

All code contributions welcome, no matter if they are bugfixes, improvements or interoperability.
# Requirements
## Using It
Time Travel works purely using Level Headers (defined in a SOC file, as normally done), and only requires a graphics file for the Future version of the minimap.

Adding it onto a level works as follows:
* Get a release from either the SRB2 MB or this GitHub.
* Open this file in SLADE. Copy and paste all of the files inside of your own PK3. If you're using a WAD file, you may need to set the markers manually for each type of file as well.
* Set the Map Headers as described below.
* Create a minimap for the future version of the level.
* For the Future version of the level, give all Boss Waypoints the `[4] Special` flag.
* Done!
## Map Headers
* **Lua.TT_2ndMapXYOffset**
	* Takes two comma-delimited numbers for the X and Y offset for the Future version of the level (for example. `16640,0`). This offset will be used for time travel teleports and echo positioning.
	* The best way to obtain this value is by using Zone Builder's Draw Rectangle Tool, clicking somewhere in the Past version of the level (preferably the corner of a room, for example), and then place your cursor on the equivalent part of the level in the Future version of the map. The width and height of this rectangle will be the offset you set in this header.

![Draw Rectangle Tool showing 1024,4096](https://github.com/JugadorXEI/time-travel/assets/1565198/16a0387d-bfc2-4d5e-b014-74128c5be9fd)
* **Lua.TT_2ndMapSkyNum**
	* Takes a sky number (for example. `8482`). The sky texture that will be used when the player is in the future version of the level.
* **Lua.TT_2ndMapSkyBoxID**
	* Takes a skybox number (for example, `1`). The Skybox ID to be used for the Future version of the level.
* **Lua.MMLib_LLBounds**
	* Takes two comma-delimited numbers that denine the lower left position of the Past level (for example, `-30848,16512`). This is used for the minimap boundaries.
	* In the lower right of Zone Builder's interface, wherever you place your cursor will show you the absolute position it would be in the level. Place your cursor on the lower left part of the level (including the empty space), note it, and put it as this level header.
* **Lua.MMLib_URBounds**
	* Takes two comma-delimited numbers that denine the upper right position of the Past level (for example, `-15616,31872`). This is used for the minimap boundaries.
	* In the lower right of Zone Builder's interface, wherever you place your cursor will show you the absolute position it would be in the level. Place your cursor on the upper right part of the level (including the empty space), note it, and put it as this level header
 
![Where the cursor should be for getting the lowest point and upper right points for the minimap.](https://github.com/JugadorXEI/time-travel/assets/1565198/d503cb46-9dcf-4272-907c-7b9496b5f073)
* **Lua.musname_future**
	* Takes a music lump name (for example, `CHRSHF`). This is the music lump used when the player is in the future. Optional.
## Graphics
The only graphic required to make Time Travel work properly is a minimap that will display in the Future version of the map. For example, `MAPXER` for the regular Past minimap (same as with other maps), and `MAPXERI` for the Future minimap.

The best way to do this is to remove the Future version temporarily, save, use `Save Map Image` in SLADE in your level, do the minimap as per usual, then undo that change in Zone Builder.
## Music
Having a Future version of the music is optional, but if you do use it, as a guideline **make sure** that it is the same BPM and roughly the same duration as the Past music. You can make BPM adjustments using Audacity.
# Credit
* JugadorXEI: Main Programmer
* Mr.Logan: GFX.
* Sound effects from Titanfall 2, Sonic CD and Half-Life. Copyright belongs to their respective owners.

# Terms
```
Time Travel - allow players to travel between two different versions of the same level.
Copyright (C) 2019-2024 Kart Krew
Copyright (C) 2023-2024 JugadorXEI

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
```
