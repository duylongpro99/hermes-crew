#!/bin/sh
set -eu

DISCUSSION_CHANNEL_ID=1515599651074736273
CHIRON_MENTION='<@1515569920988151969>'
ACHILLES_MENTION='<@1515570546811600927>'
failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

assert_yaml_parses() {
    file=$1
    description=$2

    if ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' "$file" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
    fi
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
        ruby -e '
            require "yaml"
            value = YAML.load_file(ARGV[0]).fetch("discord").fetch(ARGV[1], :missing)
            if value == :missing
              exit 2
            end

            case value
            when String
              puts value.empty? ? "\x27\x27" : value.inspect
            when TrueClass, FalseClass
              puts value
            else
              puts value.inspect
            end
        ' "$file" "$key"
    ) || actual=''

    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description (expected $expected, got ${actual:-<missing>})"
    fi
}

assert_root_config_value() {
    file=$1
    key=$2
    expected=$3
    description=$4

    actual=$(
        ruby -e '
            require "yaml"
            value = YAML.load_file(ARGV[0]).fetch(ARGV[1], :missing)
            if value == :missing
              exit 2
            end

            case value
            when String
              puts value.empty? ? "\x27\x27" : value.inspect
            when TrueClass, FalseClass
              puts value
            else
              puts value.inspect
            end
        ' "$file" "$key"
    ) || actual=''

    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description (expected $expected, got ${actual:-<missing>})"
    fi
}

for agent in chiron achilles; do
    assert_yaml_parses "$agent/data/config.yaml" \
        "$agent config parses as valid YAML"
    assert_file_contains "$agent/.env" "DISCORD_ALLOW_BOTS=mentions" \
        "$agent enables mention-only bot messages"
    assert_discord_config_value "$agent/data/config.yaml" "require_mention" "true" \
        "$agent keeps Discord mention requirements enabled"
    assert_discord_config_value "$agent/data/config.yaml" "free_response_channels" "''" \
        "$agent does not allow free-response Discord channels"
    assert_discord_config_value "$agent/data/config.yaml" "auto_thread" "true" \
        "$agent auto-threads new discussion starts"
    assert_discord_config_value "$agent/data/config.yaml" "thread_require_mention" "true" \
        "$agent requires explicit mentions inside discussion threads"
    assert_discord_config_value "$agent/data/config.yaml" "history_backfill" "true" \
        "$agent backfills thread history for shared context"
    assert_root_config_value "$agent/data/config.yaml" "thread_sessions_per_user" "false" \
        "$agent shares one Hermes thread session across participants"
    assert_file_not_contains "$agent/data/config.yaml" "#discussion protocol override" \
        "$agent does not keep an older higher-priority channel override"
    assert_file_contains "$agent/data/channel_directory.json" "\"id\": \"$DISCUSSION_CHANNEL_ID\"" \
        "$agent knows the discussion channel"
    assert_file_contains "$agent/data/SOUL.md" "$DISCUSSION_CHANNEL_ID" \
        "$agent persona names the exact discussion channel"
    assert_file_contains "$agent/data/SOUL.md" "thread" \
        "$agent persona describes the thread boundary"
    assert_file_contains "$agent/data/SOUL.md" "[Round N/10]" \
        "$agent persona defines the round marker"
    assert_file_contains "$agent/data/SOUL.md" "STOP DISCUSSION" \
        "$agent persona defines the stop command"
    assert_file_contains "$agent/data/SOUL.md" "malformed, duplicate, or out-of-order" \
        "$agent persona stops on invalid agent messages"
    assert_file_contains "$agent/data/SOUL.md" "overrides every other rule" \
        "$agent persona gives stop handling highest priority"
    assert_file_contains "$agent/data/SOUL.md" "output exactly \`[Protocol stopped: invalid agent message]\`" \
        "$agent persona defines the invalid-message terminal response"
    assert_file_contains "$agent/data/SOUL.md" "outside \`#discussion\`" \
        "$agent persona restricts the protocol to discussion"
    assert_file_contains "$agent/data/SOUL.md" "auto-created thread" \
        "$agent persona requires active turns to stay in the thread"
    assert_file_contains "$agent/data/SOUL.md" "$CHIRON_MENTION" \
        "$agent persona uses Chiron's literal Discord mention token"
    assert_file_contains "$agent/data/SOUL.md" "$ACHILLES_MENTION" \
        "$agent persona uses Achilles' literal Discord mention token"
