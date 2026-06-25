# 美术风格与素材调研

> 调研日期：2026-06-25
> 项目：《山海经 · Mountandsea》2D 开放世界 RPG，Godot 4.7 + GDScript
> 状态：调研阶段，未导入任何素材文件

---

## 当前推荐方向总结

推荐风格：**半写实东方像素** — 以 32px 像素为骨，青绿水墨为色，动漫表情为魂，荒野剪影为境。

四要素拆解：

| 要素 | 来源 | 落点 |
|------|------|------|
| 动漫感 | Eastward（风来之国）角色处理 | 明亮高对比赛璐璐明暗（2-3 色阶），表情可读 |
| 半写实 | 环境层增加纹理噪声与渐变 | 4-6 色阶而非 2 色阶，打破纯色块 |
| 荒野感 | 饥荒剪影构图与资源稀缺压迫感 | 用冷青雾色替代饥荒焦黑，做出"东方荒野" |
| 东方神话 | 山海经原文描述 + 青绿山水画语言 | 朱砂红/灵力青光突出神性；UI 用云雷纹、饕餮纹 |

---

## 不推荐方向

### 为什么不直接使用纯《饥荒》式风格

| 维度 | 饥荒风格 | 本项目目标 |
|------|---------|-----------|
| 色调 | 焦褐 + 灰黑 + 高对比暗角 | 冷青雾底 + 朱砂灵气 |
| 气质 | 哥特恐怖、尖锐怪诞 | 古朴神秘、自然空灵 |
| 角色 | 疯癫线条、扭曲比例 | 动漫感、半写实、可读表情 |
| 技术 | 手绘 2D / Flash 矢量，非像素 | 像素风（32px tile） |

结论：参考饥荒的**荒野生存气质与剪影构图**，但用**冷青雾色 + 朱砂灵气**替代其焦黑尖锐，既保留疏离空旷，又注入东方神话的灵性而非哥特恐怖。

### 其他规避方向

- 纯 Q 版：角色辨识度不足，异兽威慑感缺失
- 纯欧美卡通：与东方神话气质不符
- 克苏鲁/现代怪兽：太恐怖，偏离山海经古朴自然感
- 现代科幻 UI：与古代神话设定冲突

---

## 风格关键词

### 中文关键词
半写实东方像素、青绿山水、荒野生存、山林异兽、古朴神秘、动漫感、水墨底色、朱砂灵气、云雷纹、饕餮纹、竹简书卷、宣纸纹理

### 英文关键词
semi-realistic eastern pixel art, anime-influenced, ink-wash and cel-shaded hybrid, wilderness survival atmosphere, limited palette of 16 colors, jade green and cinnabar red accents, misty cool tones, ancient Chinese mythology, top-down RPG, forest tileset

---

## 像素尺寸规范

### 推荐尺寸标准

| 资源类型 | 推荐尺寸 | 理由 |
|---------|---------|------|
| TileSet 基础 tile | **32×32** | 现代像素甜区；chunk=32 时单 chunk=1024px，render distance 3-4 覆盖 1280 视野；autotile 过渡细节足够 |
| 角色（主角/NPC）sprite 画布 | **48×48**（实际绘制约 32宽×48高） | 比 tile 略大，留出头部表情空间，承载动漫感 |
| 异兽 sprite 画布 | **64×64**（大型异兽可到 96×96 / 128×128） | 山海经异兽需辨识度与威慑感；BOSS 级用 128 |
| 物品图标 | **32×32** | 与 tile 同档，背包网格统一 |
| 特效/粒子 | 64×64 单帧 | 灵力/法术粒子 |
| 渲染缩放 | 原生 1px，相机 2× 整数缩放 | 1280×720 ÷ 2 = 640×360 逻辑分辨率，约 20×11 tile 可见 |

### 尺寸档位对比

| 尺寸 | 风格定位 | 代表作 | 适用场景 |
|------|---------|--------|---------|
| 16×16 | 复古/极简像素 | Stardew Valley、Terraria | 强调氛围与数量 |
| 32×32 | 现代像素标准 | 多数现代独立 2D RPG | **俯视 RPG 甜区（推荐）** |
| 48×48 | 半写实像素 | RPG Maker MV/MZ | 强叙事、半写实 |
| 64×64 | HD 像素/精致 | 部分精致独立作 | 异兽特写、BOSS |

### 俯视角 vs 侧视角

