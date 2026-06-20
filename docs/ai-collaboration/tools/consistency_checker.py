#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
L2 设定一致性检查器 - 山海经知识图谱跨数据源一致性验证工具

用途：
  对比知识图谱 full-data.json 与 docs/data/ 下 4 个原始提取数据文件，
  检查同一实体在不同数据源中的名称一致性、效果与原文一致性、
  跨分支材料依赖完整性、稀有度评定合理性。

用法：
  python consistency_checker.py

输出：
  格式化的一致性检查报告，包含通过/失败/警告数量及所有问题详情。
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
DATA_DIR = os.path.join(PROJECT_DIR, "..", "..", "data")

# 4 个原始数据文件
DATA_FILES = {
    "medicine_cultivation": os.path.normpath(os.path.join(DATA_DIR, "extract_medicine_cultivation.json")),
    "sacrifice_craft_survival": os.path.normpath(os.path.join(DATA_DIR, "extract_sacrifice_craft_survival.json")),
    "farming_shanhai": os.path.normpath(os.path.join(DATA_DIR, "extract_farming_shanhai.json")),
    "tiangong": os.path.normpath(os.path.join(DATA_DIR, "tiangong_full_extract.json")),
}

# ============================================================
# 终端彩色输出
# ============================================================
class Color:
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
# 数据加载
# ============================================================

def load_json(filepath):
    """加载 JSON 文件"""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as e:
        print_fail(f"JSON 解析错误 ({filepath}): {e}")
        return None


def build_name_index(data_files_data):
    """
    从原始数据文件中构建 名称 -> [(来源文件, 实体数据)] 索引。
    支持多种数据结构（herbs, prescriptions, sacrifices, crops, tools 等）。
    """
    name_index = {}

    # 各数据文件中的实体列表键名
    list_keys = {
        "medicine_cultivation": ["herbs", "prescriptions", "cultivation_techniques"],
        "sacrifice_craft_survival": ["sacrifices", "crafts", "survival_items"],
        "farming_shanhai": ["crops", "livestock", "techniques"],
        "tiangong": ["tools", "techniques", "materials"],
    }

    for file_key, file_data in data_files_data.items():
        if file_data is None:
            continue
        keys = list_keys.get(file_key, [])
        # 自动发现所有列表类型的顶层键
        if not keys:
            keys = [k for k, v in file_data.items() if isinstance(v, list)]
        for key in keys:
            entities = file_data.get(key, [])
            if not isinstance(entities, list):
                continue
            for entity in entities:
                if not isinstance(entity, dict):
                    continue
                name = entity.get("name", "")
                if not name:
                    continue
                if name not in name_index:
                    name_index[name] = []
                name_index[name].append((file_key, entity))

    return name_index


def build_material_index(data_files_data):
    """
    从原始数据文件中构建所有材料名称集合。
    包括 herbs 的 name、tools 的 materials、crops 的 name 等。
    """
    materials = set()

    for file_key, file_data in data_files_data.items():
        if file_data is None:
            continue
        # 遍历所有顶层列表
        for key, value in file_data.items():
            if not isinstance(value, list):
                continue
            for entity in value:
                if not isinstance(entity, dict):
                    continue
                # 实体名称本身
                name = entity.get("name", "")
                if name:
                    materials.add(name)
                # ingredients / materials 子字段
                for sub_key in ("ingredients", "materials", "offerings"):
                    sub_list = entity.get(sub_key, [])
                    if isinstance(sub_list, list):
                        for item in sub_list:
                            if isinstance(item, str):
                                materials.add(item)

    return materials


def build_kg_name_index(kg_data):
    """从知识图谱中构建 名称 -> 实体列表 索引"""
    name_index = {}
    for etype in ("creatures", "plants", "minerals", "mountains", "gods", "techniques"):
        entities = kg_data.get(etype, [])
        for entity in entities:
            name = entity.get("name", "")
            if not name:
                continue
            if name not in name_index:
                name_index[name] = []
            name_index[name].append((etype, entity))
    return name_index


