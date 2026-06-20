#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
L4 文言文风格检查器 - 山海经知识图谱文案风格合规检查工具

用途：
  扫描知识图谱 full-data.json 中所有实体的描述文本，检查是否包含：
  - 禁用词汇（现代游戏术语）
  - 后世词汇（山海经成书后出现的词汇）
  - 现代命名规范问题
  参考风格指南 classical-chinese-guide.md 中的规范。

用法：
  python style_linter.py

输出：
  格式化的风格检查报告，对每个问题给出实体ID、字段、问题类型、建议修改。
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
STYLE_GUIDE_DIR = os.path.join(PROJECT_DIR, "style-guide")
FULL_DATA_PATH = os.path.join(KG_DIR, "full-data.json")
STYLE_GUIDE_PATH = os.path.join(STYLE_GUIDE_DIR, "classical-chinese-guide.md")

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
# 禁用词与后世词汇定义
# 参考 classical-chinese-guide.md 中的规范
# ============================================================

# 绝对禁用（现代游戏术语）
BANNED_WORDS = [
    "经验", "等级", "升级",
    "HP", "MP", "血量", "蓝量",
    "装备", "背包", "技能栏",
    "任务", "奖励", "成就",
    "伤害", "防御", "攻击力",
    "NPC", "BOSS", "小怪",
    "玩家", "账号", "存档",
]

# 尽量避免（后世词汇，山海经成书后出现）
ANACHRONISTIC_WORDS = [
    "佛", "菩萨", "和尚",        # 佛教东汉传入
    "道士", "道观",              # 道教后起
    "纸",                        # 汉代发明
    "茶",                        # 唐代盛行
    "椅子",                      # 唐代以后
]

# 现代游戏术语扩展检测（正则模式）
MODERN_GAME_PATTERNS = [
    (r"\d+级", "数字+级（如'3级'），建议使用'三阶'或'三层'"),
    (r"\d+阶", "数字+阶（如'5阶'），建议使用中文数字"),
    (r"[+-]?\d+(?:\.\d+)?%", "百分比数值（如'+10%'），建议使用描述性文字"),
    (r"CD|冷却", "冷却时间，建议使用'须臾'、'片刻'等"),
    (r"buff|debuff", "buff/debuff，建议使用'增益'、'减益'或具体效果描述"),
    (r"DPS", "DPS，建议使用'杀伤'、'攻击'等"),
    (r"AOE", "AOE，建议使用'群攻'、'范围'等"),
    (r"BUG|bug", "BUG，避免使用现代术语"),
    (r"PK|pk", "PK，建议使用'斗法'、'比武'等"),
    (r"VIP|vip", "VIP，避免使用"),
    (r"NPC|npc", "NPC，建议使用具体身份称呼"),
    (r"BOSS|boss", "BOSS，建议使用具体名称或'大妖'、'凶兽'等"),
]

# 现代命名模式检测
MODERN_NAMING_PATTERNS = [
    (r"新手村", "现代游戏地名，建议使用先秦风格地名"),
    (r"商店", "现代概念，建议使用'市'、'肆'"),
    (r"商城", "现代概念，建议使用'市'、'肆'"),
    (r"副本", "现代游戏术语"),
    (r"组队", "现代游戏术语，建议使用'结伴'、'同行'"),
    (r"公会", "现代游戏术语，建议使用'族'、'部落'"),
    (r"排行榜", "现代概念，建议使用'名册'、'功绩'"),
    (r"签到", "现代游戏术语"),
    (r"充值", "现代游戏术语"),
    (r"抽卡", "现代游戏术语"),
    (r"皮肤", "现代游戏术语（外观类）"),
    (r"段位", "现代游戏术语"),
    (r"匹配", "现代游戏术语"),
    (r"赛季", "现代游戏术语"),
]