| 维度 | 俯视角 | 侧视角（Terraria 式） |
|------|--------|---------------------|
| tile 宽高比 | 正方形 1:1 | 正方形为主，角色常竖长 |
| 角色 sprite | 约 1.5-2 tile 高 | 2-3 tile 高 |
| 地形表达 | autotile 过渡 | 分层 + 挖掘破坏 |
| 适配本项目 | **推荐优先** | 长线可选 |

美术方向（动漫+半写实+荒野）更契合俯视角（角色辨识度需求高于挖掘物理），建议俯视优先。

---

## 色彩规范

### 推荐色板：Endesga 16

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

---

## AI 素材生成规范

### 工具选型

| 工具 | 适用 | 商用授权 |
|------|------|---------|
| Stable Diffusion (SDXL / SD1.5) | tileset、sprite、概念图 | 模型开源，生成图商用取决于 checkpoint/LoRA 许可 |
| Midjourney | 概念图、氛围图、立绘 | 付费订阅可商用 |
| ControlNet | 一致性控制（轮廓/姿势/深度） | 随 SD |
| LoRA | 风格锁定 | 取决于 LoRA 许可 |

### 风格一致性方法

1. **训练项目专属 LoRA**：用 20-50 张统一风格目标图训练 `shanhaijing-style` LoRA
2. **固定 sampler 与尺寸**：启用像素专用 LoRA（如 `pixelart-xl-v2`），采样尺寸固定为 64/128/256
3. **ControlNet 锁结构**：生成异兽多角度时，用 OpenPose/线稿 ControlNet 锁定骨架
4. **限定色板**：prompt 中加入 `limited palette of 16 colors` 强制色彩收敛
5. **后处理流水线**：AI 直出像素图必须后处理 — 降色到固定 16/32 色板、去半透明像素、手动修描轮廓、切片为 sprite sheet

### Prompt 模板（6 段式）

```
[主体] {creature_name}, {山海经原文特征描述英文翻译},
[风格] semi-realistic eastern pixel art, anime-influenced, 32px tile aesthetic,
       ink-wash and cel-shaded hybrid, wilderness survival atmosphere,
[色板] limited palette of 16 colors, jade green and cinnabar red accents, misty cool tones,
[构图] front-facing, full body, centered, plain background, sprite sheet ready,
[技术] pixelart-xl-v2 lora, <lora:shanhaijing-style:0.8>,
[负向] nsfw, blur, anti-aliasing, smooth gradients, photorealistic, watermark, text
```

### 版权要点

- 多数司法辖区不认可纯 AI 生成物的著作权，需有人工实质性修改才能主张版权
- Steam 2024 起要求申报 AI 使用，需保留 AI 生成记录
- 项目开源属性：所有 AI 素材的 prompt、seed、模型版本应记录在 `docs/` 下，确保可复现、可审计

---

## 角色参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| LPC Medieval fantasy character sprites | https://opengameart.org/content/lpc-medieval-fantasy-character-sprites | LPC 像素，俯视角 64×64，模块化，4 方向行走 | CC-BY-SA 3.0 / GPL 3.0 | 角色底座，模块化捏脸 | SA 传染性，商业项目需法务评估 |
| Kenney Roguelike Characters | https://kenney.nl/assets/roguelike-characters | 极简像素，俯视角，450 文件 | CC0 | MVP 占位，零风险 | 过于 Q 版，正式版需替换 |
| CraftPix Tribal Warrior Boss (免费) | https://craftpix.net/freebies/free-tribal-warrior-boss-characters-asset-pack/ | 矢量卡通，俯视角 4 方向，3 个部落首领 | 免费商用（署名 craftpix.net） | 部落首领/祭祀主持者，矢量可改色东方化 | 偏明亮，需调色降饱和 |
| CraftPix Shinobi Sprites (免费) | https://craftpix.net/freebies/free-shinobi-sprites-pixel-art/ | 像素，东方忍者 | 免费商用（署名） | 最接近日系动漫风 | 像素风偏卡通 |
| CraftPix Swordsman 1-3 Level (免费) | https://craftpix.net/freebies/free-swordsman-1-3-level-pixel-top-down-sprite-character-pack/ | 像素，俯视角 | 免费商用（署名） | 山野旅人/剑客占位 | 风格偏通用 |
| CraftPix Necromancer (免费) | https://craftpix.net/freebies/free-necromancer-pixel-art-prototype-character-sprites/ | 像素 | 免费商用（署名） | 巫祝/祭祀者 | 风格偏暗黑 |
| PIPOYA Free RPG Character Sprites | https://pipoya.itch.io/pipoya-free-rpg-character-sprites | 像素，俯视角 RPG | 待确认 | 免费俯视角角色 | 需打开确认授权 |
| LPC Character Generator | https://pflat.itch.io/lpc-character-generator | LPC 像素角色生成器 | 待确认（LPC 衍生） | 批量生成不同种族角色 | 继承 SA 传染性 |

