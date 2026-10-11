// Capture ring of a planet for THIS. One flat quad per planet lies in the
// plane the ships fly in; this shader draws the ring on it.
//
// What it shows:
//   - the ring itself, glowing in the owner's colour (pale blue when nobody
//     holds the planet), with two lights running around it
//   - a dashed inner track and an outer scale of ticks turning against each
//     other, and four brackets outside
//   - a faint field inside the ring with ripples moving to the centre
//   - contested: the ring breaks up, turns amber and flickers
//   - captured: a shock wave runs outwards and the field flashes
//
// The file has no #version line: the game puts "#version 330 compatibility"
// in front, the browser preview (tools/planets/make_preview.py) puts
// "#version 300 es" there. Output is premultiplied alpha.

in vec2 uv;              // position on the quad; the ring is at length(uv) = 1
flat in vec4 vColour;    // rgb: owner's colour; a: 0 nobody, 1 owned, 2 contested
flat in vec4 vParams;    // x: seconds since the owner changed; y: random number per planet

uniform float time;

out vec4 fragColor;

const float PI = 3.14159265;

float hash1(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

// a line across r at centre c, half-width w, never thinner than about a pixel
float line(float r, float c, float w, float px) {
	w = max(w, px * 0.75);
	return 1.0 - smoothstep(w * 0.5, w * 1.5, abs(r - c));
}

// 1 inside n evenly spaced arcs that each fill `fill` of their slot
float arcs(float a, float n, float fill, float soft) {
	float x = fract(a / (2.0 * PI) * n);
	return smoothstep(0.0, soft, x) * (1.0 - smoothstep(fill, fill + soft, x));
}

void main() {
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float px = fwidth(r);
	float seed = vParams.y;
	float t = time + seed * 10.0;

	bool owned = vColour.a > 0.5 && vColour.a < 1.5;
	bool contested = vColour.a > 1.5;

	vec3 colour = owned ? vColour.rgb : vec3(0.50, 0.68, 0.90);
	float power = owned ? 1.0 : 0.5;          // an unowned ring is quieter
	if (contested) {
		float flicker = 0.65 + 0.35 * sin(t * 17.0) * sin(t * 7.3);
		colour = mix(vec3(1.0, 0.45, 0.08), vec3(1.0, 0.85, 0.5), 0.5 + 0.5 * sin(t * 11.0));
		power = 0.9 * flicker + 0.25;
	}

	float glow = 0.0;    // light in the ring's colour
	float white = 0.0;   // the hottest parts go white
	float field = 0.0;   // how much the inside is filled

	// the ring: a sharp line with a soft glow on both sides
	float broken = 1.0;
	if (contested) {
		// gaps that jump around
		float slot = floor((a + t * 1.7) / (2.0 * PI) * 28.0);
		broken = step(0.35, hash1(slot + floor(t * 6.0) * 13.0));
	}
	float core = line(r, 1.0, 0.007, px) * broken;
	glow += core * 1.2;
	white += core * 0.5;
	glow += exp(-abs(r - 1.0) * 26.0) * 0.55 * broken;
	glow += exp(-abs(r - 1.0) * 7.0) * 0.14;

	// two lights running around the ring, each with a tail
	float speed = contested ? 2.6 : 0.55;
	for (int i = 0; i < 2; i++) {
		float head = t * speed + float(i) * PI;
		float behind = fract((head - a) / (2.0 * PI));
		float tail = pow(1.0 - behind, 9.0);
		float body = exp(-abs(r - 1.0) * 40.0);
		glow += tail * body * 1.6;
		white += pow(1.0 - behind, 40.0) * exp(-abs(r - 1.0) * 60.0) * 1.2;
	}

	// inner track of dashes, turning one way
	float dashes = arcs(a + t * 0.16, 48.0, 0.55, 0.08);
	glow += line(r, 0.925, 0.006, px) * dashes * 0.75;

	// outer scale of ticks, turning the other way; every sixth is longer
	float ta = a - t * 0.07;
	float tick = arcs(ta, 72.0, 0.16, 0.05);
	float longTick = arcs(ta, 12.0, 0.027, 0.008);
	float short_ = smoothstep(1.045, 1.05, r) * (1.0 - smoothstep(1.075, 1.08, r));
	float long_ = smoothstep(1.045, 1.05, r) * (1.0 - smoothstep(1.105, 1.11, r));
	glow += (tick * short_ * 0.45 + longTick * long_ * 0.9) * smoothstep(0.0, 2.5, 0.01 / max(px, 1.0e-5));

	// four brackets outside, breathing slowly
	float breathe = 1.16 + 0.012 * sin(t * 1.3);
	float bracket = arcs(a + PI * 0.25 - 0.22, 4.0, 0.28, 0.01);
	glow += line(r, breathe, 0.012, px) * bracket * 0.9;

	// the field inside: stronger towards the ring, with ripples running inwards
	if (r < 1.0) {
		float rim = pow(r, 3.0);
		float ripple = 0.5 + 0.5 * sin(r * 26.0 + t * 2.2);
		ripple = pow(ripple, 6.0);
		field = (owned ? 0.10 : 0.02) + rim * (owned ? 0.20 : 0.05);
		glow += ripple * rim * (owned ? 0.22 : 0.07);
		// fine spokes, so the field reads as a force field and not as a flat fill
		float spokes = arcs(a - t * 0.03, 90.0, 0.5, 0.2);
		field *= 0.82 + 0.18 * spokes;
		if (contested) {
			field = 0.10 + 0.16 * rim * (0.5 + 0.5 * sin(t * 9.0));
		}
	}

	// capture: a shock wave, and the whole field flashes
	float age = vParams.x;
	if (age >= 0.0 && age < 1.6) {
		float k = age / 1.6;
		float front = 1.45 * (1.0 - pow(1.0 - k, 3.0));
		float fade = (1.0 - k) * (1.0 - k);
		float wave = exp(-abs(r - front) * 22.0);
		glow += wave * 2.4 * fade;
		white += wave * 1.4 * fade * fade;
		if (r < 1.0) {
			field += 0.55 * pow(1.0 - min(age / 0.7, 1.0), 2.0);
		}
		power = max(power, 1.0);
	}

	// nothing may reach the edge of the quad
	float edge = 1.0 - smoothstep(1.38, 1.5, r);
	glow *= power * edge;
	white *= power * edge;
	field *= edge;

	vec3 rgb = colour * (glow + field) + vec3(1.0) * white;
	// the lines are added to what is behind them; only the field covers it a little
	float alpha = clamp(field * 0.5 + glow * 0.12, 0.0, 1.0);
	fragColor = vec4(rgb, alpha);
}
