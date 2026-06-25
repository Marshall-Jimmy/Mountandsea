# 美术风格与素材调研

> 调研日期：2026-06-25
> 项目：《山海经 · Mountandsea》2D 开放世界 RPG，Godot 4.7 + GDScript
> 状态：调研阶段，未导入任何素材文件

---

## 当前推荐方向总结

推荐风格：**半写实东方手绘** — 以数字手绘为骨，青绿水墨为色，动漫表情为魂，荒野剪影为境。

四要素拆解：

| 要素 | 来源 | 落点 |
|------|------|------|
| 动漫感 | 东方动漫角色设计语言 | 明亮高对比明暗，表情可读，角色辨识度高 |
| 半写实 | 环境层纹理与渐变 | 丰富笔触质感，不追求照片级但要有材质感 |
| 荒野感 | 饥荒剪影构图与资源稀缺压迫感 | 用冷青雾色替代饥荒焦黑，做出"东方荒野" |
| 东方神话 | 山海经原文描述 + 青绿山水画语言 | 朱砂红/灵力青光突出神性；UI 用云雷纹、饕餮纹 |

### 为什么放弃像素风

AI 生成像素图存在以下硬伤，经评估后决定不采用像素风：

| 问题 | 说明 |
|------|------|
| 抗锯齿难消除 | AI 直出的"像素"边缘总有半透明像素，后处理成本高 |
| 色板控制差 | 很难稳定限定在 16/32 色，色阶会漂移 |
| 网格对齐差 | 细节不遵守像素网格，放大后全是噪点 |
| 批量一致性极差 | 同一角色不同帧的风格、比例、色阶都会变 |

相比之下，**手绘插画风是 AI 最擅长的生成领域**：SDXL/Midjourney 直出可用稿，LoRA + ControlNet 风格收敛效果好，水墨/青绿山水可直接表达东方神话气质，且与饥荒的手绘参考方向直接对标。

---

## 不推荐方向

### 为什么不直接使用纯《饥荒》式风格

| 维度 | 饥荒风格 | 本项目目标 |
|------|---------|-----------|
| 色调 | 焦褐 + 灰黑 + 高对比暗角 | 冷青雾底 + 朱砂灵气 |
| 气质 | 哥特恐怖、尖锐怪诞 | 古朴神秘、自然空灵 |
| 角色 | 疯癫线条、扭曲比例 | 动漫感、半写实、可读表情 |

结论：参考饥荒的**荒野生存气质与剪影构图**，但用**冷青雾色 + 朱砂灵气**替代其焦黑尖锐，既保留疏离空旷，又注入东方神话的灵性而非哥特恐怖。

### 其他规避方向

- 像素风：AI 生成质量差，后处理成本高，风格一致性难以保证
- 纯 Q 版：角色辨识度不足，异兽威慑感缺失
- 纯欧美卡通：与东方神话气质不符
- 克苏鲁/现代怪兽：太恐怖，偏离山海经古朴自然感
- 现代科幻 UI：与古代神话设定冲突

---

## 风格关键词

### 中文关键词
半写实东方手绘、青绿山水、荒野生存、山林异兽、古朴神秘、动漫感、水墨底色、朱砂灵气、云雷纹、饕餮纹、竹简书卷、宣纸纹理、数字手绘、插画风格

### 英文关键词
semi-realistic eastern digital painting, anime-influenced illustration, ink-wash painting style, wilderness survival atmosphere, hand-painted 2D game art, jade green and cinnabar red accents, misty cool tones, ancient Chinese mythology, top-down RPG, hand-painted forest tileset, watercolor game art

---

## 尺寸规范

### 推荐尺寸标准

手绘插画风使用高分辨率素材，通过 Godot 2D 相机缩放适配不同分辨率。

| 资源类型 | 推荐尺寸 | 理由 |
|---------|---------|------|
| 场景 Tile / 纹理 | **512×512** | 手绘细节充足，Godot 2D 缩放后无锯齿；可向下缩放适配各种视野 |
| 角色（主角/NPC）sprite | **512×512**（画布），实际角色约占 300×450 | 高分辨率手绘，表情和服饰细节清晰；导出时按需缩放 |
| 异兽 sprite | **512×512**（普通），**1024×1024**（BOSS 级） | 山海经异兽需辨识度与威慑感；BOSS 级用更大画布 |
| 物品图标 | **128×128** | UI 中按需缩放显示（背包格 64×64 显示） |
| 特效/粒子 | 256×256 单帧 | 灵力/法术粒子 |
| 概念图/立绘 | **1024×1024** 或更大 | 用于图鉴、过场、宣传 |
| 渲染策略 | 原生分辨率，相机缩放适配 | 1280×720 窗口原生渲染，无需整数缩放 |