---

## 生物 / 异兽参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| Dragon Fully Animated | https://opengameart.org/content/dragon-fully-animated | 2D 骨骼动画，60fps，完整动画 | CC0 | 龙/蛇形异兽（应龙、蛟、巴蛇）顶级免费参考 | 偏西方龙，需东方化改造 |
| 10 basic rpg enemies | https://opengameart.org/content/10-basic-rpg-enemies | FF6 风像素，侧视图 | CC-BY 3.0 / OGA-BY 3.0 | 异兽战斗立绘参考，商业友好 | 侧视图非俯视角 |
| LPC Wolf Animation | https://opengameart.org/content/lpc-wolf-animation | LPC 像素，俯视角 | CC-BY-SA 3.0 | 山林野兽直接可用 | SA 传染性 |
| LPC Horses Rework | https://opengameart.org/content/lpc-horses-rework | LPC 像素，俯视角 | CC-BY-SA 3.0 | 鹿形生物改造底座 | SA 传染性 |
| OGA Centaur | https://opengameart.org/content/centaur-0 | 像素 | 逐页确认 | 人面兽身/兽面人身结构参考 | 授权需确认 |
| CraftPix Ancient Mythology Boss (付费) | https://craftpix.net/product/ancient-mythology-boss-characters-top-down-asset-pack/ | 矢量卡通，俯视角，3 个神话 Boss | 付费可商用 | 牛头人=兽面人身原型，法老=古代王权 | 宙斯偏希腊需替换 |
| CraftPix Top-Down Pixel Ent (付费) | https://craftpix.net/product/top-down-pixel-ent-character-sprites/ | 像素，俯视角 | 付费可商用 | 树人=草木成精异兽 | 付费 |
| CraftPix Dragon Sprite Sheets (付费) | https://craftpix.net/product/dragon-pixel-art-character-sprite-sheets-pack/ | 像素 | 付费可商用 | 龙/蛇形异兽 | 付费 |
| CraftPix Anime Demon (付费) | https://craftpix.net/product/anime-demon-sprite-sheet-pixel-art-pack/ | 动漫风像素 | 付费可商用 | 接近"半写实动漫"目标 | 付费 |
| CraftPix Slime Mobs (免费) | https://craftpix.net/freebies/free-slime-mobs-pixel-art-top-down-sprite-pack/ | 像素，俯视角 | 免费商用（署名） | 黏液异兽/沼泽生物 | 风格偏卡通 |
| CraftPix Wraith (免费) | https://craftpix.net/freebies/free-wraith-tiny-style-2d-sprites/ | 像素 | 免费商用（署名） | 幽魂/精怪 | 风格偏暗 |
| OGA Temple and Ruins Assets | https://opengameart.org/content/temple-and-ruins-assets | 多种风格 | 逐包确认 | 古代祭坛/神殿废墟 | 授权需逐包核对 |

### 按山海经异兽类型匹配

| 异兽类型 | 首选素材 | 说明 |
|---------|---------|------|
| 狌狌（猿猴类） | 需自制/AI 生成 | 免费素材中猿猴类稀缺，这是缺口 |
| 鹿形生物 | LPC Horses 改造 | 鹿形需以马/兽类底座改造 |
| 鸟兽 | OGA Flappy Dragon + 自制 | 鸟形异兽（精卫、鸾凤）免费素材偏少 |
| 蛇形生物 | Cethiel Dragon CC0 改造 | 龙/蛇是覆盖最好的类型 |
| 兽面人身/人面兽身 | CraftPix 牛头人 + OGA 半人马 | 半人马结构直接参考 |
| 草木成精 | CraftPix Top-Down Pixel Ent | 树人直接对应 |
| 山野旅人/部落 | CraftPix Tribal Warrior + Shinobi | 部落+东方忍者最贴合 |
| 祭祀/巫祝 | CraftPix Necromancer/Lich | 祭祀系统角色 |

---

