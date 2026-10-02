#!/usr/bin/env python3
"""Turn a song into the timeline every scene reads: beats, bars, sections, cues.

    python3 tools/analyze_song.py <song-id>

reads songs/<song-id>.<ext> (git-ignored) and timeline/<song-id>.cues.json
(the owner's cue notes, committed), and writes timeline/<song-id>.json.

The music is assumed to sit on one steady tempo, as generated and produced
songs usually do. The grid is fitted to the whole song's onsets, and the fit
is checked window by window: the report prints how far each window's own best
beat phase sits from the grid, so drift or a tempo change shows up at once.
Swapping in another song means running this again, not rewriting scenes.
"""

import hashlib
import json
import sys
import warnings
from pathlib import Path

import librosa
import numpy as np

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parent.parent
SR = 44100
HOP = 128
BEATS_PER_BAR = 4
PHRASE_BARS = 8


def load(song_id):
    matches = [p for p in (ROOT / "songs").glob(song_id + ".*") if p.suffix.lower() in (".mp3", ".wav", ".aiff", ".flac", ".m4a")]
    if len(matches) != 1:
        sys.exit(f"expected exactly one audio file songs/{song_id}.*, found {len(matches)}")
    path = matches[0]
    y, _ = librosa.load(path, sr=SR, mono=True)
    return path, y


def onset_envelopes(y):
    """Two onset envelopes. The full band finds the tempo cleanly but also
    locks onto syncopated hats and plucks, so the beat's phase comes from the
    kick's band, which marks the beat in this music."""
    full = librosa.onset.onset_strength(y=y, sr=SR, hop_length=HOP, aggregate=np.median, fmax=8000, n_mels=128)
    S = np.abs(librosa.stft(y, n_fft=2048, hop_length=HOP))
    freqs = librosa.fft_frequencies(sr=SR, n_fft=2048)
    low = np.log1p(S[(freqs > 30) & (freqs < 120)]).sum(axis=0)
    kick = np.maximum(0.0, np.diff(low, prepend=low[0]))
    return full / full.max(), kick / kick.max()


def comb(env, period, phase, start, end):
    """Mean onset strength on a beat grid, each beat allowed ±2 frames."""
    fps = SR / HOP
    first = phase + np.ceil((start - phase) / period) * period
    idx = np.round(np.arange(first, end, period) * fps).astype(int)
    idx = idx[(idx >= 2) & (idx < len(env) - 2)]
    if len(idx) == 0:
        return 0.0
    windows = np.stack([env[idx + k] for k in range(-2, 3)])
    return float(windows.max(axis=0).mean())


def fit_period(env, duration):
    """The steady beat period that best fits the whole song."""
    best = (-1.0, 0.0)
    for period in np.arange(60 / 180, 60 / 70, 0.002):
        score = max(comb(env, period, ph, 0, duration) for ph in np.arange(0, period, 0.01))
        if score > best[0]:
            best = (score, period)
    for step, span in ((0.0002, 0.004), (0.00001, 0.0004)):
        p0 = best[1]
        for period in np.arange(p0 - span, p0 + span, step):
            score = max(comb(env, period, ph, 0, duration) for ph in np.arange(0, period, 0.002))
            if score > best[0]:
                best = (score, period)
    return best[1]


def fit_phase(env, period, duration):
    phases = np.arange(0, period, 0.0005)
    return float(phases[int(np.argmax([comb(env, period, ph, 0, duration) for ph in phases]))])


def refine(full, kick, period, duration):
    """Phase from the kick; then any slow drift between the windows that sit
    on the beat is folded back into the period, twice."""
    phase = fit_phase(kick, period, duration)
    for _ in range(2):
        checks = window_check(full, period, phase, duration)
        on = [c for c in checks if on_grid(c, period)]
        if len(on) >= 4:
            times = np.array([c["start"] + 4.0 for c in on])
            offsets = np.array([c["offset_ms"] for c in on]) / 1000.0
            slope, _ = np.polyfit(times, offsets, 1)
            period *= 1.0 + slope
        phase = fit_phase(kick, period, duration)
    return period, phase


def on_grid(check, period):
    """A window locks to the grid when its own best phase lands within a
    sixteenth of a beat of it; off-beat or drumless windows don't."""
    return check["contrast"] > 4 and abs(check["offset_ms"]) < period * 1000 / 8


def window_check(env, period, phase, duration, width=8.0, step=4.0):
    """Each window's own best phase, as an offset from the grid, in ms."""
    rows = []
    for start in np.arange(0, duration - width, step):
        phases = np.arange(0, period, 0.001)
        scores = np.array([comb(env, period, ph, start, start + width) for ph in phases])
        best = phases[int(np.argmax(scores))]
        offset = (best - phase + period / 2) % period - period / 2
        rows.append({"start": round(float(start), 2), "offset_ms": round(offset * 1000, 1),
                     "strength": round(float(scores.max()), 3), "contrast": round(float(scores.max() / scores.mean()), 2)})
    return rows


def bar_features(y, bar_times):
    """Loudness and low-end energy per bar, each scaled to the song's max."""
    S = np.abs(librosa.stft(y, n_fft=2048, hop_length=512))
    freqs = librosa.fft_frequencies(sr=SR, n_fft=2048)
    times = librosa.times_like(S, sr=SR, hop_length=512)
    rms = librosa.feature.rms(S=S)[0]
    low = S[(freqs > 30) & (freqs < 150)].mean(axis=0)
    high = S[freqs > 4000].mean(axis=0)
    rows = []
    for a, b in zip(bar_times[:-1], bar_times[1:]):
        m = (times >= a) & (times < b)
        rows.append([rms[m].mean(), low[m].mean(), high[m].mean()])
    rows = np.array(rows)
    return rows / rows.max(axis=0)


