# SmartExtend
Extends models while using as few parts as possible by resizing them

Available on [GitHub](https://github.com/RailTypes/SmartExtend/releases/tag/SmartExtend) and the [Roblox Creator Store](https://create.roblox.com/store/asset/127766719562667) (plugin also on [GitHub](https://github.com/RailTypes/SmartExtend/releases/tag/Plugin))

## Usage
Running the function is very simple - just provide the required arguments.
```lua
extending: Model | BasePart, -- The model or part you want to extend
direction: Enum.NormalId, -- The direction you want to extend in
scale: number, -- How much you want to extend by (positive numbers only)
rotEpsilon: number?, -- The rotation epsilon (default 1e-5)
sizeEpsilon: number? -- The size epsilon (default 1e-5)
```

## Tips
- Any `PVInstance` beside a `BasePart` in the model/part you'll be extending will be duplicated and moved along the primary part. To avoid this, move its contents to a `Folder` (or basically anything that isn't a `PVInstance`).
