# Angle Arcade Adventures

Status: Implemented, awaiting visual verification and TestFlight delivery
Date: 2026-10-02
Architecture: [[ADRs/ADR-0010-angle-arcade-campaign]]

## Learning journey

Age five is the default audience. Play moves from concrete aiming/turning to pictured wedges and corners, reveals degree labels after success, then uses a new setting to transfer the idea. Completion records exploration, not mastery.

| World | Missions | Discovery |
|---|---|---|
| Garden | First flower; Raised basket; Over the fence | Launch angle, height, angle and push together |
| Builder | Turn the corner; Quarter-turn gate; Another corner | Rigid shape rotation, a 90-degree turn, invariant square corners |
| Moon | Earth launch; Moon comparison; Moon delivery | Push, weaker gravity with matched launch inputs, transfer |

## Child experience

All worlds are open. Continue recommends an unfinished mission; a completed world can be replayed. Each completion reveals one of three pieces in a garden, clubhouse or rocket. Unlimited attempts, no timer, no lost lives, no reading requirement.

Guided missions show full paths. Later missions show the initial segment and retain the previous attempt. Help restores the full path and spoken hints; two misses offer help automatically. Cameras remain fixed while inputs change. Launching locks repeated inputs until feedback. Backgrounding or exiting cancels incomplete flights, preserves completed results and restores controls.

TV uses left/right for angle or rotation, up/down for push, Select for launch/check/continue, Play/Pause for help, Menu for worlds and then all games. iPad uses controls at least 80 points wide/high by default. Optional calibrated tilt adjusts launch angles, never builder rotation or push. Touch remains available without motion sensors.

## Progress and compatibility

A versioned local passport stores known mission IDs, attempted/help counts, assisted and independent completions. iPad is scoped to its active child profile; TV uses device progress. Existing Angle Cannon route and historical session name are preserved; its lab entry becomes Angle Arcade and no longer requires motion hardware. No cross-device sync or procedural content.

## Acceptance

Every authored mission is solvable on its permitted input grid. Early launch solutions require at most two adjustments, transfer launches at most four; a quarter turn is actually 0 to 90 degrees. Pure trajectory collision tests include thin obstacles and projectile radius. State tests guard double completion, stale callbacks, world progression and persistence. Touch/remote journeys cover nine missions, replay, help and foreground recovery. Screenshot review must inspect both platforms from the candidate build. Signed release source must match the immutable release tag and both platforms must be valid and available for internal TestFlight testing.