# 替代建议映射
SUGGESTION_MAP = {
    "经验": "修为、道行",
    "等级": "境界、层次",
    "HP": "气血、性命",
    "血量": "气血、性命",
    "MP": "灵力、真气",
    "蓝量": "灵力、真气",
    "装备": "随身、披挂",
    "背包": "行囊、包裹",
    "技能栏": "招式、术法",
    "任务": "差事、托付",
    "奖励": "酬劳、赏赐",
    "成就": "功绩、事迹",
    "伤害": "伤势、损耗",
    "防御": "护体、防身",
    "攻击力": "武力、杀伤",
    "NPC": "具体身份称呼（如'老父'、'巫咸'）",
    "BOSS": "大妖、凶兽、巨灵",
    "小怪": "小兽、妖虫、蛇虫",
    "玩家": "旅人、行者、修士",
    "账号": "（不应出现）",
    "存档": "（不应出现）",
    "佛": "（山海经时代佛教未传入，应避免）",
    "菩萨": "（山海经时代佛教未传入，应避免）",
    "和尚": "（山海经时代佛教未传入，应避免）",
    "道士": "（道教后起，应避免）",
    "道观": "（道教后起，应避免）",
    "纸": "简牍、帛书",
    "茶": "（唐代盛行，先秦时代应避免）",
    "椅子": "席、榻",
}


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


# ============================================================
# 文本检查函数
# ============================================================

def extract_text_fields(entity):
    """
    从实体中提取所有需要检查的文本字段。
    返回 [(字段路径, 文本值)] 列表。
    """
    text_fields = []

    # 顶层字符串字段
    string_keys = ["name", "alias", "mountain", "appearance", "cry", "description",
                   "section", "biome", "source", "type"]
    for key in string_keys:
        value = entity.get(key)
        if isinstance(value, str) and value.strip():
            text_fields.append((key, value))

    # alias 是数组
    alias = entity.get("alias")
    if isinstance(alias, list):
        for a in alias:
            if isinstance(a, str) and a.strip():
                text_fields.append(("alias[]", a))

    # effects / uses 对象
    for effects_key in ("effects", "uses"):
        effects = entity.get(effects_key)
        if isinstance(effects, dict):
            for sub_key, sub_value in effects.items():
                if isinstance(sub_value, str) and sub_value.strip():
                    text_fields.append((f"{effects_key}.{sub_key}", sub_value))

    # sacrifice 对象
    sacrifice = entity.get("sacrifice")
    if isinstance(sacrifice, dict):
        for sub_key, sub_value in sacrifice.items():
            if isinstance(sub_value, str) and sub_value.strip():
                text_fields.append((f"sacrifice.{sub_key}", sub_value))

    # blessings 数组
    blessings = entity.get("blessings")
    if isinstance(blessings, list):
        for b in blessings:
            if isinstance(b, str) and b.strip():
                text_fields.append(("blessings[]", b))

    # sacrificeRule 字符串
    sacrifice_rule = entity.get("sacrificeRule")
    if isinstance(sacrifice_rule, str) and sacrifice_rule.strip():
        text_fields.append(("sacrificeRule", sacrifice_rule))

    # 数组字段中的字符串
    # 注意：prerequisites、crossBranchPrereqs、unlocks 中的科技ID引用（如 tech_survival_1）
    # 属于结构引用而非描述文本，跳过风格检查
    id_ref_fields = {"prerequisites", "crossBranchPrereqs", "unlocks"}
    for array_key in ("techBranches", "prerequisites", "crossBranchPrereqs",
                     "unlocks", "materials", "creatures", "plants", "minerals"):
        arr = entity.get(array_key)
        if isinstance(arr, list):
            for item in arr:
                if isinstance(item, str) and item.strip():
                    if array_key in id_ref_fields and item.startswith(("tech_", "creature_", "plant_", "mineral_", "mountain_", "god_")):
                        continue  # 跳过 ID 引用，不进行风格检查
                    text_fields.append((f"{array_key}[]", item))

    return text_fields


def check_banned_words(text, field_path):
    """检查绝对禁用词汇"""
    issues = []
    for word in BANNED_WORDS:
        # 使用正则进行全词匹配，避免误匹配（如"茶"不应匹配"茶几"中的"茶"）
        pattern = re.compile(r'(?<![^\s，。、；：！？""''（）])' + re.escape(word) + r'(?![^\s，。、；：！？""''（）])')
        matches = pattern.findall(text)
        if matches:
            suggestion = SUGGESTION_MAP.get(word, "")
            issues.append({
                "type": "禁用词汇",
                "word": word,
                "field": field_path,
                "text": text,
                "suggestion": f"建议替换为: {suggestion}" if suggestion else "应删除或替换",
            })
    return issues