### 与像素风的尺寸对比

| 维度 | 像素风（已放弃） | 手绘插画风（采用） |
|------|----------------|-------------------|
| Tile 尺寸 | 32×32 | 512×512 |
| 角色尺寸 | 48×48 | 512×512 |
| 缩放方式 | 整数缩放（2×/3×） | 自由缩放（平滑插值） |
| AI 生成质量 | 差 | 优秀 |
| 风格一致性 | LoRA 难收敛 | LoRA + ControlNet 效果好 |

### 俯视角 vs 侧视角

| 维度 | 俯视角 | 侧视角（Terraria 式） |
|------|--------|---------------------|
| 角色表达 | 约 1.5-2 tile 高，角色辨识度好 | 角色更瘦长，异兽需站得起来 |
| 地形表达 | autotile 过渡（草地→沙→水） | 分层 + 挖掘破坏 |
| 手绘适配 | **推荐优先** — 手绘纹理在俯视角下表现力强 | 长线可选 |
| AI 生成 | 俯视角场景 AI 生成效果稳定 | 侧视角需更多 ControlNet 辅助 |

美术方向（动漫+半写实+荒野）更契合俯视角（角色辨识度需求高于挖掘物理），建议俯视优先。

---

## 色彩规范

### 推荐色板

手绘插画风不再受限色板约束，可使用完整色域。以下色板作为**风格指南**而非硬性限制，保持画面色彩方向统一：

| 角色 | 色值 | 用途映射 |
|------|------|---------|
| 浅赭 | #e4a672 | 干土、沙地、皮革 |
| 陶土 | #b86f50 | 树皮、兽皮、木质道具 |
| 红褐 | #743f39 | 深木、旧血迹、异兽暗部 |
| 暗紫梅 | #3f2832 | 阴影、夜晚、神秘洞穴 |
| 深朱 | #9e2835 | **朱砂——异兽灵气、神话点缀（主强调色）** |
| 亮朱 | #e53b44 | 灵力、警示、火焰 |
| 橙 | #fb922b | 黄昏、篝火、秋叶 |
| 鹅黄 | #ffe762 | 光源、法术高光、灵草 |
| 草绿 | #63c64d | 草地、嫩叶 |
| 深绿 | #327345 | 山林、松柏 |
| 墨青 | #193d3f | **深山阴影、水墨底色（主冷调）** |
| 雾蓝 | #4f6781 | 雾气、远景、水 |
| 浅雾 | #afbfd2 | 远景山峦、云 |
| 纯白 | #ffffff | 高光、灵气边 |
| 青光 | #2ce8f4 | **灵力青——神性/法术（辅助强调色）** |
| 深青 | #0484d1 | 深水、夜空 |

### 色彩策略：青绿为骨，朱砂为魂

- **主色调（60%）**：墨青 #193d3f + 深绿 #327345 + 雾蓝 #4f6781 — 构成青绿山林荒野底色
- **辅助色（30%）**：浅赭 #e4a672 + 陶土 #b86f50 + 草绿 #63c64d — 草木、土地、可交互资源
- **强调色（10%）**：朱砂 #9e2835 / 亮朱 #e53b44（异兽、危险、神性）+ 青光 #2ce8f4 / 鹅黄 #ffe762（灵力、法术、宝物）

### 与饥荒色板的差异化

饥荒以焦褐 + 灰黑 + 高对比暗角营造压迫；本项目刻意用 **冷青雾底 + 朱砂灵气** 替代，既保留荒野的疏离空旷，又注入东方神话的灵性而非哥特恐怖。

---

## AI 素材生成规范

### 工具选型