## 场景 / TileSet 参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| RPG Nature Tileset | https://stealthix.itch.io/rpg-nature-tileset | 俯视角自然地形 | CC0 | 草地/树林/水/岩石直接可用 | 风格偏写实非纯动漫 |
| LPC Tile Atlas | https://opengameart.org/content/lpc-tile-atlas | 32×32 俯视角，自然元素全覆盖 | CC-BY-SA 3.0 + GPL 3.0 | 体系最完整的免费自然 TileSet | SA 传染性 + GPL 打包义务 |
| Kenney Tiny Town | https://kenney.nl/assets/tiny-town | 16×16 像素，130 文件 | CC0 | 俯视角 overworld 占位 | 抽象简洁，缺荒野质感 |
| Kenney Roguelike/RPG Pack | https://kenney.nl/assets/roguelike-rpg-pack | 16×16 像素，1700 文件 | CC0 | RPG/城镇/家具/UI 一体 | 风格偏抽象像素 |
| CraftPix Ruined Temple (免费) | https://craftpix.net/freebies/free-ruined-temple-top-down-location-pixel-art/ | 像素，俯视角 | 免费商用（署名） | 古代祭坛/神殿废墟，高度契合 | 需东方化改造 |
| CraftPix Path and Road (免费) | https://craftpix.net/freebies/free-path-and-road-top-down-pixel-tileset/ | 像素，俯视角 | 免费商用（署名） | 山路/道路 | 像素风偏卡通 |
| CraftPix Poison Swamp (免费) | https://craftpix.net/freebies/free-poison-swamp-game-tileset-and-environment-pack/ | 像素，俯视角 | 免费商用（署名） | 荒野/沼泽，神秘荒野感 | 需配色调整 |
| CraftPix Simple Summer (免费) | https://craftpix.net/freebies/free-simple-summer-top-down-vector-tileset/ | 矢量，俯视角 | 免费商用（署名） | 自然草地/夏日户外 | 矢量非像素 |
| CraftPix Chapel (免费) | https://craftpix.net/freebies/free-chapel-pixel-art-top-down-asset-pack/ | 像素，俯视角 | 免费商用（署名） | 古代建筑内部，可改作祭坛室内 | 需东方化 |
| CraftPix Guild Hall (免费) | https://craftpix.net/freebies/free-top-down-pixel-art-guild-hall-asset-pack/ | 像素，俯视角 | 免费商用（署名） | 室内场景/营地建筑 | 需东方化 |
| OGA Forest Tiles | https://opengameart.org/content/forest-tiles | 多种风格 | 逐包确认 | 山林场景 | 授权需确认 |
| OGA 16x16 Forest Tiles | https://opengameart.org/content/16x16-forest-tiles | 16×16 像素 | 逐包确认 | 复古山林 | 授权需确认 |
| OGA Trees Mega Pack | https://opengameart.org/content/trees-mega-pack-cc-by-30-0 | 手绘 | CC-BY 3.0 | 树木量大 | 需统一风格 |

---

## UI / 图标参考

| 名称 | 链接 | 风格 | 授权 | 适合点 | 风险 |
|------|------|------|------|--------|------|
| game-icons.net | https://game-icons.net/ | 矢量单色 SVG，4180+ 图标 | CC BY 3.0 | 草药/矿石/木材/药剂图标首选，含 Animal(188)/Creature(122)/Symbol(173) | 单色矢量，需上色匹配像素 UI |
| OGA 496 pixel art icons | https://opengameart.org/content/496-pixel-art-icons-for-medievalfantasy-rpg | 32×32 像素 | CC0 | CC0 最安全，食物/武器/护甲/法术齐全 | 中世纪西式风格 |
| OGA 700+ RPG Icons | https://opengameart.org/content/700-rpg-icons | 像素 | 逐包确认 | 量大 | 授权需确认 |
| OGA 98 Pixel Art RPG Icons | https://opengameart.org/content/98-pixel-art-rpg-icons | 像素 | 逐包确认 | 精选 | 授权需确认 |
| Kenney UI Pack - Adventure | https://kenney.nl/assets/ui-pack-adventure | 扁平，130 文件 | CC0 | 冒险主题按钮/面板/滑块 | 通用扁平风，非古朴纸张风 |
| Kenney UI Pack - Pixel Adventure | https://kenney.nl/assets/ui-pack-pixel-adventure | 像素 | CC0 | 与像素 TileSet 风格统一 | 通用像素 UI |
| OGA RPG GUI construction kit | https://opengameart.org/content/rpg-gui-construction-kit-v10 | 多种风格 | 逐包确认 | RPG UI 框架 | 授权需确认 |
| OGA Painterly Spell Icons | https://opengameart.org/content/painterly-spell-icons-part-1 | 手绘 | 逐包确认 | 法术图标 | 授权需确认 |

