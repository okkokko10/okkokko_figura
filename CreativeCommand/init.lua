
local Ccom = require"CreativeCommand.CreativeCommands"
local macros = require"CreativeCommand.macro"
require"CreativeCommand.substituteMessage"


events.CHAT_SEND_MESSAGE:register(macros.macro_send_message)
events.CHAT_SEND_MESSAGE:register(Ccom.substitute_message)