| 工具 | 适用 | 商用授权 |
|------|------|---------|
| Stable Diffusion (SDXL) | tileset、sprite、概念图 | 模型开源，生成图商用取决于 checkpoint/LoRA 许可 |
| Midjourney | 概念图、氛围图、立绘 | 付费订阅可商用 |
| ControlNet | 一致性控制（轮廓/姿势/深度） | 随 SD |
| LoRA | 风格锁定 | 取决于 LoRA 许可 |

### 风格一致性方法

1. **训练项目专属 LoRA**：用 20-50 张统一风格目标图训练 `shanhaijing-style` LoRA，后续所有生成都挂载它，强制风格收敛
2. **ControlNet 锁结构**：生成异兽多角度时，用 OpenPose/线稿 ControlNet 锁定骨架与轮廓，保证 4 方向行走图一致
3. **固定采样尺寸**：SDXL 原生 1024×1024 生成，后处理缩放到目标尺寸（512×512 等）
4. **色板引导**：prompt 中加入色彩关键词（jade green, cinnabar red, misty cool tones）引导色调方向，但不做硬性限色
5. **后处理流水线**：AI 直出手绘稿需后处理 — 去背景、修描轮廓、统一光照方向、切片为 sprite sheet。AI 在本项目定位是"草稿与变体生成器"，不是"终稿生成器"

### Prompt 模板（6 段式）

```
[主体] {creature_name}, {山海经原文特征描述英文翻译},
[风格] semi-realistic eastern digital painting, anime-influenced illustration,
       ink-wash painting style, hand-painted 2D game art,
       wilderness survival atmosphere,
[色板] jade green and cinnabar red accents, misty cool tones,
       watercolor texture, ink wash background,
[构图] front-facing, full body, centered, plain background, sprite sheet ready,
[技术] sdxl, <lora:shanhaijing-style:0.8>, high quality, detailed,
[负向] nsfw, blur, pixelated, lowres, photorealistic, 3d render, watermark, text
```

字段说明：`[主体]` 填异兽名+原文特征（如 "nine-tailed fox, fox with nine tails, sounds like a baby"）；`[风格]` 固定手绘插画风；`[色板]` 引用色彩关键词；`[构图]` 控制方向与背景；`[技术]` 挂载 LoRA；`[负向]` 排除像素化、低分辨率、3D 渲染等。

### 版权要点

- 多数司法辖区不认可纯 AI 生成物的著作权，需有人工实质性修改才能主张版权
- Steam 2024 起要求申报 AI 使用，需保留 AI 生成记录
- 项目开源属性：所有 AI 素材的 prompt、seed、模型版本应记录在 `docs/` 下，确保可复现、可审计

---

## 角色参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| CraftPix Tribal Warrior Boss (免费) | https://craftpix.net/freebies/free-tribal-warrior-boss-characters-asset-pack/ | 矢量卡通手绘，俯视角 4 方向，3 个部落首领 | 免费商用（署名 craftpix.net） | 部落首领/祭祀主持者，矢量可改色东方化 | 偏明亮，需调色降饱和 |
| CraftPix Shinobi Sprites (免费) | https://craftpix.net/freebies/free-shinobi-sprites-pixel-art/ | 东方忍者 | 免费商用（署名） | 最接近日系动漫风 | 像素风，仅作风格参考 |
| CraftPix Swordsman 1-3 Level (免费) | https://craftpix.net/freebies/free-swordsman-1-3-level-pixel-top-down-sprite-character-pack/ | 俯视角 | 免费商用（署名） | 山野旅人/剑客占位 | 像素风，仅作风格参考 |
| CraftPix Necromancer (免费) | https://craftpix.net/freebies/free-necromancer-pixel-art-prototype-character-sprites/ | 暗黑风 | 免费商用（署名） | 巫祝/祭祀者 | 像素风，仅作风格参考 |
| PIPOYA Free RPG Character Sprites | https://pipoya.itch.io/pipoya-free-rpg-character-sprites | 俯视角 RPG | 待确认 | 免费俯视角角色 | 需打开确认授权 |
| LPC Character Generator | https://pflat.itch.io/lpc-character-generator | LPC 角色 | 待确认 | 批量生成角色参考 | 像素风，仅作结构参考 |

> 注：手绘插画风下，免费素材中的像素角色包降级为**风格参考**而非直接使用。角色素材应以 AI 生成 + 人工精修为主，免费素材仅用于验证数据管线。

