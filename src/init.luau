--[[

      - TODO@FEATURE Make server-to-client (and vice-versa) easy!
      - TODO@FEATURE EasingMap.luau? it applies on Alpha in the mappers
      - TODO@FEATURE Connections. Like Playing or Ended
      - TODO@OPTIM the documentation is kinda bleh lol
      - TODO@OPTIM Math for better inbetweening. You know when like, you're trying to do a Linear
            thing, but it ends up being quadratic?
]]

--[=[
      API for more control over in-betweens, easing and mapping.
--]=]
local BTwin = { }

-- Constants

local TypeMap = require(script.TypeMap)
export type BTwinable = TypeMap.BTwinable
export type BTwinMapper<T> = TypeMap.BTwinMapper<T>

local ERR_NOT_TYPE = "【BTwin】 Value %* (%*) is not the expected type '%*'"

local CLIENTSIDE = game:GetService("Players").LocalPlayer ~= nil
local TICK_METHOD = game:GetService("RunService") [CLIENTSIDE and "RenderStepped" or "Heartbeat"] -- Maybe change Heartbeat?

local TYP_BOOL = "boolean"
local TYP_STRING = "string"
local TYP_NUMBER = "number"
local TYP_INSTANCE = "Instance"
local TYP_TABLE = "table"
local TYP_FUNC = "function"

local TYP_BTWINABLE_BASE = "BTwinable ("
local TYP_BTWINABLE
local function TYP_BTWINABLE_UPDATE ( )
      TYP_BTWINABLE = TYP_BTWINABLE_BASE
      local i = 0
      for name, _ in next, TypeMap do
            if i > 0 then
                  TYP_BTWINABLE ..= "|"
            end
            i += 1
            TYP_BTWINABLE ..= name
      end
      TYP_BTWINABLE ..= ")"
end
TYP_BTWINABLE_UPDATE()

local STATES = Enum.PlaybackState
local STATE_DELAYED = STATES.Delayed
local STATES_BEGIN = STATES.Begin
local STATE_PLAYING = STATES.Playing
local STATE_PAUSED = STATES.Paused
local STATES_COMPLETED = STATES.Completed
local STATES_CANCELLED = STATES.Cancelled

local _ROUTINE_SUSPENDED = 'suspended'
local _ROUTINE_ALIVE = 'running'
local ROUTINE_DEAD = 'dead'


do -- Whitelisting

      --[[
            Returns `true` if the value type of the object is able to be used in BTwins.
      --]]
      function BTwin.IsBTwinable ( obj: any ) : boolean
            return TypeMap [typeof(obj)] ~= nil
      end

      --[[
            Returns `true` if the value type of the object is able to be used in BTwins.
      --]]
      function BTwin.IsTypeBTwinable ( type: string ) : boolean
            return TypeMap [type] ~= nil
      end

      --[[
            Creates or replaces the reference BTwins have to map in-between variables
            of a certain type `typeName`.
      --]]
      function BTwin.MakeBTwinable ( typeName: string, mapper: BTwinMapper<any> ) : ( )
            assert(typeof(typeName) == TYP_STRING, string.format(ERR_NOT_TYPE, typeName, `typeName`, TYP_STRING))
            assert(typeof(mapper) == TYP_FUNC, string.format(ERR_NOT_TYPE, mapper, `mapper`, TYP_FUNC))
            TypeMap [typeName] = mapper
            TYP_BTWINABLE_UPDATE()
      end

      --[[
            Disables the mapper function for type `typeName`.
      --]]
      function BTwin.MakeUnBTwinable ( typeName: string ) : ( )
            assert(typeof(typeName) == TYP_STRING, string.format(ERR_NOT_TYPE, typeName, `typeName`, TYP_STRING))
            TypeMap [typeName] = nil
            TYP_BTWINABLE_UPDATE()
      end

end

