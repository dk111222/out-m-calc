"""Train the bundled digit model and write assets/models/digits.f32.

The rasterizer matches lib/domain/digit_ink.dart. Run from the repo root:
  python tool/train_digits.py
"""

import gzip
import math
import struct
import urllib.request
from pathlib import Path

import numpy as np

SIDE = 28
CONTENT = 20
BRUSH = 1.35
STEP = 0.4
HIDDEN = 128
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models" / "digits.f32"
CACHE = Path.home() / ".cache" / "stepmath-mnist"
MNIST = {
    "train-images": "https://storage.googleapis.com/cvdf-datasets/mnist/train-images-idx3-ubyte.gz",
    "train-labels": "https://storage.googleapis.com/cvdf-datasets/mnist/train-labels-idx1-ubyte.gz",
    "test-images": "https://storage.googleapis.com/cvdf-datasets/mnist/t10k-images-idx3-ubyte.gz",
    "test-labels": "https://storage.googleapis.com/cvdf-datasets/mnist/t10k-labels-idx1-ubyte.gz",
}


def stamp(img, x, y, radius):
    x0 = math.floor(x - radius)
    x1 = math.ceil(x + radius)
    y0 = math.floor(y - radius)
    y1 = math.ceil(y + radius)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            if px < 0 or py < 0 or px >= SIDE or py >= SIDE:
                continue
            dx = px + 0.5 - x
            dy = py + 0.5 - y
            dist = math.hypot(dx, dy)
            if dist > radius:
                continue
            value = 1.0 - 0.25 * (dist / radius)
            index = py * SIDE + px
            if value > img[index]:
                img[index] = value


def paint(img, x0, y0, x1, y1, radius):
    dist = math.hypot(x1 - x0, y1 - y0)
    steps = max(1, math.ceil(dist / STEP))
    for i in range(steps + 1):
        t = i / steps
        stamp(img, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, radius)


def center_mass(img):
    mass = 0.0
    cx = 0.0
    cy = 0.0
    for y in range(SIDE):
        for x in range(SIDE):
            value = img[y * SIDE + x]
            mass += value
            cx += value * x
            cy += value * y
    if mass < 1:
        return img
    cx /= mass
    cy /= mass
    dx = int(round(13.5 - cx))
    dy = int(round(13.5 - cy))
    if dx == 0 and dy == 0:
        return img
    shifted = np.zeros_like(img)
    for y in range(SIDE):
        for x in range(SIDE):
            nx = x + dx
            ny = y + dy
            if nx < 0 or ny < 0 or nx >= SIDE or ny >= SIDE:
                continue
            shifted[ny * SIDE + nx] = img[y * SIDE + x]
    return shifted


def rasterize(strokes, radius=BRUSH):
    points = [point for stroke in strokes for point in stroke]
    if len(points) < 2:
        return np.zeros(SIDE * SIDE, dtype=np.float32)
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    left, right = min(xs), max(xs)
    top, bottom = min(ys), max(ys)
    width = max(right - left, 1e-3)
    height = max(bottom - top, 1e-3)
    scale = CONTENT / max(width, height)
    ox = (SIDE - width * scale) / 2
    oy = (SIDE - height * scale) / 2
    img = np.zeros(SIDE * SIDE, dtype=np.float64)

    def map_point(point):
        return (
            (point[0] - left) * scale + ox,
            (point[1] - top) * scale + oy,
        )

    for stroke in strokes:
        if len(stroke) < 2:
            continue
        mapped = [map_point(point) for point in stroke]
        for start, end in zip(mapped, mapped[1:]):
            paint(img, start[0], start[1], end[0], end[1], radius)
    return center_mass(img).astype(np.float32)


def ellipse(rx, ry):
    return [
        (
            50 + rx * math.cos(2 * math.pi * i / 40),
            50 + ry * math.sin(2 * math.pi * i / 40),
        )
        for i in range(41)
    ]


