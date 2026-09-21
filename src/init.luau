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

export type TextSection = {
	IsText: true,
	Graphemes: {string},
}
export type TagSection = {
	IsText: false,
	TagText: string,
	IsCompleted: boolean,
}
export type RichTextSection = TextSection | TagSection

-- An entry on the "currently open tags" stack.
type OpenTag = {
	TagName: string,
	Section: TagSection, -- the TagSection already sitting in `result`, mutated in place when closed
	ResultIndex: number, -- where that TagSection lives in `result`, used only to strip it out if never closed
}

const function SplitRichTextSections(str: string, isBrPreserved: boolean?): ({RichTextSection}, number)
	const result: {RichTextSection} = {}
	const openStack: {OpenTag} = {}

	local totalGraphemes: number = 0 -- count of graphemes that are not part of a tag
	local currentText: TextSection? = nil -- the text run currently being appended to
	local bytesProcessed: number = 0

    -- Ordinary text graphemes, a single `<` all go here
	-- (including cases of `<>` and `<{any single byte character}>`)
	-- and also if isBrPreserved == false, all `br` alike end up here
	const function pushTextGrapheme(grapheme: string)
		totalGraphemes += 1
		if not currentText then
			local currentTextVariable: TextSection = {
				IsText = true,
				Graphemes = {},
			}
			currentText = currentTextVariable
			table.insert(result, currentTextVariable)
		end
		table.insert((currentText :: TextSection).Graphemes, grapheme)
	end

	for graphemeStart: number, graphemeEnd: number in utf8.graphemes(str) do
		if graphemeStart < bytesProcessed then
			continue
		end

		const grapheme = str:sub(graphemeStart, graphemeEnd)

		if grapheme == `<` then
			const matchStart, matchEnd, match = string.find(str, `(%b<>)`, graphemeEnd)

			if matchStart == nil or matchStart ~= graphemeEnd then
				-- not a valid balanced tag starting here: the '<' itself is
				-- SAVED as ordinary text, and whatever follows falls through and is picked
				-- up as ordinary text by later iterations (same as before)
                pushTextGrapheme(grapheme)
				continue
			end

			const tagEnd: number = matchEnd :: number
			const tagText: string = match :: string
			const matchDelta: number = tagEnd - (matchStart :: number)

			if matchDelta < 2 then
				-- literally "<>", empty, ignore
				pushTextGrapheme(grapheme)
				continue
			end

			const isEnclosing: boolean = string.sub(tagText, 2, 2) == `/`
			if matchDelta == 2 and isEnclosing then
				-- "</>", nothing to do with this
				pushTextGrapheme(grapheme)
				continue
			end

			local tagName: string = string.sub(tagText, isEnclosing and 3 or 2, -2)
			const spaceAt = string.find(tagName, ` `)
			if type(spaceAt) == `number` then
				tagName = string.sub(tagName, 1, spaceAt - 1)
			end

			if not isBrPreserved and string.lower(tagName) == `br` then
				-- "br" is documented but shouldn't be used: Roblox's RichText
				-- renderer chokes on it and dumps the whole label as raw markup.
				-- Disable it by treating the entire tag (open or close spelling)
				-- as plain text, grapheme by grapheme, so the gradient still
				-- applies to it like any other text.
				for gs: number, ge: number in utf8.graphemes(tagText) do
					pushTextGrapheme(string.sub(tagText, gs, ge))
				end
				bytesProcessed = tagEnd + 1
				continue
			end

			if isEnclosing then
				-- try the top of the stack first (the common, well-nested case),
				-- then fall back to scanning the *currently open* stack for the
				-- nearest (most recently opened) match instead of the oldest one,
				-- so overlapping/interleaved tags close the innermost candidate
				-- first - never the full history of every tag ever seen.
				local matchIndex: number? = nil

				if #openStack > 0 and openStack[#openStack].TagName == tagName then
					matchIndex = #openStack
				else
					for i = #openStack - 1, 1, -1 do
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
		pushTextGrapheme(grapheme)
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
-- @param isBrPreserved See SplitRichTextSections. Defaults to false (br neutralized).
-- @return RichText String of the given str with given gradient applied to it.
const function ApplyRichGradient(str: string, startColor: Color3 | ColorSequence, endColorOrMarker: Color3 | boolean, isBrPreserved: boolean?): string
	const sections, totalGraphemes = SplitRichTextSections(str, isBrPreserved)

	if totalGraphemes == 0 then
		return str
	end

	-- With a single grapheme there's no meaningful "position" along the
	-- gradient to interpolate to, anchor it at the very start (t = 0)
	-- rather than dividing by zero or never reaching 1
	const lastIndex: number = math.max(totalGraphemes - 1, 1)

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
			const timeDelta = kp2.Time - kp1.Time
			-- Roblox allows two ColorSequenceKeypoints to share the same Time
            -- so the timeDelta check is necessary here 
			const alpha = if timeDelta == 0 then 1 else (t - kp1.Time) / timeDelta
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
			table.insert(result, `<font color="#{colorAt(t / lastIndex):ToHex()}">{grapheme}</font>`)
			t += 1
		end
	end

	return table.concat(result, ``)
end



const RichGradient = {
	RawAPI = table.freeze({
		SplitRichTextSections = SplitRichTextSections,
		ApplyRichGradient = ApplyRichGradient,
	})
}

function RichGradient.Apply(
	self: RichGradient,
	richText: string,
	startColor: Color3 | ColorSequence,
	endColor: (Color3 | boolean)?,
	isBrPreserved: boolean?
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
	
	return ApplyRichGradient(richText, startColor, endColor :: (Color3 | boolean), isBrPreserved)
end

table.freeze(RichGradient)
type RichGradient = typeof(RichGradient)

return RichGradient