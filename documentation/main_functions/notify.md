### notify.lua

This module provides a unified interface to trigger styled notifications across supported frameworks.

- **triggerNotify(title, message, type, src)**

  - Sends a notification to a player (or to the entire client if `src` is `nil`).
  - The notification style is determined by `type` (e.g., `success`, `error`, `info`).
  - **Parameters:**
    - `title` (`string`): The title or header of the notification.
    - `message` (`string`): The body or detail text.
    - `type` (`string`): Type of message (e.g., "success", "error", "info").
    - `src` (`number`, optional): Server ID of the player to notify (omit to notify locally).
  - **Example:**
    ```lua
    -- Client-side usage without specifying a player (shows to the current player)
    triggerNotify("Success", "You have completed the task!", "success")

    -- Server-side usage specifying a player by their server ID
    triggerNotify("Alert", "You have been warned for misconduct.", "error", source)
    ```