#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
L1 数据格式校验器 - 山海经知识图谱数据质量检查工具

用途：
  校验知识图谱 full-data.json 中所有实体是否符合 schema.json 定义的格式规范，
  检查必填字段、ID 命名规范、枚举值合法性、source 字段完整性等。

用法：
  python kg_validator.py

输出：
  格式化的校验报告，包含通过/失败/警告数量及所有问题详情。
  支持终端彩色输出（若终端不支持则自动降级为纯文本）。
"""

import json
import os
import re
import sys

# ============================================================
# 路径配置（基于脚本所在目录的上级目录）
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
KG_DIR = os.path.join(PROJECT_DIR, "knowledge-graph")
FULL_DATA_PATH = os.path.join(KG_DIR, "full-data.json")
SCHEMA_PATH = os.path.join(KG_DIR, "schema.json")

# ============================================================
# 终端彩色输出
# ============================================================
class Color:
    """终端颜色工具，若不支持彩色则自动降级"""
    RESET = ""
    RED = ""
    GREEN = ""
    YELLOW = ""
    CYAN = ""
    BOLD = ""

    @classmethod
    def enable(cls):
        cls.RESET = "\033[0m"
        cls.RED = "\033[91m"
        cls.GREEN = "\033[92m"
        cls.YELLOW = "\033[93m"
        cls.CYAN = "\033[96m"
        cls.BOLD = "\033[1m"

# 检测终端是否支持彩色
if sys.stdout.isatty() and os.environ.get("TERM", "") != "":
    try:
        Color.enable()
    except Exception:
        pass


def print_header(title):
    print(f"\n{Color.BOLD}{Color.CYAN}{'=' * 70}{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}  {title}{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}{'=' * 70}{Color.RESET}")


def print_pass(msg):
    print(f"  {Color.GREEN}[PASS]{Color.RESET} {msg}")


def print_fail(msg):
    print(f"  {Color.RED}[FAIL]{Color.RESET} {msg}")


def print_warn(msg):
    print(f"  {Color.YELLOW}[WARN]{Color.RESET} {msg}")


def print_info(msg):
    print(f"  {Color.CYAN}[INFO]{Color.RESET} {msg}")


# ============================================================
# 校验规则定义
# ============================================================

# 各实体类型的 ID 前缀
ID_PREFIXES = {
    "creature": "creature_",
    "plant": "plant_",
    "mineral": "mineral_",
    "mountain": "mountain_",
    "god": "god_",
    "technique": "tech_",
}

# 合法稀有度枚举
VALID_RARITIES = {"common", "uncommon", "rare", "epic", "legendary"}

# 合法科技树分支枚举
VALID_BRANCHES = {"survival", "medicine", "cultivation", "sacrifice", "craft", "farming"}

# 各实体类型的必填字段
REQUIRED_FIELDS = {
    "creature": ["id", "name", "mountain", "appearance", "properties", "effects", "techBranches", "rarity", "source"],
    "plant": ["id", "name", "mountain", "appearance", "properties", "effects", "techBranches", "rarity", "source"],
    "mineral": ["id", "name", "mountain", "description", "properties", "uses", "techBranches", "rarity", "source"],
    "mountain": ["id", "name", "section", "position", "distanceFromPrev", "description", "biome", "source"],
    "god": ["id", "name", "mountainRange", "appearance", "sacrifice", "blessings", "source"],
    "technique": ["id", "name", "branch", "tier", "description", "prerequisites", "unlocks", "materials", "source"],
}

# 各实体类型中 properties 的必填子字段（布尔类型）
PROPERTIES_FIELDS = {
    "creature": ["edible", "toxic", "domesticable", "rideable"],
    "plant": ["edible", "medicinal", "poisonous"],
    "mineral": ["metal", "jade", "gem"],
}

# 各实体类型中 effects/uses 的子字段
EFFECTS_FIELDS = {
    "creature": ["eat", "wear", "sacrifice"],
    "plant": ["eat", "medicine", "sacrifice"],
    "mineral": ["craft", "sacrifice", "medicine"],
}


# ============================================================
# 校验函数
# ============================================================

def load_json(filepath):
    """加载 JSON 文件，返回解析后的字典或 None"""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print_fail(f"文件不存在: {filepath}")
        return None
    except json.JSONDecodeError as e:
        print_fail(f"JSON 格式错误 ({filepath}): {e}")
        return None


def check_id_naming(entity_type, entity_id):
    """校验 ID 命名规范"""
    prefix = ID_PREFIXES.get(entity_type)
    if prefix is None:
        return None
    if not entity_id.startswith(prefix):
        return f"ID 前缀不匹配，期望 '{prefix}*'，实际为 '{entity_id}'"
    suffix = entity_id[len(prefix):]
    if not suffix:
        return f"ID 缺少标识部分: '{entity_id}'"
    if not re.match(r'^[a-z][a-z0-9_]*$', suffix):
        return f"ID 标识部分包含非法字符（仅允许小写字母、数字、下划线）: '{entity_id}'"
    return None


def check_rarity(entity_id, rarity):
    """校验稀有度枚举值"""
    if rarity not in VALID_RARITIES:
        return f"稀有度值非法: '{rarity}'，合法值: {sorted(VALID_RARITIES)}"
    return None


def check_branches(entity_id, branches):
    """校验科技树分支枚举值"""
    invalid = [b for b in branches if b not in VALID_BRANCHES]
    if invalid:
        return f"科技树分支包含非法值: {invalid}，合法值: {sorted(VALID_BRANCHES)}"
    return None


def check_source(entity_id, source):
    """校验 source 字段是否存在且非空"""
    if not source or (isinstance(source, str) and source.strip() == ""):
        return f"source 字段为空"
    return None


def check_required_fields(entity_type, entity):
    """校验必填字段是否存在且非空"""
    required = REQUIRED_FIELDS.get(entity_type, [])
    missing = []
    empty = []
    for field in required:
        if field not in entity:
            missing.append(field)
        elif entity[field] is None:
            empty.append(field)
        elif isinstance(entity[field], str) and entity[field].strip() == "":
            empty.append(field)
    issues = []
    if missing:
        issues.append(f"缺少必填字段: {missing}")
    if empty:
        issues.append(f"必填字段为空: {empty}")
    return issues


def check_properties(entity_type, entity):
    """校验 properties 子字段"""
    props_fields = PROPERTIES_FIELDS.get(entity_type)
    if props_fields is None:
        return []
    props = entity.get("properties")
    if not isinstance(props, dict):
        return ["properties 字段不是对象类型"]
    issues = []
    for field in props_fields:
        if field not in props:
            issues.append(f"properties 缺少子字段: {field}")
        elif not isinstance(props[field], bool):
            issues.append(f"properties.{field} 不是布尔类型: {type(props[field]).__name__}")
    return issues


def check_effects(entity_type, entity):
    """校验 effects/uses 子字段"""
    effects_key = "effects" if entity_type in ("creature", "plant") else "uses"
    effects_fields = EFFECTS_FIELDS.get(entity_type)
    if effects_fields is None:
        return []
    effects = entity.get(effects_key)
    if not isinstance(effects, dict):
        return [f"{effects_key} 字段不是对象类型"]
    issues = []
    for field in effects_fields:
        if field not in effects:
            issues.append(f"{effects_key} 缺少子字段: {field}")
    return issues


def check_technique_specific(entity):
    """校验 technique 类型特有字段"""
    issues = []
    branch = entity.get("branch")
    if branch and branch not in VALID_BRANCHES:
        issues.append(f"branch 值非法: '{branch}'")
    tier = entity.get("tier")
    if tier is not None and (not isinstance(tier, int) or tier < 1 or tier > 10):
        issues.append(f"tier 值非法: {tier}（应为 1-10 的整数）")
    return issues


def check_mountain_specific(entity):
    """校验 mountain 类型特有字段"""
    issues = []
    position = entity.get("position")
    if position is not None and not isinstance(position, int):
        issues.append(f"position 不是整数: {position}")
    distance = entity.get("distanceFromPrev")
    if distance is not None and not isinstance(distance, (int, float)):
        issues.append(f"distanceFromPrev 不是数字: {distance}")
    return issues


def check_god_specific(entity):
    """校验 god 类型特有字段"""
    issues = []
    sacrifice = entity.get("sacrifice")
    if not isinstance(sacrifice, dict):
        issues.append("sacrifice 字段不是对象类型")
    blessings = entity.get("blessings")
    if not isinstance(blessings, list):
        issues.append("blessings 字段不是数组类型")
    return issues


def check_duplicate_ids(all_entities):
    """检查所有实体 ID 是否唯一"""
    id_map = {}
    duplicates = []
    for entity_type, entities in all_entities.items():
        for entity in entities:
            eid = entity.get("id", "")
            if eid in id_map:
                duplicates.append((eid, id_map[eid], entity_type))
            else:
                id_map[eid] = entity_type
    return duplicates


def check_referential_integrity(data):
    """检查引用完整性：mountain 中的 creatures/plants/minerals 引用是否在对应实体列表中存在"""
    issues = []
    creature_ids = {c["id"] for c in data.get("creatures", [])}
    plant_ids = {p["id"] for p in data.get("plants", [])}
    mineral_ids = {m["id"] for m in data.get("minerals", [])}
    god_ids = {g["id"] for g in data.get("gods", [])}

    for mountain in data.get("mountains", []):
        mid = mountain.get("id", "")
        # 检查 creatures 引用
        for cid in mountain.get("creatures", []):
            if cid not in creature_ids:
                issues.append(f"山 '{mid}' 引用了不存在的异兽: {cid}")
        # 检查 plants 引用
        for pid in mountain.get("plants", []):
            if pid not in plant_ids:
                issues.append(f"山 '{mid}' 引用了不存在的植物: {pid}")
        # 检查 minerals 引用
        for m_id in mountain.get("minerals", []):
            if m_id not in mineral_ids:
                issues.append(f"山 '{mid}' 引用了不存在的矿物: {m_id}")
        # 检查 god 引用
        gid = mountain.get("god")
        if gid and gid not in god_ids:
            issues.append(f"山 '{mid}' 引用了不存在的山神: {gid}")

    return issues


# ============================================================
# 主流程
# ============================================================

def main():
    print_header("山海经知识图谱 - L1 数据格式校验报告")

    # 加载数据
    print_info(f"加载知识图谱: {FULL_DATA_PATH}")
    data = load_json(FULL_DATA_PATH)
    if data is None:
        print_fail("无法加载知识图谱数据，校验终止。")
        return

    print_info(f"加载 Schema: {SCHEMA_PATH}")
    schema = load_json(SCHEMA_PATH)
    if schema is None:
        print_warn("无法加载 Schema，将使用内置规则进行校验。")

    # 统计
    total_pass = 0
    total_fail = 0
    total_warn = 0
    all_issues = []

    # 收集所有实体
    all_entities = {}
    entity_type_map = {
        "mountain": data.get("mountains", []),
        "creature": data.get("creatures", []),
        "plant": data.get("plants", []),
        "mineral": data.get("minerals", []),
        "god": data.get("gods", []),
        "technique": data.get("techniques", []),
    }

    print_info(f"数据版本: {data.get('version', '未知')}")
    print_info(f"最后更新: {data.get('lastUpdated', '未知')}")

    # --------------------------------------------------------
    # 1. 检查 JSON 格式合法性（已通过 load_json 完成）
    # --------------------------------------------------------
    print_header("1. JSON 格式合法性检查")
    print_pass(f"full-data.json 解析成功")
    if schema:
        print_pass(f"schema.json 解析成功")
    else:
        print_warn("schema.json 未能加载")

    # --------------------------------------------------------
    # 2. 检查 ID 唯一性
    # --------------------------------------------------------
    print_header("2. ID 唯一性检查")
    for etype, entities in entity_type_map.items():
        all_entities[etype] = entities

    duplicates = check_duplicate_ids(all_entities)
    if duplicates:
        for eid, orig_type, dup_type in duplicates:
            msg = f"ID 重复: '{eid}' 同时出现在 {orig_type} 和 {dup_type}"
            print_fail(msg)
            all_issues.append(("FAIL", msg))
            total_fail += 1
    else:
        print_pass("所有实体 ID 唯一")
        total_pass += 1

    # --------------------------------------------------------
    # 3. 逐实体类型校验
    # --------------------------------------------------------
    type_names = {
        "mountain": "山系/地理实体",
        "creature": "异兽/生物实体",
        "plant": "草木/植物实体",
        "mineral": "矿物/玉石实体",
        "god": "神灵/山神实体",
        "technique": "科技/技能实体",
    }

    for etype, entities in entity_type_map.items():
        print_header(f"3. {type_names.get(etype, etype)} 校验 ({len(entities)} 个实体)")

        if not entities:
            print_warn(f"无 {type_names.get(etype, etype)} 数据")
            continue

        for entity in entities:
            eid = entity.get("id", "未知")
            entity_issues = []

            # 3.1 必填字段检查
            field_issues = check_required_fields(etype, entity)
            entity_issues.extend(field_issues)

            # 3.2 ID 命名规范
            id_issue = check_id_naming(etype, eid)
            if id_issue:
                entity_issues.append(id_issue)

            # 3.3 稀有度枚举
            rarity = entity.get("rarity")
            if rarity is not None:
                rarity_issue = check_rarity(eid, rarity)
                if rarity_issue:
                    entity_issues.append(rarity_issue)

            # 3.4 科技树分支枚举
            branches = entity.get("techBranches")
            if branches is not None:
                branch_issue = check_branches(eid, branches)
                if branch_issue:
                    entity_issues.append(branch_issue)

            # 3.5 source 字段
            source = entity.get("source")
            if source is not None:
                source_issue = check_source(eid, source)
                if source_issue:
                    entity_issues.append(source_issue)

            # 3.6 properties 子字段
            prop_issues = check_properties(etype, entity)
            entity_issues.extend(prop_issues)

            # 3.7 effects/uses 子字段
            effect_issues = check_effects(etype, entity)
            entity_issues.extend(effect_issues)

            # 3.8 类型特有校验
            if etype == "technique":
                entity_issues.extend(check_technique_specific(entity))
            elif etype == "mountain":
                entity_issues.extend(check_mountain_specific(entity))
            elif etype == "god":
                entity_issues.extend(check_god_specific(entity))

            # 输出结果
            if not entity_issues:
                total_pass += 1
            else:
                for issue in entity_issues:
                    severity = "FAIL"
                    print_fail(f"[{eid}] {issue}")
                    all_issues.append((severity, f"[{eid}] {issue}"))
                    total_fail += 1

    # --------------------------------------------------------
    # 4. 引用完整性检查
    # --------------------------------------------------------
    print_header("4. 引用完整性检查（Mountain -> Creature/Plant/Mineral/God）")
    ref_issues = check_referential_integrity(data)
    if ref_issues:
        for issue in ref_issues:
            print_fail(issue)
            all_issues.append(("FAIL", issue))
            total_fail += 1
    else:
        print_pass("所有引用均指向已存在的实体")
        total_pass += 1

    # --------------------------------------------------------
    # 5. 汇总报告
    # --------------------------------------------------------
    print_header("校验汇总")
    total_entities = sum(len(e) for e in entity_type_map.values())
    print_info(f"实体总数: {total_entities}")
    print_info(f"  山系: {len(entity_type_map['mountain'])}")
    print_info(f"  异兽: {len(entity_type_map['creature'])}")
    print_info(f"  植物: {len(entity_type_map['plant'])}")
    print_info(f"  矿物: {len(entity_type_map['mineral'])}")
    print_info(f"  山神: {len(entity_type_map['god'])}")
    print_info(f"  科技: {len(entity_type_map['technique'])}")

    print()
    if total_fail == 0:
        print(f"  {Color.GREEN}{Color.BOLD}校验结果: 全部通过{Color.RESET}")
    else:
        print(f"  {Color.RED}{Color.BOLD}校验结果: {total_fail} 个问题{Color.RESET}")

    print(f"  通过: {Color.GREEN}{total_pass}{Color.RESET}")
    print(f"  失败: {Color.RED}{total_fail}{Color.RESET}")
    print(f"  警告: {Color.YELLOW}{total_warn}{Color.RESET}")

    # 输出所有问题列表
    if all_issues:
        print_header("问题详情列表")
        for severity, detail in all_issues:
            if severity == "FAIL":
                print_fail(detail)
            else:
                print_warn(detail)

    print()
    return total_fail


if __name__ == "__main__":
    exit_code = main()
    sys.exit(1 if exit_code > 0 else 0)
