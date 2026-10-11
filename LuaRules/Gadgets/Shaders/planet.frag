// Procedural planets for THIS. One quad is drawn per planet, facing the
// camera; this shader finds where the view ray through each pixel meets the
// planet's sphere and works out the surface there from noise, so there are no
// textures. ptype picks the kind of world, seed makes each one different.
//
//   ptype 0 earthlike   1 water world   2 desert   3 ice
//         4 volcanic    5 gas giant     6 barren moon
//
// The output is premultiplied alpha (blend with ONE, ONE_MINUS_SRC_ALPHA).
//
// Written in the common subset of desktop GLSL 1.10 and WebGL's GLSL ES 1.00
// (no implicit int-to-float conversion, constant loop bounds), because
// tools/planets/make_preview.py runs this same file in a browser.

#ifdef GL_ES
precision highp float;
#endif

uniform vec3 camPos;     // camera position, world space
uniform vec3 center;     // planet centre, world space
uniform float radius;
uniform float ptype;
uniform float seed;      // 0..1000, different for every planet
uniform float time;      // seconds
uniform vec3 lightDir;   // direction towards the sun, normalised
uniform float ring;      // 1.0 = has rings

varying vec3 worldPos;

// ---- noise ------------------------------------------------------------------

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
		    mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
		    mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 5.3);
		a *= 0.5;
	}
	return v / 0.96875;
}

float fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 5.3);
		a *= 0.5;
	}
	return v / 0.875;
}

// thin bright lines: cracks, canyons, lava rivers
float ridges(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * (1.0 - abs(2.0 * noise(p) - 1.0));
		p = p * 2.03 + vec3(3.1, 1.3, 7.7);
		a *= 0.5;
	}
	return v / 0.9375;
}

// one crater per cell: returns -1 (floor) .. +1 (rim), 0 = no crater here
float crater(vec3 p) {
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;
	vec3 offset = vec3(hash(cell + 1.3), hash(cell + 4.7), hash(cell + 8.1)) - 0.5;
	float size = 0.12 + 0.2 * hash(cell + 2.9);
	float d = length(local - offset * 0.35) / size;
	float bowl = -(1.0 - smoothstep(0.0, 0.85, d));
	float rim = smoothstep(0.7, 1.0, d) * (1.0 - smoothstep(1.0, 1.35, d));
	return bowl * 0.8 + rim;
}

// ---- the kinds of world ---------------------------------------------------------
// q: point on the unit sphere in the planet's own frame (q.y = towards its
// north pole), already turned by the planet's spin.
// Each returns the surface colour and sets:
//   shine   how strongly the sun glints off it (water, ice)
//   glow    light the surface gives off by itself (lava)

vec3 offsetOf(float s) {
	return vec3(s * 1.37, s * 0.71, s * 2.13);
}

vec3 terran(vec3 q, float sea, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	float h = fbm(q * 1.7 + so + 0.6 * fbm3(q * 3.1 + so));
	float detail = fbm3(q * 9.0 + so);
	float lat = abs(q.y);
	glow = vec3(0.0);
	vec3 col;
	if (h < sea) {
		float depth = smoothstep(sea - 0.22, sea, h);
		col = mix(vec3(0.02, 0.07, 0.25), vec3(0.06, 0.32, 0.55), depth);
		col = mix(col, vec3(0.16, 0.55, 0.62), smoothstep(0.93, 1.0, depth));
		shine = 1.0;
	} else {
		float t = (h - sea) / (1.0 - sea);
		float dry = smoothstep(0.35, 0.7, fbm3(q * 2.3 + so * 1.9) + (0.5 - lat) * 0.4);
		vec3 low = mix(vec3(0.13, 0.36, 0.12), vec3(0.50, 0.44, 0.24), dry);
		col = mix(vec3(0.76, 0.70, 0.50), low, smoothstep(0.0, 0.05, t));
		col = mix(col, vec3(0.36, 0.30, 0.24), smoothstep(0.22, 0.42, t + detail * 0.1));
		col = mix(col, vec3(0.95, 0.96, 0.98), smoothstep(0.46, 0.58, t + detail * 0.1));
		col *= 0.85 + 0.3 * detail;
		shine = 0.0;
	}
	// polar ice
	float ice = smoothstep(0.88, 0.94, lat + (detail - 0.5) * 0.16);
	col = mix(col, vec3(0.93, 0.96, 1.0), ice);
	shine = mix(shine, 0.35, ice);
	return col;
}

