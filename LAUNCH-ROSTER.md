# GTA VI launch roster

Who PeakCut is watching for launch night (19 November 2026), and how each one was
checked before being added.

## How they were chosen

Two sources:

1. **YouTube's official launch broadcast** — "Launch Day: YouTube's 24 Hour GTAVI
   Livestream". YouTube published the creator list on 12 November: the pre-show
   with RDCWorld starts 11pm ET on 18 November, the marathon runs from midnight
   ET on 19 November, the minute the game unlocks, ending with coverage from
   Miami. The confirmed names include Caylus, Zhong, Kat, Jelly, Rivers, Jake
   Baldino and Cinna, plus a wider collage of Kinda Funny Games, Loserfruit,
   TGG, Total Gaming, Payal Gaming, Any Austin, KIMBLUE, Sleepground, Akagami
   no Tomo and more than a dozen others.
2. **The GTA RP crowd** — Burn, Kaysan and Will Neff have to decide what is next
   after a decade of GTA V.

## How each channel was checked

Handles were verified before anything was added, because Twitch creates a page
for *any* handle and YouTube does the same. Two checks were used together:

- **Twitch** (public GraphQL): the channel's display name, follower count and
  whether it has past broadcasts. A placeholder page has no VODs.
- **YouTube** (yt-dlp): the channel resolves, and its real channel name.

That check killed a lot of guesses: `twitch.tv/riversrosen`, `nought4fun`,
`tgg` and `windahbasudara` do not exist, and `kfngaming`, `zhong`, `nought`,
`kimblue`, `anyaustin`, `anwarjibawi`, `payalgaming`, `sharkshe`,
`skorpiongamer`, `akagaminotom` and `tggaming` are empty pages with no
broadcasts. `youtube.com/@rivers` is "Rivers Australia" with 482 subscribers —
not the Rivers on the launch list. `youtube.com/@caylus` and `@totalgaming` had
to be checked by hand too.

## The roster

| Creator | Record from | Also on | Why |
|---|---|---|---|
| IShowSpeed | twitch.tv/ishowspeed | youtube @IShowSpeed | live right now with the title *"CLICK THIS STREAM IF YOU WANT GTA 6!"* |
| Loserfruit | twitch.tv/loserfruit | youtube @loserfruit | on the launch broadcast; posted GTA 6 content the same day |
| JoblessGarrett | twitch.tv/joblessgarrett | youtube @joblessgarrett | on the launch broadcast; posted a GTA 6 demo breakdown |
| Will Neff | twitch.tv/willneff | youtube @willneff | GTA RP, 572k |
| Kaysan | twitch.tv/kaysan | | GTA RP, 613k |
| Burn | twitch.tv/burn | | GTA RP, 299k |
| SamiraClose | twitch.tv/samiraclose | | on the launch broadcast |
| Jelly | twitch.tv/jelly | | on the launch broadcast (Spain) |
| Caylus | youtube @caylus | twitch.tv/caylus | named by YouTube; 21.7M on the gaming channel. His Twitch page is an empty placeholder, so YouTube is the one to record |
| Zhong | youtube @zhong | | named by YouTube |
| Kinda Funny Games | youtube @Kindafunnygames | | gaming channel, on the launch broadcast |
| Jake Baldino | youtube @jakebaldino | | named by YouTube |
| Payal Gaming | youtube @payalgaming | | on the launch broadcast |
| Sharkshe | youtube @sharkshe | | on the launch broadcast |

Twitch is the record target wherever the channel exists, because that is where
PeakCut's chat reader works — chat activity is one of the signals it uses to
decide a moment is worth cutting. YouTube channels are added as a second
channel on the same creator, tried when the first one is not live.

## Settings they all share

```json
{ "style": "hype", "layout": "gameplay", "min_len": 15, "max_len": 60,
  "max_clips": 6, "min_score": 65, "auto_watch": false, "buffer_min": 10,
  "live_per_hour": 4, "ai_every_min": 3, "ai_only_on_spike": true }
```

`auto_watch` means PeakCut starts recording on its own the moment the channel
goes live. `min_score` is 65 rather than the default 80, because launch night is
chaotic and a tighter bar means fewer clips. `layout: gameplay` fills the screen
with the game and keeps the facecam in the corner (see [GAMING.md](GAMING.md)).

**Turn auto-record on when you want it, and off when you do not.** It is off now:
on the 14th of November it had recorded three streams at once and taken about a
gigabyte of disk.

## What the recordings cost

Each recording keeps the last `buffer_min` minutes of video on disk, so it can
cut a clip from moments that have just passed. At 720p that is roughly
**30 MB per minute of stream**, so:

| `buffer_min` | on disk per recording |
|---|---|
| 20 minutes (the default) | ~600 MB |
| 10 minutes (what the roster uses) | ~300 MB |
| 5 minutes | ~150 MB |

Ten minutes is plenty: a clip needs the half minute before the moment, not the
last ten.

`start-peakcut.ps1` also sets `PEAKCUT_MAX_LIVE=3`, so at most three streams are
recorded at once (about 900 MB of video in total). Raise it if you want more
channels covered, and lower it if space is tight.

The recording segments are trimmed as the stream goes on, but a session that is
stopped abruptly can leave them behind. To clear them by hand:

```powershell
Get-ChildItem peakcut\data\users\u_local\creators -Recurse -Directory -Filter buffer |
  ForEach-Object { Get-ChildItem $_.FullName -Filter *.ts | Remove-Item -Force }
```

That removes the raw recording only. The clips that were made are in the `clips`
folders next to it and stay.

## Adding one more

```powershell
# the Twitch channel must have past broadcasts, or it is a placeholder
.\peakcut\.venv\Scripts\python.exe -c "import yt_dlp; ..."
```

or just add it in the app under **Creators → New**, then check the channel list
shows the right name.

## The other two creators

`loprush` (kick.com/loprush) and `asmongold247` (kick.com/asmongold247) were
already on the list, added by hand, and were left as they are.

## What happened when the roster went live

Within a minute of `auto_watch` being on, PeakCut had found a live channel and
started recording it on its own:

```
live: 20261116-230529  creator=ishowspeed
       title: "CLICK THIS STREAM IF YOU WANT GTA 6!"
       twitch.tv/ishowspeed    live, 17,054 viewers
       youtube @IShowSpeed    live, 58,567 viewers
```

That session ended with three clips written by the model while the stream was
still running:

| Clip | Hook | Title |
|---|---|---|
| clip003 | `WHY NOT? THEN SKIPS ME` | *Speed Offers GTA 6, Kid Says "Why Not?" And Skips Him* (tags GTA6, Speed, funny) |
| clip002 | `W KID FROM NORTHEAST INDIA` | *Speed Promises Streamer of the Year to a Kid From Northeast India* (tags Wholesome, StreamHighlight) |
| clip001 | — | cut, but the model's answer was not readable (see the parsing fix) |

The `loprush` GTA V session produced `GUNS TO SELL` — *"Streamer Pitches an
Unhinged Gun-Selling Business Plan"*.

When the server was restarted mid-stream, the recording came back up on its own
and the next session started without anyone touching anything.
