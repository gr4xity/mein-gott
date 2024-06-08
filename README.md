# Mein Gott!
Interactive turntable of planetary maps in the Gott projection.

## About

Azimuthal maps project views of planets from a perspective in space, "ray-tracing" to render 2D images of 3D spheres.

Two views from opposite poles can show an entire planet on-screen--in a strategy-based video game for example. This app began as a prototype by Chaoskampf Studios in 2019, using a Lambert azimuthal equal-area projection.

In 2021, Gott, Goldberg, and Vanderbei [published a new method](https://arxiv.org/ftp/arxiv/papers/2102/2102.08176.pdf) minimizing spatial distortion. This **Double-Sided Gott Equidistant Azimuthal projection** "is the most accurate flat map of Earth yet"! And the authors featured a similar two-hemisphere presentation--though focused on pedagogical use, especially paper maps.

In 2023, I discovered Dr. Robert Vanderbei's Javascript + WebGL [animated Gott projection](https://vanderbei.princeton.edu/planets_webgl/GottPlanets.html). This prompted dusting off the Chaoskampf prototype using his wider selection of map images. Credit to Dr. Vanderbei for the source cylindrical maps used to render Mein Gott! And check out his simulation as well.

## Features

- Spherical Geometry
	- [x] Reprojects hemispheres from a single cylindrical projection

- Physics Model
	- [x] Applies angular momentum for animation
	- [x] Grab to stop movement
	- [x] Drag and release to impart momentum

- User Interface
	- [x] Program and context menu controls
	- [x] Dynamic resizing preserving aspect ratio
	- [x] Configurable rendering options
		- [x] Random star background
		- [x] Key parallels (lines of longitude and latitude)

- Content
	- [x] Select from multiple maps of different planets
	- [x] Cache rendered images for fast switching

## Controls

- Left mouse button: grab and drag to stop or spin the map!

- Right mouse button: select a different map. Please be patient for rendering the first time you load a map.

- Mouse wheel: scroll the map forwards or backwards relative to the cursor.

- Resize the window from the left or right border, and the height will adjust to preserve the map's aspect ratio.

- You can change rendering options in the Options menu.

## Implementation

Mein Gott! is written in [Red](https://www.red-lang.org/p/about.html), a full-stack compiled & dynamic language inspired by Carl Sassenrath's [Rebol](http://www.rebol.com/)--the dynamic, human-friendly language that influenced Douglass Crockford's (static, crufty) [JSON](https://web.archive.org/web/20160310062651/http://www.dzone.com/links/the_making_of_json_by_douglas_crockford_an_influe.html). Homoiconicity is key: code is data, and data is code. Red is a general-purpose toolkit for developing [domain-specific languages](https://en.wikipedia.org/wiki/Domain-specific_language) or 'dialects' to suit particular tasks--which makes programming fun!

This app is largely a learning excercise for Red's:
- cross-platform graphics engine [Red/View](https://github.com/red/docs/blob/master/en/view.adoc)
- Visual interface dialect [Red/Vid](https://github.com/red/docs/blob/master/en/vid.adoc) for reactive UI layouts
- 2D Draw dialect [Red/Draw](https://github.com/red/docs/blob/master/en/draw.adoc) which supports matrix transforms

## Usage Notes

**Mein Gott!** can be run directly from the [Red/View interpreter](https://www.red-lang.org/p/download.html) on supported platforms.

Pre-compiled binaries are provided for select platforms as well. These should load and initialize much faster than interpreting the script dynamically.
- [x] [Windows](mein-gott.zip)

Note that Red is currently 32-bit only (Red is built in 32-bit Rebol 2, with migration to self-hosting with 64-bit support for Red 1.0. Red's initial development preceded 64-bit open-source [Rebol 3](https://github.com/rebol/rebol)). So you'll need appropriate 32-bit libraries on Linux while MacOS users may have to resort to a virtual machine, sorry!

Red apps are compiled directly to native system code without any external dependencies. It's a unique, self-contained toolchain. This uniqueness can trigger false positives from some anti-virus products. Please report false positives to your anti-virus vendor.

### Compilation ###

With the [Red Toolchain](https://www.red-lang.org/p/download.html) named redc.exe on Windows, compiling in release mode for the Windows platform:
```
redc.exe -r -t Windows mein-gott.red
```

Cross-compilation to other target platforms is easy:
```
redc.exe -r -t Linux mein-gott.red
```

## References

- [Gott, Goldberg, and Vanderbei (2021)](https://arxiv.org/ftp/arxiv/papers/2102/2102.08176.pdf)
- [Vanderbei's Planets: Gott Projection](https://vanderbei.princeton.edu/planets_webgl/GottPlanets.html)
