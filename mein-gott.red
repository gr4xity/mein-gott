Red [
	Title:	"Mein Gott!"
	Author:	"Justin the Smith"
	Date: 2024-06-07
	Needs:	'View
	Icon: %icons/64x64.ico
	History: [
		0.1.0 [2019-06-30 "Initial planar azimuthal projection with angular momentum" "Justin the Smith"]
		0.2.0 [2021-02-25 "Add new Gott projection!" "Justin the Smith"]
		0.3.0 [2023-01-24 "Reworked image loading to support multiple images" "Justin the Smith"]
		0.4.0 [2023-02-05 "Removed old planar azimuthal projection" "Justin the Smith"]
		0.5.0 [2023-02-11 "Dynamic resizing" "Justin the Smith"]
		0.6.0 [2023-02-12 "Select map from menu, shuffle forward/backward with mouse wheel" "Justin the Smith"]
		0.7.0 [2023-02-18 "Reorganized image linking, downloading, and caching" "Justin the Smith"]
		0.8.0 [2023-02-20 "Retitled, added loading splash and menu controls" "Justin the Smith"]
		0.9.0 [2023-02-25 "Added optional parallels and option toggle for stars" "Justin the Smith"]
		1.0.0 [2023-02-26 "Documentation and release!" "Justin the Smith"]
		1.0.1 [2024-05-12 "Updated for latest Red" "Justin the Smith"]
		1.0.2 [2024-05-12 "Minor cleanup" "Justin the Smith"]
		1.0.2 [2024-06-07 "Switched to higher resolution source images to showcase subpixel rendering" "Justin the Smith"]
	]
	See-Also: https://vanderbei.princeton.edu/planets_webgl/GottPlanets.html
]

; shared configuration
random/seed now/time/precise	; set random seed
tps: 60							; frame rate, ticks per second
mouse-state: 'up				; track dragging
window-flags: [resize no-max]	; configure view window

