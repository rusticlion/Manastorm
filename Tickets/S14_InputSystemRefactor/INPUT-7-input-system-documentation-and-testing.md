# INPUT-7: Input System Documentation & Thorough Testing

**Goal:** Update all relevant documentation to reflect the new input system and perform comprehensive testing across all control schemes and game states.

## Tasks

### 1. Update Documentation

#### Update Input.reservedKeys in core/Input.lua
- List `Constants.ControlActions` and their default bindings for keyboard (P1/P2) and gamepad (P1/P2)

#### Update README.md
- Update the section on controls

#### Update CrashCourse.md and DevelopmentGuidelines.md
- Explain the action-based input system
- Document rebinding capabilities and controller support

### 2. Comprehensive Testing

#### Control Scheme Testing
- Test P1 default keyboard & P1 default gamepad controls
- Test P2 default keyboard controls (when P2 is human and no P2 gamepad)
- Test P2 default gamepad controls (when P2 is human and P2 gamepad active)

#### Rebinding Testing
- Test rebinding for various actions across keyboard P1/P2 and gamepad P1/P2
- Verify rebound controls work immediately and persist after game restart

#### Menu Navigation Testing
- Test all menu navigations with keyboard arrows, gamepad D-pad/analog, and Cast/Free as Confirm/Cancel

#### AI/Human Mode Testing
- Confirm AI mode selection works and AI behavior is correct when active
- Confirm Human P2 works correctly

#### Edge Case Testing
- Check for input conflicts, especially if P2 keyboard and P2 gamepad are both potentially active
- Test different controller connection scenarios (e.g., starting with no gamepad, connecting one mid-game)

## Acceptance Criteria
- All relevant documentation accurately reflects the new input system
- The game is fully playable and configurable with keyboard for P1 & P2, and gamepad for P1 (& P2 if implemented)
- No regressions in existing input-driven functionality
- System is robust to different controller connection scenarios