---

## 生物 / 异兽参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| Dragon Fully Animated | https://opengameart.org/content/dragon-fully-animated | 2D 骨骼动画，60fps，完整动画 | CC0 | 龙/蛇形异兽（应龙、蛟、巴蛇）参考 | 偏西方龙，需东方化改造 |
| 10 basic rpg enemies | https://opengameart.org/content/10-basic-rpg-enemies | FF6 风，侧视图 | CC-BY 3.0 / OGA-BY 3.0 | 异兽战斗立绘参考，商业友好 | 侧视图非俯视角 |
| OGA Centaur | https://opengameart.org/content/centaur-0 | 像素 | 逐页确认 | 人面兽身/兽面人身结构参考 | 授权需确认 |
| CraftPix Ancient Mythology Boss (付费) | https://craftpix.net/product/ancient-mythology-boss-characters-top-down-asset-pack/ | 矢量卡通，俯视角，3 个神话 Boss | 付费可商用 | 牛头人=兽面人身原型，法老=古代王权 | 宙斯偏希腊需替换 |
| CraftPix Top-Down Pixel Ent (付费) | https://craftpix.net/product/top-down-pixel-ent-character-sprites/ | 俯视角 | 付费可商用 | 树人=草木成精异兽 | 付费 |
| CraftPix Dragon Sprite Sheets (付费) | https://craftpix.net/product/dragon-pixel-art-character-sprite-sheets-pack/ | 俯视角 | 付费可商用 | 龙/蛇形异兽 | 付费 |
| CraftPix Anime Demon (付费) | https://craftpix.net/product/anime-demon-sprite-sheet-pixel-art-pack/ | 动漫风 | 付费可商用 | 接近"半写实动漫"目标 | 付费 |
| CraftPix Slime Mobs (免费) | https://craftpix.net/freebies/free-slime-mobs-pixel-art-top-down-sprite-pack/ | 俯视角 | 免费商用（署名） | 黏液异兽/沼泽生物 | 风格偏卡通 |
| CraftPix Wraith (免费) | https://craftpix.net/freebies/free-wraith-tiny-style-2d-sprites/ | 暗黑风 | 免费商用（署名） | 幽魂/精怪 | 风格偏暗 |
| OGA Temple and Ruins Assets | https://opengameart.org/content/temple-and-ruins-assets | 多种风格 | 逐包确认 | 古代祭坛/神殿废墟 | 授权需逐包核对 |

### 按山海经异兽类型匹配

| 异兽类型 | 首选方案 | 说明 |
|---------|---------|------|
| 狌狌（猿猴类） | AI 生成 | 免费素材空白，AI 手绘可精准表达 |
| 鹿形生物 | AI 生成 + 现有素材结构参考 | AI 擅长手绘鹿形异兽 |
| 鸟兽 | AI 生成 | 精卫、鸾凤等东方鸟兽 AI 生成效果好 |
| 蛇形生物 | AI 生成 + Dragon 参考 | 龙/蛇形是 AI 擅长的题材 |
| 兽面人身/人面兽身 | AI 生成 + CraftPix 牛头人参考 | 半人马/牛头人结构作参考 |
| 草木成精 | AI 生成 + Ent 参考 | 树人造型 AI 可直接生成 |
| 山野旅人/部落 | AI 生成 + Tribal Warrior 参考 | 部落风格 AI 生成效果好 |
| 祭祀/巫祝 | AI 生成 + Necromancer 参考 | 巫祝造型 AI 生成效果好 |

---

