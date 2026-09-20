--[[--
    RichGradient V0.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/RichGradient
    Stars are appreciated!
--]]--

--!strict
--!optimize 2

type TextSection = {
	IsText: true,
	Graphemes: {string},
}
type TagSection = {
	IsText: false,
	TagText: string,
	IsCompleted: boolean,
}
type RichTextSection = TextSection | TagSection

-- An entry on the "currently open tags" stack.
type OpenTag = {
	TagName: string,
	Section: TagSection, -- the TagSection already sitting in `result`, mutated in place when closed
	ResultIndex: number, -- where that TagSection lives in `result`, used only to strip it out if never closed
}

const function SplitRichTextSections(str: string): ({RichTextSection}, number)
	const result: {RichTextSection} = {}
	const openStack: {OpenTag} = {}

	local totalGraphemes: number = 0 -- count of graphemes that are not part of a tag
	local currentText: TextSection? = nil -- the text run currently being appended to
	local bytesProcessed: number = 0

	for graphemeStart: number, graphemeEnd: number in utf8.graphemes(str) do
		if graphemeStart < bytesProcessed then
			continue
		end

		const grapheme = str:sub(graphemeStart, graphemeEnd)

		if grapheme == `<` then
			const matchStart, matchEnd, match = string.find(str, `(%b<>)`, graphemeEnd)

			if matchStart == nil or matchStart ~= graphemeEnd then
				-- not a valid balanced tag starting here: the '<' itself is
				-- dropped, and whatever follows falls through and is picked
				-- up as ordinary text by later iterations (same as before)
				continue
			end

			const tagEnd: number = matchEnd :: number
			const tagText: string = match :: string
			const matchDelta: number = tagEnd - (matchStart :: number)

			if matchDelta < 2 then
				-- literally "<>", empty, ignore
				continue
			end

			const isEnclosing: boolean = string.sub(tagText, 2, 2) == `/`
			if matchDelta == 2 and isEnclosing then
				-- "</>", nothing to do with this
				continue
			end

			local tagName: string = string.sub(tagText, isEnclosing and 3 or 2, -2)
			const spaceAt = string.find(tagName, ` `)
			if type(spaceAt) == `number` then
				tagName = string.sub(tagName, 1, spaceAt - 1)
			end

			if isEnclosing then
				-- try the top of the stack first (the common, well-nested case),
				-- then fall back to scanning the *currently open* stack only —
				-- never the full history of every tag ever seen.
				local matchIndex: number? = nil

				if #openStack > 0 and openStack[#openStack].TagName == tagName then
					matchIndex = #openStack
				else
					for i = 1, #openStack - 1 do
						if openStack[i].TagName == tagName then
							matchIndex = i
							break
						end
					end
				end

				if matchIndex then
					const openEntry = openStack[matchIndex]
					openEntry.Section.IsCompleted = true
					
					const tagSection: TagSection = {
						IsText = false,
						TagText = tagText,
						IsCompleted = true,
					}
					
					table.insert(result, tagSection)

					table.remove(openStack, matchIndex)
					currentText = nil
					bytesProcessed = tagEnd + 1
				end
				-- no match found: this closing tag is left unconsumed and
				-- degrades to literal text on the next iterations, exactly
				-- as the original did
				continue
			end

			-- opening tag
			const tagSection: TagSection = {
				IsText = false,
				TagText = tagText,
				IsCompleted = false,
			}
			table.insert(result, tagSection)
			table.insert(openStack, {
				TagName = tagName,
				Section = tagSection,
				ResultIndex = #result,
			})
			currentText = nil
			bytesProcessed = tagEnd + 1
			continue
		end

		-- actual text grapheme
		totalGraphemes += 1

		if not currentText then
			currentText = {
				IsText = true,
				Graphemes = {},
			}
			table.insert(result, currentText)
		end
		table.insert((currentText :: TextSection).Graphemes, grapheme)
	end

-- actually nah, preseve all malformed tags!
	-- Any tag still on the stack was never closed: invalidate it. Its
	-- TagSection entry is stripped from the output, but the text that was
	-- typed inside it is left in place as plain text (same semantics as
	-- the original's `sections[i] = nil` invalidation).
	--if #openStack > 0 then
	--	const removeIndex: {[number]: boolean} = {}
	--	for _, entry in openStack do
	--		removeIndex[entry.ResultIndex] = true
	--	end

	--	const filtered: {RichTextSection} = table.create(#result - #openStack)
	--	for i, item in result do
	--		if not removeIndex[i] then
	--			table.insert(filtered, item)
	--		end
	--	end
	--	result = filtered
	--end
	
	--print(result, totalGraphemes)

	return result, totalGraphemes
end

-- Applies a Gradient to the given text in RichText format.
-- @param str The text to apply the greadient to.
-- @param startColor The start Color3 of the gradient |OR| the complete ColorSequence.
-- @param endColorOrMarker The end Color3 of the gradient |OR| <strong>true</strong> to Indicate you are using a ColorSequence.
-- @return RichText String of the given str with given gradient applied to it.
function ApplyRichGradient(str: string, startColor: Color3 | ColorSequence, endColorOrMarker: Color3 | boolean): string
	const sections, totalGraphemes = SplitRichTextSections(str)

	if totalGraphemes == 0 then
		return str
	end

	const function colorAt(t: number): Color3
		if endColorOrMarker == true and typeof(startColor) == "ColorSequence" then
			const keypoints = startColor.Keypoints
			local idx = 1
			while idx < #keypoints and keypoints[idx + 1].Time < t do
				idx += 1
			end
			if idx == #keypoints then
				return keypoints[idx].Value
			end

			const kp1, kp2 = keypoints[idx], keypoints[idx + 1]
			const alpha = (t - kp1.Time) / (kp2.Time - kp1.Time)
			return Color3.new(
				kp1.Value.R + (kp2.Value.R - kp1.Value.R) * alpha,
				kp1.Value.G + (kp2.Value.G - kp1.Value.G) * alpha,
				kp1.Value.B + (kp2.Value.B - kp1.Value.B) * alpha
			)
		else
			const r = startColor.R + ((endColorOrMarker :: Color3).R - startColor.R) * t
			const g = startColor.G + ((endColorOrMarker :: Color3).G - startColor.G) * t
			const b = startColor.B + ((endColorOrMarker :: Color3).B - startColor.B) * t
			return Color3.new(r, g, b)
		end
	end

	const result: {string} = {}
	local t: number = 0

	for _, section: TagSection | TextSection in sections do
		if section.IsText == false then
			table.insert(result, section.TagText)
			continue
		end

		for _, grapheme in section.Graphemes do
			table.insert(result, `<font color="#{colorAt(t / totalGraphemes):ToHex()}">{grapheme}</font>`)
			t += 1
		end
	end

	return table.concat(result, ``)
end



const RichGradient = {}

function RichGradient.Apply(
	self: RichGradient,
	richText: string,
	startColor: Color3 | ColorSequence,
	endColor: (Color3 | boolean)?
): string
	
	const startTypeof = typeof(startColor)
	if startTypeof == `ColorSequence` then
		endColor = true
	elseif startTypeof ~= `Color3` then
		warn(`startColor must be a Color3 or a ColorSequence; Returning richText without changes.`)
		return richText
	else
		if typeof(endColor) ~= `Color3` then
			endColor = startColor :: Color3
		end
	end
	
	return ApplyRichGradient(richText, startColor, endColor :: (Color3 | boolean))
end

table.freeze(RichGradient)
type RichGradient = typeof(RichGradient)

return RichGradient