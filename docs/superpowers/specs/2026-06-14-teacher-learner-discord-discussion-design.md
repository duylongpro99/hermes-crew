# Teacher-Learner Discord Discussion Design

## Purpose

Enable the two Hermes agents to conduct structured discussions that help the
human observer deeply understand a problem.

- Chiron is the teacher.
- Achilles is the learner.
- The human user is the observer and may guide the discussion.
- Discussions start in the existing Discord `#discussion` channel and run
  inside one automatically created thread per topic.

The discussion must explain core principles, explore related knowledge, expose
misunderstandings, and conclude with a useful observer-facing summary.

## Scope

This design uses Hermes' existing Discord bot-message support and agent persona
instructions. It does not add a coordinator service or modify the Hermes image.

The existing `#discussion` channel ID is `1515599651074736273`. It is the
discussion lobby, not the location for active agent-to-agent turns.

## Architecture

Both containers enable Hermes' mention-only bot-message mode:

```text
DISCORD_ALLOW_BOTS=mentions
```

Hermes then accepts a message authored by the other bot only when that message
explicitly mentions the receiving bot. Existing multi-agent filtering ensures
an agent stays silent when only another bot is mentioned.

Hermes' built-in Discord auto-threading creates a thread when Chiron is
mentioned in `#discussion`. Threads use a shared session across participants by
default, so Chiron, Achilles, and the observer receive one coherent discussion
transcript. Explicit mention requirements remain enabled inside the thread so
only the intended next agent acts.

Role-specific discussion protocols are added to the agents' persona
instructions:

- Chiron owns teaching, evaluation, round progression, and closure.
- Achilles owns questioning, challenging assumptions, applying concepts, and
  demonstrating understanding.

No autonomous response is allowed in the `#discussion` lobby or outside an
active discussion thread.

## Starting A Discussion

A discussion starts when the human observer posts a problem in `#discussion`
and explicitly mentions only Chiron.

Chiron always leads:

1. Hermes creates a new thread from the observer's Chiron mention.
2. Chiron recognizes the message as a new discussion.
3. Chiron posts the first teaching turn inside the new thread and mentions
   Achilles.
4. Achilles receives only Chiron's direct mention and replies inside the same
   thread.

Messages outside the `#discussion` lobby cannot start this protocol. A message
that mentions Achilles in the lobby does not start a discussion.

## Turn And Round Protocol

One round consists of:

1. One Chiron teaching message.
2. One Achilles learner response.

Every active-discussion message begins with a visible marker:

```text
[Round N/10]
```

Chiron's continuing turns:

- Explain one focused concept.
- Connect it to core values or principles and explain why they matter.
- Explore useful implications, examples, trade-offs, edge cases, or related
  knowledge.
- Evaluate Achilles' previous response when applicable.
- Ask Achilles one targeted question or request a summary.
- End by explicitly mentioning Achilles.

Achilles' turns:

- Explain its current understanding in its own words.
- Challenge assumptions or ask focused questions where useful.
- Apply the concept to an example or implication.
- Provide a full summary when Chiron requests one.
- End by explicitly mentioning Chiron.

Chiron is the authority for the round number. Achilles repeats the round marker
from Chiron's message. Chiron advances the number on its next teaching turn.

All active turns remain inside the thread created for the topic. Neither agent
continues the discussion in the parent `#discussion` lobby.

## Completion

Chiron closes the discussion when either condition is met:

- Achilles provides a correct and sufficiently complete summary.
- Round 10 has completed or the next turn would exceed round 10.

The closing message must not mention Achilles. This prevents another
agent-to-agent turn.

The closing message includes an `Observer Summary` addressed to the human:

- Core values and principles
- Key conclusions
- Important trade-offs
- Further knowledge to explore
- Remaining uncertainty

The observer summary appears only once, at the end of the discussion.

## Human Guidance And Stop Behavior

During an active discussion, the human observer may post guidance or questions
inside the discussion thread by explicitly mentioning Chiron. Chiron
incorporates that guidance into its next teaching turn. Achilles does not treat
human guidance as permission to lead.

If the human sends `STOP DISCUSSION` inside the discussion thread and explicitly
mentions both agents, both agents immediately stop the protocol. Neither agent
mentions the other in response. Chiron may acknowledge the stop briefly, but it
does not produce the full observer summary unless explicitly requested by the
human.

## Safety And Error Handling

- Bot-authored messages are accepted only when they explicitly mention the
  receiving agent.
- New discussions start only from a human message that mentions only Chiron in
  the `#discussion` lobby.
- Agent-to-agent discussion behavior is restricted to the auto-created
  discussion thread.
- Thread messages require explicit mentions. This prevents both agents from
  responding to the same human or bot message.
- Chiron ignores bot-authored discussion messages without a valid round marker.
- Achilles remains silent in the lobby and waits for Chiron's first direct
  mention inside the discussion thread.
- An agent receiving a malformed, duplicate, or out-of-order agent message
  stops instead of guessing or continuing.
- Any message at or beyond the round limit must not mention the other agent.
- Closing messages never mention the other agent.
- The protocol relies on explicit mentions and prompt rules; if stronger
  deterministic enforcement is later required, an external coordinator should
  replace round tracking.

## Configuration Changes

Add the following environment variable to both agent environments:

```text
DISCORD_ALLOW_BOTS=mentions
```

Keep Discord mention requirements enabled. Restrict autonomous responses to the
auto-created discussion threads through persona instructions and existing
Discord channel configuration.

Configure both agents with:

```yaml
discord:
  require_mention: true
  free_response_channels: ''
  auto_thread: true
  thread_require_mention: true
  history_backfill: true

thread_sessions_per_user: false
```

The `#discussion` lobby must not be a free-response channel. Otherwise Hermes
skips auto-thread creation and both agents may process unmentioned lobby
messages.

Update each agent's `SOUL.md` with its role-specific protocol. The role prompts
must include the exact `#discussion` lobby ID, thread boundary, round rules,
completion rules, stop command, and mention behavior.

## Verification

Verify these scenarios manually in Discord and through gateway logs:

1. A human mention of only Chiron in `#discussion` creates a new thread.
2. Chiron posts the first `[Round 1/10]` turn inside the new thread.
3. Achilles remains silent until Chiron directly mentions it inside the thread.
4. All participants use one shared Hermes thread session.
5. Agents alternate with valid round markers and no duplicate responses.
6. Bot-authored messages without a direct mention are ignored.
7. Unmentioned human messages inside the thread do not trigger either agent.
8. Chiron teaches core principles and explores related knowledge.
9. A correct Achilles summary causes Chiron to close with one observer summary.
10. Round 10 forces Chiron to close with one observer summary.
11. A thread-local `STOP DISCUSSION` mentioning both agents prevents further
    replies.
12. Messages outside `#discussion` do not start the protocol.
13. Malformed or out-of-order agent messages do not continue the discussion.

## Known Limitation

Round counting, completion evaluation, and malformed-message classification are
prompt-governed rather than enforced by a deterministic coordinator.

Thread creation, shared transcript routing, and explicit-mention turn
addressing are enforced by Hermes and Discord. This removes the known
per-sender context split and concurrent-start failure, but it does not make the
round state machine deterministic. If stronger guarantees are later required,
an external coordinator should enforce round transitions and completion.
