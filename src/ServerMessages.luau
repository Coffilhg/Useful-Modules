--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/ServerMessages

    ServerMessages (and used DatatypeUtility parts)
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)
    
    

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/ServerMessages
    Module Version: 1.0.0
--]]--

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- MUST be a ColorSequence; The color to apply for Premium Player's Chat Tags!
local PremiumPrefixGradientColor : ColorSequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 255)),
})

local DatatypeUtility = {} -- Necessary parts of DatatypeUtility module by @coffilhg for this module.
do
	local function splitRichTextSections(str: string)
		local sections = {}
		local i = 1
		while i <= #str do
			local c = str:sub(i,i)
			if c == "<" then
				local close = str:find(">", i)
				if close then
					table.insert(sections, {str:sub(i, close), true})
					i = close + 1
				else
					table.insert(sections, {c, false})
					i += 1
				end
			else
				local start = i
				while i <= #str and str:sub(i,i) ~= "<" do
					i += 1
				end
				table.insert(sections, {str:sub(start, i - 1), false})
			end
		end
		return sections
	end
	
	-- Applies a Gradient to the given text in RichText format.
	-- @param str The text to apply the greadient to.
	-- @param startColor The start Color3 of the gradient |OR| the complete ColorSequence.
	-- @param endColorOrMarker The end Color3 of the gradient |OR| <strong>true</strong> to Indicate you are using a ColorSequence.
	-- @return RichText String of the given str with given gradient applied to it.
	function DatatypeUtility.ApplyRichGradient(str: string, startColor: Color3 | ColorSequence, endColorOrMarker: Color3 | boolean): string
		local sections = splitRichTextSections(str)
		-- Function to split a string into grapheme clusters
		local function splitGraphemes(s: string)
			local clusters = {}
			local cluster = ""
			local skipNext = false

			local chars = {} -- store codepoints
			for _, cp in utf8.codes(s) do
				table.insert(chars, cp)
			end

			local i = 1
			while i <= #chars do
				local cp = chars[i]
				cluster = utf8.char(cp)

				-- Look ahead for combining marks (U+0300–U+036F) and variation selectors (U+FE00–U+FE0F)
				local j = i + 1
				while j <= #chars do
					local nextCp = chars[j]
					-- Combining mark or variation selector
					if (nextCp >= 0x300 and nextCp <= 0x36F) or (nextCp >= 0xFE00 and nextCp <= 0xFE0F) then
						cluster ..= utf8.char(nextCp)
						j += 1
						-- Zero-width joiner (ZWJ) sequences for composed emojis
					elseif nextCp == 0x200D and chars[j+1] then
						-- ZWJ + next emoji
						cluster ..= utf8.char(nextCp) .. utf8.char(chars[j+1])
						j += 2
					else
						break
					end
				end
				table.insert(clusters, cluster)
				i = j
			end

			return clusters
		end

		-- count text chars (excluding markup)
		local totalCharacters = 0
		local graphemeSections = {}
		for _, section in ipairs(sections) do
			if section[2] then
				-- markup → store as-is
				table.insert(graphemeSections, {section[1], true})
			else
				local graphemes = splitGraphemes(section[1])
				totalCharacters += #graphemes
				table.insert(graphemeSections, {graphemes, false})
			end
		end

		local function colorAt(t: number): Color3
			if endColorOrMarker == true and typeof(startColor) == "ColorSequence" then
				local keypoints = startColor.Keypoints
				local idx = 1
				while idx < #keypoints and keypoints[idx+1].Time < t do
					idx += 1
				end
				if idx == #keypoints then
					return keypoints[idx].Value
				end
				local kp1, kp2 = keypoints[idx], keypoints[idx+1]
				local alpha = (t - kp1.Time) / (kp2.Time - kp1.Time)
				return Color3.new(
					kp1.Value.R + (kp2.Value.R - kp1.Value.R) * alpha,
					kp1.Value.G + (kp2.Value.G - kp1.Value.G) * alpha,
					kp1.Value.B + (kp2.Value.B - kp1.Value.B) * alpha
				)
			else
				local r = startColor.R + (endColorOrMarker.R - startColor.R) * t
				local g = startColor.G + (endColorOrMarker.G - startColor.G) * t
				local b = startColor.B + (endColorOrMarker.B - startColor.B) * t
				return Color3.new(r,g,b)
			end
		end

		-- Build the result
		local result = ""
		local charIndex = 0

		for _, section in ipairs(graphemeSections) do
			if section[2] then
				result ..= section[1] -- markup
			else
				for _, grapheme in ipairs(section[1]) do
					charIndex += 1
					local t = totalCharacters > 1 and (charIndex - 1)/(totalCharacters - 1) or 0
					local color = colorAt(t)
					local hex = string.format("#%02x%02x%02x", color.R * 255, color.G * 255, color.B * 255)
					result ..= string.format('<font color="%s">%s</font>', hex, grapheme)
				end
			end
		end

		return result
	end
	
	function DatatypeUtility.SplitCamelCase(str: string): string
		local result = ""
		for i = 1, #str do
			local char = str:sub(i, i)
			if i > 1 and char:match("%u") then
				result = result .. " "
			end
			result = result .. char
		end
		return result
	end
end

local module = {}

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local overrideProperties : TextChatMessageProperties = Instance.new("TextChatMessageProperties")

	if message.TextSource == nil then -- It's not a message sent by a Player

		if string.find(string.lower(message.Metadata), "roblox") then return end -- Skip Roblox System Messages
		overrideProperties.PrefixText = message.Metadata or "" -- Use prefix sent from server

	elseif message.TextSource then

		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if player then
			if player.MembershipType ~= Enum.MembershipType.None then
				local prefixPart = DatatypeUtility.ApplyRichGradient(
					`[{DatatypeUtility.SplitCamelCase(player.MembershipType.Name)}]`,
					PremiumPrefixGradientColor,
					true
				)
				overrideProperties.PrefixText = `{prefixPart} {message.PrefixText}`
			end
		end

	end
	return overrideProperties
end



local Channels = TextChatService:WaitForChild("TextChannels")
local GeneralChannel = Channels:WaitForChild("RBXGeneral")

-- Use this for connecting User Feedback (e.g. RemoteEvent)
function module:SendMessage(text : string?, prefix : string?)
	GeneralChannel:DisplaySystemMessage(`{text}`, prefix or "")
	
	return module
end

return module