; map configuration, state, and operations
map: make reactor! [
	; image configuration
	image-source: https://vanderbei.princeton.edu/planets_webgl/
	menu: [
		"Earth"	Earth	%EarthMap_brighter_2500x1250.jpg
		"Earth No Ice"	EarthNoIce	%pixy_earth_431843_2500x1250.jpg
;		"EarthCountries"	EarthCountries	%World_location_map_equirectangular_1250x625.jpg
		"Moon 1"	Moon1	%MoonMap_mixed_RGB_2500x1250.jpg
		"Moon 2"	Moon2	%moon_2500x1250.jpg
		"Mars"	Mars	%5672_mars_12k_color_annotated_2500x1250.jpg
		"Jupiter Cassini"	Jupiter1	%jupiter_cassini_2500x1250.jpg
		"Jupiter CSS"	Jupiter2	%jupiter_css_2500x1250.jpg
		"Jupiter VGR2"	Jupiter3	%jupiter_vgr2_2500x1250.jpg
		"Saturn"	Saturn	%saturn_2500x1250.jpg
		"Tycho Stars"	TychoStars	%tycho8_2500x1250.jpg
		"Milky Way"	MilkyWay	%milkyway_1250x2500.jpg
		"Planck Cosmos"	PlanckCosmos	%PlanckCosmos2_cropped_2500x1250.png
	]

	; mouse operations
	coord1: coord2: 0x0		; track last two clicked coordinates
	wheel-angle: 9			; degree shift from mouse scroll

	; graphical model
	window-size: as-pair 0.4 * system/view/screens/1/size/y 0.8 * system/view/screens/1/size/y
	current-angle:	0		; initialize animation placement
	star-scale: 3			; render scaling factor for star background
	star-density: 20%		; relative density of stars
	stars?: true			; render stars?
	parallels?: true		; render key parallels?
	parallel-lines: 12		; number of paralles in each dimension
	shadow?: true			; render sun shadow?

	; physics model
	moment-of-inertia: 1.0	; constant for momentum calculation
	angular-velocity: -1 * 3 / tps	; start animation, Earth spins counter-clockwise

	; empty images for hemispheres
	image-key: image: none
	north: south: make image! window-size / 1x2
	maps: make map! []

	; function defintions
	load-image: func [
		"Try to load map image by menu key, inform error on fail"
		key [word!]
	/local image-url image-data
	][
		image-key: key
		if all [
			not maps/(image-key)
			any [
				error? try [image-data: read/binary image-url: to-url rejoin [image-source select menu key]]
				not image: load/as image-data 'jpeg
			]
		][
			view/flags compose [
				title "Mein Gott, an Error!"
				text bold "Sorry, cannot load map image."
				return
				text (form image-url)
				return
				button "Quit" [unview]
				button "Open in Browser" [browse image-url]
			][modal]
			quit
		]
	]

	generate-map: func [
		"Generate circular map hemispheres from square source images"
		/local w h r x y a b rad lat lon northern southern
	][
		either images: select maps image-key [
			north: images/1	; grab from cache
			south: images/2	; if available
		][
			; short-cuts to characterize image sizes
			w: image/size/y	; size of square
			h: w * 2		; width of image
			r: w / 2		; half of square

			; new black background for hemispheres
			north: copy south: make image! reduce [as-pair w w 0.0.0.0]

			; iterate through destination pixels
			repeat y w [
				repeat x w [
					; target relative offsets from center
					a: (x - 1) - r
					b: r - (y - 1)

					; draw if within circle's radius
					if r >= rad: square-root add a * a b * b [
						; determine spherical coordinates from relative offsets
						lat: (1 - (rad / r)) * pi / 2
						lon: atan2 b a

						; transform to rectangular coordinates
						a: multiply cos lon cos lat
						b: multiply sin lon cos lat

						; reproject to longitude
						lon: atan2 b a

						; convert to source pixel indices for northern hemisphere
						northern: to-pair reduce [
							1 + round/floor (w + ((lon * w / pi) + (h / 16))) % h
							1 + round/floor (r - (lat * r * 2 / pi)) % w
						]

						; rotate source pixel indices for southern hemisphere
						southern: to-pair reduce [
							1 + ((r + northern/x) % h)
							w - northern/y
						]

						; draw both hemispheres
						poke north as-pair x y pick image northern
						poke south as-pair y x pick image southern ; rotating coords
					]
				]
			]
			; cache rendered map images
			extend maps reduce [image-key reduce [north south]]
		]
	]

	; dynamically size and center hemispheres
	hemi-size: center-north: center-south: radius: none	; definitions for compiler (deprecated IS handled this but new RELATE doesn't)
	relate hemi-size: [as-pair window-size/x window-size/x]
	relate center-north: [(hemi-size / 2) + 0x1]
	relate center-south: [(hemi-size / 2) + to-pair reduce [0 1 + hemi-size/x]]
	relate radius: [window-size/x / 2]

	; measurement functions
	distance-zero: function [
		"Calculate distance from a point to centrum"
		a	[pair! point2D!]
	][
		either error? try [d: square-root add (power a/x 2) (power a/y 2)][none][d]
	]

	distance-between: func [
		"Calculate distance between points"
		a	[pair! point2D!]
		b	[pair! point2D!]
	][
		distance-zero a - b
	]

	measure-angle: func [
		"Measure angle between x and y coordinates in a pair"
		pair [pair! point2D!]
	][
		case [
			pair/x <> 0 [
				arctangent divide pair/y pair/x
			]
			true [-90]	; pick a side, correct later
		]
	]

	; physics model
	angular-momentum: does [
		multiply moment-of-inertia angular-velocity
	]

	apply: func [
		"Apply some angular momentum to current angle"
		momentum
	][
		current-angle: add current-angle momentum
		while [current-angle > 360]	[current-angle: current-angle - 360]
		while [current-angle < 0]	[current-angle: current-angle + 360]
	]

	iterate: func [
		"Apply current angular momentum"
	][
		apply angular-momentum
	]

	; cargtography
	parallels: function [
		"Draw key parallels (lines of latitude and longitude)"
		center [pair!]
	][
		collect [
			if parallels? [
				repeat i parallel-lines / 2 [	; half of latitude lines in each hemisphere
					keep compose [circle (center) (2 * i * radius / parallel-lines)]
				]
				repeat i parallel-lines [		; all longitude lines in each hemisphere
					keep compose/deep [
						rotate (i * 360 / parallel-lines) (center) [
							line (as-pair 0 center/y) (as-pair 2 * radius center/y)
						]
					]
				]
			]
		]
	]

	; procedural generation
	nrandom: func [
		"Box-Muller pseudo-random from pseudo-normal distribution"
		/scale factor [number!]
	][
		multiply either scale [factor] [1.0] multiply square-root multiply -2 log-e random 1.0 cosine multiply multiply 2 pi random 1.0
	]

	space: function [
		"Generate random star background"
	][
		; scale parameters once
		n: star-scale * center-north
		s: star-scale * center-south
		r: star-scale * radius
		w: star-scale * window-size

		; collect stars
		stars: collect [
			repeat i num-stars: either stars? [star-scale * star-density * window-size/x * window-size/y][0] [
				star-center: random w	; from uniform distribution
				star-radius: multiply divide i num-stars divide exp nrandom 12	; from log-normal distribution

				; only render visible stars
				if 0 < mask: star-radius + (min (distance-between star-center n) (distance-between star-center s)) - r [
					star-bright: multiply divide i num-stars multiply divide min 32.0 mask 32.0 random 255
					star-color: 1.5 * to-tuple reduce [
						star-bright * (rshine: 0.75 + random 0.25)
						min 255 star-bright * (bshine: (0.5 * rshine) + (0.5 * random rshine))
						min 255 star-bright * ((0.25 * bshine) + (0.5 * random rshine))
					]
					keep compose/deep [
						fill-pen (star-color)
						pen (star-color / 2)
						circle (star-center) (star-radius)
					]
				]
			]
		]

		; render scaled image
		draw make image! reduce [star-scale * window-size 0.0.0.0] stars
	]

	; map operation functions
	redraw: function [
		"Rewrite draw code for updated map state"
		face [object!]
	][
		angles: reduce [current-angle -1 * current-angle]
		n: length? angles
		parse face/draw [
			n [
				thru angler: l: (
					l/2: angles/1
					angles: next angles
				)
			]
		]
	]

	spin-table: func [
		"Spin turntable from mouse input"
		event [event!]
		face [object!]
	][
		if mouse-state = 'down [
			coord2: event/offset	; get new state

			; select hemisphere
			either coord2/y > north/size/y [
				centrum: center-south
				coriolis: -1.0
			][
				centrum: center-north
				coriolis: 1.0
			]

			; calculate angular change in position before and after
			angle1: measure-angle diff1: coord1 - centrum
			angle2: measure-angle diff2: coord2 - centrum
			angular-velocity: (coriolis * (angle2 - angle1)) + either all [
				angle1 * angle2 < 0			; different sign in angle
				any [
					angle1 = -90			; dx = 0
					angle2 = -90			; dx = 0
					(diff2/x * diff1/x) < 0	; different half of canvas
				]
			][180][0]	; correct arctangent boundaries

			; update new state
			coord1: coord2
			iterate
		]
	]
]