vec3 desert(vec3 q, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	float h = fbm(q * 2.0 + so + 0.5 * fbm3(q * 4.0 + so));
	float detail = fbm3(q * 11.0 + so);
	vec3 sand = mix(vec3(0.80, 0.60, 0.36), vec3(0.86, 0.72, 0.50), fract(seed * 0.37));
	vec3 rust = mix(vec3(0.56, 0.27, 0.13), vec3(0.42, 0.24, 0.20), fract(seed * 0.59));
	vec3 col = mix(sand, rust, smoothstep(0.35, 0.68, h));
	// dark canyons
	float canyon = smoothstep(0.80, 0.93, ridges(q * 2.2 + so * 0.7));
	col *= 1.0 - 0.45 * canyon;
	col *= 0.82 + 0.36 * detail;
	// small frost caps
	float cap = smoothstep(0.94, 0.98, abs(q.y) + (detail - 0.5) * 0.10);
	col = mix(col, vec3(0.92, 0.88, 0.84), cap);
	shine = 0.0;
	glow = vec3(0.0);
	return col;
}

vec3 iceworld(vec3 q, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	float h = fbm(q * 2.2 + so);
	float detail = fbm3(q * 10.0 + so);
	vec3 col = mix(vec3(0.52, 0.70, 0.88), vec3(0.90, 0.95, 1.0), smoothstep(0.3, 0.7, h));
	// long blue-grey cracks
	float crack = smoothstep(0.84, 0.95, ridges(q * 2.6 + so * 1.3 + 0.4 * fbm3(q * 2.0 + so)));
	col = mix(col, vec3(0.20, 0.36, 0.56), crack * 0.8);
	col *= 0.88 + 0.24 * detail;
	shine = 0.45 * (1.0 - crack);
	glow = vec3(0.0);
	return col;
}

vec3 volcanic(vec3 q, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	float h = fbm(q * 2.1 + so);
	float detail = fbm3(q * 12.0 + so);
	vec3 col = mix(vec3(0.07, 0.06, 0.06), vec3(0.24, 0.19, 0.17), smoothstep(0.3, 0.75, h));
	col *= 0.75 + 0.5 * detail;
	// glowing rivers, and seas of lava in the lowlands
	float river = smoothstep(0.82, 0.94, ridges(q * 2.4 + so * 0.9 + 0.5 * fbm3(q * 2.5 + so)));
	float sea = 1.0 - smoothstep(0.33, 0.40, h);
	float heat = max(river, sea * (0.55 + 0.45 * detail));
	float pulse = 0.85 + 0.15 * sin(time * 0.7 + h * 20.0);
	glow = mix(vec3(0.9, 0.16, 0.02), vec3(1.0, 0.72, 0.25), heat * heat) * heat * pulse;
	col *= 1.0 - 0.7 * heat;
	shine = 0.0;
	return col;
}

void gasPalette(out vec3 a, out vec3 b, out vec3 c) {
	float pick = fract(seed * 0.173) * 4.0;
	if (pick < 1.0) {          // tan and brown
		a = vec3(0.82, 0.68, 0.50); b = vec3(0.55, 0.36, 0.24); c = vec3(0.93, 0.86, 0.74);
	} else if (pick < 2.0) {   // deep blue
		a = vec3(0.20, 0.36, 0.76); b = vec3(0.12, 0.22, 0.58); c = vec3(0.62, 0.78, 0.96);
	} else if (pick < 3.0) {   // pale gold
		a = vec3(0.86, 0.76, 0.52); b = vec3(0.72, 0.58, 0.36); c = vec3(0.96, 0.92, 0.78);
	} else {                   // violet and teal
		a = vec3(0.46, 0.32, 0.62); b = vec3(0.22, 0.50, 0.54); c = vec3(0.82, 0.72, 0.92);
	}
}

