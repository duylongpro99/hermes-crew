#!/bin/sh
set -eu

DISCUSSION_CHANNEL_ID=1515599651074736273
failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

assert_file_contains() {
    file=$1
    text=$2
    description=$3

    if grep -Fq "$text" "$file"; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_file_not_contains() {
    file=$1
    text=$2
    description=$3

    if grep -Fq "$text" "$file"; then
        fail "$description"
    else
        pass "$description"
    fi
}

assert_discord_config_value() {
    file=$1
    key=$2
    expected=$3
    description=$4

    actual=$(
        awk -v key="$key" '
            /^discord:$/ { in_discord = 1; next }
            in_discord && /^[^[:space:]]/ { exit }
            in_discord && $1 == key ":" {
                sub(/^[^:]+:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file"
    )

    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description (expected $expected, got ${actual:-<missing>})"
    fi
}

for agent in chiron achilles; do
    assert_file_contains "$agent/.env" "DISCORD_ALLOW_BOTS=mentions" \
        "$agent enables mention-only bot messages"
    assert_discord_config_value "$agent/data/config.yaml" "require_mention" "true" \
        "$agent keeps Discord mention requirements enabled"
    assert_discord_config_value "$agent/data/config.yaml" "free_response_channels" "'$DISCUSSION_CHANNEL_ID'" \
        "$agent receives unmentioned human guidance and stop commands in discussion"
    assert_discord_config_value "$agent/data/config.yaml" "auto_thread" "false" \
        "$agent keeps discussions in the existing Discord channel"
    assert_file_contains "$agent/data/config.yaml" "#discussion protocol override" \
        "$agent has a discussion-specific prompt override"
    assert_file_contains "$agent/data/channel_directory.json" "\"id\": \"$DISCUSSION_CHANNEL_ID\"" \
        "$agent knows the discussion channel"
    assert_file_contains "$agent/data/SOUL.md" "$DISCUSSION_CHANNEL_ID" \
        "$agent persona names the exact discussion channel"
    assert_file_contains "$agent/data/SOUL.md" "[Round N/10]" \
        "$agent persona defines the round marker"
    assert_file_contains "$agent/data/SOUL.md" "STOP DISCUSSION" \
        "$agent persona defines the stop command"
    assert_file_contains "$agent/data/SOUL.md" "malformed, duplicate, or out-of-order" \
        "$agent persona stops on invalid agent messages"
    assert_file_contains "$agent/data/SOUL.md" "This classification overrides every other rule" \
        "$agent persona gives stop handling highest priority"
    assert_file_contains "$agent/data/SOUL.md" "[Protocol stopped: invalid agent message]" \
        "$agent persona defines a non-mention invalid-message terminal response"
    assert_file_contains "$agent/data/SOUL.md" "[Discussion stopped]" \
        "$agent persona defines a non-mention human-stop terminal response"
    assert_file_contains "$agent/data/SOUL.md" "outside #discussion" \
        "$agent persona restricts the protocol to discussion"
    assert_file_contains "$agent/data/SOUL.md" "joint human mention outside #discussion" \
        "$agent stays silent on joint mentions outside discussion"
done

assert_file_contains "chiron/data/SOUL.md" "Chiron always leads" \
    "Chiron owns discussion startup"
assert_file_contains "chiron/data/SOUL.md" "Observer Summary" \
    "Chiron defines the observer summary"
assert_file_contains "chiron/data/SOUL.md" "must not mention Achilles" \
    "Chiron closes without mentioning Achilles"
assert_file_contains "chiron/data/SOUL.md" "correct and sufficiently complete summary" \
    "Chiron closes on demonstrated understanding"
assert_file_contains "chiron/data/SOUL.md" "Round 10" \
    "Chiron enforces the round limit"

assert_file_contains "achilles/data/SOUL.md" "ignore the initial joint human mention" \
    "Achilles waits for Chiron"
assert_file_contains "achilles/data/SOUL.md" "repeat Chiron's exact round marker" \
    "Achilles repeats Chiron's round marker"
assert_file_contains "achilles/data/SOUL.md" "Do not produce an Observer Summary" \
    "Achilles does not close the discussion"
assert_file_not_contains "achilles/data/SOUL.md" "Chiron always leads" \
    "Achilles persona does not assign itself Chiron's startup rule"

if [ "$failures" -ne 0 ]; then
    printf '\n%d verification check(s) failed.\n' "$failures" >&2
    exit 1
fi

printf '\nAll discussion configuration checks passed.\n'
