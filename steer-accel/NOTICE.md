# NOTICE

Copyright (c) 2026 p10ns11y. MIT. See `LICENSE`.

The five steps are the engineering order published for SpaceX. Question the requirement, then delete, then simplify, then accelerate, then automate. A public telling is the Everyday Astronaut interview with Elon Musk, 2021. This plugin is the loop an agent runs against a stage log. It does not copy that interview.

The watch is on when `.steer/loop.on` exists, or when `.steer/now.md` says `actor: coordinator`. A crash while that watch is on denies the call. With neither signal, the hook allows the call. Deleting `.steer/loop.on` when the stretch ends turns a builder's watch off.

The hook is PreToolUse on Read, Write, Edit, and Bash. Cursor also runs it on `preToolUse` for Write and Edit, and fails closed. It does not run during token generation or compaction. A session that never got the plugin, or never got a stretch marker, is a host install. Closing issue 38 does not install this on a bot.