do -- Mapping
      
      --[[
            Maps a variable to an in-between number from `value0` to `value1`.
      --]]
      function BTwin.Map (
            object: table|Instance, variable: string,
            value0: BTwinable, value1: BTwinable, alpha: number
      ) : BTwinable

            assert(typeof(object) == TYP_TABLE or typeof(object) == TYP_INSTANCE, string.format(ERR_NOT_TYPE, object, `object`, TYP_INSTANCE.."|"..TYP_TABLE ))
            assert(typeof(variable) == TYP_STRING, string.format(ERR_NOT_TYPE, variable, `variable`, TYP_STRING ))
            local type0 = typeof(value0)
            assert(BTwin.IsTypeBTwinable(type0), string.format(ERR_NOT_TYPE, value0, `value0`, TYP_NUMBER ))
            local type1 = typeof(value1)
            assert(BTwin.IsTypeBTwinable(type1), string.format(ERR_NOT_TYPE, value1, `value1`, TYP_NUMBER ))
            assert(typeof(alpha) == TYP_NUMBER, string.format(ERR_NOT_TYPE, alpha, `alpha`, TYP_NUMBER ))

            assert(type0 == type1, string.format(ERR_NOT_TYPE.." (needs to be same type as value0)", value1, `value1`, type0))
            object [variable] = TypeMap [type0] (value0, value1, alpha)
            type0, type1 = nil, nil
            return object [variable]
      end

      --[[
            Maps `object0`'s `variable` to an in-between number of theirs and `object1`'s
            starting from `value0`.
      --]]
      function BTwin.Map2 (
            object0: table|Instance, object1: table|Instance, variable: string,
            value0: BTwinable, alpha: number
      ) : BTwinable

            assert(typeof(object0) == TYP_TABLE or typeof(object0) == TYP_INSTANCE, string.format(ERR_NOT_TYPE, object0, `object0`, TYP_INSTANCE.."|"..TYP_TABLE ))
            assert(typeof(object1) == TYP_TABLE or typeof(object1) == TYP_INSTANCE, string.format(ERR_NOT_TYPE, object1, `object1`, TYP_INSTANCE.."|"..TYP_TABLE ))
            assert(typeof(variable) == TYP_STRING, string.format(ERR_NOT_TYPE, variable, `variable`, TYP_STRING ))
            assert(BTwin.IsTypeBTwinable(typeof(value0)), string.format(ERR_NOT_TYPE, value0, `value0`, TYP_NUMBER ))
            assert(typeof(alpha) == TYP_NUMBER, string.format(ERR_NOT_TYPE, alpha, `alpha`, TYP_NUMBER ))

            return BTwin.Map (object0, variable, value0, object1 [variable], alpha)
      end

end

