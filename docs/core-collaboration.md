# Snowhuman Framework 协作规则

当前协作规则：

1. 暂时不要拆分为新仓库。
2. 保持 `snowhuman_framework` 位于 `game/addons/snowhuman_framework/`。
3. 公开接口应先通过 RFC 提案，再进入实现。
4. 每个 PR 应聚焦一个模块或一个明确目标。
5. 不要把项目专属逻辑写入 Snowhuman Framework。
6. 内容数据放在 `game/data/`。
7. 第三方依赖记录在 `docs/third-party.md`。
8. 不要直接推送到主分支。
9. 通过 issue、分支和 PR 协作。

## CI 验证

PR 提交前应通过 `tools/validate_data.py` 和 `tools/check_framework.py`。
GitHub Actions 会在 PR 和 master push 时自动运行基础验证。
Godot CLI 检查仍作为本地可选验证。
