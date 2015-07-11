local EnvironmentTable = { {	actual = _G , id = "global table" } }

local dynamic = require"experimental.dynamic"

--This really should not work.
--[[
runtest {
	mapping = dynamic,
	encodeerror = "unable to dump given function",
	EnvironmentTable
}]]--