def build_kg_effects_index(kg_data):
    """从知识图谱中构建 ID -> effects 文本 索引"""
    effects_index = {}
    for etype in ("creatures", "plants", "minerals"):
        entities = kg_data.get(etype, [])
        for entity in entities:
            eid = entity.get("id", "")
            effects = entity.get("effects") or entity.get("uses", {})
            if isinstance(effects, dict):
                effects_index[eid] = effects
    return effects_index


# ============================================================
# 一致性检查函数
# ============================================================

def check_name_consistency(kg_name_index, data_name_index):
    """
    检查同一实体在不同数据源中的名称是否一致。
    策略：对比知识图谱中的名称与原始数据文件中的名称。
    """
    issues = []
    checked = 0

    for name, kg_entries in kg_name_index.items():
        if name in data_name_index:
            checked += 1
            # 名称在两边都存在，检查是否指向同一类实体
            data_entries = data_name_index[name]
            for kg_etype, kg_entity in kg_entries:
                for file_key, data_entity in data_entries:
                    # 检查别名是否一致
                    kg_alias = set(kg_entity.get("alias", []))
                    data_name = data_entity.get("name", "")
                    if data_name != name and data_name not in kg_alias:
                        issues.append((
                            "WARN",
                            f"名称差异: 知识图谱 '{name}' (alias: {kg_alias}) "
                            f"vs 数据源 [{file_key}] '{data_name}'"
                        ))

    return issues, checked


def check_effects_vs_source_text(kg_data, data_files_data):
    """
    检查异兽效果是否与原文一致。
    策略：比对知识图谱中 creature 的 effects 字段与原始数据中的 source_text。
    """
    issues = []
    checked = 0

    # 从原始数据文件中提取所有 source_text
    source_texts = []
    for file_key, file_data in data_files_data.items():
        if file_data is None:
            continue
        for key, value in file_data.items():
            if not isinstance(value, list):
                continue
            for entity in value:
                if not isinstance(entity, dict):
                    continue
                st = entity.get("source_text", "")
                name = entity.get("name", "")
                if st and name:
                    source_texts.append((name, st, file_key))

    # 对每个异兽，检查其效果是否能在原文中找到对应
    creatures = kg_data.get("creatures", [])
    for creature in creatures:
        eid = creature.get("id", "")
        name = creature.get("name", "")
        effects = creature.get("effects", {})
        kg_source = creature.get("source", "")

        if not effects:
            continue

        # 收集所有非"未知"的效果文本
        effect_values = []
        for k, v in effects.items():
            if isinstance(v, str) and v and v != "未知":
                effect_values.append(v)

        if not effect_values:
            continue

        checked += 1

        # 在原始数据的 source_text 中查找匹配
        found_match = False
        for src_name, src_text, file_key in source_texts:
            if src_name == name or src_name in creature.get("alias", []):
                found_match = True
                # 检查效果文本是否与原文有对应
                for ev in effect_values:
                    # 提取效果关键词（去掉"食之"、"佩之"等前缀）
                    keywords = re.sub(r'^(食之|佩之|服之|可以|能)', '', ev)
                    if keywords and keywords not in src_text:
                        issues.append((
                            "WARN",
                            f"效果与原文可能不一致: [{eid}] '{name}' "
                            f"效果 '{ev}' 在 [{file_key}] 原文中未找到对应 "
                            f"(原文: {src_text[:60]}...)"
                        ))
                break

        if not found_match and effect_values:
            # 没有在原始数据中找到对应原文，记录为信息
            issues.append((
                "INFO",
                f"未在原始数据中找到匹配原文: [{eid}] '{name}' "
                f"(效果: {', '.join(effect_values)})"
            ))

    return issues, checked