def shapes(label, rng):
    if label == 0:
        return [ellipse(rng.uniform(28, 38), rng.uniform(36, 46))]
    if label == 1:
        slant = rng.uniform(-8, 8)
        strokes = [[(50 + slant, 8), (50 - slant, 92)]]
        if rng.random() < 0.55:
            strokes.append([(32, 24), (50 + slant, 8)])
        return strokes
    if label == 2:
        return [[
            (22, 28), (40, 10), (68, 10), (80, 28),
            (62, 50), (22, 90), (82, 90),
        ]]
    if label == 3:
        return [[
            (22, 16), (72, 12), (80, 32), (46, 48),
            (80, 66), (72, 88), (22, 84),
        ]]
    if label == 4:
        return [
            [(72, 8), (72, 95)],
            [(16, 58), (88, 58)],
            [(18, 58), (68, 10)],
        ]
    if label == 5:
        return [[
            (78, 12), (26, 14), (24, 46), (58, 40),
            (82, 58), (72, 88), (26, 88),
        ]]
    if label == 6:
        return [[
            (68, 12), (38, 28), (24, 58), (36, 90),
            (68, 86), (80, 62), (58, 48), (28, 64),
        ]]
    if label == 7:
        strokes = [[(16, 12), (84, 12), (36, 94)]]
        if rng.random() < 0.45:
            strokes.append([(40, 44), (72, 42)])
        return strokes
    if label == 8:
        top = [
            (
                50 + 24 * math.cos(2 * math.pi * i / 28),
                32 + 20 * math.sin(2 * math.pi * i / 28),
            )
            for i in range(29)
        ]
        bottom = [
            (
                50 + 28 * math.cos(2 * math.pi * i / 32),
                70 + 24 * math.sin(2 * math.pi * i / 32),
            )
            for i in range(33)
        ]
        return [top, bottom]
    top = [
        (
            50 + 24 * math.cos(2 * math.pi * i / 28),
            30 + 20 * math.sin(2 * math.pi * i / 28),
        )
        for i in range(29)
    ]
    return [top, [(72, 28), (46, 94)]]


def jitter(strokes, rng):
    angle = rng.uniform(-0.22, 0.22)
    cosine, sine = math.cos(angle), math.sin(angle)
    sx = rng.uniform(0.82, 1.18)
    sy = rng.uniform(0.82, 1.18)
    moved = []
    for stroke in strokes:
        points = []
        for x, y in stroke:
            x = (x - 50) * sx
            y = (y - 50) * sy
            points.append((
                cosine * x - sine * y + 50 + rng.normal(0, 0.7),
                sine * x + cosine * y + 50 + rng.normal(0, 0.7),
            ))
        moved.append(points)
    return moved


def canonical(label):
    fixed = {
        0: [ellipse(32, 42)],
        1: [[(50, 8), (50, 92)], [(34, 22), (50, 8)]],
        2: [[(22, 28), (42, 10), (70, 12), (78, 30), (58, 52), (20, 90), (82, 90)]],
        3: [[(24, 16), (74, 12), (78, 34), (46, 48), (80, 66), (70, 90), (22, 84)]],
        4: [[(70, 8), (70, 95)], [(18, 58), (86, 58)], [(18, 58), (66, 10)]],
        5: [[(76, 12), (28, 14), (24, 48), (56, 40), (80, 58), (70, 88), (26, 88)]],
        6: [[(66, 14), (36, 30), (24, 60), (38, 90), (70, 84), (78, 60), (52, 48), (28, 66)]],
        7: [[(18, 14), (84, 12), (38, 94)]],
        8: shapes(8, np.random.default_rng(0)),
        9: [
            [
                (
                    50 + 22 * math.cos(2 * math.pi * i / 28),
                    30 + 18 * math.sin(2 * math.pi * i / 28),
                )
                for i in range(29)
            ],
            [(70, 26), (44, 94)],
        ],
    }
    return fixed[label]


def synthetic(rng, count):
    images = np.zeros((count, SIDE * SIDE), dtype=np.float32)
    labels = np.zeros(count, dtype=np.int64)
    for i in range(count):
        label = i % 10
        radius = float(rng.uniform(1.15, 1.75))
        images[i] = rasterize(jitter(shapes(label, rng), rng), radius)
        labels[i] = label
    return images, labels


def download(name):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / name
    if path.exists() and path.stat().st_size > 0:
        return path
    url = MNIST[name]
    print(f"download {name}")
    urllib.request.urlretrieve(url, path)
    return path


def load_idx_images(path):
    with gzip.open(path, "rb") as handle:
        _, count, rows, cols = struct.unpack(">IIII", handle.read(16))
        data = np.frombuffer(handle.read(), dtype=np.uint8)
    return data.reshape(count, rows * cols).astype(np.float32) / 255.0


def load_idx_labels(path):
    with gzip.open(path, "rb") as handle:
        _, count = struct.unpack(">II", handle.read(8))
        data = np.frombuffer(handle.read(), dtype=np.uint8)
    return data.astype(np.int64)


def shift_batch(images, rng):
    out = np.zeros_like(images)
    dx = int(rng.integers(-2, 3))
    dy = int(rng.integers(-2, 3))
    src = images.reshape(-1, SIDE, SIDE)
    dst = out.reshape(-1, SIDE, SIDE)
    x0s, x0d = max(0, -dx), max(0, dx)
    y0s, y0d = max(0, -dy), max(0, dy)
    x1 = SIDE - abs(dx)
    y1 = SIDE - abs(dy)
    dst[:, y0d:y0d + y1, x0d:x0d + x1] = src[:, y0s:y0s + y1, x0s:x0s + x1]
    return out


