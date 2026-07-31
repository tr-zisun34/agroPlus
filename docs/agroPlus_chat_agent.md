# AgroPlus — Chat With Agent (Frontend)

Frontend-only for this increment — chat UI and scoping, no backend agent logic yet (see §6 for what's deferred and why).

## 1. Entry points

Two paths into the same chat screen, differing only in how `farm_id` is supplied:

1. **Dashboard → "Chat with agent" button** → opens the farm picker modal → farmer selects a farm → chat opens scoped to it.
2. **Farm page → Card 3 "Chat with agent" button** → chat opens directly, scoped to the current farm — no picker, since the farm is already the active context.

Both paths render the identical chat screen component; only the entry differs. Do not build two separate chat screens.

## 2. Farm picker modal (dashboard entry point only)

Shown when "Chat with agent" is tapped from the dashboard.

- Title: "Chat about which farm?" + one line of context ("The assistant will use this farm's soil and weather data.")
- List of the farmer's saved farms, same visual pattern as the dashboard farm cards (icon, name, location + area, chevron)
- Tapping a farm closes the modal and opens the chat screen scoped to that `farm_id`
- Reuses the existing `farm_provider` farm list — no separate fetch needed

## 3. Chat screen

**Header:** back button, small assistant icon, "Farm assistant" title, and the scoped farm's name as a subtitle — always visible so the farmer knows which farm's context they're in.

**Message thread:**
- Agent messages: left-aligned, muted background, rounded corners with a sharp bottom-left corner
- Farmer messages: right-aligned, accent background, rounded corners with a sharp bottom-right corner
- Opening message is always an agent greeting scoped to the farm name (e.g. "Hi, I'm your farm assistant for [farm name]. Ask me anything about your soil, weather, or what to plant this season.")

**Quick-suggestion chips:** a horizontal scrollable row above the input bar, shown at minimum on chat open (can also reappear after each agent response). For this increment, three fixed chips are enough:
- "Show profit breakdown"
- "Check soil condition"
- "Suggest another crop"

These map directly to backend functions already defined in `agroPlus_farm_card.md` (`get_profit_estimate`, `get_soil_reading`, `get_recommendation`) — tapping a chip should send the same text a farmer would type, not a special hidden action, so the frontend doesn't need to know about the backend function names at all.

**Input bar:** text field + circular send button, standard chat pattern. No voice input, attachments, or other chat features for this increment.

## 4. Flutter structure

```
lib/features/chat/
├── farm_picker_modal.dart      # dashboard entry point only
├── chat_screen.dart            # shared by both entry points, takes farm_id
├── chat_bubble.dart            # single message bubble (agent/farmer variants)
├── quick_chips.dart            # suggestion chip row
└── chat_provider.dart          # holds message list state for the active session
```

`chat_screen.dart` takes a required `farm_id` parameter — the dashboard entry navigates to it after the picker resolves a selection; the farm page entry navigates to it directly with the current farm's id already known.

## 5. State for this increment

Since there's no backend yet, `chat_provider.dart` should hold messages in memory only (no persistence, no real API call). Sending a message should append it to the thread and show a placeholder agent response — enough to validate the full UI flow (picker → scoped chat → message send → chip tap) before backend logic exists.

## 6. Deferred to backend increment (not part of this spec)

- Wiring the agent to real OpenAI function calling against the four `recommendation_service` functions defined in `agroPlus_farm_card.md`
- Persisting chat history per farm
- Streaming responses instead of placeholder replies
- Any inline structured content in agent replies (e.g. a compact profit card rendered inside a message, instead of plain text) — worth revisiting once real responses exist and it's clear which answers benefit from structured display

## 7. Build order

1. `farm_picker_modal.dart` — reuse existing farm list data, add selection callback.
2. `chat_provider.dart` — in-memory message state, send/append logic.
3. `chat_bubble.dart` — agent/farmer variants.
4. `quick_chips.dart` — fixed three-chip row, tapping sends the chip's text as a message.
5. `chat_screen.dart` — assembles header, message thread, chips, input bar; wires both entry points to it.
6. Wire "Chat with agent" buttons: dashboard → picker → chat; farm page Card 3 → chat directly.

End state: a farmer can reach a scoped chat screen from either entry point, send messages, tap suggestion chips, and see a working (placeholder-response) conversation UI — ready for real agent logic to be wired in behind `chat_provider.dart` without any UI rework.
