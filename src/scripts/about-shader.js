// About-page WebGL: a transparent dust/particle overlay. The portrait itself is
// a plain CSS background on .about-figure (theme-switched via .dark), so this
// shader only draws drifting particles on top.
(function () {
  var canvas = document.getElementById('about-canvas');
  if (!canvas) return;

  var gl =
    canvas.getContext('webgl', { alpha: true, premultipliedAlpha: false }) ||
    canvas.getContext('experimental-webgl', { alpha: true });
  if (!gl) return; // no overlay; the CSS portrait still shows.

  var DPR_CAP = 1.5;
  var RES_SCALE = 0.6;
  var THEME_FADE = 700;

  var VERT = 'attribute vec2 position; void main(){ gl_Position = vec4(position, 0.0, 1.0); }';

  var FRAG = [
    'precision highp float;',
    'uniform vec2 uRes;',
    'uniform float uTime;',
    'uniform float uNight;',
    'float hash1(float n){ return fract(sin(n) * 43758.5453123); }',
    'float dust(vec2 uv, float aspect, float t){',
    '  float acc = 0.0;',
    '  for (int i = 0; i < 64; i++) {',
    '    float fi = float(i);',
    '    float r1 = hash1(fi * 1.37 + 3.1);',
    '    float r2 = hash1(fi * 2.71 + 11.7);',
    '    float r3 = hash1(fi * 3.11 + 23.3);',
    '    float speed = 0.012 + 0.05 * r3;',
    '    float y = fract(r2 - t * speed);',
    '    vec2 d = (uv - vec2(r1, y)) * vec2(aspect, 1.0);',
    '    float rad = 0.0012 + 0.0022 * r3;',
    '    float sp = smoothstep(rad, 0.0, length(d));',
    '    float tw = 0.55 + 0.45 * sin(t * (0.4 + 1.6 * r3) + fi * 2.3);',
    '    acc += sp * tw;',
    '  }',
    '  return acc;',
    '}',
    'void main(){',
    '  vec2 uv = gl_FragCoord.xy / uRes;',
    '  float d = clamp(dust(uv, uRes.x / uRes.y, uTime), 0.0, 1.0);',
    '  vec3 c = mix(vec3(0.10, 0.10, 0.12), vec3(1.0, 0.98, 0.92), uNight);',
    '  gl_FragColor = vec4(c, d * mix(0.22, 0.45, uNight));',
    '}',
  ].join('\n');

  function shader(type, src) {
    var s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      console.error(gl.getShaderInfoLog(s));
      return null;
    }
    return s;
  }

  var program = gl.createProgram();
  gl.attachShader(program, shader(gl.VERTEX_SHADER, VERT));
  gl.attachShader(program, shader(gl.FRAGMENT_SHADER, FRAG));
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(program));
    return;
  }
  gl.useProgram(program);

  var buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW);
  var posLoc = gl.getAttribLocation(program, 'position');
  gl.enableVertexAttribArray(posLoc);
  gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);

  var uRes = gl.getUniformLocation(program, 'uRes');
  var uTime = gl.getUniformLocation(program, 'uTime');
  var uNight = gl.getUniformLocation(program, 'uNight');

  function isNight() {
    return document.documentElement.classList.contains('dark');
  }
  var night = isNight() ? 1 : 0;
  var nightTarget = night;
  var nightFrom = night;
  var nightStart = null;
  function updateNight(now) {
    var desired = isNight() ? 1 : 0;
    if (desired !== nightTarget) {
      nightFrom = night;
      nightTarget = desired;
      nightStart = now;
    }
    if (nightStart !== null) {
      var p = Math.min((now - nightStart) / THEME_FADE, 1);
      var e = p * p * (3 - 2 * p);
      night = nightFrom + (nightTarget - nightFrom) * e;
      if (p >= 1) { nightStart = null; night = nightTarget; }
    } else {
      night = nightTarget;
    }
    return night;
  }

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var start = null;

  function resize() {
    var w = canvas.clientWidth;
    var h = canvas.clientHeight;
    if (!w || !h) return;
    var dpr = Math.min(window.devicePixelRatio || 1, DPR_CAP);
    var cw = Math.max(1, Math.round(w * dpr * RES_SCALE));
    var ch = Math.max(1, Math.round(h * dpr * RES_SCALE));
    if (canvas.width !== cw || canvas.height !== ch) {
      canvas.width = cw;
      canvas.height = ch;
    }
  }

  function frame(now) {
    requestAnimationFrame(frame);
    if (!canvas.clientWidth) return; // hidden
    if (start === null) { start = now; return; }
    var t = (now - start) / 1000;

    resize();
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.useProgram(program);
    gl.uniform2f(uRes, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.uniform1f(uTime, reduced ? t * 0.15 : t);
    gl.uniform1f(uNight, updateNight(now));
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }

  window.addEventListener('resize', resize);
  resize();
  canvas.classList.add('shader-ready');
  requestAnimationFrame(frame);
})();