vec3 gasgiant(vec3 q, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	vec3 a; vec3 b; vec3 c;
	gasPalette(a, b, c);
	// bands follow latitude, pushed about by turbulence
	float swirl = fbm3(q * vec3(3.0, 9.0, 3.0) + so);
	float lat = q.y + 0.07 * (swirl - 0.5);
	float bands = 5.0 + 5.0 * fract(seed * 0.71);
	float v = noise(vec3(lat * bands, seed, 0.5));
	float w = noise(vec3(lat * bands * 2.7 + 11.0, seed, 3.5));
	vec3 col = mix(a, b, smoothstep(0.3, 0.7, v));
	col = mix(col, c, smoothstep(0.55, 0.85, w) * 0.7);
	col *= 0.86 + 0.28 * fbm3(q * vec3(5.0, 22.0, 5.0) + so * 1.7);
	// one great storm
	vec3 spot = normalize(vec3(cos(seed), 0.35 * sin(seed * 3.1), sin(seed)));
	vec3 d = q - spot;
	float storm = 1.0 - smoothstep(0.0, 1.0, length(d * vec3(1.0, 2.2, 1.0)) / 0.24);
	col = mix(col, mix(c, b, 0.5 + 0.5 * sin(storm * 9.0 + swirl * 4.0)), storm * 0.85);
	shine = 0.0;
	glow = vec3(0.0);
	return col;
}

vec3 barren(vec3 q, out float shine, out vec3 glow) {
	vec3 so = offsetOf(seed);
	float h = fbm(q * 2.4 + so);
	float detail = fbm3(q * 14.0 + so);
	vec3 tint = mix(vec3(0.52, 0.50, 0.48), vec3(0.50, 0.44, 0.38), fract(seed * 0.41));
	vec3 col = tint * (0.55 + 0.6 * h);
	// dark plains
	col *= 1.0 - 0.35 * smoothstep(0.52, 0.62, fbm3(q * 1.3 + so * 2.0));
	float pits = crater(q * 3.0 + so) * 0.5 + crater(q * 6.5 + so * 1.7) * 0.32 + crater(q * 13.0 + so * 0.3) * 0.2;
	col *= 1.0 + 0.55 * pits;
	col *= 0.85 + 0.3 * detail;
	shine = 0.0;
	glow = vec3(0.0);
	return col;
}

// colour and strength of the air: the rim of the disc and the halo around it
vec4 atmosphere() {
	if (ptype < 1.5) return vec4(0.35, 0.60, 1.00, 1.0);
	if (ptype < 2.5) return vec4(0.95, 0.62, 0.38, 0.55);
	if (ptype < 3.5) return vec4(0.62, 0.82, 1.00, 0.6);
	if (ptype < 4.5) return vec4(1.00, 0.34, 0.10, 0.55);
	if (ptype < 5.5) {
		vec3 a; vec3 b; vec3 c;
		gasPalette(a, b, c);
		return vec4(c, 0.7);
	}
	return vec4(0.0);
}

// how much cloud covers a point: white for the watery worlds, dust for deserts
float clouds(vec3 q) {
	if (ptype > 2.5) return 0.0;
	vec3 so = offsetOf(seed + 37.0);
	vec3 p = q * 2.4 + so + vec3(time * 0.004, 0.0, time * 0.003);
	float c = fbm(p + 0.7 * fbm3(p * 1.9));
	if (ptype > 1.5) return smoothstep(0.58, 0.85, c) * 0.35;
	return smoothstep(0.52, 0.74, c) * 0.92;
}

// ---- main -----------------------------------------------------------------------

