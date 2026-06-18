# Discord Discussion Guide

Use this guide to run a structured teacher-learner discussion between Chiron
and Achilles.

- Chiron is the teacher and discussion leader.
- Achilles is the learner and constructive challenger.
- You are the observer and may guide the discussion.
- Run discussions only in Discord `#discussion`.

## Start The Crew

The gateways are currently stopped. Start them before triggering a discussion:

```bash
docker compose up -d
docker compose ps
```

Both `chiron` and `achilles` should show an `Up` status.

## Trigger A Discussion

Post the following template in the parent `#discussion` channel. Replace the
placeholders and use Discord's mention picker so the Chiron mention is a real
mention. The lobby trigger must mention only Chiron.

```text
@cris_chiron

DISCUSSION TOPIC:
Explain [problem or topic].

OBSERVER GOAL:
Help me understand [specific outcome].

FOCUS ON:
- Core principles and why they matter
- Practical examples
- Important trade-offs and edge cases
- Common misunderstandings

Chiron: start the discussion in the thread, teach, and lead the rounds.
```

Expected behavior:

1. Mentioning only Chiron in `#discussion` auto-creates a new thread for that
   topic.
2. Chiron posts the first reply inside that thread, not in the parent lobby.
3. Chiron begins with `[Round 1/10]` and explicitly mentions Achilles.
4. Achilles stays silent until Chiron mentions it inside the thread.
5. All active discussion turns stay inside the thread and alternate one agent
   at a time.
6. Unmentioned messages do not trigger either agent.
7. Chiron eventually closes with exactly one `Observer Summary` and does not
   mention Achilles in that closing message.

Do not mention Achilles in the lobby trigger. Do not continue the discussion in
the parent `#discussion` channel after the thread is created.

## Example Trigger

```text
@cris_chiron

DISCUSSION TOPIC:
Explain why distributed systems cannot guarantee consistency, availability,
and partition tolerance at the same time.

OBSERVER GOAL:
Help me choose an appropriate consistency model for a collaborative editor.

FOCUS ON:
- The core CAP trade-off
- Concrete failure scenarios
- Strong versus eventual consistency
- Common misunderstandings about CAP

Chiron: start the discussion in the thread, teach, and lead the rounds.
```

## Guide An Active Discussion

Post guidance inside the active discussion thread and explicitly mention Chiron:

```text
@cris_chiron

OBSERVER GUIDANCE:
Please use a concrete example involving [scenario] in the next teaching turn.
```

```text
@cris_chiron

OBSERVER QUESTION:
Please clarify [specific uncertainty] in the next teaching turn.
```

```text
@cris_chiron

OBSERVER GUIDANCE:
Ask Achilles to provide a full summary and test its understanding.
```

Guidance posted in the parent lobby should not affect an active discussion.
Achilles should not treat observer guidance as permission to lead.

## Stop A Discussion

Post this inside the active discussion thread and explicitly mention both agents:

```text
@cris_chiron @cris_achilles STOP DISCUSSION
```

`STOP DISCUSSION` in the parent lobby, or without both mentions, should not
stop the discussion.

After sending the thread-local stop command, Chiron may acknowledge once with
`[Discussion stopped]`. Achilles should remain silent, and neither agent should
continue the discussion after that.

If the agents continue replying to each other, stop the gateways immediately:

```bash
docker compose stop chiron achilles
```

## Start A New Discussion

Wait until the previous discussion has closed or been stopped. Then post a new
Chiron-only trigger in the parent `#discussion` lobby using the template above.

Do not try to continue a stopped discussion by manually creating round markers.

## Safety Limitation

Round tracking, malformed-message handling, and completion are governed by
prompts rather than a deterministic coordinator. Thread creation, shared
transcript routing, and explicit-mention turn addressing are handled by Hermes
and Discord.

Avoid manually sending messages that imitate agent turns, including:

```text
[Round N/10]
```

If a discussion becomes malformed, duplicated, or out of order, treat that as a
bug and stop both gateways with:

```bash
docker compose stop chiron achilles
```

Then remove the malformed Discord messages before restarting the crew.

## Troubleshooting

If the wrong thing happens, check these first:

- No thread was created: confirm the start message was posted in the parent
  `#discussion` channel and mentioned only Chiron.
- Achilles replied too early: confirm Chiron mentioned Achilles inside the
  thread, and that Achilles was not mentioned in the lobby trigger.
- An agent replied in the parent lobby: treat that as incorrect behavior. Active
  turns belong in the thread only.
- Human guidance was ignored: confirm it was posted inside the active thread and
  explicitly mentioned Chiron.
- `STOP DISCUSSION` did nothing: confirm it was posted inside the active thread
  and explicitly mentioned both agents.
- An unmentioned message triggered a reply: treat that as incorrect behavior and
  inspect the logs for mention handling.

Expected acceptance checks during manual verification:

1. A Chiron-only mention in `#discussion` creates one thread.
2. Chiron starts in the thread with `[Round 1/10]` and mentions Achilles.
3. Achilles does not respond before that mention.
4. Chiron, Achilles, and the observer share one coherent thread transcript.
5. All agent turns stay in the thread, with one valid reply per turn, and round
   markers alternate correctly without exceeding `10`.
6. Unmentioned human or bot messages do not trigger either agent.
7. A valid thread-local `STOP DISCUSSION` mentioning both agents stops further
   replies.
8. Chiron ends with exactly one `Observer Summary`.

Check service status:

```bash
docker compose ps
```

Follow gateway logs:

```bash
docker compose logs -f chiron achilles
```

Run the configuration verifier:

```bash
./scripts/verify-discussion-config.sh
```

If only one agent connects, inspect its gateway log:

```bash
tail -100 chiron/data/logs/gateway.log
tail -100 achilles/data/logs/gateway.log
```
