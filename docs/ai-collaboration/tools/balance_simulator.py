#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
山海经项目 - 数值平衡仿真器
============================
用途：对山海经游戏的知识图谱数据进行数值平衡仿真分析，
     检测科技树可达性、材料经济平衡、战力曲线匹配度、食物链压力等。

用法：
    python balance_simulator.py

输出：
    在同目录下生成 balance_report.md 仿真报告。

依赖：仅使用 Python 标准库（json, os, collections, re）。
"""

import json
import os
import re
from collections import defaultdict, deque


# ============================================================================
# 工具函数
# ============================================================================

def load_json(path):
    """加载 JSON 文件，失败时返回空字典并打印警告。"""
    if not os.path.exists(path):
        print(f"[警告] 文件不存在: {path}")
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def ensure_dir(path):
    """确保目录存在。"""
    d = os.path.dirname(path)
    if d and not os.path.exists(d):
        os.makedirs(d, exist_ok=True)


# ============================================================================
# 路径配置（相对于本脚本所在目录）
# ============================================================================

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# 知识图谱 full-data.json 位于 ai-collaboration/knowledge-graph/
KG_PATH = os.path.join(SCRIPT_DIR, "..", "knowledge-graph", "full-data.json")
# data 目录下的 4 个 JSON 文件
DATA_DIR = os.path.join(SCRIPT_DIR, "..", "..", "data")
DATA_FILES = [
    os.path.join(DATA_DIR, "extract_farming_shanhai.json"),
    os.path.join(DATA_DIR, "extract_medicine_cultivation.json"),
    os.path.join(DATA_DIR, "extract_sacrifice_craft_survival.json"),
    os.path.join(DATA_DIR, "tiangong_full_extract.json"),
]
# 附录6（完整科技线）用于战力曲线参考
APPENDIX6_PATH = os.path.join(SCRIPT_DIR, "..", "..", "山海经附录6-完整科技线.md")
# 输出报告路径
REPORT_PATH = os.path.join(SCRIPT_DIR, "balance_report.md")


# ============================================================================
# 稀有度配置
# ============================================================================

RARITY_ACQUISITION_RATE = {
    "common": 1.0,       # 每分钟 1 个
    "uncommon": 1 / 5,   # 每 5 分钟 1 个
    "rare": 1 / 30,      # 每 30 分钟 1 个
    "epic": 1 / 120,     # 每 2 小时 1 个
    "legendary": 1 / 1440,  # 每 24 小时 1 个
}

RARITY_LABEL_CN = {
    "common": "普通",
    "uncommon": "精良",
    "rare": "稀有",
    "epic": "史诗",
    "legendary": "传说",
}

RARITY_COMBAT_MULTIPLIER = {
    "common": 1.0,
    "uncommon": 1.5,
    "rare": 2.5,
    "epic": 5.0,
    "legendary": 10.0,
}

# 科技层级对应的战力基准（玩家）
TIER_COMBAT_BASE = {
    1: 10,
    2: 30,
    3: 80,
    4: 200,
    5: 500,
}


# ============================================================================
# 1. 科技树可达性仿真
# ============================================================================

def simulate_tech_tree(techniques):
    """
    模拟科技树可达性：
    - 从起始节点（无前置条件）开始 BFS
    - 检测死锁（循环依赖、不可达节点）
    - 计算从起点到每个节点的最短路径
    - 输出拓扑图和关键路径
    """
    report_lines = []
    report_lines.append("# 一、科技树可达性仿真\n")

    if not techniques:
        report_lines.append("> 无科技节点数据，跳过此模块。\n")
        return report_lines, {}

    # 构建图：节点 -> 前置（同分支 + 跨分支）
    tech_map = {}
    for t in techniques:
        tech_map[t["id"]] = t

    # 构建邻接表（前置 -> 后继）
    prereq_graph = defaultdict(list)   # node -> list of nodes that depend on it
    all_prereqs = defaultdict(set)   # node -> set of prerequisite nodes

    for t in techniques:
        tid = t["id"]
        for p in t.get("prerequisites", []):
            prereq_graph[p].append(tid)
            all_prereqs[tid].add(p)
        for p in t.get("crossBranchPrereqs", []):
            prereq_graph[p].append(tid)
            all_prereqs[tid].add(p)

    # BFS 计算最短路径
    start_nodes = [t["id"] for t in techniques if not all_prereqs[t["id"]]]
    dist = {}
    queue = deque()

    for s in start_nodes:
        dist[s] = 0
        queue.append(s)

    while queue:
        node = queue.popleft()
        for neighbor in prereq_graph[node]:
            new_dist = dist[node] + 1
            if neighbor not in dist or new_dist < dist[neighbor]:
                dist[neighbor] = new_dist
                queue.append(neighbor)

    # 检测不可达节点
    unreachable = [tid for tid in tech_map if tid not in dist]

    # 检测循环依赖（DFS 检测环）
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {tid: WHITE for tid in tech_map}
    cycles = []

    def dfs_cycle(node, path):
        color[node] = GRAY
        path.append(node)
        for prereq in all_prereqs[node]:
            if prereq not in tech_map:
                continue
            if color[prereq] == GRAY:
                cycle_start = path.index(prereq)
                cycles.append(path[cycle_start:] + [prereq])
            elif color[prereq] == WHITE:
                dfs_cycle(prereq, path)
        path.pop()
        color[node] = BLACK

    for tid in tech_map:
        if color[tid] == WHITE:
            dfs_cycle(tid, [])

    # 输出起始节点
    report_lines.append("## 1.1 起始节点（无前置条件）\n")
    for s in start_nodes:
        t = tech_map[s]
        branch_cn = _branch_cn(t.get("branch", ""))
        report_lines.append(f"- `{s}` ({t['name']}) - 分支: {branch_cn}\n")

    # 输出最短路径
    report_lines.append("\n## 1.2 各节点最短路径（最少前置步骤）\n")
    report_lines.append("| 节点ID | 名称 | 分支 | 层级 | 最短路径 | 状态 |\n")
    report_lines.append("|--------|------|------|------|----------|------|\n")
    for t in sorted(techniques, key=lambda x: (x.get("branch", ""), x.get("tier", 0))):
        tid = t["id"]
        branch_cn = _branch_cn(t.get("branch", ""))
        d = dist.get(tid, -1)
        if tid in unreachable:
            status = "!! 不可达"
        else:
            status = "可达"
        report_lines.append(
            f"| {tid} | {t['name']} | {branch_cn} | {t.get('tier', '?')} | {d if d >= 0 else 'N/A'} | {status} |\n"
        )

    # 输出死锁/循环依赖
    report_lines.append("\n## 1.3 死锁检测\n")
    if cycles:
        report_lines.append("**发现循环依赖：**\n")
        for i, cycle in enumerate(cycles, 1):
            names = [tech_map.get(n, {}).get("name", n) for n in cycle]
            report_lines.append(f"{i}. {' -> '.join(names)}\n")
    else:
        report_lines.append("未发现循环依赖。\n")

    if unreachable:
        report_lines.append("\n**不可达节点：**\n")
        for tid in unreachable:
            t = tech_map[tid]
            report_lines.append(f"- `{tid}` ({t['name']}) - 前置: {all_prereqs[tid]}\n")
    else:
        report_lines.append("\n所有节点均可达。\n")

    # 输出拓扑图（按分支分组）
    report_lines.append("\n## 1.4 科技树拓扑图\n")
    report_lines.append("```mermaid\ngraph TD\n")

    # 按分支分组输出
    branches = defaultdict(list)
    for t in techniques:
        branches[t.get("branch", "unknown")].append(t)

    branch_colors = {
        "survival": "#4CAF50",
        "medicine": "#2196F3",
        "cultivation": "#9C27B0",
        "sacrifice": "#FF9800",
        "craft": "#795548",
        "farming": "#8BC34A",
    }

    for branch, techs in sorted(branches.items()):
        color = branch_colors.get(branch, "#999")
        for t in techs:
            tid = t["id"]
            label = t["name"]
            report_lines.append(f"    {tid}[{label}]\n")

    report_lines.append("\n")
    for t in techniques:
        tid = t["id"]
        for p in t.get("prerequisites", []):
            report_lines.append(f"    {p} --> {tid}\n")
        for p in t.get("crossBranchPrereqs", []):
            report_lines.append(f"    {p} -.->|跨分支| {tid}\n")

    report_lines.append("```\n")

    # 关键路径（最长路径）
    report_lines.append("\n## 1.5 关键路径（最长解锁链）\n")
    max_dist = max(dist.values()) if dist else 0
    critical = [(tid, d) for tid, d in dist.items() if d == max_dist]
    if critical:
        report_lines.append(f"最长路径长度: **{max_dist} 步**\n")
        report_lines.append("关键终点节点:\n")
        for tid, d in critical:
            t = tech_map.get(tid, {})
            report_lines.append(f"- `{tid}` ({t.get('name', tid)})\n")

        # 回溯一条关键路径
        for end_tid, _ in critical[:1]:
            path = _trace_path(end_tid, all_prereqs, dist, tech_map)
            if path:
                report_lines.append("\n关键路径示例:\n")
                names = [tech_map.get(n, {}).get("name", n) for n in path]
                report_lines.append(" -> ".join(f"`{n}`" for n in names) + "\n")
    else:
        report_lines.append("无关键路径数据。\n")

    report_lines.append("\n")

    return report_lines, tech_map


def _branch_cn(branch):
    """分支英文名转中文。"""
    mapping = {
        "survival": "生存",
        "medicine": "医药",
        "cultivation": "修仙",
        "sacrifice": "祭祀",
        "craft": "工匠",
        "farming": "农牧",
    }
    return mapping.get(branch, branch)


def _trace_path(end_node, all_prereqs, dist, tech_map):
    """从终点回溯最短路径。"""
    path = [end_node]
    current = end_node
    while dist.get(current, 0) > 0:
        prereqs = [p for p in all_prereqs.get(current, set()) if p in dist]
        if not prereqs:
            break
        # 选择距离最近的先驱
        best = min(prereqs, key=lambda p: dist.get(p, 999))
        path.append(best)
        current = best
    path.reverse()
    return path


# ============================================================================
# 2. 材料经济仿真
# ============================================================================

def simulate_material_economy(kg_data, data_files_data):
    """
    模拟材料经济平衡：
    - 统计所有材料（creatures, plants, minerals）的稀有度
    - 模拟获取速率
    - 模拟消耗速率（基于科技节点需求）
    - 计算供需平衡
    """
    report_lines = []
    report_lines.append("# 二、材料经济仿真\n")

    # 收集所有实体
    creatures = kg_data.get("creatures", [])
    plants = kg_data.get("plants", [])
    minerals = kg_data.get("minerals", [])
    techniques = kg_data.get("techniques", [])

    # 构建材料稀有度映射
    material_rarity = {}
    material_name = {}

    for c in creatures:
        material_rarity[c["id"]] = c.get("rarity", "common")
        material_name[c["id"]] = c.get("name", c["id"])
    for p in plants:
        material_rarity[p["id"]] = p.get("rarity", "common")
        material_name[p["id"]] = p.get("name", p["id"])
    for m in minerals:
        material_rarity[m["id"]] = m.get("rarity", "common")
        material_name[m["id"]] = m.get("name", m["id"])

    # 从 data 文件中补充材料
    for df in data_files_data:
        for key in ("herbs", "materials", "creatures", "cultivation_techniques"):
            for item in df.get(key, []):
                item_id = item.get("id", "")
                if item_id and item_id not in material_rarity:
                    # 根据来源书推断稀有度
                    rarity = _infer_rarity_from_source(item)
                    material_rarity[item_id] = rarity
                    material_name[item_id] = item.get("name", item_id)

    # 统计科技节点对材料的需求
    material_demand_count = defaultdict(int)
    for t in techniques:
        for mat in t.get("materials", []):
            material_demand_count[mat] += 1

    # 计算供需
    report_lines.append("## 2.1 材料供需平衡表\n")
    report_lines.append("| 材料ID | 名称 | 稀有度 | 获取速率(个/时) | 需求次数 | 供需比 | 状态 |\n")
    report_lines.append("|--------|------|--------|----------------|----------|--------|------|\n")

    supply_demand_results = []
    all_material_ids = set(material_rarity.keys()) | set(material_demand_count.keys())

    for mid in sorted(all_material_ids):
        name = material_name.get(mid, mid)
        rarity = material_rarity.get(mid, "common")
        rate_per_min = RARITY_ACQUISITION_RATE.get(rarity, 1.0)
        rate_per_hour = rate_per_min * 60
        demand = material_demand_count.get(mid, 0)

        if demand == 0:
            ratio = float("inf")
            status = "无需求"
        elif rate_per_hour == 0:
            ratio = 0
            status = "!! 无法获取"
        else:
            ratio = rate_per_hour / demand

        if demand > 0:
            if ratio < 1:
                status = "!! 稀缺"
            elif ratio > 10:
                status = "过剩"
            else:
                status = "平衡"

        supply_demand_results.append({
            "id": mid, "name": name, "rarity": rarity,
            "rate_per_hour": rate_per_hour, "demand": demand,
            "ratio": ratio, "status": status,
        })

        ratio_str = f"{ratio:.2f}" if ratio != float("inf") else "inf"
        rarity_cn = RARITY_LABEL_CN.get(rarity, rarity)
        report_lines.append(
            f"| {mid} | {name} | {rarity_cn} | {rate_per_hour:.2f} | {demand} | {ratio_str} | {status} |\n"
        )

    # 稀缺材料汇总
    report_lines.append("\n## 2.2 稀缺材料（需求 > 供给）\n")
    scarce = [r for r in supply_demand_results if r["status"] == "!! 稀缺" or r["status"] == "!! 无法获取"]
    if scarce:
        for r in scarce:
            report_lines.append(
                f"- **{r['name']}** ({r['id']}): 稀有度={RARITY_LABEL_CN.get(r['rarity'], r['rarity'])}, "
                f"获取速率={r['rate_per_hour']:.2f}/时, 需求次数={r['demand']}\n"
            )
    else:
        report_lines.append("无稀缺材料。\n")

    # 过剩材料汇总
    report_lines.append("\n## 2.3 过剩材料（供给 > 需求 x 10）\n")
    surplus = [r for r in supply_demand_results if r["status"] == "过剩"]
    if surplus:
        for r in surplus:
            report_lines.append(
                f"- **{r['name']}** ({r['id']}): 稀有度={RARITY_LABEL_CN.get(r['rarity'], r['rarity'])}, "
                f"获取速率={r['rate_per_hour']:.2f}/时, 需求次数={r['demand']}\n"
            )
    else:
        report_lines.append("无过剩材料。\n")

    # 按稀有度统计
    report_lines.append("\n## 2.4 稀有度分布统计\n")
    rarity_stats = defaultdict(lambda: {"count": 0, "demanded": 0})
    for r in supply_demand_results:
        rarity_stats[r["rarity"]]["count"] += 1
        if r["demand"] > 0:
            rarity_stats[r["rarity"]]["demanded"] += 1

    report_lines.append("| 稀有度 | 总数 | 被需求 | 未被需求 |\n")
    report_lines.append("|--------|------|--------|----------|\n")
    for rarity_key in ["common", "uncommon", "rare", "epic", "legendary"]:
        s = rarity_stats.get(rarity_key, {"count": 0, "demanded": 0})
        cn = RARITY_LABEL_CN.get(rarity_key, rarity_key)
        report_lines.append(f"| {cn} | {s['count']} | {s['demanded']} | {s['count'] - s['demanded']} |\n")

    report_lines.append("\n")

    return report_lines


def _infer_rarity_from_source(item):
    """根据来源书和效果推断稀有度。"""
    source = item.get("source_book", "")
    effects = " ".join(item.get("effects", []))
    name = item.get("name", "")

    # 传说级：长生不死、白日升天等
    if any(kw in effects for kw in ["不死", "升天", "神仙", "万岁"]):
        return "legendary"
    # 史诗级：延年不老、通神明等
    if any(kw in effects for kw in ["不老", "延年", "通神", "杀鬼", "辟邪"]):
        return "epic"
    # 稀有级：特殊功效
    if any(kw in effects for kw in ["明目", "轻身", "益气", "解毒"]):
        return "rare"
    # 精良级：一般药用
    if any(kw in effects for kw in ["主治", "治", "除"]):
        return "uncommon"

    return "common"


# ============================================================================
# 3. 战力曲线仿真
# ============================================================================

def simulate_combat_curve(kg_data, data_files_data):
    """
    模拟战力曲线：
    - 基于科技层级和装备计算玩家战力成长
    - 基于异兽稀有度计算怪物战力分布
    - 检查战力匹配度
    """
    report_lines = []
    report_lines.append("# 三、战力曲线仿真\n")

    techniques = kg_data.get("techniques", [])
    creatures = kg_data.get("creatures", [])

    if not techniques and not creatures:
        report_lines.append("> 无科技或异兽数据，跳过此模块。\n")
        return report_lines

    # 玩家战力成长曲线（基于科技层级）
    # 每个层级解锁的科技提升战力
    player_power_by_tier = defaultdict(list)
    tech_map = {t["id"]: t for t in techniques}

    for t in techniques:
        tier = t.get("tier", 1)
        branch = t.get("branch", "")
        base = TIER_COMBAT_BASE.get(tier, tier * 100)

        # 分支修正
        branch_modifier = {
            "survival": 1.0,
            "medicine": 0.8,
            "cultivation": 1.5,
            "sacrifice": 1.2,
            "craft": 1.3,
            "farming": 0.7,
        }
        modifier = branch_modifier.get(branch, 1.0)
        power = int(base * modifier)
        player_power_by_tier[tier].append({
            "id": t["id"],
            "name": t["name"],
            "branch": branch,
            "power": power,
        })

    # 计算每层级的累计战力（假设玩家按最优路径解锁所有科技）
    report_lines.append("## 3.1 玩家战力成长曲线\n")
    report_lines.append("| 层级 | 可解锁科技数 | 单节点战力范围 | 累计战力(全解锁) | 代表科技 |\n")
    report_lines.append("|------|-------------|---------------|-----------------|----------|\n")

    cumulative_power = 0
    tier_powers = {}
    for tier in sorted(player_power_by_tier.keys()):
        techs = player_power_by_tier[tier]
        powers = [t["power"] for t in techs]
        min_p = min(powers) if powers else 0
        max_p = max(powers) if powers else 0
        total = sum(powers)
        cumulative_power += total
        tier_powers[tier] = cumulative_power

        # 取代表性科技（战力最高的）
        rep = max(techs, key=lambda x: x["power"])
        branch_cn = _branch_cn(rep["branch"])
        report_lines.append(
            f"| Tier {tier} | {len(techs)} | {min_p}~{max_p} | {cumulative_power} | "
            f"{rep['name']}({branch_cn}) |\n"
        )

    # 怪物战力分布（基于异兽稀有度）
    report_lines.append("\n## 3.2 怪物（异兽）战力分布\n")

    creature_power_list = []
    for c in creatures:
        rarity = c.get("rarity", "common")
        base_monster_power = 15  # 基础怪物战力
        multiplier = RARITY_COMBAT_MULTIPLIER.get(rarity, 1.0)
        power = int(base_monster_power * multiplier)

        # 根据效果增强
        effects = c.get("effects", {})
        all_effects_text = " ".join(effects.values()) if isinstance(effects, dict) else str(effects)
        if any(kw in all_effects_text for kw in ["食之不饥", "不老", "不死", "神仙"]):
            power = int(power * 1.5)
        if any(kw in all_effects_text for kw in ["食之杀人", "有毒", "毒"]):
            power = int(power * 1.3)

        creature_power_list.append({
            "id": c["id"],
            "name": c.get("name", c["id"]),
            "rarity": rarity,
            "power": power,
        })

    # 按稀有度分组统计
    rarity_creatures = defaultdict(list)
    for cp in creature_power_list:
        rarity_creatures[cp["rarity"]].append(cp)

    report_lines.append("| 稀有度 | 数量 | 战力范围 | 平均战力 | 对应玩家层级 |\n")
    report_lines.append("|--------|------|----------|----------|-------------|\n")

    for rarity_key in ["common", "uncommon", "rare", "epic", "legendary"]:
        c_list = rarity_creatures.get(rarity_key, [])
        if not c_list:
            continue
        powers = [c["power"] for c in c_list]
        avg_power = sum(powers) / len(powers)
        min_p = min(powers)
        max_p = max(powers)

        # 推算对应玩家层级
        matched_tier = "N/A"
        for tier in sorted(tier_powers.keys()):
            if tier_powers[tier] >= avg_power:
                matched_tier = f"Tier {tier}"
                break
        if matched_tier == "N/A" and tier_powers:
            matched_tier = f"> Tier {max(tier_powers.keys())}"

        cn = RARITY_LABEL_CN.get(rarity_key, rarity_key)
        report_lines.append(
            f"| {cn} | {len(c_list)} | {min_p}~{max_p} | {avg_power:.0f} | {matched_tier} |\n"
        )

    # 战力匹配度检查
    report_lines.append("\n## 3.3 战力匹配度分析\n")

    # 将怪物按战力排序，检查每个玩家层级是否能应对
    sorted_creatures = sorted(creature_power_list, key=lambda x: x["power"])

    gaps = []      # 战力断层
    surpluses = []  # 战力过剩

    for tier in sorted(tier_powers.keys()):
        player_power = tier_powers[tier]
        # 该层级玩家应该能击败的怪物
        defeatable = [c for c in creature_power_list if c["power"] <= player_power]
        undefeated = [c for c in creature_power_list if c["power"] > player_power]

        # 检查下一层级最低战力怪物是否差距过大
        if undefeated:
            next_monster = min(undefeated, key=lambda x: x["power"])
            gap_ratio = next_monster["power"] / max(player_power, 1)
            if gap_ratio > 3.0:
                gaps.append({
                    "tier": tier,
                    "player_power": player_power,
                    "next_monster": next_monster,
                    "gap_ratio": gap_ratio,
                })

        # 检查是否有大量怪物战力远低于玩家
        if defeatable and len(defeatable) > len(creature_power_list) * 0.7:
            surpluses.append({
                "tier": tier,
                "player_power": player_power,
                "defeatable_count": len(defeatable),
                "total_count": len(creature_power_list),
            })

    if gaps:
        report_lines.append("### 战力断层（玩家无法击败的区域）\n")
        for g in gaps:
            report_lines.append(
                f"- **Tier {g['tier']}** (玩家战力 {g['player_power']}): "
                f"下一挑战 `{g['next_monster']['name']}` 战力 {g['next_monster']['power']}，"
                f"差距 {g['gap_ratio']:.1f}x\n"
            )
    else:
        report_lines.append("### 战力断层\n未发现严重战力断层。\n")

    if surpluses:
        report_lines.append("\n### 战力过剩（太简单的区域）\n")
        for s in surpluses:
            pct = s["defeatable_count"] / s["total_count"] * 100
            report_lines.append(
                f"- **Tier {s['tier']}** (玩家战力 {s['player_power']}): "
                f"可击败 {s['defeatable_count']}/{s['total_count']} ({pct:.0f}%) 的怪物\n"
            )
    else:
        report_lines.append("\n### 战力过剩\n未发现严重战力过剩。\n")

    # ASCII 战力曲线图
    report_lines.append("\n## 3.4 战力曲线图（ASCII）\n")
    report_lines.append("```\n")
    report_lines.append("战力 | 玩家(累计)          怪物(按稀有度)\n")
    report_lines.append("-----+--------------------------------------------------\n")

    # 归一化到 60 字符宽度
    max_power = max(
        [tier_powers[t] for t in tier_powers] +
        [c["power"] for c in creature_power_list],
        default=1,
    )
    if max_power == 0:
        max_power = 1
    width = 60

    # 绘制玩家战力点
    player_points = []
    for tier in sorted(tier_powers.keys()):
        power = tier_powers[tier]
        bar_len = int(power / max_power * width)
        player_points.append((tier, power, bar_len))

    # 绘制怪物战力点（取每个稀有度的平均）
    monster_points = []
    for rarity_key in ["common", "uncommon", "rare", "epic", "legendary"]:
        c_list = rarity_creatures.get(rarity_key, [])
        if c_list:
            avg = sum(c["power"] for c in c_list) / len(c_list)
            bar_len = int(avg / max_power * width)
            cn = RARITY_LABEL_CN.get(rarity_key, rarity_key)
            monster_points.append((cn, avg, bar_len))

    # 简单文本图
    all_points = []
    for tier, power, bar_len in player_points:
        all_points.append((f"T{tier}玩家", power, bar_len, "P"))
    for name, power, bar_len in monster_points:
        all_points.append((name, power, bar_len, "M"))

    for label, power, bar_len, ptype in all_points:
        marker = "@" if ptype == "P" else "#"
        bar = marker * bar_len
        report_lines.append(f"{power:>5.0f} | {bar} ({label})\n")

    report_lines.append("```\n")
    report_lines.append("> 图例: `@` = 玩家战力, `#` = 怪物平均战力\n\n")

    return report_lines


# ============================================================================
# 4. 食物链仿真
# ============================================================================

def simulate_food_chain(kg_data, data_files_data):
    """
    模拟食物/药品的产出与消耗：
    - 基于植物/异兽的可食用属性计算产出
    - 基于饥饿/疾病系统计算消耗
    - 计算生存压力曲线
    """
    report_lines = []
    report_lines.append("# 四、食物链仿真\n")

    creatures = kg_data.get("creatures", [])
    plants = kg_data.get("plants", [])
    techniques = kg_data.get("techniques", [])

    # 收集食物来源
    food_sources = []
    for p in plants:
        props = p.get("properties", {})
        effects = p.get("effects", {})
        edible = False
        if isinstance(props, dict):
            edible = props.get("edible", False)
        if not edible:
            # 检查效果中是否有食用相关
            if isinstance(effects, dict) and effects.get("eat", ""):
                edible = True
            elif isinstance(effects, str) and effects:
                edible = True

        if edible:
            rarity = p.get("rarity", "common")
            rate = RARITY_ACQUISITION_RATE.get(rarity, 1.0) * 60  # 个/时
            food_sources.append({
                "id": p["id"],
                "name": p.get("name", p["id"]),
                "type": "植物",
                "rarity": rarity,
                "rate": rate,
                "hunger_restore": _estimate_hunger_restore(p),
            })

    for c in creatures:
        props = c.get("properties", {})
        effects = c.get("effects", {})
        edible = False
        if isinstance(props, dict):
            edible = props.get("edible", False)
        if not edible:
            if isinstance(effects, dict) and effects.get("eat", ""):
                edible = True

        if edible:
            rarity = c.get("rarity", "common")
            rate = RARITY_ACQUISITION_RATE.get(rarity, 1.0) * 60  # 个/时
            food_sources.append({
                "id": c["id"],
                "name": c.get("name", c["id"]),
                "type": "异兽",
                "rarity": rarity,
                "rate": rate,
                "hunger_restore": _estimate_hunger_restore(c),
            })

    # 从 data 文件补充食物/药品
    for df in data_files_data:
        for herb in df.get("herbs", []):
            effects = " ".join(herb.get("effects", []))
            if any(kw in effects for kw in ["不饥", "充饥", "饥", "食"]):
                rarity = _infer_rarity_from_source(herb)
                rate = RARITY_ACQUISITION_RATE.get(rarity, 1.0) * 60
                food_sources.append({
                    "id": herb.get("id", ""),
                    "name": herb.get("name", ""),
                    "type": "草药/食物",
                    "rarity": rarity,
                    "rate": rate,
                    "hunger_restore": 20,
                })

    # 收集药品来源
    medicine_sources = []
    for p in plants:
        props = p.get("properties", {})
        if isinstance(props, dict) and props.get("medicinal", False):
            rarity = p.get("rarity", "common")
            rate = RARITY_ACQUISITION_RATE.get(rarity, 1.0) * 60
            medicine_sources.append({
                "id": p["id"],
                "name": p.get("name", p["id"]),
                "type": "植物药",
                "rarity": rarity,
                "rate": rate,
            })

    for df in data_files_data:
        for herb in df.get("herbs", []):
            effects = " ".join(herb.get("effects", []))
            if any(kw in effects for kw in ["治", "主", "除", "解毒", "愈"]):
                rarity = _infer_rarity_from_source(herb)
                rate = RARITY_ACQUISITION_RATE.get(rarity, 1.0) * 60
                medicine_sources.append({
                    "id": herb.get("id", ""),
                    "name": herb.get("name", ""),
                    "type": "典籍药",
                    "rarity": rarity,
                    "rate": rate,
                })

        for rx in df.get("prescriptions", []):
            # 方剂产出基于药材获取难度
            medicine_sources.append({
                "id": rx.get("id", ""),
                "name": rx.get("name", ""),
                "type": "方剂",
                "rarity": "rare",
                "rate": RARITY_ACQUISITION_RATE["rare"] * 60 * 0.5,  # 方剂产出减半
            })

    # 模拟消耗模型
    # 基础饥饿消耗：每小时消耗 10 点饱食度（需要约 0.5 个食物/时）
    HUNGER_RATE = 10  # 饱食度/时
    # 基础疾病概率：每小时 5% 概率生病（需要约 0.05 个药品/时）
    DISEASE_RATE = 0.05  # 次/时

    total_food_rate = sum(f["rate"] for f in food_sources)
    total_medicine_rate = sum(m["rate"] for m in medicine_sources)

    # 食物需求：每小时需要恢复的饱食度 / 平均每个食物恢复量
    avg_hunger_restore = sum(f["hunger_restore"] for f in food_sources) / max(len(food_sources), 1)
    food_demand_rate = HUNGER_RATE / max(avg_hunger_restore, 1)

    report_lines.append("## 4.1 食物产出与消耗\n")
    report_lines.append(f"- **基础饥饿消耗速率**: {HUNGER_RATE} 饱食度/时\n")
    report_lines.append(f"- **平均食物恢复量**: {avg_hunger_restore:.1f} 饱食度/个\n")
    report_lines.append(f"- **食物需求速率**: {food_demand_rate:.2f} 个/时\n")
    report_lines.append(f"- **食物总产出速率**: {total_food_rate:.2f} 个/时\n")
    report_lines.append(f"- **食物供需比**: {total_food_rate / max(food_demand_rate, 0.01):.2f}\n")

    if total_food_rate < food_demand_rate:
        report_lines.append(f"\n> **!! 警告: 食物供给不足!** 缺口: {food_demand_rate - total_food_rate:.2f} 个/时\n")
    elif total_food_rate > food_demand_rate * 10:
        report_lines.append(f"\n> 食物供给充足（过剩 {total_food_rate / food_demand_rate:.1f}x）\n")
    else:
        report_lines.append(f"\n> 食物供需基本平衡。\n")

    # 食物来源明细
    report_lines.append("\n### 食物来源明细（按稀有度分组）\n")
    report_lines.append("| 名称 | 类型 | 稀有度 | 产出速率(个/时) | 饱食度恢复 |\n")
    report_lines.append("|------|------|--------|----------------|------------|\n")
    for f in sorted(food_sources, key=lambda x: RARITY_ACQUISITION_RATE.get(x["rarity"], 1)):
        cn = RARITY_LABEL_CN.get(f["rarity"], f["rarity"])
        report_lines.append(
            f"| {f['name']} | {f['type']} | {cn} | {f['rate']:.2f} | {f['hunger_restore']} |\n"
        )

    report_lines.append(f"\n## 4.2 药品产出与消耗\n")
    report_lines.append(f"- **基础疾病发生率**: {DISEASE_RATE * 100:.1f}%/时\n")
    report_lines.append(f"- **药品需求速率**: {DISEASE_RATE:.2f} 个/时\n")
    report_lines.append(f"- **药品总产出速率**: {total_medicine_rate:.2f} 个/时\n")
    report_lines.append(f"- **药品供需比**: {total_medicine_rate / max(DISEASE_RATE, 0.01):.2f}\n")

    if total_medicine_rate < DISEASE_RATE:
        report_lines.append(f"\n> **!! 警告: 药品供给不足!** 缺口: {DISEASE_RATE - total_medicine_rate:.2f} 个/时\n")
    elif total_medicine_rate > DISEASE_RATE * 10:
        report_lines.append(f"\n> 药品供给充足（过剩 {total_medicine_rate / DISEASE_RATE:.1f}x）\n")
    else:
        report_lines.append(f"\n> 药品供需基本平衡。\n")

    # 生存压力曲线（按科技层级模拟）
    report_lines.append("\n## 4.3 生存压力曲线\n")
    report_lines.append("模拟各科技层级的生存压力变化：\n\n")

    report_lines.append("| 层级 | 食物加成 | 药品加成 | 饥饿压力 | 疾病压力 | 综合压力 |\n")
    report_lines.append("|------|----------|----------|----------|----------|----------|\n")

    # 科技层级对生存的改善
    tier_survival_bonus = {
        1: {"food": 1.0, "medicine": 1.0},    # 无加成
        2: {"food": 1.5, "medicine": 1.2},    # 采集辨识/草药辨识
        3: {"food": 2.0, "medicine": 1.8},    # 辟凶御险/外治之法
        4: {"food": 3.0, "medicine": 2.5},    # 不饥之术/解毒之术
        5: {"food": 5.0, "medicine": 4.0},    # 御兵之术/不死之药
    }

    pressure_points = []
    for tier in range(1, 6):
        bonus = tier_survival_bonus.get(tier, {"food": 1.0, "medicine": 1.0})
        effective_food = total_food_rate * bonus["food"]
        effective_medicine = total_medicine_rate * bonus["medicine"]

        hunger_pressure = max(0, food_demand_rate - effective_food) / food_demand_rate * 100
        disease_pressure = max(0, DISEASE_RATE - effective_medicine) / DISEASE_RATE * 100
        combined = (hunger_pressure + disease_pressure) / 2

        pressure_points.append((tier, hunger_pressure, disease_pressure, combined))

        # 压力等级标记
        if combined > 50:
            pressure_label = "!! 极高"
        elif combined > 20:
            pressure_label = "! 偏高"
        elif combined > 0:
            pressure_label = "轻微"
        else:
            pressure_label = "无压力"

        report_lines.append(
            f"| Tier {tier} | {bonus['food']}x | {bonus['medicine']}x | "
            f"{hunger_pressure:.0f}% | {disease_pressure:.0f}% | {combined:.0f}% {pressure_label} |\n"
        )

    # 标记生存瓶颈
    report_lines.append("\n### 生存瓶颈阶段\n")
    bottlenecks = [(t, h, d, c) for t, h, d, c in pressure_points if c > 20]
    if bottlenecks:
        for tier, hp, dp, cp in bottlenecks:
            report_lines.append(
                f"- **Tier {tier}**: 综合压力 {cp:.0f}% "
                f"(饥饿 {hp:.0f}% + 疾病 {dp:.0f}%)\n"
            )
    else:
        report_lines.append("无严重生存瓶颈。\n")

    # ASCII 生存压力曲线
    report_lines.append("\n### 生存压力曲线图（ASCII）\n")
    report_lines.append("```\n")
    report_lines.append("压力% | 饥饿压力    疾病压力    综合压力\n")
    report_lines.append("------+----------------------------------------\n")

    for tier, hp, dp, cp in pressure_points:
        h_bar = "#" * int(hp / 5)
        d_bar = "#" * int(dp / 5)
        c_bar = "@" * int(cp / 5)
        report_lines.append(
            f"  T{tier} | {h_bar:<12} {d_bar:<12} {c_bar}\n"
        )

    report_lines.append("```\n")
    report_lines.append("> 图例: `#` = 饥饿/疾病压力, `@` = 综合压力\n\n")

    return report_lines


def _estimate_hunger_restore(entity):
    """估算实体的饱食度恢复量。"""
    effects = entity.get("effects", {})
    name = entity.get("name", "")

    if isinstance(effects, dict):
        eat_effect = effects.get("eat", "")
    else:
        eat_effect = str(effects)

    # 不饥类食物效果最好
    if "不饥" in eat_effect:
        return 100
    if "充饥" in eat_effect:
        return 60
    if "饥" in eat_effect:
        return 50

    # 根据稀有度估算
    rarity = entity.get("rarity", "common")
    rarity_restore = {
        "common": 15,
        "uncommon": 25,
        "rare": 40,
        "epic": 60,
        "legendary": 80,
    }
    return rarity_restore.get(rarity, 20)


# ============================================================================
# 5. 主函数：汇总报告
# ============================================================================

def generate_report():
    """生成完整的数值平衡仿真报告。"""
    print("=" * 60)
    print("  山海经项目 - 数值平衡仿真器")
    print("=" * 60)
    print()

    # 加载数据
    print("[1/5] 加载知识图谱...")
    kg_data = load_json(KG_PATH)
    print(f"  - 山系: {len(kg_data.get('mountains', []))}")
    print(f"  - 异兽: {len(kg_data.get('creatures', []))}")
    print(f"  - 植物: {len(kg_data.get('plants', []))}")
    print(f"  - 矿物: {len(kg_data.get('minerals', []))}")
    print(f"  - 科技: {len(kg_data.get('techniques', []))}")
    print(f"  - 山神: {len(kg_data.get('gods', []))}")

    print("\n[2/5] 加载 data 目录数据文件...")
    data_files_data = []
    for fp in DATA_FILES:
        d = load_json(fp)
        if d:
            data_files_data.append(d)
            keys = [k for k in d.keys() if k != "metadata" and k != "meta" and k != "source_books_summary"]
            print(f"  - {os.path.basename(fp)}: {keys}")
        else:
            print(f"  - {os.path.basename(fp)}: 加载失败")

    print("\n[3/5] 运行科技树可达性仿真...")
    tech_report, tech_map = simulate_tech_tree(kg_data.get("techniques", []))
    print(f"  - 完成")

    print("\n[4/5] 运行材料经济仿真...")
    material_report = simulate_material_economy(kg_data, data_files_data)
    print(f"  - 完成")

    print("\n[5/5] 运行战力曲线和食物链仿真...")
    combat_report = simulate_combat_curve(kg_data, data_files_data)
    food_report = simulate_food_chain(kg_data, data_files_data)
    print(f"  - 完成")

    # 汇总报告
    report = []
    report.append("# 山海经项目 - 数值平衡仿真报告\n")
    report.append(f"> 自动生成于数值平衡仿真器\n")
    report.append(f"> 数据来源: 知识图谱 full-data.json + data 目录 4 个 JSON 文件\n")
    report.append(f"> 知识图谱版本: {kg_data.get('version', 'N/A')}\n\n")

    report.append("---\n\n")
    report.append("## 目录\n")
    report.append("1. [科技树可达性仿真](#一科技树可达性仿真)\n")
    report.append("2. [材料经济仿真](#二材料经济仿真)\n")
    report.append("3. [战力曲线仿真](#三战力曲线仿真)\n")
    report.append("4. [食物链仿真](#四食物链仿真)\n\n")
    report.append("---\n\n")

    report.extend(tech_report)
    report.append("---\n\n")
    report.extend(material_report)
    report.append("---\n\n")
    report.extend(combat_report)
    report.append("---\n\n")
    report.extend(food_report)

    # 写入报告
    ensure_dir(REPORT_PATH)
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.writelines(report)

    print(f"\n{'=' * 60}")
    print(f"  报告已生成: {REPORT_PATH}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    generate_report()