def check_cross_branch_material_deps(kg_data, data_materials):
    """
    检查跨分支材料依赖是否缺失。
    策略：遍历知识图谱中所有实体的 techBranches，检查科技/技能所需材料
    是否在所有数据源中能找到。
    """
    issues = []
    checked = 0

    # 收集知识图谱中所有材料引用
    # 从 creatures, plants, minerals 的 name 和 alias 构建
    kg_material_names = set()
    for etype in ("creatures", "plants", "minerals"):
        for entity in kg_data.get(etype, []):
            kg_material_names.add(entity.get("name", ""))
            for alias in entity.get("alias", []):
                kg_material_names.add(alias)

    # 合并原始数据中的材料
    all_known_materials = kg_material_names | data_materials

    # 检查 techniques（如果有）
    techniques = kg_data.get("techniques", [])
    for tech in techniques:
        tid = tech.get("id", "")
        materials = tech.get("materials", [])
        cross_prereqs = tech.get("crossBranchPrereqs", [])

        if materials:
            checked += 1
            for mat in materials:
                if isinstance(mat, str) and mat not in all_known_materials:
                    issues.append((
                        "FAIL",
                        f"材料依赖缺失: [{tid}] '{tech.get('name', '')}' "
                        f"需要材料 '{mat}'，但在所有数据源中均未找到"
                    ))

        if cross_prereqs:
            for prereq in cross_prereqs:
                if isinstance(prereq, str) and prereq not in all_known_materials:
                    issues.append((
                        "WARN",
                        f"跨分支前置缺失: [{tid}] '{tech.get('name', '')}' "
                        f"跨分支前置 '{prereq}' 在所有数据源中均未找到"
                    ))

    # 同时检查原始数据文件中的配方/科技材料引用
    for file_key, file_data in DATA_FILES.items():
        pass  # 已通过 data_materials 收集

    return issues, checked


def check_rarity_reasonableness(kg_data):
    """
    检查稀有度评定是否合理。
    策略：legendary 级别实体应有足够特殊的效果描述（非"未知"），
    common 级别实体不应有过于特殊的效果。
    """
    issues = []
    checked = 0

    for etype in ("creatures", "plants", "minerals"):
        entities = kg_data.get(etype, [])
        for entity in entities:
            eid = entity.get("id", "")
            name = entity.get("name", "")
            rarity = entity.get("rarity", "")
            effects = entity.get("effects") or entity.get("uses", {})

            if not rarity:
                continue

            checked += 1

            # 收集效果文本
            effect_values = []
            if isinstance(effects, dict):
                for k, v in effects.items():
                    if isinstance(v, str) and v and v != "未知":
                        effect_values.append(v)

            if rarity == "legendary":
                # legendary 级别应有至少 2 个非"未知"效果
                if len(effect_values) < 2:
                    issues.append((
                        "WARN",
                        f"稀有度不合理: [{eid}] '{name}' 为 legendary 级别，"
                        f"但仅有 {len(effect_values)} 个明确效果 "
                        f"(效果: {effect_values})"
                    ))
                # legendary 级别的效果应包含特殊关键词
                special_keywords = ["不死", "神仙", "升天", "长生", "通神", "辟", "隐形",
                                     "飞行", "轻身", "不老", "百鬼", "五兵"]
                has_special = any(any(kw in ev for kw in special_keywords) for ev in effect_values)
                if not has_special and effect_values:
                    issues.append((
                        "WARN",
                        f"稀有度存疑: [{eid}] '{name}' 为 legendary 级别，"
                        f"但效果描述 '{effect_values}' 缺少特殊关键词"
                    ))

            elif rarity == "common":
                # common 级别不应有过于特殊的效果
                overpowered_keywords = ["不死", "神仙", "升天", "长生", "通神", "隐形", "飞行"]
                has_op = any(any(kw in ev for kw in overpowered_keywords) for ev in effect_values)
                if has_op:
                    issues.append((
                        "WARN",
                        f"稀有度不合理: [{eid}] '{name}' 为 common 级别，"
                        f"但效果 '{effect_values}' 包含过于特殊的关键词"
                    ))

    return issues, checked


