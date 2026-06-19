# 典籍数据提取索引

> 从 45 部古典典籍中提取的游戏结构化数据索引。
> 提取日期：2026-06-19
> 提取方法：逐部典籍全文读取，提取有明确名称、功效、用途的条目

---

## 数据文件

| 文件 | 内容 | 条目数 | 来源典籍 |
|------|------|--------|---------|
| [extract_medicine_cultivation.json](extract_medicine_cultivation.json) | 草药、方剂、修仙功法、异兽、材料 | 102 | 神农本草经、伤寒论、抱朴子内篇、养性延命录、登真隐诀、坐忘论等 23 部 |
| [extract_sacrifice_craft_survival.json](extract_sacrifice_craft_survival.json) | 祭祀、工具/武器、材料、建筑、异兽、植物 | 196 | 古今刀剑录、南方草木状、搜神记、博物志、周礼、礼记、楚辞等 15 部 |
| [extract_farming_shanhai.json](extract_farming_shanhai.json) | 作物、牲畜、农具、耕作技术、山海经异兽/植物/矿物 | 221 | 齐民要术、氾胜之书等 7 部农牧典籍 + 山海经原文 18 卷 |

**总计：519 条结构化数据条目**

---

## 各文件详细条目统计

### extract_medicine_cultivation.json

| 类别 | 数量 | 主要来源 |
|------|------|---------|
| herbs（草药） | 42 | 神农本草经（上品玉石/草/木/虫兽/米谷部、中品草/玉石部） |
| prescriptions（方剂） | 21 | 伤寒论（桂枝汤、麻黄汤、大小青龙汤、大小柴胡汤等） |
| cultivation_techniques（修仙功法） | 20 | 抱朴子内篇（15）、养性延命录（3）、坐忘论（1）、登真隐诀（5） |
| creatures（异兽/神灵） | 11 | 抱朴子内篇（千岁龟、千岁鹤、麒麟、狐狸等） |
| materials（矿物/材料） | 8 | 抱朴子内篇（7）、登真隐诀（1） |

### extract_sacrifice_craft_survival.json

| 类别 | 数量 | 主要来源 |
|------|------|---------|
| sacrifices（祭祀） | 18 | 周礼、礼记、仪礼、楚辞、搜神记、周氏冥通记 |
| tools_weapons（工具/武器） | 32 | 古今刀剑录（28 把名剑名刀）、天工开物、博物志 |
| materials（材料） | 66 | 南方草木状（38）、博物志（15）、古今刀剑录（8） |
| buildings（建筑） | 10 | 营造法式（6）、博物志（2）、南方草木状（2） |
| creatures（异兽/神灵） | 37 | 搜神记（20）、博物志（17） |
| plants（植物） | 33 | 南方草木状（25）、博物志（5）、搜神记（3） |

### extract_farming_shanhai.json

| 类别 | 数量 | 主要来源 |
|------|------|---------|
| crops（作物） | 20 | 齐民要术、氾胜之书、农政全书 |
| livestock（牲畜） | 8 | 齐民要术、相马经 |
| farm_tools（农具） | 6 | 齐民要术、王祯农书 |
| farming_techniques（耕作技术） | 8 | 氾胜之书、齐民要术、陈旉农书 |
| shanhai_creatures（山海经异兽） | 97 | 山海经原文 18 卷 |
| shanhai_plants（山海经植物） | 54 | 山海经原文 18 卷 |
| shanhai_minerals（山海经矿物） | 28 | 山海经原文 18 卷 |

---

## 各典籍数据价值评估

### 高价值（大量可提取条目）

