#!/usr/bin/env python3
"""Preview the procedural planets in a web browser, without starting the game.

    python3 tools/planets/make_preview.py

writes tools/planets/preview.html. Open that file in any browser: it shows
every kind of planet, a few of each, turning slowly. It runs the game's own
shader (LuaRules/Gadgets/Shaders/planet.frag), so after changing the shader,
run this again and reload the page to see the result.
"""
import json
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SHADER = os.path.join(ROOT, "LuaRules", "Gadgets", "Shaders", "planet.frag")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.html")

PAGE = """<!doctype html>
<meta charset="utf-8">
<title>THIS planets preview</title>
<style>
  body { margin: 0; background: #05070d; color: #8c9bb3; font: 13px sans-serif; }
  canvas { display: block; }
  #labels { position: absolute; left: 0; top: 0; }
  #labels div { position: absolute; width: 200px; text-align: center; }
</style>
<canvas id="c"></canvas>
<div id="labels"></div>
<script>
const FRAGMENT = __FRAGMENT__;
const VERTEX = `
attribute vec2 corner;
uniform vec3 center;
uniform float extent;
varying vec3 worldPos;
void main() {
	// the quad lies flat under a camera that looks straight down, as in the game
	worldPos = center + vec3(corner.x * extent, 0.0, -corner.y * extent);
	gl_Position = vec4(corner, 0.0, 1.0);
}`;
const TYPES = ["Earthlike", "Water world", "Desert", "Ice", "Volcanic", "Gas giant", "Barren moon"];
const PER_TYPE = 3, CELL = 200;
const canvas = document.getElementById("c");
canvas.width = CELL * TYPES.length; canvas.height = CELL * PER_TYPE + 24;
const gl = canvas.getContext("webgl", {premultipliedAlpha: true, preserveDrawingBuffer: true});
function compile(type, source) {
	const shader = gl.createShader(type);
	gl.shaderSource(shader, source); gl.compileShader(shader);
	if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
		const log = gl.getShaderInfoLog(shader);
		document.title = "SHADER ERROR"; document.body.append(log); console.log("SHADER ERROR " + log);
		throw new Error(log);
	}
	return shader;
}
const program = gl.createProgram();
gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX));
gl.attachShader(program, compile(gl.FRAGMENT_SHADER, FRAGMENT));
gl.linkProgram(program); gl.useProgram(program);
gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
const corner = gl.getAttribLocation(program, "corner");
gl.enableVertexAttribArray(corner); gl.vertexAttribPointer(corner, 2, gl.FLOAT, false, 0, 0);
const U = name => gl.getUniformLocation(program, name);
gl.enable(gl.BLEND); gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
const labels = document.getElementById("labels");
TYPES.forEach((name, i) => {
	const div = document.createElement("div");
	div.textContent = name; div.style.left = i * CELL + "px"; div.style.top = CELL * PER_TYPE + 4 + "px";
	labels.append(div);
});
const start = performance.now();
const fixedTime = new URLSearchParams(location.search).get("t");
function frame() {
	const time = fixedTime !== null ? Number(fixedTime) : (performance.now() - start) / 1000 * 20; // 20x the game's speed
	gl.viewport(0, 0, canvas.width, canvas.height);
	gl.clearColor(0.02, 0.027, 0.05, 1); gl.clear(gl.COLOR_BUFFER_BIT);
	for (let type = 0; type < TYPES.length; type++) {
		for (let n = 0; n < PER_TYPE; n++) {
			gl.viewport(type * CELL, canvas.height - (n + 1) * CELL, CELL, CELL);
			const radius = 250, extent = 2.15 * radius;
			gl.uniform3f(U("center"), 0, -300, 0);
			gl.uniform3f(U("camPos"), 0, 4000, 0);
			gl.uniform1f(U("extent"), extent);
			gl.uniform1f(U("radius"), (type === 5 && n === 0) ? radius : radius * 1.6);
			gl.uniform1f(U("ptype"), type);
			gl.uniform1f(U("seed"), 13.7 + type * 71.3 + n * 211.9);
			gl.uniform1f(U("time"), time);
			gl.uniform3f(U("lightDir"), -0.52, 0.68, -0.52);
			gl.uniform1f(U("ring"), (type === 5 && n === 0) ? 1 : 0);
			gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		}
	}
	document.title = "THIS planets preview";
	window.rendered = true;
	if (fixedTime === null) requestAnimationFrame(frame);
}
frame();
</script>
"""


def main():
    with open(SHADER, encoding="utf-8") as handle:
        fragment = handle.read()
    with open(OUT, "w", encoding="utf-8") as handle:
        handle.write(PAGE.replace("__FRAGMENT__", json.dumps(fragment)))
    print("wrote", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