def dilate_batch(images):
    src = images.reshape(-1, SIDE, SIDE)
    padded = np.pad(src, ((0, 0), (1, 1), (1, 1)))
    out = src.copy()
    for dy in range(3):
        for dx in range(3):
            out = np.maximum(out, padded[:, dy:dy + SIDE, dx:dx + SIDE])
    return out.reshape(images.shape)


def softmax(logits):
    shifted = logits - logits.max(axis=1, keepdims=True)
    exp = np.exp(shifted)
    return exp / exp.sum(axis=1, keepdims=True)


def accuracy(images, labels, w1, b1, w2, b2):
    correct = 0
    for start in range(0, len(images), 512):
        batch = images[start:start + 512]
        hidden = np.maximum(batch @ w1.T + b1, 0)
        logits = hidden @ w2.T + b2
        correct += (logits.argmax(axis=1) == labels[start:start + 512]).sum()
    return correct / len(images)


def prototypes(w1, b1, w2, b2):
    ok = 0
    for label in range(10):
        image = rasterize(canonical(label), BRUSH)[None, :]
        hidden = np.maximum(image @ w1.T + b1, 0)
        guess = int((hidden @ w2.T + b2).argmax(axis=1)[0])
        ok += int(guess == label)
        if guess != label:
            print(f"prototype {label} read as {guess}")
    return ok


def train():
    rng = np.random.default_rng(7)
    try:
        mnist_x = load_idx_images(download("train-images"))
        mnist_y = load_idx_labels(download("train-labels"))
        test_x = load_idx_images(download("test-images"))
        test_y = load_idx_labels(download("test-labels"))
    except Exception as error:
        print(f"mnist unavailable ({error}); synthetic only")
        mnist_x = np.zeros((0, SIDE * SIDE), dtype=np.float32)
        mnist_y = np.zeros(0, dtype=np.int64)
        test_x = mnist_x
        test_y = mnist_y
    made_x, made_y = synthetic(rng, 4000)
    images = np.concatenate([mnist_x, made_x])
    labels = np.concatenate([mnist_y, made_y])
    w1 = rng.normal(0, math.sqrt(2 / 784), size=(HIDDEN, 784)).astype(np.float32)
    b1 = np.zeros(HIDDEN, dtype=np.float32)
    w2 = rng.normal(0, math.sqrt(2 / HIDDEN), size=(10, HIDDEN)).astype(np.float32)
    b2 = np.zeros(10, dtype=np.float32)
    moments = {id(p): [np.zeros_like(p), np.zeros_like(p)] for p in (w1, b1, w2, b2)}
    step = 0
    for epoch in range(8):
        order = rng.permutation(len(images))
        loss_sum = 0.0
        seen = 0
        for start in range(0, len(images), 256):
            step += 1
            pick = order[start:start + 256]
            batch = images[pick]
            target = labels[pick]
            if len(mnist_x) and rng.random() < 0.7:
                batch = shift_batch(batch, rng)
            if rng.random() < 0.25:
                batch = dilate_batch(batch)
            hidden_in = batch @ w1.T + b1
            hidden = np.maximum(hidden_in, 0)
            logits = hidden @ w2.T + b2
            probs = softmax(logits)
            eye = np.zeros_like(probs)
            eye[np.arange(len(target)), target] = 1
            loss_sum += -np.log(probs[np.arange(len(target)), target] + 1e-8).sum()
            seen += len(target)
            grad_logits = (probs - eye) / len(target)
            grads = {
                id(w2): grad_logits.T @ hidden,
                id(b2): grad_logits.sum(axis=0),
                id(w1): ((grad_logits @ w2) * (hidden_in > 0)).T @ batch,
                id(b1): ((grad_logits @ w2) * (hidden_in > 0)).sum(axis=0),
            }
            for param in (w1, b1, w2, b2):
                moment, velocity = moments[id(param)]
                grad = grads[id(param)]
                moment[:] = 0.9 * moment + 0.1 * grad
                velocity[:] = 0.999 * velocity + 0.001 * (grad * grad)
                moment_hat = moment / (1 - 0.9**step)
                velocity_hat = velocity / (1 - 0.999**step)
                param -= 0.001 * moment_hat / (np.sqrt(velocity_hat) + 1e-8)
        held = prototypes(w1, b1, w2, b2)
        mnist = accuracy(test_x, test_y, w1, b1, w2, b2) if len(test_x) else 0
        print(
            f"epoch {epoch + 1} loss {loss_sum / seen:.4f} "
            f"mnist {mnist:.4f} prototypes {held}/10"
        )
    held = prototypes(w1, b1, w2, b2)
    if held < 10:
        raise SystemExit(f"clean digits not all recognized ({held}/10)")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("wb") as handle:
        handle.write(b"DGT1")
        handle.write(struct.pack("<HHHH", HIDDEN, 784, 10, 0))
        for array in (w1, b1, w2, b2):
            handle.write(np.ascontiguousarray(array, dtype="<f4").tobytes())
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    train()
