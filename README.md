# Server Messages

Server Messages is a very simple module that helps display custom chat messages and automatically gives **Premium Players*** a gradient-colored chat prefix.

---

## Usage
- Simply require to activate **Premium Players*** benefit.
- Use :SendMessage() to send anything. This supports RichText.

### Example:
```lua
local ServerMessages = require(script.ServerMessages) -- or wherever the ServerMessages Module is located.

ServerMessages:SendMessage("Hello World!", "[System]:")
```

![Example image showcases how the chat looks after running the example code. The chat displays "[System]: Hello World!" and 4 Messages "Hi" showcasing how different types of Enum.MemberShipType Chat Prefixes look like. Those chat prefixes come before the username and are colored in a gradient from teal-cyan to teal-purple. Enum.MemberShipType.None is not shown, because it has no such benefit.](./images/example.png "Example Code Preview")

---

## Notes
- Please do not use </br> as it breaks Roblox's built-in RichText styles, even though it is documented as one of the RichText supported tags. Use \n instead.
- **Premium Players** - All Players with Enum.MembershipType other than Enum.MembershipType.None

---

## 📜 License & Attribution

This project is licensed under **Apache License 2.0**.

If you reuse any DatatypeUtility parts from this project, you must retain attribution in accordance with the Apache License 2.0.

You can freely use, share and modify this code in accordance with the Apache License 2.0, provided that required copyright and attribution notices are preserved.

Example attribution:
`DatatypeUtility originally obtained from https://github.com/Coffilhg/Useful-Modules/tree/ServerMessages - © 2026 Coffilhg (Roblox UserId 517222346)`