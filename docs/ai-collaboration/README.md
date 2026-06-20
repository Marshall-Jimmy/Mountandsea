# AI协作开发体系

**版本**: 0.1.0  
**最后更新**: 2026-06-20  
**维护者**: 文化内核AI负责人

---

## 目录说明

本目录包含山海经项目的AI多人协作开发体系，由文化内核AI负责人发起并维护。

### 目录结构

```
ai-collaboration/
├── knowledge-graph/          # 山海经知识图谱
│   ├── schema.json           # 知识图谱Schema定义
│   ├── example-data.json     # 示例数据（南山经部分）
│   ├── mvp-data.json        # MVP版数据（鹊山系10山，39个实体）
│   └── full-data.json       # 完整版数据（全部山经+海经+大荒经，340+实体）
│
├── tools/                   # 自动化校验工具
│   ├── kg_validator.py       # L1 数据格式校验器
│   ├── consistency_checker.py # L2 设定一致性检查器
│   └── style_linter.py      # L4 文言文风格检查器
│
├── consistency-check/        # 跨系统一致性校验
│   └── rules.md              # 校验规则文档
│
├── style-guide/              # 风格指南
│   └── classical-chinese-guide.md  # 文言文风格指南与命名规范
│
└── workflow/                 # 协作工作流
    └── roles-and-workflow.md # AI角色分工与协作工作流
```

---

## 核心思想

AI多人协作最大的风险不是"做不出来"，而是"拼不起来"。

六个AI各干各的，最后会出现：
- 设定打架（这个AI说九尾狐是瑞兽，那个AI说是妖兽）
- 内容缺失（医药AI要的材料，工匠AI没做）
- 数值崩坏（跨分支组合强度爆炸）
- 风格不统一（有的像先秦，有的像明清）

本体系就是为了解决这些问题。

---

## 我是谁？

我是**文化内核AI负责人**，负责：
- 🧠 维护山海经知识图谱（所有设定的唯一真相源）
- ⚖️ 跨系统设定一致性校验
- 📜 文言文风格把控与命名规范
- 🏛️ 文化考据与设定仲裁

简单说：**别人负责把游戏做"大"，我负责把游戏做"对"。**

---

## 快速开始

### 新AI加入项目必读
1. 先看 [workflow/roles-and-workflow.md](./workflow/roles-and-workflow.md) 了解角色分工
2. 再看 [knowledge-graph/schema.json](./knowledge-graph/schema.json) 了解数据格式
3. 然后看 [style-guide/classical-chinese-guide.md](./style-guide/classical-chinese-guide.md) 了解文风要求
4. 最后看 [consistency-check/rules.md](./consistency-check/rules.md) 了解校验规则

### 提交内容前自查
- [ ] 数据格式符合Schema
- [ ] 命名符合规范
- [ ] 没有现代游戏术语
- [ ] 设定与知识图谱一致
- [ ] 有明确的典籍/原文出处

---

## 后续规划

- [x] 知识图谱数据补全（全部山经+海经+大荒经，340+实体）
- [x] 自动化校验工具开发（L1格式/L2一致性/L4风格，3个Python脚本）
- [ ] CI/CD流程集成
- [ ] 数值平衡仿真器
- [ ] 文言文风格检查器增强（接入大模型）

---

**欢迎其他AI负责人补充完善本体系，有问题随时找文化内核AI。**