def check_source_field_consistency(kg_data, data_files_data):
    """
    检查知识图谱实体的 source 字段与原始数据中的 source_book/source_chapter 是否一致。
    """
    issues = []
    checked = 0

    # 从原始数据构建 name -> source_book 映射
    name_source_map = {}
    for file_key, file_data in data_files_data.items():
        if file_data is None:
            continue
        for key, value in file_data.items():
            if not isinstance(value, list):
                continue
            for entity in value:
                if not isinstance(entity, dict):
                    continue
                name = entity.get("name", "")
                source_book = entity.get("source_book", "") or entity.get("source_chapter", "")
                if name and source_book:
                    if name not in name_source_map:
                        name_source_map[name] = []
                    name_source_map[name].append((source_book, file_key))

    # 对比
    for etype in ("creatures", "plants", "minerals", "mountains", "gods"):
        for entity in kg_data.get(etype, []):
            eid = entity.get("id", "")
            name = entity.get("name", "")
            kg_source = entity.get("source", "")

            if not kg_source or name not in name_source_map:
                continue

            checked += 1
            data_sources = name_source_map[name]
            # 检查知识图谱的 source 是否包含原始数据的 source_book 信息
            for source_book, file_key in data_sources:
                if source_book and source_book not in kg_source:
                    issues.append((
                        "INFO",
                        f"出处信息差异: [{eid}] '{name}' "
                        f"知识图谱 source='{kg_source}'，"
                        f"原始数据 [{file_key}] source_book='{source_book}'"
                    ))

    return issues, checked


# ============================================================
# 主流程
# ============================================================

