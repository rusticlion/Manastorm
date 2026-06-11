# Manastorm Readability Spec

How game state is communicated to players, per channel and per sense.
This document drives the "juice" work: the goal is not spectacle, it is
making the core mechanic — reading your opponent — actually playable.

## Locked Design Decisions

1. **Disclosure policy:** Full disclosure by default. Every spell has a
   unique, learnable *signature* readable during its channel phase. A small
   set of deliberately designed **mix-up pairs** per character share a
   signature until resolution.
2. **Reaction window:** **3 seconds.** Every threat must be fully legible
   no later than 3 seconds before it resolves, and a universal urgency cue
   fires at T−3s.
3. **Canonical matchup:** Ashgar vs. Selene. All readability decisions are
   tuned against this duel first. Demo roster target: Ashgar, Selene,
   Borrak, Brightwulf.

## The Read Model

Every piece of information passes through three stages, and each stage has
a preferred sense:

| Stage | Question | Primary sense | Why |
|---|---|---|---|
| Detection | "Something changed" | **Audio** | Eyes are busy managing your own slots |
| Identification | "What is it" | **Visual** | Shape/color language carries detail |
| Urgency | "How long do I have" | **Both** | Absolute-timing sting + arc escalation |

Audio is the detection channel because attention is the scarce resource in
real-time play. Stereo-pan cues by caster side.

## Signature Anatomy

A spell's signature is the tuple the player can observe during channel:

```
signature = (affinity, attackType, visualShape, costProfile, castTimeTier)
```

Each component maps to a render channel:

- **affinity** → arc/rune color (exists today in `WizardVisuals`) + audio
  timbre of the channel loop.
- **attackType** (projectile / remote / zone / utility) → channel-phase
  audio family and the resolution impact sound. Also determines which
  shield answers it, so it must be the loudest part of the read.
- **visualShape** → channel-phase geometry: token orbit behavior, rune
  motif, arc character. (Resolution visuals already use this via
  `VisualResolver`; this extends it backward into the channel phase.)
- **costProfile** → magnitude cues: orbit density, glow, audio layering.
  Token types are visible in the orbit (exists today).
- **castTimeTier** → the inherent rhythm of the arc.

Two spells are distinguishable iff their tuples differ in any observable
component. A **mix-up pair** is two spells whose tuples collide *by
design*, declared in the spell definition:

```lua
mixupWith = "firebolt",  -- shares a signature with this spell until resolution
```

### Signature lint (tool to build)

Extend the spirit of `tools/lint_spell_enums.lua`: for each character's
spellbook, flag any two spells with colliding signature tuples that are
not mutually tagged `mixupWith`. Accidental ambiguity becomes a build
failure; intentional mix-ups become authored data (which AI personalities
can eventually exploit).

**Known collision (decide: differentiate or tag):** Selene's *Tidal Force*
(FAST, REMOTE/WARP, water+moon) vs. *Increase Gravity* (FAST, REMOTE/WARP,
moon+any) — when ANY is paid with water, the tuples are identical.

## Timing Rules

Cast tiers (default `CastSpeedSets.FAST`, `core/Constants.lua:164`):
VERY_FAST=3s, FAST=6s, NORMAL=9s, SLOW=12s, VERY_SLOW=15s.

- **R1 — Legible at queue.** The full signature is readable from the
  moment tokens arrive in the slot. No "mystery channel" phase.
- **R2 — Universal sting at T−3s.** Absolute, not proportional, so players
  build a reliable reflex (flash = block). Audio sting + visual
  intensification of the arc.
- **R3 — VERY_FAST spells sting at queue.** A 3s spell's sting fires the
  instant it is queued. Design constraint: 3s spells must be low-impact or
  utility (true today: Salt Circle, Total Eclipse).
