#!/bin/bash
# Screenshots of THIS units with the WINDOWS Recoil engine, run from WSL.
#
#   VISUAL=dagger,sword,mace tools/visual-test/run.sh [timeout seconds]
#     VISUALZOOM=700 camera distance   VISUALALT=130 height looked at   VISUALRX=2.35 camera pitch
#     VISUALSPACING=150 between units  VISUALUI=1 keep LuaUI running (VISUALSHOWUI=1: and show the HUD)    VISUALENEMY=<unit> an enemy facing each unit
#     VISUALHURT=1 units at 40 % health   VISUALKILL=1 destroy them during the shots
#     VISUALNODRAW=<unit> hide that unit of the line-up with Spring.SetUnitNoDraw (it must vanish)
#     VISUALSHOTFRAME=190 first screenshot, VISUALSHOTS=6, VISUALSTEP=10 frames apart, VISUALFRAMES=n run until frame n
#     VISUALCMD="luarules x|luaui y" console commands at frame 40   VISUALCFG=$'Key = value\n' extra engine config
#     LIGHTSPROBE=1 (with VISUALUI=1) log the light buffers every 60 frames: grep LIGHTSPROBE in the infolog
#     VISUALRSYNC="--exclude=x.lua" leave game files out of the run (before/after comparisons)
#     VISUALOUT=dir where the screenshots go (default <run>/shots)
#     VISUALMAP=/path/map.sd7 VISUALMAPNAME=<name in its mapinfo.lua>: a real map instead of the generated flat one
#
# WINROOT (default "/mnt/i/Claude Space/recoil-win") holds engine-2026.09.01/ (the release's amd64-windows.7z
# unpacked) and run-this/ (write dir; the game is rsynced to run-this/games/this.sdd).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
GAME=$(cd "$HERE/../.." && pwd)
WINROOT=${WINROOT:-"/mnt/i/Claude Space/recoil-win"}
ENGINE="$WINROOT/engine-2026.09.01"
RUN="$WINROOT/run-this"
mkdir -p "$RUN/games"
rsync -a --delete --delete-excluded --exclude=.git --exclude=tools --exclude=tools_autotex $VISUALRSYNC "$GAME/" "$RUN/games/this.sdd/"
rsync -a --delete "$HERE/thistest.sdd/" "$RUN/games/thistest.sdd/"
rm -rf "$RUN/screenshots" "$RUN/infolog.txt"
cp "$HERE/script.txt" "$RUN/script.txt"
OPTS=""
for kv in "visualunits=$VISUAL" "visualzoom=$VISUALZOOM" "visualalt=$VISUALALT" "visualrx=$VISUALRX" \
  "visualspacing=$VISUALSPACING" "visualui=$VISUALUI" "visualenemy=$VISUALENEMY" "visualhurt=$VISUALHURT" \
  "visualkill=$VISUALKILL" "visualshotframe=$VISUALSHOTFRAME" "visualshots=$VISUALSHOTS" "visualstep=$VISUALSTEP" \
  "visualframes=$VISUALFRAMES" "visualcmd=$VISUALCMD" "lightsprobe=$LIGHTSPROBE" "visualnodraw=$VISUALNODRAW" "visualshowui=$VISUALSHOWUI" $VISUALOPTS; do
  [ -n "${kv#*=}" ] && OPTS="$OPTS\n\t\t$kv;"
done
sed -i "s#visualprobe=1;#visualprobe=1;$OPTS#" "$RUN/script.txt"
rm -rf "$RUN/maps"
if [ -n "$VISUALMAP" ]; then
  mkdir -p "$RUN/maps" && cp "$VISUALMAP" "$RUN/maps/"
  sed -i "/InitBlank=1;/d; s/MapName=blank_test;/MapName=${VISUALMAPNAME:?set VISUALMAPNAME to the name in the map mapinfo.lua};/" "$RUN/script.txt"
fi
printf 'XResolutionWindowed = %s\nYResolutionWindowed = %s\nFullscreen = 0\nsnd_volmaster = 0\nMaxSounds = 0\n%s' "${VISUALW:-1600}" "${VISUALH:-900}" "${VISUALCFG:-}" > "$RUN/vis.cfg"
set +e
timeout "${1:-300}" "$ENGINE/spring.exe" --window --config "$(wslpath -w "$RUN/vis.cfg")" --isolation \
  --isolation-dir "$(wslpath -w "$ENGINE")" --write-dir "$(wslpath -w "$RUN")" "$(wslpath -w "$RUN/script.txt")" > /dev/null 2>&1
echo "engine exit: $?   (infolog: $RUN/infolog.txt)"
OUT=${VISUALOUT:-$RUN/shots}
rm -rf "$OUT"; mkdir -p "$OUT" && cp "$RUN"/screenshots/* "$OUT/" 2>/dev/null
echo "--- screenshots: $OUT ($(ls "$OUT" | wc -l))"
grep -a "\[VISUAL\]\|GL renderer\|Error\|error\|rror:" "$RUN/infolog.txt" | sed 's/^\[t=[^]]*\]//' | sort | uniq -c | sort -rn | head -${VISUALLOG:-25}