--[=[
      The replacement Tween instance.
--]=]
local Instance = { }
local shadow = { __index = Instance, __type = "BTwin" }
do

      --[[
            Sets a goal of the BTwin.
      --]]
      function Instance:SetGoal ( property: string, value: BTwinGoals|BTwinable ) : ( )
            assert(BTwin.IsBTwinable(value) or typeof(value) == TYP_TABLE, string.format(ERR_NOT_TYPE, value, `value`, TYP_BTWINABLE.."|"..TYP_TABLE ))
            assert(typeof(property) == TYP_STRING, string.format(ERR_NOT_TYPE, property, `property`, TYP_STRING ))

            self.Goals [property] = value
      end

      --[[
            Removes a goal of the BTwin.
      --]]
      function Instance:DestroyGoal ( ...: string ) : ( )
            local tree = {...}
            local holder = self.Goals
            local _property
            for _, property in next, tree do
                  assert(typeof(property) == TYP_STRING, string.format(ERR_NOT_TYPE, property, `property`, TYP_STRING ))
                  if holder [property] == nil then return end
                  _property = property
                  if typeof(holder [property]) ~= TYP_TABLE then break end
                  holder = holder [property]
            end

            holder [_property] = nil
            holder = nil
            tree = nil
            _property = nil
      end


      --[[
            Sets the duration of the BTwin.
      --]]
      function Instance:SetDuration ( value: number ) : ( )
            assert(typeof(value) == TYP_NUMBER, string.format(ERR_NOT_TYPE, value, `value`, TYP_NUMBER ))

            self.Duration = value
      end

      --[[
            Sets the speed of the BTwin.
      --]]
      function Instance:SetSpeed ( value: number ) : ( )
            assert(typeof(value) == TYP_NUMBER, string.format(ERR_NOT_TYPE, value, `value`, TYP_NUMBER ))

            self.Speed = value
      end
      
      --[[
            Sets the current time (delta) of the BTwin.
      --]]
      function Instance:SetTime ( value: number ) : ( )
            assert(typeof(value) == TYP_NUMBER, string.format(ERR_NOT_TYPE, value, `value`, TYP_NUMBER ))

            self.Delta = value
      end
      -- Alias

      Instance.SetDelta = Instance.SetTime
      
      --[[
            Offsets the current time (delta) of the BTwin.
      --]]
      function Instance:OffsetTime ( value: number ) : ( )
            assert(typeof(value) == TYP_NUMBER, string.format(ERR_NOT_TYPE, value, `value`, TYP_NUMBER ))

            self.Delta += value
      end
      -- Alias

      Instance.OffsetDelta = Instance.OffsetTime

      --[[
            The function that gets called every frame to update the BTwin.
      --]]
      function Instance:_onTick ( )
		local dt: number -- Time passed per frame
		local clock0: number, clock1: number = os.clock(), os.clock() -- Comparison numbers
            self.State = self.STATE_PLAYING
		repeat
			clock1 = os.clock()
			dt = clock1-clock0
                  if self.Delay <= 0 then
                        if not self.Reversing then
                              self.Delta += dt * self.Speed
                        else
                              self.Delta -= dt * self.Speed
                        end
                  else
                        self.Delay -= dt * self.Speed
                  end
                  self.Delta = math.clamp(self.Delta, 0, self.Duration)
                  self.Alpha = self.Delta / self.Duration
                  for variable, goal in self.Goals do
                        -- TODO@FEATURE Make it detect if it is a compound type (UDim2)
                        -- so you can change only the Y Scale for example
                        if typeof(goal) == TYP_TABLE then
                              -- TODO@FEATURE Make it go inside tables aswell!
                              continue
                        end
                        if self.GoalsInitial [variable] == nil then
                              self.GoalsInitial [variable] = self.Instance [variable]
                        end
                        BTwin.Map(self.Instance, variable, self.GoalsInitial [variable], goal, self.Alpha )
                  end
                  TICK_METHOD:Wait()
                  -- FIXME@FEATURE This is incorrect.
                  -- When reps = 0 it doesn't begin
                  -- When reps > 0 and reverses = true it doesn't count the
                  -- reversion as the same cycle
                  if (self.Speed >= 0 and
                        self.Delta >= self.Duration or (self.Reversing and self.Delta <= 0))
                  or (self.Speed < 0 and
                        self.Delta <= 0 or (self.Reversing and self.Delta >= self.Duration )) then
                        if self.Repetitions == 0 and ((self.Reverses and self.Reversing) or not self.Reverses) then
                              self.State = STATES_COMPLETED
                        elseif self.Repetitions > 0 and (self.Reverses and self.Reversing) then
                              self.Repetitions -= 1
                        end
                        if self.Reverses then
                              self.Reversing = not self.Reversing
                        end
                  end

                  -- FIXME@OPTIM Probably unsafe to do this.
                  if self.State == STATE_PAUSED then
				coroutine.yield()
				clock1 = os.clock()
			end
			clock0 = clock1
            until self.Repetitions == 0
            and self.State ~= STATES_BEGIN
            and self.State ~= STATE_PLAYING
            dt = nil
            clock0, clock1 = nil, nil
      end

      --[[
            (re)Starts the current BTwin. Returns the routine that controls the tweening.
      --]]
      function Instance:Play ( speed: number ) : ( )
            if speed ~= nil then
                  self.Speed = speed
            end
            if self.Routine ~= nil and coroutine.status(self.Routine) ~= ROUTINE_DEAD then
                  coroutine.close(self.Routine)
                  self.Routine = nil
            end
            -- Check if speed is negative
            -- if it is, go to the maximum
            if self.Speed >= 0 then
                  self.Delta = 0
            else
                  self.Delta = self.Duration
            end
            self.State = STATES_BEGIN
            self.Routine = task.spawn(self._onTick, self)
            return self.Routine
      end

      --[[
            Pauses the current BTwin.
      --]]
      function Instance:Pause ( ) : ( )
            self.State = STATE_PAUSED
      end

      --[[
            Resumes the current BTwin.
      --]]
      function Instance:Resume ( ) : ( )
            self.State = STATE_PLAYING
      end

      --[[
            Cancels the current BTwin.
      --]]
      function Instance:Cancel ( ) : ( )
            self.State = STATES_CANCELLED
            if self.Routine ~= nil and coroutine.status(self.Routine) ~= ROUTINE_DEAD then
                  coroutine.close(self.Routine)
                  self.Routine = nil
            end
      end


      --[[
            Destroys the current BTwin.
      --]]
      function Instance:Destroy ( ) : ( )
            self:Cancel()
            self.Instance = nil
            setmetatable(self, nil)
            table.clear(self)
            table.freeze(self)
      end