## 场景 / TileSet 参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| RPG Nature Tileset | https://stealthix.itch.io/rpg-nature-tileset | 俯视角自然地形 | CC0 | 草地/树林/水/岩石直接可用 | 风格偏写实，可作为底座 |
| LPC Tile Atlas | https://opengameart.org/content/lpc-tile-atlas | 32×32 俯视角 | CC-BY-SA 3.0 + GPL 3.0 | 仅作结构参考 | SA 传染性 |
| Kenney Tiny Town | https://kenney.nl/assets/tiny-town | 16×16，130 文件 | CC0 | MVP 占位 | 抽象简洁，缺荒野质感 |
| Kenney Roguelike/RPG Pack | https://kenney.nl/assets/roguelike-rpg-pack | 16×16，1700 文件 | CC0 | RPG/城镇/家具/UI 一体 | 风格偏抽象 |
| CraftPix Ruined Temple (免费) | https://craftpix.net/freebies/free-ruined-temple-top-down-location-pixel-art/ | 俯视角 | 免费商用（署名） | 古代祭坛/神殿废墟，高度契合 | 需东方化改造 |
| CraftPix Path and Road (免费) | https://craftpix.net/freebies/free-path-and-road-top-down-pixel-tileset/ | 俯视角 | 免费商用（署名） | 山路/道路 | 像素风，仅作参考 |
| CraftPix Poison Swamp (免费) | https://craftpix.net/freebies/free-poison-swamp-game-tileset-and-environment-pack/ | 俯视角 | 免费商用（署名） | 荒野/沼泽，神秘荒野感 | 需配色调整 |
| CraftPix Simple Summer (免费) | https://craftpix.net/freebies/free-simple-summer-top-down-vector-tileset/ | 矢量，俯视角 | 免费商用（署名） | 自然草地/夏日户外 | 矢量可缩放 |
| CraftPix Chapel (免费) | https://craftpix.net/freebies/free-chapel-pixel-art-top-down-asset-pack/ | 俯视角 | 免费商用（署名） | 古代建筑内部 | 需东方化 |
| CraftPix Guild Hall (免费) | https://craftpix.net/freebies/free-top-down-pixel-art-guild-hall-asset-pack/ | 俯视角 | 免费商用（署名） | 室内场景/营地建筑 | 需东方化 |
| OGA Forest Tiles | https://opengameart.org/content/forest-tiles | 多种风格 | 逐包确认 | 山林场景 | 授权需确认 |
| OGA Trees Mega Pack | https://opengameart.org/content/trees-mega-pack-cc-by-30-0 | 手绘 | CC-BY 3.0 | 树木量大，手绘风格接近目标 | 需统一风格 |

> 注：手绘插画风下，像素 TileSet 降级为**占位/结构参考**。正式场景素材以 AI 生成手绘纹理为主，人工精修后导入 Godot 4 TileSet 编辑器。

---

## UI / 图标参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| game-icons.net | https://game-icons.net/ | 矢量单色 SVG，4180+ 图标 | CC BY 3.0 | 草药/矿石/木材/药剂图标首选 | 单色矢量，需上色匹配手绘 UI |
| OGA 496 pixel art icons | https://opengameart.org/content/496-pixel-art-icons-for-medievalfantasy-rpg | 32×32 像素 | CC0 | CC0 最安全，食物/武器/护甲/法术齐全 | 像素风，仅作占位 |
| OGA 700+ RPG Icons | https://opengameart.org/content/700-rpg-icons | 像素 | 逐包确认 | 量大 | 授权需确认 |
| Kenney UI Pack - Adventure | https://kenney.nl/assets/ui-pack-adventure | 扁平，130 文件 | CC0 | 冒险主题按钮/面板/滑块 | 通用扁平风，需东方化改造 |
| OGA RPG GUI construction kit | https://opengameart.org/content/rpg-gui-construction-kit-v10 | 多种风格 | 逐包确认 | RPG UI 框架 | 授权需确认 |
| OGA Painterly Spell Icons | https://opengameart.org/content/painterly-spell-icons-part-1 | 手绘 | 逐包确认 | 法术图标，手绘风格接近目标 | 授权需确认 |

### UI 风格缺口

现有素材均为通用冒险/西式 RPG UI，**无直接匹配的古朴纸张/竹简/山海经书卷风 UI**。建议：
- 用 Kenney UI 框架（CC0）做骨架
- AI 生成宣纸/竹简纹理覆盖
- 使用篆隶字体做东方化改造

---

## 授权风险矩阵

| 授权 | 传染性 | 商用 | 代表素材 | 建议 |
|------|--------|------|---------|------|
| CC0 | 无 | 完全自由 | Kenney 全系、Cethiel Dragon、496 图标、stealthix Tileset | **优先采用** |
| CC-BY / OGA-BY | 无 | 需署名 | 10 basic rpg enemies、game-icons.net | 商业友好，推荐 |
| CraftPix 免费 | 无 | 需署名 craftpix.net | Tribal Warrior、Ruined Temple 等 | 推荐，注意署名 |
| CraftPix 付费 | 无 | 购买后商用 | Ancient Mythology Boss、Ent、Dragon | 预算允许则采用 |
| CC-BY-SA / GPL | **有** | 争议 | LPC 全套、Wolf、Goblin | **商业项目慎用** |

