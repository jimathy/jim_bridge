### phones.lua

This module allows you to send in-game mail/messages to player phones, depending on the phone system integrated (e.g., QB, NPWD).

- **sendPhoneMail(data)**

  - Sends a mail message to a player's in-game phone app.
  - Typically used to notify players about deliveries, missions, or reminders.
  - **Parameters:**
    - `data` (`table`): Must contain phone/mail system-compatible fields like `sender`, `subject`, `message`, and `receiver`.
  - **Example:**
    ```lua
    sendPhoneMail({
        subject = "Welcome!",
        sender = "Admin",
        message = "Thank you for joining our server.",
        actions = {
            { label = "Reply", action = replyFunction }
        }
    })
    ```