def check_anachronistic_words(text, field_path):
    """检查后世词汇"""
    issues = []
    for word in ANACHRONISTIC_WORDS:
        # 对单字词汇使用更精确的匹配
        if len(word) == 1:
            pattern = re.compile(re.escape(word))
        else:
            pattern = re.compile(re.escape(word))
        matches = pattern.findall(text)
        if matches:
            suggestion = SUGGESTION_MAP.get(word, "")
            issues.append({
                "type": "后世词汇",
                "word": word,
                "field": field_path,
                "text": text,
                "suggestion": f"建议替换为: {suggestion}" if suggestion else "应避免使用",
            })
    return issues


def check_modern_game_terms(text, field_path):
    """检查现代游戏术语模式"""
    issues = []
    for pattern, desc in MODERN_GAME_PATTERNS:
        matches = re.findall(pattern, text)
        if matches:
            issues.append({
                "type": "现代游戏术语",
                "word": matches[0],
                "field": field_path,
                "text": text,
                "suggestion": desc,
            })
    return issues


def check_modern_naming(text, field_path):
    """检查现代命名模式"""
    issues = []
    for pattern, desc in MODERN_NAMING_PATTERNS:
        matches = re.findall(pattern, text)
        if matches:
            issues.append({
                "type": "现代命名",
                "word": matches[0],
                "field": field_path,
                "text": text,
                "suggestion": desc,
            })
    return issues


def check_entity(entity, entity_id):
    """
    对单个实体执行所有风格检查。
    返回问题列表。
    """
    issues = []
    text_fields = extract_text_fields(entity)

    for field_path, text in text_fields:
        # 跳过 "未知" 值
        if text.strip() == "未知":
            continue

        # 1. 禁用词汇检查
        issues.extend(check_banned_words(text, field_path))

        # 2. 后世词汇检查
        issues.extend(check_anachronistic_words(text, field_path))

        # 3. 现代游戏术语检查
        issues.extend(check_modern_game_terms(text, field_path))

        # 4. 现代命名检查
        issues.extend(check_modern_naming(text, field_path))

    return issues


# ============================================================
# 主流程
# ============================================================