### UI 风格缺口

现有素材均为通用冒险/西式 RPG UI，**无直接匹配的古朴纸张/竹简/山海经书卷风 UI**。建议：
- 用 Kenney UI 框架（CC0）做骨架
- 自制宣纸/竹简纹理覆盖
- 使用篆隶字体做东方化改造

---

## 授权风险矩阵

| 授权 | 传染性 | 商用 | 代表素材 | 建议 |
|------|--------|------|---------|------|
| CC0 | 无 | 完全自由 | Kenney 全系、Cethiel Dragon、496 图标、stealthix Tileset | **优先采用** |
| CC-BY / OGA-BY | 无 | 需署名 | 10 basic rpg enemies、game-icons.net | 商业友好，推荐 |
| CraftPix 免费 | 无 | 需署名 craftpix.net | Tribal Warrior、Shinobi、Slime、Ruined Temple 等 | 推荐，注意署名 |
| CraftPix 付费 | 无 | 购买后商用 | Ancient Mythology Boss、Ent、Dragon | 预算允许则采用 |
| CC-BY-SA / GPL | **有** | 争议 | LPC 全套、Wolf、Goblin | **商业项目慎用** |

---

## 初步推荐组合

### 方案 A：CC0 零风险组合（MVP 阶段首选）

| 用途 | 素材 | 授权 |
|------|------|------|
| 自然地形 | stealthix RPG Nature Tileset | CC0 |
| 占位角色 | Kenney Roguelike Characters | CC0 |
| 龙/蛇异兽 | Cethiel Dragon (OGA 标清版) | CC0 |
| 物品图标 | OGA 496 pixel art icons | CC0 |
| UI 框架 | Kenney UI Pack - Adventure | CC0 |
| 草药/矿石符号 | game-icons.net | CC BY 3.0 |

优点：零授权风险，可快速搭出可玩原型。缺点：风格不统一（Kenney 极简 + Dragon 精致 + 图标中世纪），需大量二改或 AI 生成补齐东方神话风格。

### 方案 B：CraftPix 东方化组合（正式版基础）

| 用途 | 素材 | 授权 |
|------|------|------|
| 山路/祭坛/沼泽 | CraftPix Path + Ruined Temple + Poison Swamp | 免费商用（署名） |
| 部落首领/祭祀 | CraftPix Tribal Warrior Boss | 免费商用（署名） |
| 东方角色 | CraftPix Shinobi + Swordsman | 免费商用（署名） |
| 异兽底座 | CraftPix Ancient Mythology Boss (付费) + Ent (付费) | 付费可商用 |
| UI 框架 | Kenney UI Pack + 东方化纹理改造 | CC0 |

优点：俯视角匹配度高，矢量可改色东方化。缺点：部分付费，矢量卡通需调色降饱和适配荒野感。

### 方案 C：AI 生成 + CC0 底座混合（风格统一最优）

| 用途 | 方案 |
|------|------|
| 底座/占位 | 方案 A 的 CC0 素材 |
| 角色/异兽 | SDXL + shanhaijing-style LoRA + Endesga 16 色板 + ControlNet |
| 场景变体 | AI 生成 tile 变体 + 手动修描 |
| UI | Kenney 框架 + AI 生成宣纸/竹简纹理 |

优点：风格统一度最高，可精准匹配"半写实东方像素"定位。缺点：需训练 LoRA，AI 生成物需人工后处理定稿。

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
- Eastward — 参考动漫感像素角色处理与光影密度

### 必须自制/AI 生成

- 猿猴类异兽（狌狌）— 免费素材空白
- 东方鸟兽（精卫、鸾凤）— 免费素材偏少
- 古朴纸张/竹简/山海经书卷风 UI — 现有素材均不匹配
- 纯正东方神话造型 — 需基于山海经原文自制

### 下一步行动

1. 确定美术风格（像素 vs 半写实动漫）以锁定素材方向
2. 人工打开 itch.io 链接核验授权
3. 用 SDXL + Endesga 16 色板 + prompt 模板生成招摇山场景测试 tile
4. 训练 shanhaijing-style LoRA 统一风格
5. 在 `docs/山海经附录5-工程路线图.md` 落定尺寸标准与色板
