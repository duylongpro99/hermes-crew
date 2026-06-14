# Teacher-Learner Discord Discussion Design

## Purpose

Enable the two Hermes agents to conduct structured discussions that help the
human observer deeply understand a problem.

- Chiron is the teacher.
- Achilles is the learner.
- The human user is the observer and may guide the discussion.
- Discussions run only in the existing Discord `#discussion` channel.

The discussion must explain core principles, explore related knowledge, expose
misunderstandings, and conclude with a useful observer-facing summary.

## Scope

This design uses Hermes' existing Discord bot-message support and agent persona
instructions. It does not add a coordinator service or modify the Hermes image.

The existing `#discussion` channel ID is `1515599651074736273`.

## Architecture

Both containers enable Hermes' mention-only bot-message mode:

```text
DISCORD_ALLOW_BOTS=mentions
```

Hermes then accepts a message authored by the other bot only when that message
explicitly mentions the receiving bot. Existing multi-agent filtering ensures
an agent stays silent when only another bot is mentioned.

Role-specific discussion protocols are added to the agents' persona
instructions:

- Chiron owns teaching, evaluation, round progression, and closure.
- Achilles owns questioning, challenging assumptions, applying concepts, and
  demonstrating understanding.

No autonomous response is allowed outside `#discussion`.

## Starting A Discussion

A discussion starts when the human observer posts a problem in `#discussion`
and explicitly mentions both Chiron and Achilles.

Chiron always leads:

1. Chiron recognizes the joint human mention as a new discussion.
2. Chiron posts the first teaching turn and mentions Achilles.
3. Achilles ignores the initial joint human message and waits for Chiron's
   teaching turn.

Messages outside `#discussion` cannot start this protocol, even if both agents
are mentioned.

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

During an active discussion, the human observer may post guidance or questions.
Chiron incorporates that guidance into its next teaching turn. Achilles does
not treat human guidance as permission to lead.

If the human sends `STOP DISCUSSION` in `#discussion`, both agents immediately
stop the protocol. Neither agent mentions the other in response. Chiron may
acknowledge the stop briefly, but it does not produce the full observer summary
unless explicitly requested by the human.

## Safety And Error Handling

- Bot-authored messages are accepted only when they explicitly mention the
  receiving agent.
- Agent-to-agent discussion behavior is restricted to `#discussion`.
- Chiron ignores bot-authored discussion messages without a valid round marker.
- Achilles ignores the initial joint human mention and waits for Chiron.
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
existing `#discussion` channel through persona instructions and existing
Discord channel configuration where supported.

Update each agent's `SOUL.md` with its role-specific protocol. The role prompts
must include the exact `#discussion` channel ID, round rules, completion rules,
stop command, and mention behavior.

## Verification

Verify these scenarios manually in Discord and through gateway logs:

1. A joint human mention in `#discussion` causes only Chiron to lead.
2. Achilles waits until Chiron mentions it.
3. Agents alternate with valid round markers and no duplicate responses.
4. Bot-authored messages without a direct mention are ignored.
5. Chiron teaches core principles and explores related knowledge.
6. A correct Achilles summary causes Chiron to close with one observer summary.
7. Round 10 forces Chiron to close with one observer summary.
8. `STOP DISCUSSION` prevents further agent-to-agent replies.
9. Joint mentions outside `#discussion` do not start the protocol.
10. Malformed or out-of-order agent messages do not continue the discussion.

## Known Limitation

Round counting and protocol compliance are prompt-governed rather than enforced
by a deterministic coordinator. Mention-only filtering reliably prevents
unaddressed bot messages from triggering replies, while the persona protocols
provide the discussion structure and stopping behavior.
