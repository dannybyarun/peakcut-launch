# Running PeakCut on this machine

PeakCut is cloned at `peakcut/` (depth 1, upstream MIT). This file records how it
runs here, what was changed, and what the results were.

## The environment

| Thing | Choice | Why |
|---|---|---|
| Python | 3.13 venv at `peakcut/.venv` | their `requirements.txt` pins `numpy==2.2.6`, which has no Python 3.14 wheels. The machine's default `python` is 3.14, so a separate 3.13 environment was built rather than editing their pins. |
| Database | SQLite (`data/peakcut.db`) | their default. Postgres is only needed for a shared multi-user deployment. |
| Data folder | `peakcut/data` | `PEAKCUT_DATA`. |
| Speech model | Parakeet TDT 0.6b v2 int8 (~480 MB) | sherpa-onnx, fetched once by `python -m studio.fetch_model`. |
| AI | custom OpenAI-compatible endpoint | `data/ai.json`, provider `custom`, model `deepseek-v4.1-flash-free`. |

## Starting it

```powershell
cd peakcut
$env:PEAKCUT_DATA      = "C:\Users\Arun\Downloads\clipping\peakcut\data"
$env:PYTHONIOENCODING = "utf-8"          # their test suite prints Devanagari
$env:PEAKCUT_PUBLIC_URL = "http://127.0.0.1:8765"
.\.venv\Scripts\python.exe -m studio.server
```

The app is then at <http://127.0.0.1:8765/app>. Sign-in is off by default, so every
request belongs to one built-in owner (`u_local`).

## The changes made to their code

### 1. `studio/ai.py` — servers that answer with an event stream

The endpoint used here answers with a **server-sent event stream** unless the
request asks otherwise, and `r.json()` on that body is not JSON. The call now
sends `"stream": False`, and `_openai_body()` reads the answer from either shape
- plain JSON, or the event stream, if a service streams anyway.

### 2. `studio/quality.py` + `studio/jobs.py` — ad breaks and static screens

New module `quality.py`: the mean frame-to-frame luma difference
(`tblend=difference` + `signalstats`) is measured once for the whole video, and
the stretches that never moved are found. Any clip sitting mostly inside one is
dropped, with a note saying so.

Settings: `PEAKCUT_SKIP_STATIC` (on), `PEAKCUT_STATIC_THRESHOLD` (0.4),
`PEAKCUT_STATIC_MIN_SECONDS` (6).

### 3. `tests/test_static.py` — a test for it

Registered in `tests/run.py` as *"ad breaks and frozen screens"*.

## Their test suite

```
python tests/run.py
```

All groups pass - but only with `PYTHONIOENCODING=utf-8`. Without it the
"Hindi and Urdu captions in Roman letters" group dies with a `UnicodeEncodeError`
while printing Devanagari to a cp1252 console. That is a console encoding
problem, not a logic bug.

## What it produced

| Run | Input | Result |
|---|---|---|
| 1 | `demo_input.mp4` - clipforge's own captioned output | 1 clip, 46s, the whole video. Captions rendered twice: the source already had clipforge's burned-in captions, and PeakCut added its own. |
| 2 | `demo_clean.mp4` - the same cut without burned captions | 0 clips. The AI was reachable (`used: true`, 11,581 tokens) but rejected the transcript as not clip-worthy: the source audio is crosstalk over game audio and transcribes to repeated junk. |
| 3 | `speech_input.mp4` - the same video with a clean synthesised monologue | **2 clips, hooks and titles that read like a human wrote them**: `FOUR OF THEM BEHIND ME` / *"He Realizes Four Players Are Behind Him Way Too Late"* and `1 VS 3 SHOTGUN` / *"1v3 With a Shotgun Ends in the Cleanest Round of His Life"*. Categories `fail` and `clutch`, highlights `['behind', 'four', 'hit', 'dead', 'believe']`. |
| 4 | `ad_test.mp4` - gameplay for 11s, then a gray slate | The AI turned the ad break down on its own: 0 clips, because a "subscribe to my channel" pitch is not a clip. The ad-break filter had nothing to drop, so it is covered by `tests/test_static.py` instead of by a live run. |

A note on run 4: the filter is proven by unit test (frozen screen found, moving
picture not, a missing file gives nothing rather than an error) rather than by
watching it fire in a real job - the model turned the ad down before the filter
ever saw it.

Run 3's source is built by Windows text-to-speech (`System.Speech`), so the
transcript is clean:

```powershell
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.SetOutputToWaveFile("speech.wav")
$s.SpeakSsml("<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>...</speak>")
```

Note: `Speak()` reads SSML markup aloud as text. `SpeakSsml()` is the one that
speaks it.

## Running it headlessly

`pk_drive.py` (in the temp folder) uploads a file to `/api/upload`, polls
`/api/jobs/{id}`, and prints the clips with their hooks, titles and highlights.
Options are read from a file (`@file.json`): PowerShell strips the double quotes
out of a JSON string passed as a command-line argument, and the server then
quietly falls back to the default options.

`speech_input.mp4` (87s, 40 MB) is the sample from run 3. It is not in git; it
is rebuilt from the raw cut plus the text-to-speech recipe above.
