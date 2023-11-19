Some collected ideas on how to make this library easy to use.
The idea of the library is to easily program a LED strip (like WS2801), to create different effects and to easily change the effects on the fly (similar to [sonic pi](https://sonic-pi.net))

* change the brightness through a `with :brightness` block that also alows dynamic brightness settings with a function
* define the colors with a simple function (like rainbow)
* allow the colors to move with a simple move function (move 1) wich just changes the offset by a ceratin amount
* allow different loops to interact (you could have a single red light move always to the right and a single blue light to the left. When the two colors meet on a single pixel they would mix to a purple color)
* allow the synchronisation with an external event

# Research:
Color blending from: https://meyerweb.com/eric/tools/color-blend/#FF0000:0000FF:5:hex
```javascript
function drawPalette() {
	stepCalc();
	mixPalette();
	for (i = 0; i < 12; i++) {
		colorPour('pal',i);
	}		
	updateHash();
}

function stepCalc() {
	var steps = parseInt(document.getElementById('steps').value) + 1;
	step[0] = (ends[1].r - ends[0].r) / steps;
	step[1] = (ends[1].g - ends[0].g) / steps;
	step[2] = (ends[1].b - ends[0].b) / steps;
}

function mixPalette() {
	var steps = parseInt(document.getElementById('steps').value);
	var count = steps + 1;
	palette[0] = new Color(ends[0].r,ends[0].g,ends[0].b);
	palette[count] = new Color(ends[1].r,ends[1].g,ends[1].b);
	for (i = 1; i < count; i++) {
		var r = (ends[0].r + (step[0] * i));
		var g = (ends[0].g + (step[1] * i));
		var b = (ends[0].b + (step[2] * i));
			palette[i] = new Color(r,g,b);
	}
	for (j = count + 1; j < 12; j++) {
		palette[j].text = '';
		palette[j].bg = 'white';
	}
}
```

Possible call constructs:
```elixir
lights :exact, do
	<<rgb, rgb, rgb, ...>>
end
```
or
```elixir
lights :stretch, do
	<<rgb, rgb, rgb, ...>>
end
```
or
```elixir
lights :repeat, do
	<<rgb, rgb, rgb, ...>>
end
```
In general it follows a stucture like:
```elixir
lights opts, do
 	... 
 end
```
It should also be possible to nest light sequences, i.e.:
```elixir
lights :exact, do
	lights type: :repeat, number: 32, do
		[rgb]
	end
	lights type: :stretch, number: 32, do
		[rgb, rgb]
	end
	lights %{type: :increment, color: rgb, number: 32}, do
		[rgb]
	end
end
```

Dimming, brightness
```elixir
with_brightness ops, do
	...
end
```

Movements
```elixir
with_movement ops, do
	# default movement (offset) is 1, rotating around 
	# list rotation can be achieved through something like:
	# vals = 1..9
	# Enum.slide(vals, 0..rem(o-1 + Enum.count(vals),Enum.count(vals)), Enum.count(vals))
	# resulting in: [1, 2, 3, 4, 5, 6, 7, 8, 9]
	...
end
```
Through the ops it should be possible to specify the speed, it should be possible to synchronize (? not quite sure how that would work)

We also want to have a `animation` so that things can be changed on the fly.
Two `animation`s will mix the colors together from the two loops 