---

## 初步推荐组合

### 方案 A：CC0 占位 + AI 生成（MVP 阶段首选）

| 用途 | 方案 | 授权 |
|------|------|------|
| 场景占位 | stealthix RPG Nature Tileset | CC0 |
| 角色占位 | Kenney Roguelike Characters | CC0 |
| 物品图标 | OGA 496 图标 + game-icons.net | CC0 / CC BY |
| UI 框架 | Kenney UI Pack - Adventure | CC0 |
| 角色/异兽 | **AI 生成手绘插画** (SDXL + shanhaijing-style LoRA) | 需人工定稿 |
| 场景纹理 | **AI 生成手绘 tile** (SDXL + prompt 模板) | 需人工定稿 |
| UI 纹理 | **AI 生成宣纸/竹简纹理** | 需人工定稿 |

优点：CC0 底座零风险，AI 生成补齐东方神话手绘风格，风格统一度高。缺点：需训练 LoRA，AI 生成物需人工后处理定稿。

### 方案 B：CraftPix 东方化 + AI 生成（正式版基础）

| 用途 | 方案 | 授权 |
|------|------|------|
| 山路/祭坛/沼泽 | CraftPix Path + Ruined Temple + Poison Swamp | 免费商用（署名） |
| 部落首领/祭祀 | CraftPix Tribal Warrior Boss | 免费商用（署名） |
| 异兽底座 | CraftPix Ancient Mythology Boss (付费) + Ent (付费) | 付费可商用 |
| 角色/异兽 | **AI 生成手绘插画** 补齐东方神话造型 | 需人工定稿 |
| UI 框架 | Kenney UI Pack + AI 生成东方化纹理 | CC0 + AI |

优点：俯视角匹配度高，矢量可改色东方化。缺点：部分付费，需 AI 生成补齐风格统一。

### 方案 C：全 AI 生成（风格统一最优）

| 用途 | 方案 |
|------|------|
| 全部角色/异兽 | SDXL + shanhaijing-style LoRA + ControlNet |
| 全部场景 | AI 生成手绘 tile 纹理 + 人工修描 |
| 全部 UI | AI 生成宣纸/竹简/云雷纹纹理 + Kenney 框架 |
| 物品图标 | AI 生成手绘图标 + game-icons.net 补充 |

优点：风格统一度最高，可精准匹配"半写实东方手绘"定位。缺点：全部依赖 AI 生成 + 人工精修，工作量大。

---

## 后续建议

### 可直接试用

- stealthix RPG Nature Tileset（CC0）— 导入 Godot 4 验证 TileSet 工作流
- Kenney Roguelike Characters（CC0）— 验证角色 sprite 加载与动画
- OGA 496 图标（CC0）— 验证背包图标显示
- CraftPix 免费俯视角包（署名）— 验证祭坛/山路/沼泽场景

### 仅作风格参考

- LPC 生态（CC-BY-SA）— 参考俯视角 RPG 的模块化角色体系，但不直接使用
- 饥荒 — 参考荒野剪影构图与色板策略，但不照搬风格
- CraftPix 像素素材包 — 参考角色/异兽结构设计，但不直接使用

### 必须自制/AI 生成

- 全部东方神话角色/异兽 — AI 生成手绘插画 + 人工精修
- 古朴纸张/竹简/山海经书卷风 UI — AI 生成纹理 + Kenney 框架
- 手绘场景纹理 — AI 生成 + 人工修描

### 下一步行动

1. 用 SDXL + prompt 模板生成招摇山场景测试 tile（512×512 手绘纹理）
2. 训练 shanhaijing-style LoRA 统一风格
3. 生成 3-5 只异兽测试稿（狌狌、鹿蜀、九尾狐等），验证 AI 手绘质量
4. 在 `docs/山海经附录5-工程路线图.md` 落定尺寸标准与色板
5. 人工打开 itch.io 链接核验授权，寻找手绘风 2D RPG 素材