void main() {
	vec3 rd = normalize(worldPos - camPos);
	vec3 ro = camPos - center;
	vec3 L = normalize(lightDir);

	// the planet's own frame: a tilted spin axis, different for every planet
	float azimuth = seed * 2.399;
	float tilt = 0.85 + 0.35 * fract(seed * 0.618);   // radians away from straight up
	vec3 axis = vec3(sin(tilt) * cos(azimuth), cos(tilt), sin(tilt) * sin(azimuth));
	vec3 east = normalize(cross(vec3(0.0, 1.0, 0.0), axis));
	vec3 north = cross(axis, east);

	float b = dot(ro, rd);
	float c = dot(ro, ro) - radius * radius;
	float h = b * b - c;

	vec4 air = atmosphere();
	vec3 rgb = vec3(0.0);   // premultiplied
	float alpha = 0.0;
	float tSphere = 1.0e20;

	if (h > 0.0) {
		tSphere = -b - sqrt(h);
		vec3 n = normalize(ro + rd * tSphere);
		// into the planet's frame, then spin
		vec3 q = vec3(dot(n, east), dot(n, axis), dot(n, north));
		float spin = time * 0.02 + seed;
		float cs = cos(spin);
		float sn = sin(spin);
		q = vec3(q.x * cs - q.z * sn, q.y, q.x * sn + q.z * cs);

		float shine;
		vec3 glow;
		vec3 col;
		if (ptype < 0.5) col = terran(q, 0.50, shine, glow);
		else if (ptype < 1.5) col = terran(q, 0.63, shine, glow);
		else if (ptype < 2.5) col = desert(q, shine, glow);
		else if (ptype < 3.5) col = iceworld(q, shine, glow);
		else if (ptype < 4.5) col = volcanic(q, shine, glow);
		else if (ptype < 5.5) col = gasgiant(q, shine, glow);
		else col = barren(q, shine, glow);

		float cloud = clouds(q);
		vec3 cloudColour = (ptype > 1.5) ? vec3(0.90, 0.74, 0.56) : vec3(1.0);
		col = mix(col, cloudColour, cloud);
		shine *= 1.0 - cloud;

		float d = dot(n, L);
		float lit = smoothstep(-0.12, 0.55, d);
		vec3 halfway = normalize(L - rd);
		float glint = pow(max(dot(n, halfway), 0.0), 70.0) * shine * 0.8;
		float facing = max(dot(n, -rd), 0.0);
		float rim = pow(1.0 - facing, 2.5);

		rgb = col * (0.035 + 0.965 * lit) + vec3(1.0, 0.96, 0.88) * glint * lit;
		rgb += glow * (1.0 - cloud);
		rgb = mix(rgb, air.rgb * (0.25 + 0.95 * lit), rim * air.a * 0.75);
		// soften the very edge of the disc
		float edge = smoothstep(0.0, 0.05, facing);
		alpha = edge;
		rgb *= edge;
	}

	// halo of air around the disc
	if (air.a > 0.0) {
		float nearest = sqrt(max(dot(ro, ro) - b * b, 0.0));
		float x = (nearest - radius) / (radius * 0.10);
		if (x > -0.6) {
			vec3 side = normalize(ro - rd * b);
			float sun = smoothstep(-0.35, 0.5, dot(side, L));
			float halo = exp(-max(x, 0.0) * 2.2) * air.a * 0.8 * sun * (1.0 - alpha);
			rgb += air.rgb * halo;
			alpha += halo * (1.0 - alpha);
		}
	}

	// rings, in the plane of the equator
	if (ring > 0.5) {
		float down = dot(rd, axis);
		if (abs(down) > 1.0e-4) {
			float tRing = -dot(ro, axis) / down;
			if (tRing > 0.0 && tRing < tSphere) {
				vec3 p = ro + rd * tRing;
				float r = length(p) / radius;
				float band = smoothstep(1.30, 1.38, r) * (1.0 - smoothstep(1.92, 2.0, r));
				if (band > 0.0) {
					float grain = noise(vec3(r * 22.0, seed, 1.5));
					float wide = noise(vec3(r * 6.0, seed, 7.5));
					float density = band * (0.25 + 0.75 * smoothstep(0.25, 0.6, wide)) * (0.6 + 0.4 * grain);
					density *= 1.0 - 0.85 * (smoothstep(1.60, 1.63, r) * (1.0 - smoothstep(1.66, 1.69, r)));  // a gap
					vec3 a; vec3 bb; vec3 cc;
					gasPalette(a, bb, cc);
					vec3 ringColour = mix(cc, a, wide) * (0.75 + 0.35 * grain);
					// the planet's shadow across the rings
					float pb = dot(p, L);
					float ph = pb * pb - (dot(p, p) - radius * radius);
					float shade = (ph > 0.0 && pb < 0.0) ? 0.12 : 1.0;
					float ringAlpha = density * 0.85;
					rgb = ringColour * shade * ringAlpha + rgb * (1.0 - ringAlpha);
					alpha = ringAlpha + alpha * (1.0 - ringAlpha);
				}
			}
		}
	}

	gl_FragColor = vec4(rgb, alpha);
}
