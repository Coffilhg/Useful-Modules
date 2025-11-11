--[[--
📦 NotificationGui Component | V1 (11/11/2025)
👤 @Coffilhg
🪪 MIT License (You can use and modify this module freely)
Full license: https://github.com/Coffilhg/Useful-Modules/blob/NotificationsGui/LICENSE

Dependencies:
	Must be parented under Coffee Components | [V2.1]
	SoundProvider (included in the RBXM file)
	throttle (included in the RBXM file)

💡 Tip:
	Check out the RBXM file! (one of the files here: https://github.com/Coffilhg/Useful-Modules/blob/NotificationsGui)
--]]--

local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Loader = script

local SoundProvider = require(Loader:WaitForChild("SoundProvider"))
local throttle = require(Loader:WaitForChild("throttle"))



--- ADJUSTABLE VARIABLES
local NotifyRemote = RS:WaitForChild("Notify") :: RemoteEvent -- MUST BE A REMOTE EVENT
local PaddingBounceTweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true, 0)
local MinTextSize = 12 :: number -- In Pixels
local DarkerColorValueDifference = 135 :: number -- the darker color version has it's Value = Value of given Color3 - DarkerColorValueDifference
-- Notifying player with the same notificationId quickly stacks the notifications; 
local StackingCap = nil -- StackingCap is the max displayed stack number; Leave nil or math.huge for no limit.
-- Usually it takes 1/6 of the Notification Duration to fade in and out;
local MaxFadeTime = 1 -- Sometimes the duration is too big - this will work as the max amount of seconds for fading-in/out.
--- Done ✅





local TotalNotifications = 0

function IncrementTotalNotifications()
	TotalNotifications = TotalNotifications % 1000 + 1
end

function cleverTween(instance : Instance, twInf : TweenInfo, goals : {[string]: any})
	local tween = TS:Create(instance, twInf, goals)
	tween:Play()
	
	Debris:AddItem(tween, twInf.Time + 0.9)
	
	
	local function stop()
		tween:Pause()
	end
	local function replay()
		return cleverTween(instance, twInf, goals)
	end
	
	return stop, replay
end




a=true
b=false
d=Color3.fromRGB(255, 255, 255)
c=UDim.new(0.12, 0)
e=UDim.new(0, 15)

local loaded = false
local loadedItems

local module = {}

local C : (className : string, parent : Instance, props : {[string]: (any)}?, tags : {[number]: string}?, attributes : {[string]: (any)}?) -> Instance, Component : {
	[string] : ModuleScript,
	["new"]: (componentName : string, parent : Instance, any) -> any,
}