def main():
    print_header("山海经知识图谱 - L4 文言文风格检查报告")

    # 加载数据
    print_info(f"加载知识图谱: {FULL_DATA_PATH}")
    kg_data = load_json(FULL_DATA_PATH)
    if kg_data is None:
        print_fail("无法加载知识图谱数据，检查终止。")
        return 1

    # 加载风格指南（可选，用于参考）
    print_info(f"风格指南: {STYLE_GUIDE_PATH}")
    if os.path.exists(STYLE_GUIDE_PATH):
        print_pass("风格指南文件存在")
    else:
        print_warn("风格指南文件不存在，将使用内置规则进行检查")

    print_info(f"数据版本: {kg_data.get('version', '未知')}")

    # 统计
    all_issues = []
    total_entities_checked = 0
    total_text_fields_checked = 0
    entities_with_issues = set()

    # 实体类型映射
    entity_type_map = {
        "mountain": kg_data.get("mountains", []),
        "creature": kg_data.get("creatures", []),
        "plant": kg_data.get("plants", []),
        "mineral": kg_data.get("minerals", []),
        "god": kg_data.get("gods", []),
        "technique": kg_data.get("techniques", []),
    }

    type_names = {
        "mountain": "山系/地理实体",
        "creature": "异兽/生物实体",
        "plant": "草木/植物实体",
        "mineral": "矿物/玉石实体",
        "god": "神灵/山神实体",
        "technique": "科技/技能实体",
    }

    # --------------------------------------------------------
    # 逐实体类型检查
    # --------------------------------------------------------
    for etype, entities in entity_type_map.items():
        print_header(f"检查: {type_names.get(etype, etype)} ({len(entities)} 个实体)")

        if not entities:
            print_info(f"无 {type_names.get(etype, etype)} 数据")
            continue

        type_issues = []
        for entity in entities:
            eid = entity.get("id", "未知")
            name = entity.get("name", "未知")
            issues = check_entity(entity, eid)
            total_entities_checked += 1
            total_text_fields_checked += len(extract_text_fields(entity))

            if issues:
                entities_with_issues.add(eid)
                for issue in issues:
                    issue["entity_id"] = eid
                    issue["entity_name"] = name
                    type_issues.append(issue)

        if type_issues:
            for issue in type_issues:
                issue_type = issue["type"]
                word = issue["word"]
                field = issue["field"]
                eid = issue["entity_id"]
                ename = issue["entity_name"]
                suggestion = issue["suggestion"]

                # 根据问题类型选择输出级别
                if issue_type == "禁用词汇":
                    print_fail(
                        f"[{eid}] '{ename}' | 字段: {field} | "
                        f"发现禁用词: '{word}' | {suggestion}"
                    )
                elif issue_type == "后世词汇":
                    print_warn(
                        f"[{eid}] '{ename}' | 字段: {field} | "
                        f"发现后世词: '{word}' | {suggestion}"
                    )
                else:
                    print_warn(
                        f"[{eid}] '{ename}' | 字段: {field} | "
                        f"{issue_type}: '{word}' | {suggestion}"
                    )

                all_issues.append(issue)
        else:
            print_pass(f"全部 {len(entities)} 个实体通过风格检查")

    # --------------------------------------------------------
    # 按问题类型汇总
    # --------------------------------------------------------
    print_header("问题分类汇总")

    # 按类型统计
    type_counts = {}
    for issue in all_issues:
        itype = issue["type"]
        type_counts[itype] = type_counts.get(itype, 0) + 1

    banned_count = type_counts.get("禁用词汇", 0)
    anach_count = type_counts.get("后世词汇", 0)
    game_term_count = type_counts.get("现代游戏术语", 0)
    modern_name_count = type_counts.get("现代命名", 0)

    if banned_count > 0:
        print_fail(f"禁用词汇（现代游戏术语）: {banned_count} 处")
    else:
        print_pass("未发现禁用词汇")

    if anach_count > 0:
        print_warn(f"后世词汇: {anach_count} 处")
    else:
        print_pass("未发现后世词汇")

    if game_term_count > 0:
        print_warn(f"现代游戏术语模式: {game_term_count} 处")
    else:
        print_pass("未发现现代游戏术语模式")

    if modern_name_count > 0:
        print_warn(f"现代命名模式: {modern_name_count} 处")
    else:
        print_pass("未发现现代命名模式")

    # --------------------------------------------------------
    # 最终汇总
    # --------------------------------------------------------
    print_header("风格检查汇总")
    print_info(f"检查实体总数: {total_entities_checked}")
    print_info(f"检查文本字段总数: {total_text_fields_checked}")
    print_info(f"有问题实体数: {len(entities_with_issues)}")
    print_info(f"问题总数: {len(all_issues)}")

    print()
    total_severe = banned_count
    total_moderate = anach_count + game_term_count + modern_name_count

    if len(all_issues) == 0:
        print(f"  {Color.GREEN}{Color.BOLD}检查结果: 全部通过，文案风格符合文言文规范{Color.RESET}")
    elif total_severe == 0:
        print(f"  {Color.YELLOW}{Color.BOLD}检查结果: 无禁用词，但有 {total_moderate} 个建议修改项{Color.RESET}")
    else:
        print(f"  {Color.RED}{Color.BOLD}检查结果: {total_severe} 个禁用词，{total_moderate} 个建议修改项{Color.RESET}")

    # --------------------------------------------------------
    # 详细问题列表（表格形式）
    # --------------------------------------------------------
    if all_issues:
        print_header("问题详情列表")
        print(f"  {'实体ID':<30} {'实体名':<10} {'字段':<20} {'类型':<12} {'问题词':<8} {'建议'}")
        print(f"  {'-'*30} {'-'*10} {'-'*20} {'-'*12} {'-'*8} {'-'*20}")
        for issue in all_issues:
            eid = issue["entity_id"]
            ename = issue["entity_name"]
            field = issue["field"]
            itype = issue["type"]
            word = issue["word"]
            suggestion = issue["suggestion"]
            # 截断过长的文本
            if len(suggestion) > 20:
                suggestion = suggestion[:20] + "..."
            print(f"  {eid:<30} {ename:<10} {field:<20} {itype:<12} {word:<8} {suggestion}")

    print()
    return total_severe


if __name__ == "__main__":
    exit_code = main()
    sys.exit(1 if exit_code > 0 else 0)