end


--[[
      Creates a BTwin instance.
--]]
function BTwin.Create ( object: table|Instance, goals: BTwinGoals?,
      info: { offset: number?, duration: number?, speed: number?, delay: number?, reps: number?, reverses: boolean? }? ): BTwin
      assert(typeof(object) == TYP_TABLE or typeof(object) == TYP_INSTANCE, string.format(ERR_NOT_TYPE, object, `object0`, TYP_INSTANCE.."|"..TYP_TABLE ))
      assert(typeof(goals) == TYP_TABLE or goals == nil, string.format(ERR_NOT_TYPE, goals, `goals`, TYP_TABLE.."?" ))

      -- Certify if info is OK if it exists
      if info ~= nil then
            assert(typeof(info.duration) == TYP_NUMBER or info.duration == nil, string.format(ERR_NOT_TYPE, info.duration, `info.duration`, TYP_NUMBER.."?" ))
            assert(typeof(info.offset) == TYP_NUMBER or info.offset == nil, string.format(ERR_NOT_TYPE, info.offset, `info.offset`, TYP_NUMBER.."?" ))
            assert(typeof(info.speed) == TYP_NUMBER or info.speed == nil, string.format(ERR_NOT_TYPE, info.speed, `info.speed`, TYP_NUMBER.."?" ))
            assert(typeof(info.delay) == TYP_NUMBER or info.delay == nil, string.format(ERR_NOT_TYPE, info.delay, `info.delay`, TYP_NUMBER.."?" ))
            assert(typeof(info.reps) == TYP_NUMBER or info.reps == nil, string.format(ERR_NOT_TYPE, info.reps, `info.reps`, TYP_NUMBER.."?" ))
            assert(typeof(info.reverses) == TYP_BOOL or info.reverses == nil, string.format(ERR_NOT_TYPE, info.reverses, `info.reverses`, TYP_BOOL.."?" ))
      end

      --[[
            TODO@FEATURE? Being able to set if the BTwin goal is relative or absolute.
            Pratical example: If using Repetitions, a part could be repeteadly offset 10 studs.
      --]]
      local self: BTwin = {
            Instance = object, -- The table|instance to be tweened
            Goals = (goals or { }) :: BTwinGoals, -- What to tween
            GoalsInitial = { } :: BTwinGoals, -- What was being tweened (Goals - GoalsInitial)
            Speed = info.speed or 1, -- The speed scale of the BTwin's progression
            Duration = info.duration or .1, -- Duration (in seconds) of the BTwin
            Delta = info.offset or 0, -- Progression (in seconds) of the BTwin
            Alpha = if info.offset ~= nil then -- Progression as a ratio of the BTwin
                        if info.duration ~= nil then
                              info.offset / info.duration
                              else
                              info.offset / 0.1
                  else
                        0,

            -- The goal goes backwards with the same duration upon initially ending
            --
            -- TotalDuration = Duration · 2
            Reverses = if info.reverses ~= nil then info.reverses else false,
            Reversing = false, -- If the BTwin is reversing.
            
            Delay = info.delay or 0, -- Delay until the BTwin resumes.
            Repetitions = info.reps or 0, -- How many times will the BTwin repeat the same action. -1 for infinite

            Routine = nil :: thread?,

            State = STATE_DELAYED -- The current PlaybackState of the BTwin. Starts as `Enum.PlaybackState.Delayed`
      }

      setmetatable(self, shadow)
      return self :: BTwin
end

export type BTwinGoals = { [string]: BTwinGoals|BTwinable }
export type BTwin = typeof(BTwin.Create(table.unpack(...)))


return BTwin