; GUI layouts and building blocks
loading: layout compose/deep [
	title "Loading Mein Gott!"
	below
	text 320x24 center italic font-size 13 "All these worlds are yours, on a turntable!"
	base 320x320 170.144.124 draw [ ; record grooves
		fill-pen radial 63.63.63 63.63.63 63.63.63 63.63.63 63.63.63 63.63.63 0.0.0 0.0.0 23.23.23 0.0.0 0.0.0 23.23.23 0.0.0 0.0.0 0.0.0 23.23.23 0.0.0 0.0.0 31.31.31 0.0.0 0.0.0 23.23.23 0.0.0 0.0.0 0.0.0 31.31.31 0.0.0 0.0.0 0.0.0
		circle 160x160 148
		fill-pen (31.31.31 + random 233.233.233)
		circle 160x160 48
		fill-pen black
		circle 160x160 3
	]
	text 320x24 bold "Please wait while initializing objects..."
]

about: layout [
	title "About Mein Gott!"
	below
	text 320x24 center italic font-size 13 "Mein Gott! 1.0 - A Chaoskampf Prototype"
	rich-text 320x320 font-size 9 {Azimuthal maps project views of planets from a perspective in space, "ray-tracing" to render 2D images of 3D spheres.

Two view from opposite poles can show an entire planet on-screen--in a strategy-based video game for example.

This app began as a game mechanic prototype in 2019, using a Lambert azimuthal equal-area projection.

In 2021, Gott, Goldberg, and Vanderbei published "the most accurate flat map of Earth yet". This double-sided Gott equidistant azimuthal projection not only minimizes spatial distortion, it features a similar two-hemisphere presentation.

This inspired updating the Chaoskampf prototype to use the better maps--and give it a punnier name. Credit to Dr. Robert Vanderbei for the source cylindrical maps used to render Mein Gott! Be sure to check out his implementation of animated Gott projections as well.}
with [data: [1x9 italic 430x50 italic 750x10 italic]]

	across
	button "Ok" [unview about]
	button "Reference" [browse https://arxiv.org/ftp/arxiv/papers/2102/2102.08176.pdf]
	button "Vanderbei"  [browse https://vanderbei.princeton.edu/planets_webgl/GottPlanets.html]
	button "Say Thanks" [browse https://www.paypal.me/Chaoskampf/5]
]

controls: layout compose/deep [
	title "Controlling Mein Gott!"
	below
	text 320x24 center italic font-size 13 "All these worlds are yours, on a turntable!"
	rich-text 320x240 font-size 9 {Left mouse button: grab and drag to stop or spin the map!
A physics model applies angular momentum for animation.

Right mouse button: select a different map. Please be patient for rendering the first time you load a map.

Mouse wheel: scroll the map forwards or backwards relative to the cursor.

Resize the window from the left or right border. The height will adjust to preserve the map's aspect ratio.

The Options menu lets you configure map rendering.}
	with [
		data: [
			1x17 bold
			116x18 bold
			224x11 bold
			299x6 bold
			415x12 bold
			415x7 italic
		]
	]
	button "Ok" [unview controls]
]

main: [
	title "Mein Gott!"
	base (map/window-size) black draw [
		; random stars
		space: image (map/space) 0x0 (map/window-size)
		pen black line-width 0.5

		; northern hemisphere
		fill-pen bitmap (in map 'north) (map/north/size) 0x0
		scalar: scale 'fill-pen (divide map/window-size/x map/north/size/x) (divide map/window-size/x map/north/size/x)
		angler: rotate (map/current-angle) (map/center-north) [
			circle (map/center-north) (map/radius)
			pen white
			fill-pen off
			par: [(map/parallels map/center-north)]
		]
		shader: [
			pen 0.0.0.63 fill-pen 0.0.0.63
			arc (map/center-north) (as-pair map/radius map/radius) 270 180 closed
		]

		; southern hemisphere
		fill-pen bitmap (in map 'south) (map/south/size) 0x0
		scalar: scale 'fill-pen (divide map/window-size/x map/south/size/x) (divide map/window-size/x map/south/size/x)
		angler: rotate (map/current-angle) (map/center-south) [
			circle (map/center-south) (map/radius)
			pen white
			fill-pen off
			par: [(map/parallels map/center-south)]
		]
		shader: [
			pen 0.0.0.63 fill-pen 0.0.0.63
			arc (map/center-south) (as-pair map/radius map/radius) 270 180 closed
		]
	]
	rate (tps) on-time [
		if mouse-state = 'down [
			map/angular-velocity: 0	; grab
		]
		map/iterate
		map/redraw face
	]
	with [
		menu: [(map/menu)]
	]
	on-menu [
		map/load-image event/picked
		map/generate-map
	]
	on-up [
		mouse-state: 'up
	]
	on-down [
		mouse-state: 'down
		map/coord1: event/offset
	]
	all-over on-over [
		map/spin-table event face
	]
	on-wheel [
		diff: event/offset - (map/window-size / 2)
		map/apply multiply multiply either diff/x * diff/y < 0 [-1] [1] map/wheel-angle event/picked
	]
	do [
		unview loading	; close loading splash
	]
]
test: loc: none
window-controls: compose/deep [
	menu: [
		"Options" [
			"Toggle Parallels" parallels
			"Toggle Shadow" shadow
			"Toggle Stars" stars
		]
		"Map" [(map/menu)]
		"Help" [
			"Controls" controls
			"Restart Animation" restart
			"About Mein Gott!" about
		]
	]
]
append window-controls [
	actors: object [
		on-resize: func [face event][
			; lock window aspect ratio to image
			face/size/y: to-integer face/size/x * 2
			
			; update drawing
			sizes: reduce [map/north/size map/south/size]
			centers: reduce [map/center-north map/center-south]
			n: length? centers
			parse face/pane/1/draw [
				thru space: space: (space/4: face/size)
				n [
					thru scalar: l: (
						l/3: divide face/size/x sizes/1/x
						l/4: divide face/size/x sizes/1/x
					)
					thru angler: l: (l/3: centers/1)
					to block! into [
						loc: (
							loc/2: centers/1
							loc/3: map/radius
						)
						thru par: par: (par/1: map/parallels centers/1)
						to end
					]
					thru shader: into [
						thru 'arc l: (
							l/1: centers/1
							l/2: as-pair map/radius map/radius
						)
						to end
					]
					(	; iterate hemisphere
						sizes: next sizes
						centers: next centers
					)
				]
			]
			face/pane/1/size: face/size
			map/window-size: face/size
		]
		on-menu: func [face event][
			case [
				find map/menu event/picked [
					map/load-image event/picked
					map/generate-map
				]
				switch event/picked [
					controls [view/no-wait controls]
					about [view/no-wait about]
					thanks [browse https://www.paypal.me/Chaoskampf/5]
					restart [
						map/angular-velocity: -1 * 3 / tps
					]
					stars [
						map/stars?: not map/stars?
						parse face/pane/1/draw [
							thru space: l: (l/2: map/space)
						]
					]
					shadow [
						map/shadow?: not map/shadow?
						parse face/pane/1/draw [
							2 [
								thru shader: into [
									thru 'pen l: (
										l/1: l/3: either map/shadow? [
											0.0.0.47
										][
											0.0.0.255
										]
									)
									to end
								]
							]
						]
					]
					parallels [
						map/parallels?: not map/parallels?
						centers: reduce [map/center-north map/center-south]
						n: length? centers
						parse face/pane/1/draw [
							n [
								thru angler: to block! into [
									thru par: par: (
										par/1: map/parallels centers/1
										centers: next centers
									)
									to end
								]
							]
						]
					]
				]
			]
		]
	]
]

; startup-sequence
view/no-wait loading

loading/pane/3/text: "Please wait while downloading cylindrical projection..."
map/load-image map/menu/2

loading/pane/3/text: "Please wait while reprojecting to spherical map..."
map/generate-map

loading/pane/3/text: "Please wait while generating star background..."
view/flags/options/tight compose/deep main window-flags window-controls
