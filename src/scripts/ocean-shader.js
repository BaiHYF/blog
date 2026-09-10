// WebGL background shader for the Earendil-style blog.
// Ported from earendil.com /static/script.js — fragment shader derived from
// afl_ext's "ocean weaves" WebGL shader (MIT Licensed):
//   https://www.shadertoy.com/view/Ms2SD1
// Wired: canvas, day/night sky + stars, water reflection with logo, click
// ripples, film grain, theme blend, reduced-motion + content-page throttling.

(function () {
  var canvas = document.getElementById('canvas');
  if (!canvas) return;

  var EMBLEM_URL = canvas.getAttribute('data-logo') || '/static/emblem.svg';

  var gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  if (!gl) {
    document.body.classList.add('no-webgl');
    return;
  }

  var CAMERA_PROJECTION_DEPTH = 1.5;
  var BASE_CAMERA_TILT = 0.14;
  var WATER_DEPTH = 1.0;
  var CAMERA_HEIGHT = 1.5;
  var THEME_FADE_DURATION = 700;

  var QUALITY = {
    scale: 0.4,
    lowDpiScale: 0.68,
    raymarchSteps: 32,
    waveIterRaymarch: 8,
    waveIterNormal: 16,
    fbmOctaves: 4
  };
  var LOW_DPI_THRESHOLD = 1.5;
  var CONTENT_PAGE_FPS = 15;
  var CONTENT_PAGE_RESOLUTION_SCALE = 0.5;
  var REDUCED_MOTION_WAVE_SPEED = 0.15;
  var REDUCED_MOTION_GRAIN_SPEED = 0.75;

  function buildFragmentShader() {
    return `
precision highp float;
uniform vec2 iResolution;
uniform float iTime;
uniform float u_waveTime;
uniform float u_grainTime;
uniform float u_noiseScale;
uniform sampler2D u_logo;
uniform vec2 u_logoCenter;
uniform vec2 u_logoSize;
uniform float u_logoFade;
uniform vec4 u_ripples[10];
uniform int u_rippleCount;
uniform float u_night;

#define PI 3.14159265359
#define DRAG_MULT 0.38
#define WATER_DEPTH ${WATER_DEPTH.toFixed(3)}
#define CAMERA_HEIGHT ${CAMERA_HEIGHT.toFixed(3)}
#define ITERATIONS_RAYMARCH ${QUALITY.waveIterRaymarch}
#define ITERATIONS_NORMAL ${QUALITY.waveIterNormal}
#define RAYMARCH_STEPS ${QUALITY.raymarchSteps}
#define FBM_OCTAVES ${QUALITY.fbmOctaves}
#define LOGO_INTENSITY 3.5
#define NIGHT_EPS 0.001

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise21(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  float frequency = 1.0;
  for (int i = 0; i < FBM_OCTAVES; i++) {
    value += amplitude * noise21(p * frequency);
    frequency *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}

mat3 createRotationMatrixAxisAngle(vec3 axis, float angle);

vec2 dirToScreenUV(vec3 dir) {
  vec3 unrotated = createRotationMatrixAxisAngle(vec3(1.0, 0.0, 0.0), -(${BASE_CAMERA_TILT.toFixed(4)})) * dir;
  if (unrotated.z <= 0.0) return vec2(-1.0);
  vec2 uv = (unrotated.xy / unrotated.z) * ${CAMERA_PROJECTION_DEPTH.toFixed(3)};
  vec2 ndc = uv / vec2(iResolution.x / iResolution.y, 1.0);
  return ndc * 0.5 + 0.5;
}

float star(vec2 screenUv, vec2 cellId, vec2 grid) {
  float rnd = hash21(cellId);
  if (rnd > 0.8) return 0.0;
  vec2 starPos = vec2(hash21(cellId + 0.1), hash21(cellId + 0.2));
  vec2 starUv = (cellId + starPos) / grid;
  vec2 deltaPx = (screenUv - starUv) * iResolution.xy;
  float sizePx = 0.25 + hash21(cellId + 0.3) * 0.45;
  float d = length(deltaPx);
  float core = smoothstep(sizePx, sizePx * 0.2, d);
  float flickerPhase = hash21(cellId + 0.4) * 6.28318;
  float flickerSpeed = 0.2 + hash21(cellId + 0.5) * 0.3;
  float flickerAmount = mix(0.1, 0.35, hash21(cellId + 0.7));
  float flicker = mix(1.0 - flickerAmount, 1.0 + flickerAmount, 0.5 + 0.5 * sin(iTime * flickerSpeed + flickerPhase));
  float lumens = mix(1.0, 12.0, hash21(cellId + 0.6));
  float brightness = mix(0.6, 1.4, lumens / 12.0);
  return core * flicker * brightness;
}

vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

float getripples(vec2 position) {
  float rippleSum = 0.0;
  for (int i = 0; i < 10; i++) {
    if (i >= u_rippleCount) break;
    vec4 ripple = u_ripples[i];
    vec2 ripplePos = ripple.xy;
    float birthTime = ripple.z;
    float amplitude = ripple.w;
    float age = u_waveTime - birthTime;
    if (age < 0.0 || age > 12.0) continue;
    float dist = length(position - ripplePos);
    float frequency = 4.0;
    float speed = 3.2;
    float decay = 0.45;
    float spatialDecay = 0.16;
    float phase = dist * frequency - age * speed;
    float envelope = exp(-decay * age) * exp(-dist * spatialDecay);
    float fadeIn = smoothstep(0.0, 0.3, age);
    rippleSum += amplitude * envelope * fadeIn * sin(phase);
  }
  return rippleSum;
}

float getwaves_base(vec2 position, int iterations) {
  float wavePhaseShift = length(position) * 0.1;
  vec2 swellDir = normalize(vec2(-0.25, 1.0));
  float swellBias = 0.35;
  float iter = 0.0;
  float frequency = 1.0;
  float timeMultiplier = 2.0;
  float weight = 1.0;
  float sumOfValues = 0.0;
  float sumOfWeights = 0.0;
  for (int i = 0; i < 16; i++) {
    if (i >= iterations) break;
    vec2 p = normalize(mix(vec2(sin(iter), cos(iter)), swellDir, swellBias));
    vec2 res = wavedx(position, p, frequency, u_waveTime * timeMultiplier + wavePhaseShift);
    position += p * res.y * weight * DRAG_MULT;
    sumOfValues += res.x * weight;
    sumOfWeights += weight;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;
    iter += 1232.399963;
  }
  float baseWaves = sumOfValues / sumOfWeights;
  float swellPhase = dot(position, swellDir) * 0.18 - u_waveTime * 0.08;
  float swell = sin(swellPhase);
  vec2 cameraPos = vec2(u_waveTime * 0.2, 1.0);
  float swellFade = smoothstep(28.0, 4.0, length(position - cameraPos));
  return baseWaves + swell * swellFade * 0.35;
}

float getwaves(vec2 position, int iterations) {
  return getwaves_base(position, iterations) + getripples(position);
}

float raymarchwater(vec3 camera, vec3 start, vec3 end, float depth) {
  vec3 pos = start;
  vec3 dir = normalize(end - start);
  for (int i = 0; i < RAYMARCH_STEPS; i++) {
    float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
    if (height + 0.01 > pos.y) {
      return distance(pos, camera);
    }
    pos += dir * (pos.y - height);
  }
  return distance(start, camera);
}

vec3 normal(vec2 pos, float e, float depth) {
  vec2 ex = vec2(e, 0);
  float H = getwaves(pos.xy, ITERATIONS_NORMAL) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a - vec3(pos.x - e, getwaves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y),
      a - vec3(pos.x, getwaves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e)
    )
  );
}

mat3 createRotationMatrixAxisAngle(vec3 axis, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;
  return mat3(
    oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
  );
}

vec3 getRay(vec2 fragCoord) {
  vec2 uv = ((fragCoord.xy / iResolution.xy) * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
  vec3 proj = normalize(vec3(uv.x, uv.y, ${CAMERA_PROJECTION_DEPTH.toFixed(3)}));
  return createRotationMatrixAxisAngle(vec3(1.0, 0.0, 0.0), ${BASE_CAMERA_TILT.toFixed(4)}) * proj;
}

float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal) {
  return clamp(dot(point - origin, normal) / dot(direction, normal), -1.0, 9991999.0);
}

vec3 extra_cheap_atmosphere(vec3 raydir, vec3 sundir) {
  float special_trick = 1.0 / (raydir.y * 1.0 + 0.1);
  float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
  float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
  float sundt = pow(max(0.0, dot(sundir, raydir)), 8.0);
  float mymie = sundt * special_trick * 0.2;
  vec3 suncolor = mix(vec3(1.0), max(vec3(0.0), vec3(1.0) - vec3(5.5, 13.0, 22.4) / 22.4), special_trick2);
  vec3 bluesky = vec3(12.0, 12.0, 13.0) / 22.4 * suncolor;
  vec3 bluesky2 = max(vec3(0.0), bluesky - vec3(12.0, 12.0, 13.0) * 0.002 * (special_trick + -6.0 * sundir.y * sundir.y));
  bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
  return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y, 3.0));
}

vec3 getSunDirection() {
  return normalize(vec3(-0.0773502691896258, 0.6, 0.5773502691896258));
}

vec3 getAtmosphere(vec3 dir) {
  return extra_cheap_atmosphere(dir, getSunDirection()) * 0.5;
}

vec2 skyUV(vec3 dir) {
  float u = atan(dir.z, dir.x) / (2.0 * PI) + 0.5;
  float v = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
  return vec2(u, v);
}

vec3 getDaySky(vec3 dir) { return getAtmosphere(dir); }

vec3 getNightSky(vec3 dir) {
  vec2 uv = skyUV(dir);
  vec3 topColor = vec3(0.015, 0.02, 0.04);
  vec3 bottomColor = vec3(0.03, 0.035, 0.05);
  vec3 color = mix(bottomColor, topColor, uv.y);
  vec2 screenUv = dirToScreenUV(dir);
  if (screenUv.x >= 0.0 && screenUv.x <= 1.0 && screenUv.y >= 0.0 && screenUv.y <= 1.0) {
    if (screenUv.y > 0.35) {
      float gridX = 40.0;
      float gridY = 30.0;
      vec2 grid = vec2(gridX, gridY);
      vec2 baseCell = floor(vec2(screenUv.x * gridX, screenUv.y * gridY));
      float s = 0.0;
      for (int yi = -1; yi <= 1; yi++) {
        for (int xi = -1; xi <= 1; xi++) {
          vec2 cell = baseCell + vec2(float(xi), float(yi));
          if (cell.y < 0.0 || cell.y >= gridY) continue;
          cell.x = mod(cell.x + gridX, gridX);
          s += star(screenUv, cell, grid);
        }
      }
      float horizonFade = smoothstep(0.35, 0.55, screenUv.y);
      vec3 starColor = vec3(1.0, 0.97, 0.9);
      color += starColor * s * horizonFade;
    }
  }
  return color;
}

float sampleLogo(vec2 uv) {
  vec2 local = (uv - u_logoCenter) / u_logoSize + 0.5;
  float inside = step(0.0, local.x) * step(local.x, 1.0) * step(0.0, local.y) * step(local.y, 1.0);
  float alpha = texture2D(u_logo, local).a * inside;
  return alpha * u_logoFade;
}

vec3 aces_tonemap(vec3 color) {
  mat3 m1 = mat3(
    0.59719, 0.07600, 0.02840,
    0.35458, 0.90834, 0.13383,
    0.04823, 0.01566, 0.83777
  );
  mat3 m2 = mat3(
    1.60475, -0.10208, -0.00327,
    -0.53108,  1.10813, -0.07276,
    -0.07367, -0.00605,  1.07602
  );
  vec3 v = m1 * color;
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));
}

float gaussian(float z, float u, float o) {
  return (1.0 / (o * sqrt(2.0 * 3.1415))) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

vec4 applyFilmGrain(vec3 color, vec2 fragCoord) {
  float gray = dot(color, vec3(0.299, 0.587, 0.114));
  vec2 uv = fragCoord * u_noiseScale / iResolution;
  float seed = dot(uv, vec2(12.9898, 78.233));
  float noise = fract(sin(seed) * 43758.5453 + u_grainTime * 1.5);
  float variance = mix(0.75, 0.6, u_night);
  noise = gaussian(noise, 0.0, variance * variance);
  float grainIntensity = mix(0.4, 0.065, u_night);
  gray += noise * (1.0 - gray) * grainIntensity;
  gray = clamp(gray, 0.0, 1.0);
  vec3 dark = mix(vec3(0.62), vec3(0.05), u_night);
  vec3 light = mix(vec3(0.97), vec3(1.0), u_night);
  return vec4(mix(dark, light, gray), 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec3 ray = getRay(fragCoord);
  if (ray.y >= 0.0) {
    vec3 C;
    float horizonFactor = smoothstep(0.02, 0.25, ray.y);
    float nightBlend = pow(u_night, mix(0.35, 1.0, horizonFactor));
    if (u_night <= NIGHT_EPS) {
      C = getDaySky(ray);
    } else if (u_night >= 1.0 - NIGHT_EPS) {
      C = getNightSky(ray);
    } else {
      C = mix(getDaySky(ray), getNightSky(ray), nightBlend);
    }
    fragColor = vec4(aces_tonemap(C * 2.0), 1.0);
    return;
  }

  vec3 origin = vec3(u_waveTime * 0.2, CAMERA_HEIGHT, 1.0);
  vec3 waterPlaneHigh = vec3(0.0, 0.0, 0.0);
  vec3 waterPlaneLow = vec3(0.0, -WATER_DEPTH, 0.0);

  float highPlaneHit = intersectPlane(origin, ray, waterPlaneHigh, vec3(0.0, 1.0, 0.0));
  float lowPlaneHit = intersectPlane(origin, ray, waterPlaneLow, vec3(0.0, 1.0, 0.0));
  vec3 highHitPos = origin + ray * highPlaneHit;
  vec3 lowHitPos = origin + ray * lowPlaneHit;

  float dist = raymarchwater(origin, highHitPos, lowHitPos, WATER_DEPTH);
  vec3 waterHitPos = origin + ray * dist;

  float eps = max(0.01, dist * 0.004);
  vec3 N = normal(waterHitPos.xz, eps, WATER_DEPTH);
  N = mix(N, vec3(0.0, 1.0, 0.0), 0.8 * min(1.0, sqrt(dist * 0.01) * 1.1));

  float fresnelSharp = 0.04 + 0.96 * pow(1.0 - max(0.0, dot(-N, ray)), 5.0);
  float fresnelFlat = 0.04 + 0.96 * pow(1.0 - max(0.0, dot(vec3(0.0, 1.0, 0.0), -ray)), 5.0);
  float fresnelBlend = min(1.0, sqrt(dist * 0.01) * 1.1);
  float fresnel = mix(fresnelSharp, fresnelFlat, fresnelBlend);

  vec3 R = normalize(reflect(ray, N));
  R.y = abs(R.y);

  float reflectedLogo = sampleLogo(skyUV(R));
  vec3 reflection;
  float reflectionHorizon = smoothstep(0.02, 0.25, R.y);
  float nightReflectionBlend = pow(u_night, mix(0.35, 1.0, reflectionHorizon));
  if (u_night <= NIGHT_EPS) {
    reflection = getDaySky(R);
  } else if (u_night >= 1.0 - NIGHT_EPS) {
    reflection = getNightSky(R);
  } else {
    reflection = mix(getDaySky(R), getNightSky(R), nightReflectionBlend);
  }
  reflection += vec3(1.0) * (reflectedLogo * LOGO_INTENSITY);
  vec3 scatteringBase = mix(vec3(0.08, 0.08, 0.09), vec3(0.02, 0.02, 0.03), u_night);
  vec3 scattering = scatteringBase * (0.2 + (waterHitPos.y + WATER_DEPTH) / WATER_DEPTH);

  vec3 C = fresnel * reflection + scattering;

  vec3 fogColor = mix(vec3(0.55, 0.55, 0.58), vec3(0.03, 0.035, 0.05), u_night);
  float fogAmount = 1.0 - exp(-dist * 0.02);
  C = mix(C, fogColor, fogAmount);

  float waveBrightness = mix(1.4, 1.9, u_night);
  fragColor = vec4(aces_tonemap(C * waveBrightness), 1.0);
}

void main() {
  vec4 sceneColor;
  mainImage(sceneColor, gl_FragCoord.xy);
  gl_FragColor = applyFilmGrain(sceneColor.rgb, gl_FragCoord.xy);
}
`;
  }

  var fragmentShaderSource = buildFragmentShader();

  var vertexShaderSource = `
attribute vec2 position;
void main() { gl_Position = vec4(position, 0.0, 1.0); }
`;

  function createShader(type, source) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error(gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  function createProgram(vs, fs) {
    var program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.error(gl.getProgramInfoLog(program));
      gl.deleteProgram(program);
      return null;
    }
    return program;
  }

  var vertexShader = createShader(gl.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = createShader(gl.FRAGMENT_SHADER, fragmentShaderSource);
  var program = createProgram(vertexShader, fragmentShader);
  if (!program) {
    document.body.classList.add('no-webgl');
    return;
  }

  var positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW);

  var positionLocation = gl.getAttribLocation(program, 'position');
  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

  // Uniform locations + helpers.
  var U = {};
  [
    'iResolution', 'iTime', 'u_waveTime', 'u_grainTime', 'u_noiseScale',
    'u_logo', 'u_logoCenter', 'u_logoSize', 'u_logoFade',
    'u_ripples', 'u_rippleCount', 'u_night'
  ].forEach(function (name) {
    U[name] = gl.getUniformLocation(program, name);
  });

  var logoCenter = [0.53, 0.72];
  var logoSize = [0.18, 0.18 / 1.32];
  var logoFade = 0;
  var logoFadeTarget = 0.85;

  var logoTexture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, logoTexture);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0, 0]));
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

  function setupLogoTexture() {
    var img = new Image();
    img.onload = function () {
      var aspect = img.naturalWidth && img.naturalHeight ? img.naturalWidth / img.naturalHeight : 1.32;
      var baseSize = 0.18;
      logoSize = [baseSize, baseSize / aspect];

      var width = 512;
      var height = Math.max(1, Math.round(width / aspect));
      var c = document.createElement('canvas');
      c.width = width;
      c.height = height;
      var ctx = c.getContext('2d');
      ctx.drawImage(img, 0, 0, width, height);
      gl.bindTexture(gl.TEXTURE_2D, logoTexture);
      gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, c);
    };
    img.src = EMBLEM_URL;
  }

  // Click ripples: project screen position onto the y=0 water plane.
  // The canvas sits behind the site frame, so listen at document level and
  // skip interactive elements to avoid ripples when clicking links/buttons.
  var ripples = [];
  function spawnRipple(clientX, clientY) {
    var rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    var x = clientX - rect.left;
    var y = clientY - rect.top;
    var aspect = rect.width / rect.height;
    var uvx = ((x / rect.width) * 2 - 1) * aspect;
    var uvy = (y / rect.height) * 2 - 1;
    var px = uvx, py = uvy, pz = CAMERA_PROJECTION_DEPTH;
    var len = Math.sqrt(px * px + py * py + pz * pz);
    px /= len; py /= len; pz /= len;
    var cos = Math.cos(BASE_CAMERA_TILT), sin = Math.sin(BASE_CAMERA_TILT);
    var ry = py * cos - pz * sin;
    var rz = py * sin + pz * cos;
    var rx = px;
    var origin = { x: waveTime * 0.2, y: CAMERA_HEIGHT, z: 1.0 };
    if (ry >= -0.001) return;
    var t = -origin.y / ry;
    var wx = origin.x + rx * t;
    var wz = origin.z + rz * t;
    ripples.push([wx, wz, waveTime, 0.5]);
    if (ripples.length > 10) ripples.shift();
  }
  document.addEventListener('click', function (e) {
    if (e.target && e.target.closest && e.target.closest('a, button, input, textarea, select, summary')) return;
    spawnRipple(e.clientX, e.clientY);
  });

  // Theme blend: follow .dark on <html>, eased over THEME_FADE_DURATION.
  function isNight() {
    return document.documentElement.classList.contains('dark');
  }
  var nightBlend = isNight() ? 1 : 0;
  var nightTarget = nightBlend;
  var nightFadeFrom = nightBlend;
  var nightFadeStart = null;
  function updateNightBlend(time) {
    var desired = isNight() ? 1 : 0;
    if (desired !== nightTarget) {
      nightFadeFrom = nightBlend;
      nightTarget = desired;
      nightFadeStart = time;
    }
    if (nightFadeStart !== null) {
      var p = Math.min((time - nightFadeStart) / THEME_FADE_DURATION, 1);
      var e = p * p * (3 - 2 * p);
      nightBlend = nightFadeFrom + (nightTarget - nightFadeFrom) * e;
      if (p >= 1) { nightFadeStart = null; nightBlend = nightTarget; }
    } else {
      nightBlend = nightTarget;
    }
    return nightBlend;
  }

  // Motion: content pages + prefers-reduced-motion slow the waves/grain.
  var motionPrefs = window.matchMedia('(prefers-reduced-motion: reduce)');
  var waveTime = 0, grainTime = 0;
  var waveSpeed = 1, grainSpeed = 1;
  var lastFrameTime = null;
  var lastFrame = null;
  var isContentPage = !!document.querySelector('.content-page');
  var currentResScale = isContentPage ? CONTENT_PAGE_RESOLUTION_SCALE : 1;

  function frame(now) {
    requestAnimationFrame(frame);
    if (lastFrameTime === null) { lastFrameTime = now; return; }
    var dt = (now - lastFrameTime) / 1000;
    lastFrameTime = now;

    // Skip drawing while hidden (e.g. the About page hides it behind its portrait).
    if (!canvas.clientWidth || !canvas.clientHeight) return;

    var contentNow = !!document.querySelector('.content-page');
    if (contentNow !== isContentPage) {
      isContentPage = contentNow;
      currentResScale = isContentPage ? CONTENT_PAGE_RESOLUTION_SCALE : 1;
      resize();
    }

    // Content page frames capped to keep the browser cheap while reading.
    if (isContentPage && lastFrame !== null && (now - lastFrame) < 1000 / CONTENT_PAGE_FPS) return;
    lastFrame = now;

    var reduced = motionPrefs.matches || isContentPage;
    var targetWave = reduced ? REDUCED_MOTION_WAVE_SPEED : 1;
    var targetGrain = reduced ? REDUCED_MOTION_GRAIN_SPEED : 1;
    // Ease speed changes toward targets.
    waveSpeed += (targetWave - waveSpeed) * Math.min(1, dt * 1.5);
    grainSpeed += (targetGrain - grainSpeed) * Math.min(1, dt * 1.5);
    waveTime += dt * waveSpeed;
    grainTime += dt * grainSpeed;

    var night = updateNightBlend(now);

    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.useProgram(program);
    gl.uniform2f(U.iResolution, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.uniform1f(U.iTime, now * 0.001);
    gl.uniform1f(U.u_waveTime, waveTime);
    gl.uniform1f(U.u_grainTime, grainTime);
    gl.uniform1f(U.u_noiseScale, 1.0);
    gl.uniform1f(U.u_logoFade, logoFade);
    gl.uniform2f(U.u_logoCenter, logoCenter[0], logoCenter[1]);
    gl.uniform2f(U.u_logoSize, logoSize[0], logoSize[1]);
    gl.uniform4fv(U.u_ripples, new Float32Array(ripples.reduce(function (acc, r) { return acc.concat(r); }, []).concat(new Array(40 - ripples.length * 4).fill(0)).slice(0, 40)));
    gl.uniform1i(U.u_rippleCount, ripples.length);
    gl.uniform1f(U.u_night, night);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, logoTexture);
    gl.uniform1i(U.u_logo, 0);

    // Ease logo fade in after load.
    if (logoFade < logoFadeTarget) {
      logoFade = Math.min(logoFadeTarget, logoFade + dt * 0.5);
    }

    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }

  function resize() {
    var width = canvas.clientWidth;
    var height = canvas.clientHeight;
    if (!width || !height) return;
    var isLowDpi = window.devicePixelRatio < LOW_DPI_THRESHOLD;
    var qualityScale = isLowDpi ? QUALITY.lowDpiScale : QUALITY.scale;
    var scale = qualityScale * currentResScale * window.devicePixelRatio;
    var w = Math.round(width * scale);
    var h = Math.round(height * scale);
    if (canvas.width !== w || canvas.height !== h) {
      canvas.width = w;
      canvas.height = h;
    }
  }

  window.addEventListener('resize', resize);
  resize();
  setupLogoTexture();
  canvas.classList.add('shader-ready');
  requestAnimationFrame(frame);
})();