- **R4 — Answerability audit.** For every threat, at least one answer
  (shield, reposition, interrupt) must be queueable-and-resolvable inside
  the threat's legibility window. Audit finding in the canonical matchup:
  - Ashgar's *Salt Circle* (ward, 3s) answers anything if queued by T−3s —
    his sting **is** his last call. Clean.
  - Selene's *Wings of Moonlight* (ward, 6s) requires queueing by T−6s.
    Against Ashgar's FAST (6s) threats her reactive window is **zero** —
    she must pre-read or pay for it. Decide whether that asymmetry is
    character identity (Selene = anticipation, Ashgar = reaction) or a
    balance bug. If identity: it should be stated in her design notes and
    compensated elsewhere in the kit.
- **R5 — Zone beats turtling.** Wards block projectile+remote but not
  ZONE; Blast Wave punishes shield-first play. Preserve this triangle in
  all audits.

## Channel Specs

### Audio (new system: `AudioResolver`, mirrors `VisualResolver`)

Picks sounds from event metadata exactly as VisualResolver picks visuals.
Cue inventory (~15 placeholder sounds to start), hung off existing
EventRunner flow:

| Cue | Trigger point | Varies by |
|---|---|---|
| Queue thunk | token acquisition (TokenManager → slot) | caster side (pan) |
| Channel loop | slot active, looping, low volume | affinity (timbre), cost (layers) |
| Urgency sting | slot remaining time crosses 3.0s | attackType |
| Resolution impact | DAMAGE / EFFECT events | attackType + affinity |
| Shield block | SHIELD_BLOCKED / BLOCKED_DAMAGE | shield type |
| Shield up | CREATE_SHIELD | shield type |
| Position change | SET_ELEVATION / range events | direction |
| Trap trigger | TRIGGER_TRAP / NOTIFY_TRAP_TRIGGER | — |
| Token return | tokens released to pool | token type |
| Pool ambience | continuous, intensity from pool volatility | match phase |

### Spell slots / cast arcs (`systems/WizardVisuals.lua`)

- Channel phase gains a **shape motif** per `visualShape` (rune behavior /
  orbit pattern), extending the affinity coloring that exists today.
- At T−3s the arc escalates: brightness, pulse rate, particle agitation.
- Escalation is identical across all spells (reflex training), the motif
  is what differs (identification).

### Shields (`systems/ShieldSystem.lua`)

Shield type must be identifiable in peripheral vision in under a second:

- **Barrier** → hard-edged wall geometry (physical, blocks projectiles).
- **Ward** → orbiting runes (magical, blocks remote per type table).
- **Field** → ambient haze (flexible).

Blocked hits are the single best juice moment in the game: clank +
flash + shake already partially wired (`vfx.lua` shield-block path) —
consolidate into the Juice module.

### Mana pool (`manapool.lua`)

- **Countability:** cluster or band tokens by type so pool composition is
  glanceable ("can she afford Full Moon Beam?" = count moon tokens fast).
- **Escalation:** orbit speed/brightness/volatility rises as the match
  ramps — the pacing channel promised in the design doc, plus the audio
  ambience above.

### Position states

Binary states can be loud. AERIAL must change silhouette (posture,
altitude, shadow), not just y-coordinate. NEAR/FAR should read as
different screen compositions. Transition moments get audio + Juice
(squash/stretch, dust).

## Coarse and Fine Reads

Every channel serves two literacy levels with the same pixels:

- **Novice (coarse):** "red arc + lots of tokens + rising whine = big fire
  thing coming, get ready."
- **Expert (fine):** "two fire + one salt, GROUND_BURST motif, SLOW arc =
  Molten Ash; he wants me grounded; go AERIAL before the sting."

When adding any cue, check it degrades gracefully to a coarse read.

## Ownership

- `AudioResolver` (new, `systems/`) — all cue selection; no direct
  `love.audio` calls from handlers.
- `Juice.lua` (new, `systems/`) — owns shake/hitstop/flash/squash-stretch
  with one API; replaces the three-way fallback chains in `vfx.lua` and
  the locals in `main.lua`.
- `VisualResolver` — unchanged role; channel-phase motifs added in
  `WizardVisuals` keyed by the same metadata.
- Signature lint — new tool in `tools/`, runs with the existing
  validation suite.
