# Route Quest MVP

Route Quest is a Room Quest route mode inspired by TestFlight issue #739. It reuses the delight of Compass Angles body turns, but it does **not** claim exact indoor route tracking.

## Product boundary

- Compass Angles stays a turn-only geometry game.
- Room Quest owns adult setup, safe room movement, station confirmation, and fallbacks.
- Route Quest adds ordered route nodes: start, turn, careful steps, station confirmation, return home.

## MVP route

The first shippable route template is `room_route_two_station_mvp`:

1. Start at home base.
2. Turn right 45°.
3. Take five careful steps.
4. Confirm Red Rocket and collect three.
5. Turn left 90°.
6. Take four careful steps.
7. Confirm Blue Bubble and collect two.
8. Return to home base.

Step nodes are manual/parent-confirmed in the MVP. Step sensors may be logged as optional evidence only after real-device proof.

## Safety and privacy rules

- Adult setup and safety checklist remain required.
- Copy says "careful steps" and never rewards speed or running.
- Camera is used only at stationary checkpoint moments.
- Telemetry stores route template, node kind/index, target turn/steps, completion method, elapsed time, and fallback counts.
- Telemetry must not store raw GPS traces, continuous coordinates, or route paths.

## Proof before TestFlight enablement

- Unit tests cover route progression, fallback completion, and telemetry payload shape.
- Simulator proof must show the route can complete without hardware step sensors.
- Real-device proof is required before enabling a sensor-gated route: turn success ≥ 8/10 and step evidence within ±2 steps at least 85% of the time, otherwise steps stay manual.
