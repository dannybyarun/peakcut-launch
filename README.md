# Local clipping pipeline

Turns a stream VOD into vertical, captioned clips that are ready to post.

**PeakCut does the work.** It is the engine: it transcribes locally, asks your AI
which moments a stranger would stop for, and renders each one 9:16 with karaoke
captions, a hook, a title, a description and hashtags. It records live streams
and can post to YouTube, Instagram and TikTok.

```
VOD or a link ──> transcribe (local model) ──> AI picks the moments
                                                    │
                        hook / title / description / hashtags
                                                    │
                            karaoke captions, 9:16 render
                                                    │
                                          clips + ready post copy
```

Tested against the same footage, it produced hooks like `1 VS 3 SHOTGUN` with the
title *"1v3 With a Shotgun Ends in the Cleanest Round of His Life"* — copy that a
keyword matcher cannot write.

## Quickstart

```powershell
.\start-peakcut.ps1
```

Then open <http://127.0.0.1:8765/app>. Sign-in is off by default, so there is no
account to create. Paste a YouTube, Twitch or Kick link, or upload a file.

The first run downloads the speech model (~480 MB). Full setup notes, every
setting and the exact commands used here: [PEAKCUT-LOCAL.md](PEAKCUT-LOCAL.md).

### The AI endpoint

PeakCut needs an AI to judge the moments. Any OpenAI-compatible endpoint works,
including one running on this machine:

| Setting | Where |
|---|---|
| Provider | `custom (OpenAI-compatible)` |
| Address | the endpoint's `/v1` base, e.g. `http://127.0.0.1:11434/v1` |
| Model | the model name the endpoint expects |
| Key | anything the endpoint accepts |

Saved to `peakcut/data/ai.json` and picked up without a restart.

Without an AI the app still works, but it picks clips by loudness alone, which on
a quiet stream means one clip covering the whole video.

## What we changed in PeakCut

Three patches, all in `peakcut/studio/`, all verified with their own test suite
(`python tests/run.py` → *All tests passed*).

### 1. `ai.py` — servers that answer with an event stream

The OpenAI-compatible path called `r.json()` on the response body. The endpoint
used here answers with a **server-sent event stream** unless the request says
otherwise, and that body is not JSON. The call now sends `"stream": False`, and
`_openai_body()` reads the answer from either shape — plain JSON, or the event
stream, if a service streams anyway.

### 2. `ai.py` — answers that are not quite right

A model asked for JSON now and then answers with a sentence in front of it, a
second object after it, a tool call instead of a message, or a truncated
bracket. All of those are now read rather than refused: the JSON is looked for
inside the answer (`_parse`), and a tool call's arguments are used when the
message is empty (`_openai_body`).

This was not hypothetical — on a live stream it cost two clips their hook and
title, because the parse failed and the clip was made with nothing.

### 3. `quality.py` + `jobs.py` — ad breaks and static screens

Commercials and "be right back" slates are stitched into streams, and a clip
taken from one is worthless. `studio/quality.py` measures the mean frame-to-frame
luma difference (`tblend=difference` + `signalstats`) once for the whole video
and finds the stretches that never moved; any clip sitting mostly inside one is
dropped, with a note saying so.

Measured on real captures: ad slate **~0.19**, gameplay **~1.6–2.5** — a wide
margin, so no OCR, no reference image and no model is needed.

| Setting | Default | Meaning |
|---|---|---|
| `PEAKCUT_SKIP_STATIC` | `1` | drop clips that sit in an ad break |
| `PEAKCUT_STATIC_THRESHOLD` | `0.4` | mean luma difference under which nothing moved |
| `PEAKCUT_STATIC_MIN_SECONDS` | `6` | how long a static stretch must be to count |

`tests/test_static.py` covers it, registered in their suite as *"ad breaks and
frozen screens"*, and `tests/test_answer.py` as *"answers that are not quite
right"*.

## Gaming mode

PeakCut was built for talk. A gaming stream is mostly not talk — it is a game, a
facecam, and a streamer reacting. Four changes make it work on those streams,
all in [GAMING.md](GAMING.md):

1. **It knows which game it is.** `studio/games.py` reads the game from the
   stream title, the video title, the channel name, or the creator's own
   setting — 25 games by name, GTA VI among them. The AI is then told what it is
   looking at, and every post carries that game's tags (`#GTA6`, `#ViceCity`,
   `#RockstarGames`) whatever the AI wrote for itself.
2. **The crowd is counted as people.** One person sending fifty messages is not
   a crowd getting excited. The chat reader now keeps the names, and the two
   places that ask "did the chat react?" use people instead of messages.
3. **The facecam is found.** A webcam is the one thing in a gaming stream with a
   straight border that never moves. `studio/facecam.py` finds that border and
   the new **gameplay** layout fills the screen with the game and keeps the
   facecam in the corner — instead of squeezing the whole 16:9 frame into a band
   with blurred fill.
4. **Ad breaks** — as above.

The proof, from a real run on a video called "GTA 6 launch night.mp4":

```
game:    Grand Theft Auto VI
hook:    1 VS 3, THAT WAS CLEAN
title:   GTA 6: Driving a Cop Car Into a Cop Car (1 vs 3)
tags:    GTA6, GTA6Launch, GTA6Game, ViceCity, RockstarGames
```

And the facecam, on a real GTA V stream with a webcam in the top-left: found at
289x162 in the 1280x720 picture, and the clip that comes out has the game filling
the frame with the webcam in the corner.

## The launch roster

[LAUNCH-ROSTER.md](LAUNCH-ROSTER.md) has the thirteen GTA VI launch-night
streamers now on the creator list, how each channel was checked before it was
added, and the settings they share.

## clipforge (parked)

`clipforge/` was the earlier attempt at the same job: a local pipeline that found
hype by **chat velocity** — unique chatters per second against a rolling
baseline — instead of reading the transcript. Its caption engine was ported from
PeakCut and back again, and its ad-break rejection now lives inside PeakCut.

It is **parked**: PeakCut's AI judgement and its post copy came out ahead on
every test, so clipforge is not being worked on. Its one idea worth reviving is
the chat reader, because **PeakCut reads the transcript, and a moment with no
speech does not exist to it** — a streamer screaming over game audio transcribes
to nothing useful. See [clipforge/README.md](clipforge/README.md) if that day
comes.

## Honest limits

- **PeakCut needs an AI key.** Without one it falls back to loudness only.
- **PeakCut is transcript-driven.** A VOD of pure gameplay with no speech gives
  it nothing to judge.
- **Word timings are the weak point.** On crosstalk the transcript garbles
  ("Boss both of them both of them one day"), and the karaoke captions drift
  with it.
- **PeakCut's own test suite needs `PYTHONIOENCODING=utf-8`** on Windows. The
  Roman-script test prints Devanagari and dies on a cp1252 console.

## Layout

```
peakcut/          the PeakCut project, with our patches
start-peakcut.ps1 one command to run it
GAMING.md         how it is made to work on game streams
LAUNCH-ROSTER.md  who is being watched for launch night
clipforge/        the earlier attempt, parked (see clipforge/README.md)
tests/            clipforge's tests
PEAKCUT-LOCAL.md  how PeakCut runs on this machine
demo/, out/       sample output
```
