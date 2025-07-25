# SmartExtend
Extends models while using as few parts as possible by resizing them.

The module is available on the [releases page](https://github.com/RailTypes/SmartExtend/releases) and the [Roblox Creator Store](https://create.roblox.com/store/asset/127766719562667).
The plugin is also on the releases page and the [Creator Store](https://create.roblox.com/store/asset/125008315136342).

## Usage
Running the function is very simple - just provide the required arguments.
```lua
extending: Model | BasePart, -- The model or part you want to extend
direction: Enum.NormalId, -- The direction you want to extend in
scale: number, -- How much you want to extend by (positive numbers only)
rotEpsilon: number?, -- The rotation epsilon (default 1e-5, must be between 0 and 1)
sizeEpsilon: number? -- The size epsilon (default 1e-5, positive numbers only)
```

## Tips
- Any `PVInstance` beside a `BasePart` in the model/part you'll be extending will be duplicated and moved along the primary part. To avoid this, move its contents to a `Folder` (or basically anything that isn't a `PVInstance`).
- If `BasePart`s are being duplicated but you don't want that to happen, then increasing the epsilons may fix this.
- To extend to a certain length, set your scale to the new length divided by the original length. The [demo plugin](https://github.com/RailTypes/SmartExtend/blob/main/plugin/Plugin.luau) has an example of this.
