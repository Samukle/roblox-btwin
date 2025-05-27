--!strict
local TypeMap: {BTwinMapper<BTwinable>} = {
      ["number"] = function(x: number, y: number, a: number) : number
            return x + (y - x) * a
      end :: BTwinMapper<number>,
      ["UDim"] = function(x: UDim, y: UDim, a: number) : UDim
            return x:Lerp(y, a)
      end :: BTwinMapper<UDim>,
      ["UDim2"] = function(x: UDim2, y: UDim2, a: number) : UDim2
            return x:Lerp(y, a)
      end :: BTwinMapper<UDim2>,
      ["Vector2"] = function(x: Vector2, y: Vector2, a: number) : Vector2
            return x:Lerp(y, a)
      end :: BTwinMapper<Vector2>,
      ["Vector3"] = function(x: Vector3, y: Vector3, a: number) : Vector3
            return x:Lerp(y, a)
      end :: BTwinMapper<Vector3>,
      ["CFrame"] = function(x: CFrame, y: CFrame, a :number) : CFrame
            return x:Lerp(y, a)
      end :: BTwinMapper<CFrame>,
      ["Color3"] = function(x: Color3, y: Color3, a :number) : Color3
            return x:Lerp(y, a)
      end :: BTwinMapper<Color3>
}

export type BTwinable = number|UDim|UDim2|Vector2|Vector3|CFrame|Color3
export type BTwinMapper<T> = (x: T, y: T, a: number ) -> T

return TypeMap