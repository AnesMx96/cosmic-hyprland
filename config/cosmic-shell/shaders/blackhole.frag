#version 440
// Agujero negro con lente gravitatoria: cada píxel lanza un rayo que se curva hacia
// el centro; si cruza el disco suma su luz y si cae dentro queda la sombra.
// Recompilar: qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o blackhole.frag.qsb blackhole.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float aspect;    // ancho / alto del elemento
    float cx;        // centro del agujero, 0..1
    float cy;
    float zoom;      // radio del horizonte en unidades del alto
    float tilt;      // elevación de la cámara, en radianes
    float pixel;     // tamaño de un píxel, en unidades del alto
};
//---BODY
const int STEPS = 72;
const float DISK_IN = 2.4, DISK_OUT = 13.0;

float hash(float n) { return fract(sin(n * 91.3458) * 47453.5453); }

// Trazos que giran: periódicos en el ángulo para que no haya costura, y ondulados
// para que no parezcan círculos perfectos sino el remolino del fondo de pantalla
float streaks(float r, float phi, float spin, float grazing) {
    float sum = 0.0, freq = 3.2, amp = 1.0;
    float warp = 0.55 * sin(phi * 2.0 - spin * 0.6) + 0.3 * sin(phi * 3.0 + r * 0.9 + spin * 0.4);
    for (int i = 0; i < 4; i++) {
        float x = (r + warp * 0.35) * freq + float(i) * 3.7;
        float id = floor(x), h = hash(id + float(i) * 13.0);
        // de canto los trazos se apelotonan: bajo 2 px se sustituyen por su valor medio (sin moiré)
        float visible = smoothstep(1.2, 3.2, grazing * zoom / pixel / freq);
        float line = mix(0.38, pow(0.5 + 0.5 * cos(6.2832 * fract(x)), 2.0), visible);
        float k = 1.0 + floor(h * 3.0);
        float wave = 0.5 + 0.5 * sin(phi * k + h * 40.0 - spin * (0.75 + h * 0.5));
        sum += amp * line * (0.25 + 0.75 * wave * wave) * (0.45 + h * 0.55);
        freq *= 1.95; amp *= 0.72;
    }
    return sum * 0.62;
}

vec4 diskAt(vec3 p, vec3 dir) {
    float r = length(p.xz);
    if (r < DISK_IN || r > DISK_OUT) return vec4(0.0);
    float phi = atan(p.z, p.x);
    float spin = time * 2.2 * pow(r / DISK_IN, -1.5);     // Kepler: dentro gira más rápido
    float n = streaks(r, phi, spin, abs(dir.y));
    float edge = smoothstep(DISK_IN, DISK_IN + 0.3, r) * pow(smoothstep(DISK_OUT, DISK_IN + 1.2, r), 1.15);
    // Doppler: el lado que viene hacia nosotros es blanco y brillante; el otro, cobre
    vec3 orbit = normalize(vec3(-p.z, 0.0, p.x));
    float doppler = -dot(orbit, dir);
    float boost = pow(clamp(1.0 + 0.62 * doppler, 0.3, 2.0), 2.2);
    vec3 hot = vec3(0.93, 0.97, 1.0), cool = vec3(0.30, 0.52, 0.80), ember = vec3(0.86, 0.52, 0.34);
    vec3 col = mix(hot, cool, smoothstep(DISK_IN + 0.6, DISK_OUT * 0.72, r));
    col = mix(col, ember, smoothstep(-0.05, -0.8, doppler) * 0.9);
    float a = edge * clamp(0.34 + n * 0.8, 0.0, 1.0);
    return vec4(col * boost * (1.0 + n * 1.5), a);
}

vec4 trace(vec2 uv) {
    float D = 26.0, ct = cos(tilt), st = sin(tilt);
    vec3 ro = vec3(0.0, st * D, -ct * D);
    vec3 fw = normalize(-ro), rt = vec3(1.0, 0.0, 0.0), up = cross(fw, rt);
    vec3 v = normalize(fw * D + rt * uv.x + up * uv.y);

    // Curvatura: aceleración de un fotón en Schwarzschild (r_s = 1)
    vec3 p = ro;
    vec3 L = cross(p, v);
    float h2 = dot(L, L);
    vec3 col = vec3(0.0);
    float alpha = 0.0;
    bool captured = false;
    float r = D;

    for (int i = 0; i < STEPS; i++) {
        float r2 = dot(p, p);
        r = sqrt(r2);
        if (r < 1.25) { captured = true; break; }
        if (r > D * 1.35 && dot(p, v) > 0.0) break;
        float dt = clamp(0.3 * (r - 0.9), 0.12, 2.2);
        vec3 acc = -1.5 * h2 * p / (r2 * r2 * r);
        vec3 next = p + v * dt;
        if (p.y * next.y < 0.0) {
            vec3 hit = mix(p, next, p.y / (p.y - next.y));
            vec4 d = diskAt(hit, normalize(v));
            col += (1.0 - alpha) * d.rgb * d.a;
            alpha += (1.0 - alpha) * d.a;
            if (alpha > 0.97) break;
        }
        v = normalize(v + acc * dt);
        p = next;
    }
    if (r < 3.2) captured = true;      // rayo que se quedó orbitando sin escapar

    if (captured) {
        // Sombra azul noche, como en el fondo de pantalla
        vec3 shade = mix(vec3(0.010, 0.025, 0.09), vec3(0.03, 0.11, 0.30), smoothstep(-2.4, 3.0, uv.y));
        col += (1.0 - alpha) * shade;
        alpha = 1.0;
    }
    return vec4(col, alpha);
}

void main() {
    vec2 uv = vec2((qt_TexCoord0.x - cx) * aspect, cy - qt_TexCoord0.y) / zoom;
    // Dos muestras por píxel para que los trazos finos no tiemblen
    vec2 px = vec2(0.25 / zoom) * pixel;
    vec4 c = 0.5 * (trace(uv + px) + trace(uv - px));
    // Anillo de fotones: luz que casi cae y da la vuelta
    float rim = exp(-pow((length(uv) - 2.72) * 9.0, 2.0)) * smoothstep(-3.2, 1.4, uv.y);
    c.rgb += vec3(0.86, 0.94, 1.0) * rim * 0.9;
    c.a = max(c.a, rim * 0.8);
    c.rgb = 1.0 - exp(-c.rgb * 1.55);                    // revelado suave
    fragColor = vec4(c.rgb, c.a) * qt_Opacity;
}