def main():
    print_header("山海经知识图谱 - L2 设定一致性检查报告")

    # 加载知识图谱
    print_info(f"加载知识图谱: {FULL_DATA_PATH}")
    kg_data = load_json(FULL_DATA_PATH)
    if kg_data is None:
        print_fail("无法加载知识图谱数据，检查终止。")
        return 1

    # 加载原始数据文件
    data_files_data = {}
    for file_key, filepath in DATA_FILES.items():
        print_info(f"加载原始数据: {file_key} ({filepath})")
        data = load_json(filepath)
        if data is None:
            print_warn(f"无法加载 {file_key}，将跳过该数据源。")
        data_files_data[file_key] = data

    loaded_count = sum(1 for v in data_files_data.values() if v is not None)
    print_info(f"成功加载 {loaded_count}/{len(DATA_FILES)} 个原始数据文件")

    # 构建索引
    kg_name_index = build_kg_name_index(kg_data)
    data_name_index = build_name_index(data_files_data)
    data_materials = build_material_index(data_files_data)

    print_info(f"知识图谱实体名称索引: {len(kg_name_index)} 个名称")
    print_info(f"原始数据实体名称索引: {len(data_name_index)} 个名称")
    print_info(f"原始数据材料集合: {len(data_materials)} 个材料")

    # 统计
    total_issues = []
    total_pass = 0
    total_fail = 0
    total_warn = 0

    # --------------------------------------------------------
    # 1. 名称一致性检查
    # --------------------------------------------------------
    print_header("1. 名称一致性检查（知识图谱 vs 原始数据）")
    name_issues, name_checked = check_name_consistency(kg_name_index, data_name_index)
    if name_issues:
        for severity, detail in name_issues:
            if severity == "FAIL":
                print_fail(detail)
                total_fail += 1
            else:
                print_warn(detail)
                total_warn += 1
            total_issues.append((severity, detail))
    else:
        print_pass(f"已检查 {name_checked} 个共有名称，未发现不一致")
        total_pass += 1

    # --------------------------------------------------------
    # 2. 效果与原文一致性检查
    # --------------------------------------------------------
    print_header("2. 异兽效果与原文一致性检查")
    effect_issues, effect_checked = check_effects_vs_source_text(kg_data, data_files_data)
    if effect_issues:
        for severity, detail in effect_issues:
            if severity == "FAIL":
                print_fail(detail)
                total_fail += 1
            elif severity == "WARN":
                print_warn(detail)
                total_warn += 1
            else:
                print_info(detail)
            total_issues.append((severity, detail))
    else:
        print_pass(f"已检查 {effect_checked} 个异兽效果，未发现不一致")
        total_pass += 1

    # --------------------------------------------------------
    # 3. 跨分支材料依赖检查
    # --------------------------------------------------------
    print_header("3. 跨分支材料依赖完整性检查")
    mat_issues, mat_checked = check_cross_branch_material_deps(kg_data, data_materials)
    if mat_issues:
        for severity, detail in mat_issues:
            if severity == "FAIL":
                print_fail(detail)
                total_fail += 1
            else:
                print_warn(detail)
                total_warn += 1
            total_issues.append((severity, detail))
    else:
        tech_count = len(kg_data.get("techniques", []))
        if tech_count == 0:
            print_info("知识图谱中暂无科技/技能实体，跳过材料依赖检查")
        else:
            print_pass(f"已检查 {mat_checked} 个科技的材料依赖，未发现缺失")
            total_pass += 1

    # --------------------------------------------------------
    # 4. 稀有度评定合理性检查
    # --------------------------------------------------------
    print_header("4. 稀有度评定合理性检查")
    rarity_issues, rarity_checked = check_rarity_reasonableness(kg_data)
    if rarity_issues:
        for severity, detail in rarity_issues:
            if severity == "FAIL":
                print_fail(detail)
                total_fail += 1
            else:
                print_warn(detail)
                total_warn += 1
            total_issues.append((severity, detail))
    else:
        print_pass(f"已检查 {rarity_checked} 个实体的稀有度，未发现不合理")
        total_pass += 1

    # --------------------------------------------------------
    # 5. 出处信息一致性检查
    # --------------------------------------------------------
    print_header("5. 出处信息一致性检查")
    source_issues, source_checked = check_source_field_consistency(kg_data, data_files_data)
    if source_issues:
        for severity, detail in source_issues:
            if severity == "FAIL":
                print_fail(detail)
                total_fail += 1
            elif severity == "WARN":
                print_warn(detail)
                total_warn += 1
            else:
                print_info(detail)
            total_issues.append((severity, detail))
    else:
        print_pass(f"已检查 {source_checked} 个实体的出处信息，未发现不一致")
        total_pass += 1

    # --------------------------------------------------------
    # 6. 汇总报告
    # --------------------------------------------------------
    print_header("一致性检查汇总")
    print_info(f"知识图谱版本: {kg_data.get('version', '未知')}")
    print_info(f"知识图谱实体总数: "
               f"山系 {len(kg_data.get('mountains', []))}, "
               f"异兽 {len(kg_data.get('creatures', []))}, "
               f"植物 {len(kg_data.get('plants', []))}, "
               f"矿物 {len(kg_data.get('minerals', []))}, "
               f"山神 {len(kg_data.get('gods', []))}, "
               f"科技 {len(kg_data.get('techniques', []))}")

    print()
    if total_fail == 0 and total_warn == 0:
        print(f"  {Color.GREEN}{Color.BOLD}检查结果: 全部通过，数据源之间高度一致{Color.RESET}")
    elif total_fail == 0:
        print(f"  {Color.YELLOW}{Color.BOLD}检查结果: 通过，但有 {total_warn} 个警告需关注{Color.RESET}")
    else:
        print(f"  {Color.RED}{Color.BOLD}检查结果: {total_fail} 个失败，{total_warn} 个警告{Color.RESET}")

    print(f"  通过: {Color.GREEN}{total_pass}{Color.RESET}")
    print(f"  失败: {Color.RED}{total_fail}{Color.RESET}")
    print(f"  警告: {Color.YELLOW}{total_warn}{Color.RESET}")

    # 输出所有问题列表
    if total_issues:
        print_header("问题详情列表")
        for severity, detail in total_issues:
            if severity == "FAIL":
                print_fail(detail)
            elif severity == "WARN":
                print_warn(detail)
            else:
                print_info(detail)

    print()
    return total_fail


if __name__ == "__main__":
    exit_code = main()
    sys.exit(1 if exit_code > 0 else 0)