function module.new(
	parent : Instance,
	isMobile : boolean?
)
	
	if not C then
		repeat task.wait() C = module["CreateInstance"] until C
	end
	if not Component then
		repeat task.wait() Component = module["Component"] until Component
	end
	
	if loaded then
		if not loadedItems then
			repeat task.wait() until loadedItems
		end
		
		return table.unpack(loadedItems)
	end
	loaded = true
	
	local Notifications = C("ScreenGui", parent, {
		Name="Notifications",	
		DisplayOrder=12,	
		IgnoreGuiInset=a,	
		ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets,	
		ResetOnSpawn=b,	
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	-- a wrapper frame, because just putting everything into screengui sometimes breaks up the notification alignment
	local Wrap = C("Frame", Notifications, {
		AnchorPoint=Vector2.new(0.5, 0.5),	
		BackgroundColor3=Color3.fromRGB(255, 255, 255),	
		BackgroundTransparency=1,	
		BorderColor3=Color3.fromRGB(0, 0, 0),	
		BorderSizePixel=0,	
		Position=UDim2.new(0.5, 0, 0.5, 0),	
		Size=UDim2.new(1, 0, 1, 0),	
	}) :: Frame
	local Uipadding = C("UIPadding", Wrap, {
		Name="UIPadding",	
		PaddingBottom=c,	
		PaddingLeft=c,	
		PaddingRight=c,	
		PaddingTop=c,
	}) :: UIPadding
	local Uilistlayout = C("UIListLayout", Wrap, {
		Name="UIListLayout",	
		Padding=UDim.new(0, 0),	
		HorizontalAlignment=Enum.HorizontalAlignment.Center,	
		SortOrder=Enum.SortOrder.LayoutOrder,	
		VerticalAlignment=Enum.VerticalAlignment.Bottom,
	}) :: UIListLayout
	local NotificationTemplate = C("TextLabel", Wrap, {
		Name="NotificationTemplate",	
		FontFace=Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold, Enum.FontStyle.Normal),	
		RichText=a,	
		Text="",
		TextColor3=d,	
		TextSize=(isMobile and 12 or 24),	
		TextWrapped=a,	
		BackgroundColor3=d,	
		BackgroundTransparency=1,	
		BorderColor3=Color3.fromRGB(0, 0, 0),	
		BorderSizePixel=0,	
		Size=UDim2.new(1, 0, 0, 60),
		ZIndex=250,
	}) :: TextLabel
	local Uipadding = C("UIPadding", NotificationTemplate, {
		Name="UIPadding",	
		PaddingBottom=e,
	}) :: UIPadding
	local Uistroke = C("UIStroke", NotificationTemplate, {
		Name="UIStroke",	
		Color=Color3.fromRGB(120, 120, 120),	
		Thickness=(isMobile and 0.9 or 1.5),
	}) :: UIStroke
	
	
	
	local IdCache = {} :: {
		[string]: {
			["Notification"]: TextLabel,
			["OriginalText"]: string,
			["Stack"]: number,
			["Init"]: (string, boolean?) -> (),
		}
	}
	
	-- Displays an on-screen notification with text, color, and duration settings.
	-- Duration in milliseconds (1 second = 1000 milliseconds).
	-- Sending multiple notifications with the same id overrides the previous text and adds a stack count.
	-- Returns nothing
	local function Notify(NotificationText : string?, Duration : number?, NotificationColor : Color3?, id : string?, stackingDisabled : boolean?)
		--print("Receiving", NotificationText, NotificationColor, Duration, id)
		
		IncrementTotalNotifications()
		
		if id then
			local cached = IdCache[id]
			if cached then
				local newText = {`{NotificationText or cached.OriginalText}`}
				
				if cached.Stack then
					cached.Stack = StackingCap and math.min(cached.Stack + 1, StackingCap) or cached.Stack + 1
					table.insert(newText, `[x{cached.Stack}]`)
					newText = table.concat(newText, " ")
				else
					newText = newText[1]
				end
				
				cached.Init(newText, true)
				cached.Notification.Text = newText
				return
			end
		end


		
		Duration = math.max(Duration or 4500, 1)
		NotificationColor = NotificationColor or Color3.fromRGB(255, 255, 255)
		NotificationText = NotificationText or `{NotificationText}`
		
		
		
		local TimeForNotification = Duration / 1000
		local FadeTime = math.clamp(TimeForNotification / 6, 0.03, MaxFadeTime)
		local twInf = TweenInfo.new(FadeTime) :: TweenInfo --, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
		
		
		
		local clone = NotificationTemplate:Clone()
		clone.Parent = Wrap
		clone.Name = NotificationText
		clone.Text = NotificationText
		clone.TextColor3 = NotificationColor

		local stroke = clone.UIStroke
		local padding = clone.UIPadding
		
		local H, S, V = NotificationColor:ToHSV()
		local DarkerValue = math.clamp(V*255-DarkerColorValueDifference, 0, 255)
		local DarkCol = S > 0 and Color3.fromHSV(H, S, DarkerValue/255) or Color3.fromRGB(DarkerValue, DarkerValue, DarkerValue)

		stroke.Color = DarkCol

		clone.TextTransparency = 1
		stroke.Transparency = 1
		clone.Visible = true
		
		
		
		local cleanup = false
		local tweenAstop, tweenBstop, tweenCStop
		local function stopTweens()
			if tweenAstop then
				tweenAstop()
			end
			if tweenBstop then
				tweenBstop()
			end
			if tweenCStop then
				tweenCStop()
			end
		end
		
		local function show()
			cleanup = false
			tweenAstop = cleverTween(stroke, twInf, {Transparency = 0})
			tweenBstop = cleverTween(clone, twInf, {TextTransparency = 0})
		end
		
		local function hide()
			stopTweens()
			
			tweenAstop = cleverTween(stroke, twInf, {Transparency = 1})
			tweenBstop = cleverTween(clone, twInf, {TextTransparency = 1})
			
			task.delay(0.9, function()
				if clone and cleanup then
					if id then
						IdCache[id] = nil
					end
					clone:Destroy()
				end
			end)
		end
		
		local function init(OriginalText : string, Bounce : boolean?)
			clone.LayoutOrder = TotalNotifications
			stopTweens()
			padding.PaddingBottom=e
			if Bounce then
				tweenCStop = cleverTween(padding, PaddingBounceTweenInfo, {PaddingBottom=UDim.new(0, 0)})
			end
			throttle("NotifySound", 0.3, function()
				SoundProvider.playSound(40, false, 1)
			end)
			show()

			task.delay(TimeForNotification - FadeTime*2, function()
				if OriginalText ~= clone.Text then
					return -- text was changed due to stacking (being called with the same id again; DONT HIDE)
				end
				cleanup = true
				hide()
			end)
		end
		
		
		
		if id then
			local idCacheObject = {
				Notification = clone,
				OriginalText = NotificationText,
				Init = init,
			}
			IdCache[id] = idCacheObject
			
			if not stackingDisabled then
				idCacheObject["Stack"] = 1
			end
		end
		
		init(NotificationText)
		
	end
	
	
	
	NotifyRemote.OnClientEvent:Connect(Notify)


	
	loadedItems = {Notify, Notifications}
	return Notify, Notifications
end

return module