done

assert_file_contains "chiron/data/SOUL.md" "Chiron always leads" \
    "Chiron owns discussion startup"
assert_file_contains "chiron/data/SOUL.md" "mentions only Chiron" \
    "Chiron starts only from a Chiron-only lobby mention"
assert_file_contains "chiron/data/SOUL.md" "posts the first teaching turn inside the new thread" \
    "Chiron starts the protocol inside the thread"
assert_file_contains "chiron/data/SOUL.md" "first human message you see is inside a thread whose parent" \
    "Chiron treats the first delivered thread message as the discussion start"
assert_file_contains "chiron/data/SOUL.md" "End with the literal Discord mention" \
    "Chiron hands off each active round to Achilles"
assert_file_contains "chiron/data/SOUL.md" "Observer Summary" \
    "Chiron defines the observer summary"
assert_file_contains "chiron/data/SOUL.md" "must not mention Achilles" \
    "Chiron closes without mentioning Achilles"
assert_file_contains "chiron/data/SOUL.md" "correct and sufficiently complete summary" \
    "Chiron closes on demonstrated understanding"
assert_file_contains "chiron/data/SOUL.md" "Round 10" \
    "Chiron enforces the round limit"
assert_file_contains "chiron/data/SOUL.md" "explicitly mentioning both agents" \
    "Chiron requires a thread-local joint mention for STOP DISCUSSION"
assert_file_contains "chiron/data/SOUL.md" "output exactly \`[Discussion stopped]\`" \
    "Chiron defines the optional stop acknowledgement"
assert_file_not_contains "chiron/data/SOUL.md" "mentions both Chiron and Achilles" \
    "Chiron persona no longer uses the old joint-lobby start rule"

assert_file_contains "achilles/data/SOUL.md" "A message that mentions Achilles in the lobby does not start a discussion." \
    "Achilles stays silent on lobby mentions"
assert_file_contains "achilles/data/SOUL.md" "Never lead a discussion or answer before Chiron's first teaching turn" \
    "Achilles waits for Chiron inside the thread"
assert_file_contains "achilles/data/SOUL.md" "End by directly mentioning Chiron with the literal Discord mention" \
    "Achilles hands valid learner turns back to Chiron with a real mention"
assert_file_contains "achilles/data/SOUL.md" "repeat Chiron's exact round marker" \
    "Achilles repeats Chiron's round marker"
assert_file_contains "achilles/data/SOUL.md" "Do not produce an Observer Summary" \
    "Achilles does not close the discussion"
assert_file_contains "achilles/data/SOUL.md" "N is below 10" \
    "Achilles will not reply at or beyond round 10"
assert_file_contains "achilles/data/SOUL.md" "remain silent. Output nothing." \
    "Achilles stays silent on STOP DISCUSSION"
assert_file_not_contains "achilles/data/SOUL.md" "joint human mention" \
    "Achilles persona no longer depends on the old joint-human start flow"

assert_file_contains "docs/DISCUSSION-GUIDE.md" "mention only Chiron" \
    "Guide documents the Chiron-only lobby trigger"
assert_file_contains "docs/DISCUSSION-GUIDE.md" "auto-creates a new thread" \
    "Guide documents automatic thread creation"
assert_file_contains "docs/DISCUSSION-GUIDE.md" "inside the thread" \
    "Guide tells the operator to stay in the thread for active discussion"
assert_file_contains "docs/DISCUSSION-GUIDE.md" "explicitly mention Chiron" \
    "Guide documents thread-local human guidance"
assert_file_contains "docs/DISCUSSION-GUIDE.md" "explicitly mention both agents" \
    "Guide documents thread-local stop behavior"
assert_file_not_contains "docs/DISCUSSION-GUIDE.md" "both bot mentions are real mentions" \
    "Guide no longer shows the old joint-lobby trigger"
assert_file_not_contains "docs/DISCUSSION-GUIDE.md" "without mentioning either agent" \
    "Guide no longer tells the observer to post unmentioned guidance"

if [ "$failures" -ne 0 ]; then
    printf '\n%d verification check(s) failed.\n' "$failures" >&2
    exit 1
fi

printf '\nAll discussion configuration checks passed.\n'