| 典籍 | 条目数 | 价值 |
|------|--------|------|
| 山海经原文 | 179 | 异兽/植物/矿物，游戏核心数据源 |
| 神农本草经 | 42 | 草药体系，医药科技树基础 |
| 南方草木状 | 38+25 | 植物+材料，南方生态数据 |
| 古今刀剑录 | 28+8 | 武器名录，工匠科技树核心 |
| 搜神记 | 20+2+3+5 | 神灵异兽+祭祀+材料，神话内容 |
| 博物志 | 17+15+2 | 异兽+材料+建筑 |
| 伤寒论 | 21 | 方剂体系，医药科技树核心 |
| 抱朴子内篇 | 15+7+11 | 修仙功法+材料+异兽，修仙科技树核心 |

### 中等价值（部分可提取条目）

| 典籍 | 条目数 | 价值 |
|------|--------|------|
| 齐民要术 | 10+ | 作物/牲畜/农具/技术，农牧科技树 |
| 天工开物 | 4 | 工具/材料（节选缺少五金冶铸等章） |
| 周礼 | 6 | 祭祀仪式，祭祀科技树 |
| 礼记 | 4 | 祭祀规则 |
| 登真隐诀 | 5+1 | 修仙功法+材料 |
| 养性延命录 | 3 | 修仙功法 |
| 楚辞 | 3 | 楚地祭祀文化 |

### 低价值（主要为理论论述）

| 典籍 | 原因 |
|------|------|
| 黄帝内经 | 纯医学理论，无具体药方条目 |
| 道德经 | 哲学论述，无具体功法条目 |
| 周易参同契 | 炼丹理论，隐喻过多难以结构化 |
| 庄子 | 哲学寓言，无具体条目 |
| 真诰 | 仙真降授记录，可提取内容少 |
| 黄庭经 | 存思法门，在登真隐诀中已提取 |
| 尔雅 | 词典性质，缺乏功效描述 |
| 营造法式 | 仅为目录和制度概述 |
| 希波克拉底文集 | 西方医学，与东方游戏体系不兼容 |
| 盖伦著作 | 西方医学，与东方游戏体系不兼容 |

---

## 数据使用说明

### 与附录5 JSON Schema 的对应关系

| 提取数据类别 | 对应 Schema | 说明 |
|-------------|-----------|------|
| herbs | items.json (type: herb) | 草药条目可直接转为物品数据 |
| prescriptions | recipes.json (type: medicine) | 方剂条目可直接转为配方数据 |
| cultivation_techniques | tech_nodes.json (branch: cultivation) | 修仙功法可转为科技节点 |
| shanhai_creatures | creatures.json | 山海经异兽可直接转为异兽数据 |
| shanhai_plants | items.json (type: herb/tree) | 山海经植物可直接转为物品数据 |
| shanhai_minerals | items.json (type: mineral) | 山海经矿物可直接转为物品数据 |
| sacrifices | sacrifice_rules.json (Phase 3) | 祭祀条目留待祭祀系统 |
| tools_weapons | items.json (type: equipment) | 武器可直接转为装备数据 |
| materials | items.json (type: material) | 材料可直接转为物品数据 |
| crops | tech_nodes.json (branch: farming) | 作物可转为农牧科技节点 |
| livestock | creatures.json (type: domestic) | 牲畜可转为可驯服异兽数据 |
| farm_tools | items.json (type: tool) | 农具可转为物品数据 |
| farming_techniques | tech_nodes.json (branch: farming) | 耕作技术可转为科技节点 |
| buildings | (新增 buildings.json) | 建筑数据需新增 schema |

### ID 命名规则

提取数据中的 id 已按以下规则生成：
- 神农本草经：`shennong_` + 拼音（如 `shennong_dansha`）
- 伤寒论方剂：`shanghan_` + 方名拼音（如 `shanghan_guizhi_tang`）
- 山海经异兽：使用描述性拼音（如 `shengjing`、`jiuweihu`）
- 武器：`weapon_` + 名称拼音（如 `weapon_longquan`）
- 其余：`来源简称_` + 拼音

进入 Phase 0 后，需将提取数据的 id 统一为附录5 定义的命名规范。
