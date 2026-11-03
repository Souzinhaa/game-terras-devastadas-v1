"""Recompõe a animação existente: cenário para a direita, carro para a esquerda.

Não muda artes do carro nem o mix sonoro. Usa o ciclo de caminhada em atlas.
Requer Pillow, NumPy e FFmpeg (somente ferramentas de produção, fora do jogo).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import argparse
import hashlib
import json
import math
import subprocess
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("--ffmpeg", required=True)
args = parser.parse_args()
REV = Path(__file__).resolve().parent
SOURCE = REV.parent
W, H, FPS, DURATION = 1280, 720, 24, 18
OUT = REV / "output"
OUT.mkdir(exist_ok=True)
rng = np.random.default_rng(42)  # Produção de partículas, nunca RNG do jogo.
background = Image.open(SOURCE / "assets/cenario.png").convert("RGB").resize((W, H), Image.Resampling.LANCZOS)
tile = Image.new("RGB", (W * 2, H))
tile.paste(background, (0, 0))
tile.paste(background.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (W, 0))
cars = [Image.open(SOURCE / f"assets/carro_{i:02}.png").convert("RGBA") for i in range(24)]

def trim(path, width):
    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").point(lambda a: 255 if a > 30 else 0).getbbox()
    image = image.crop(bounds)
    return image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)

barrier = trim(SOURCE / "assets/barricada.png", 210)
atlas = Image.open(REV / "hostil_walk.png").convert("RGBA")
cw, ch = atlas.width // 4, atlas.height // 2
cells = [atlas.crop(((i % 4) * cw, (i // 4) * ch, (i % 4 + 1) * cw, (i // 4 + 1) * ch)) for i in range(8)]
bounds = [cell.getchannel("A").point(lambda a: 255 if a > 30 else 0).getbbox() for cell in cells]
crop = (min(b[0] for b in bounds), min(b[1] for b in bounds), max(b[2] for b in bounds), max(b[3] for b in bounds))
walk = [cell.crop(crop).resize((round((crop[2] - crop[0]) * 170 / (crop[3] - crop[1])), 170), Image.Resampling.LANCZOS) for cell in cells]

def ease(a, b, t):
    t = float(np.clip(t, 0, 1))
    return a + (b - a) * t * t * (3 - 2 * t)

def velocity(t):
    if t < 3: return 1
    if t < 4: return 4 - t
    if t < 5: return 0
    if t < 6: return (t - 5) * 1.6
    if t < 7.5: return 1.6
    return 1

def car_x(t):
    if t < 5: return 760.0
    if t < 6: return ease(760, 700, t - 5)
    # Reenquadramento lento: sempre mais lento que o deslocamento do cenário.
    return ease(700, 760, (t - 6) / 12)

times = np.arange(FPS * DURATION + 1) / FPS
velocities = np.array([velocity(t) for t in times])
distance = np.concatenate(([0.0], np.cumsum((velocities[:-1] + velocities[1:]) * 0.5 / FPS)))
distance *= W * 2 / distance[-1]
relative = np.diff([car_x(t) for t in times]) - np.diff(distance)
assert max(relative) <= 1e-6, "O carro não pode recuar em relação à estrada."
assert len({hashlib.sha256(frame.tobytes()).hexdigest() for frame in walk}) == 8

def road_frame(displacement):
    # Crop negativo => marcos da estrada se deslocam para a DIREITA.
    # O Hatch aponta para a ESQUERDA: esse movimento representa marcha à frente.
    start = round(-displacement) % (W * 2)
    frame = Image.new("RGB", (W, H))
    first = tile.crop((start, 0, min(W * 2, start + W), H))
    frame.paste(first, (0, 0))
    if start + W > W * 2:
        frame.paste(tile.crop((0, 0, start + W - W * 2, H)), (W * 2 - start, 0))
    return frame.convert("RGBA")

particles = [(float(rng.uniform(-1, 1)), float(rng.uniform(0.3, 1)), float(rng.uniform(5, 15))) for _ in range(22)]
chunks = []
for index in range(6):
    x, y = index % 3 * 70, index // 3 * (barrier.height // 2)
    chunks.append((barrier.crop((x, y, x + 70, y + barrier.height // 2)), x, y))

def put(canvas, sprite, x, y):
    canvas.alpha_composite(sprite, (round(x), round(y)))

command = [args.ffmpeg, "-y", "-v", "error", "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", f"{W}x{H}", "-framerate", str(FPS), "-i", "-", "-an", "-c:v", "libx264", "-preset", "fast", "-crf", "19", "-pix_fmt", "yuv420p", str(OUT / "fundo_sem_audio_v2.mp4")]
process = subprocess.Popen(command, stdin=subprocess.PIPE)
target = car_x(13) - walk[0].width * 0.55
for index in range(FPS * DURATION):
    t = index / FPS
    canvas = road_frame(distance[index])
    cx = car_x(t)
    if 1.2 <= t < 6:
        bx = ease(-220, 490, (t - 1.2) / 2.8) if t < 4 else 490
        put(canvas, barrier, bx, 627 - barrier.height)
    if 10 <= t < 13:
        phase = int((t - 10) * 12) % 8
        human = walk[phase]
        # Marcha no chão: velocidade de cenário + avanço próprio do hostil.
        hx = 140 + (target - 140) * (t - 10) / 3
        if t < 10.2:
            human = human.copy()
            human.putalpha(human.getchannel("A").point(lambda a: round(a * (t - 10) / 0.2)))
        put(canvas, human, hx, 627 - human.height)
    if 13 <= t < 14:
        age = t - 13
        human = walk[3].rotate(180 * age, Image.Resampling.BICUBIC, expand=True)
        put(canvas, human, target - age * 380, 627 - walk[3].height - 95 * math.sin(age * math.pi) + 210 * age * age)
    car = cars[int(t * 20) % 24 if velocity(t) > 0.05 else 0]
    shadow = Image.new("RGBA", (W, H))
    ImageDraw.Draw(shadow).ellipse((cx + 15, 612, cx + 365, 636), fill=(0, 0, 0, 95))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(6)))
    put(canvas, car, cx, 635 - car.height)
    if 6 <= t < 7.2:
        age = t - 6
        for j, (chunk, x, y) in enumerate(chunks):
            rotated = chunk.rotate((j - 2) * age * 110, Image.Resampling.BICUBIC, expand=True)
            put(canvas, rotated, 490 + x - (90 + j * 19) * age, 627 - barrier.height + y - 130 * age + (210 + j * 13) * age * age)
    fx = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(fx)
    for k in range(10):
        age = (t * 0.8 + k / 10) % 1
        radius = 6 + age * 17
        xx, yy = cx + 335 + age * 130, 624 - age * 27
        if velocity(t) > 0.03:
            draw.ellipse((xx - radius, yy - radius * 0.6, xx + radius, yy + radius * 0.6), fill=(160, 137, 105, round((1 - age) * 35)))
    for impact_t, ix in [(6, 670), (13, target + 30)]:
        age = t - impact_t
        if 0 <= age < 1.25:
            for vx, vy, radius in particles:
                xx, yy = ix + vx * age * 150, 600 - vy * age * 80 + age * age * 25
                rr = radius + age * 30
                draw.ellipse((xx - rr, yy - rr * 0.65, xx + rr, yy + rr * 0.65), fill=(166, 130, 86, round(92 * (1 - age / 1.25))))
    canvas = Image.alpha_composite(canvas, fx.filter(ImageFilter.GaussianBlur(1.5)))
    if index in [0, 96, 144, 248, 252, 256, 264, 312]: canvas.convert("RGB").save(OUT / f"frame_{index:03}.jpg", quality=92)
    process.stdin.write(canvas.convert("RGB").tobytes())
    if index % 72 == 0: print(f"render {index}/{FPS * DURATION}", flush=True)
process.stdin.close()
assert process.wait() == 0
audio = SOURCE / "audio/mix_sincronizado.wav"
subprocess.run([args.ffmpeg, "-y", "-v", "error", "-i", str(OUT / "fundo_sem_audio_v2.mp4"), "-i", str(audio), "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", "-t", "18", "-movflags", "+faststart", str(OUT / "fundo_com_audio_v2.mp4")], check=True)
subprocess.run([args.ffmpeg, "-y", "-v", "error", "-i", str(OUT / "fundo_sem_audio_v2.mp4"), "-i", str(audio), "-c:v", "libtheora", "-q:v", "7", "-c:a", "libvorbis", "-q:a", "4", "-t", "18", str(OUT / "fundo_godot_v2.ogv")], check=True)
subprocess.run([args.ffmpeg, "-y", "-v", "error", "-i", str(OUT / "fundo_com_audio_v2.mp4"), "-vf", "scale=640:360", "-c:v", "libx264", "-crf", "24", "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", str(OUT / "previa_v2.mp4")], check=True)
report = {"width": W, "height": H, "fps": FPS, "seconds": DURATION, "road_direction": "right", "car_facing": "left", "max_relative_displacement_per_frame": float(max(relative)), "walk_frames": len(walk), "walk_fps": 12, "impact_times": [6, 13], "audio_source_sha256": hashlib.sha256(audio.read_bytes()).hexdigest()}
(OUT / "motion-check.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("READY", flush=True)
