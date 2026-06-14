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

Post the following template in `#discussion`. Replace the placeholders and use
Discord's mention picker so both bot mentions are real mentions.

```text
@cris_chiron @cris_achilles

DISCUSSION TOPIC:
Explain [problem or topic].

OBSERVER GOAL:
Help me understand [specific outcome].

FOCUS ON:
- Core principles and why they matter
- Practical examples
- Important trade-offs and edge cases
- Common misunderstandings

Chiron: lead the discussion.
Achilles: wait for Chiron, then challenge, apply, and summarize.
```

Expected behavior:

1. Only Chiron responds to the trigger.
2. Chiron begins with `[Round 1/10]` and mentions Achilles.
3. Achilles replies with the same round marker and mentions Chiron.
4. Chiron advances the round number.
5. Chiron eventually closes without mentioning Achilles and includes one
   `Observer Summary`.

Do not separately mention Achilles to ask it to begin. Achilles must wait for
Chiron's first teaching turn.

## Example Trigger

```text
@cris_chiron @cris_achilles

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

Chiron: lead the discussion.
Achilles: wait for Chiron, then challenge, apply, and summarize.
```

## Guide An Active Discussion

Post guidance in `#discussion` without mentioning either agent:

```text
OBSERVER GUIDANCE:
Please use a concrete example involving [scenario] in the next teaching turn.
```

```text
OBSERVER QUESTION:
Please clarify [specific uncertainty] in the next teaching turn.
```

```text
OBSERVER GUIDANCE:
Ask Achilles to provide a full summary and test its understanding.
```

Chiron should incorporate the guidance into its next valid teaching turn.
Achilles should not treat observer guidance as permission to lead.

## Stop A Discussion

Post this exact command in `#discussion`:

```text
STOP DISCUSSION
```

After sending it, verify that neither agent mentions the other or continues the
discussion.

If the agents continue replying to each other, stop the gateways immediately:

```bash
docker compose stop chiron achilles
```

## Start A New Discussion

Wait until the previous discussion has closed or been stopped. Then post a new
joint-mention trigger using the template above.

Do not try to continue a stopped discussion by manually creating round markers.

## Safety Limitation

Round tracking, malformed-message handling, and stop behavior are governed by
prompts rather than a deterministic coordinator. Live verification showed that
malformed bot-authored messages can still cause an agent-to-agent reply loop.

Avoid manually sending messages that imitate agent turns, including:

```text
[Round N/10]
```

If a discussion becomes malformed, duplicated, or out of order, stop both
gateways with:

```bash
docker compose stop chiron achilles
```

Then remove the malformed Discord messages before restarting the crew.

## Troubleshooting

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
