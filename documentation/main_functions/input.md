### input.lua

This function displays a customizable input dialog for user text or number entry. It supports both simple and complex input structures.

- **createInput(title, opts)**
  - Opens a styled input dialog with configurable fields, labels, input types, and validation.
  - Supports multiple field types including `text`, `number`, `password`, `checkbox`, `color`, `slider`, and more.
  - **Parameters:**
    - `title` (`string`): Title displayed at the top of the input box.
    - `opts` (`table`): A table of fields with attributes like `label`, `name`, `type`, `value`, and more.
  - **Example:**
    ```lua
    local userInput = createInput("Enter Details", {
        { type = "text", text = "Name", name = "playerName", isRequired = true },
        { type = "number", text = "Age", name = "playerAge", min = 18, max = 99 },
        { type = "radio", label = "Gender", name = "playerGender", options = {
            { text = "Male", value = "male" },
            { text = "Female", value = "female" },
            { text = "Other", value = "other" },
        }},
    })
    if userInput then
        print(json.encode(userInput))
    end
    ```