def downbeat_offset(features_by_beat):
    """Which beat (mod 4) starts a bar: the one where the music changes most."""
    novelty = np.abs(np.diff(features_by_beat, axis=0)).sum(axis=1)
    novelty = np.concatenate([[0.0], novelty])
    scores = [novelty[o::BEATS_PER_BAR].mean() for o in range(BEATS_PER_BAR)]
    return int(np.argmax(scores)), scores


def sections_from_bars(bars, bar_times):
    """Split at bars where the loudness or low end jumps; label by energy."""
    level = bars[:, 0] * 0.5 + bars[:, 1] * 0.5
    jumps = []
    for i in range(1, len(level)):
        before = level[max(0, i - 2):i].mean()
        after = level[i:i + 2].mean()
        if abs(after - before) > 0.18:
            jumps.append(i)
    # Keep one boundary per cluster of neighbouring bars: the biggest jump.
    bounds = [0]
    for i in jumps:
        if i - bounds[-1] <= 2 and bounds[-1] != 0:
            prev = bounds[-1]
            change = lambda k: abs(level[k:k + 2].mean() - level[max(0, k - 2):k].mean())
            if change(i) > change(prev):
                bounds[-1] = i
        else:
            bounds.append(i)
    bounds.append(len(level))
    out = []
    for a, b in zip(bounds[:-1], bounds[1:]):
        energy = float(level[a:b].mean())
        out.append({"start_bar": int(a), "end_bar": int(b), "start": round(float(bar_times[a]), 3),
                    "end": round(float(bar_times[b]), 3), "energy": round(energy, 2),
                    "level": "high" if energy > 0.7 else "low"})
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    song_id = sys.argv[1]
    path, y = load(song_id)
    duration = len(y) / SR
    full, kick = onset_envelopes(y)
    period, phase = refine(full, kick, fit_period(full, duration), duration)
    checks = window_check(full, period, phase, duration)

    beats = np.arange(phase, duration, period)
    # Features per beat, to find where bars start.
    per_beat = bar_features(y, np.append(beats, duration))
    offset, scores = downbeat_offset(per_beat)
    bar_starts = beats[offset::BEATS_PER_BAR]
    # Bar 0 starts on the first downbeat; a pickup before it is bar -1.
    bar_times = np.append(bar_starts, bar_starts[-1] + period * BEATS_PER_BAR)
    bars = bar_features(y, bar_times)
    sections = sections_from_bars(bars, bar_times)

    cues_path = ROOT / "timeline" / f"{song_id}.cues.json"
    cues = json.loads(cues_path.read_text()) if cues_path.exists() else {"sections": {}, "cues": []}
    names = cues.get("sections", {})
    for s in sections:
        s["name"] = names.get(str(s["start_bar"]), "")
    resolved = []
    for cue in cues.get("cues", []):
        # A cue placed by the owner at a rough time lands on the nearest bar.
        bar = int(np.argmin(np.abs(bar_starts - cue["near"])))
        resolved.append({**cue, "bar": bar, "t": round(float(bar_starts[bar]), 3)})

    lockable = [c for c in checks if on_grid(c, period)]
    timeline = {
        "song": song_id,
        "audio": str(path.relative_to(ROOT)),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "duration": round(duration, 3),
        "tempo_bpm": round(60 / period, 3),
        "beat_period": round(period, 6),
        "first_beat": round(phase, 4),
        "beats_per_bar": BEATS_PER_BAR,
        "phrase_bars": PHRASE_BARS,
        "downbeat_offset": offset,
        "bar_zero": round(float(bar_starts[0]), 4),
        "beats": [round(float(b), 4) for b in beats],
        "bars": [round(float(b), 4) for b in bar_starts],
        "bar_energy": [[round(float(v), 3) for v in row] for row in bars],
        "sections": sections,
        "cues": resolved,
        "check": {
            "method": "steady period from the full-band onset envelope, phase from the kick band, drift folded back in; each 8 s window's own best phase compared with the grid",
            "windows_on_grid": len(lockable),
            "windows": len(checks),
            "max_offset_ms_on_grid": max(abs(c["offset_ms"]) for c in lockable) if lockable else None,
            "downbeat_scores": [round(float(s), 4) for s in scores],
            "per_window": checks,
        },
    }
    out = ROOT / "timeline" / f"{song_id}.json"
    out.write_text(json.dumps(timeline, indent=1) + "\n")

    print(f"{song_id}: {duration:.2f} s, {60 / period:.3f} BPM, first beat {phase:.3f} s, bar 0 at {bar_starts[0]:.3f} s")
    print(f"grid check: {len(lockable)}/{len(checks)} windows lock to the grid, worst {timeline['check']['max_offset_ms_on_grid']} ms")
    for c in checks:
        flag = "" if c in lockable else "   (off-beat or no drums)"
        print(f"  {int(c['start']) // 60}:{c['start'] % 60:05.2f}  {c['offset_ms']:+7.1f} ms  contrast {c['contrast']:5.2f}{flag}")
    print("sections:")
    for s in sections:
        print(f"  bars {s['start_bar']:3d}-{s['end_bar']:3d}  {int(s['start']) // 60}:{s['start'] % 60:05.2f} - {int(s['end']) // 60}:{s['end'] % 60:05.2f}  {s['level']:4s} {s['energy']:.2f}  {s['name']}")
    for c in resolved:
        print(f"  cue {c['name']}: near {c['near']} -> bar {c['bar']} at {c['t']:.3f} s")
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
