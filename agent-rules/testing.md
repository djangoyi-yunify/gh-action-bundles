# 测试规则

## 多任务测试策略

### 适用范围

本规则适用于任何按 scenario 组织、包含多步骤、可能依赖外部状态或存在前后序关系的多任务测试，包括但不限于 shell E2E 脚本、Python 集成测试、workflow 验证工具等。

### 三个层级

多任务测试围绕三个层级展开：

| 层级 | 定义 | 示例 |
|------|------|------|
| **task** | 需要完成的工作项，通常是实现或验证的最小计划单元 | OpenSpec task、开发任务 |
| **scenario** | 可独立执行的端到端测试用例，验证一个或多个 task | `tc-fork-auto-external` |
| **full regression** | 所有 scenario 一次性全量执行，作为最终验证 gate | 无参数运行测试脚本 |

一个 scenario 通常对应一个顶层 task；一个 task 可能包含多个实现子步骤，但这些子步骤不应作为独立的可执行 scenario。

### 工作流

开发期遵循 **task → scenario → 全量回归** 的顺序：

```
            实现 task
               │
               ▼
        运行对应 scenario
               │
      ┌────────┴────────┐
      ▼                 ▼
    通过               失败
      │                 │
      ▼                 ▼
  下一个 task ◀──────  修复
      │
      ▼
  还有未完成的 task/scenario？
      │
     否
      ▼
┌───────────────┐
│ 全量回归（1次） │
└───────────────┘
```

全量回归只在所有 scenario individually 通过后执行一次，用于最终验证，不应在迭代调试中反复重跑。

### 核心原则

1. **按 scenario 组织**：每个测试场景是一个独立、可命名的执行单元，具有明确的输入、断言和 cleanup。
2. **独立可运行**：任何 scenario 都应能通过单一命令单独触发，不依赖手动前置步骤。
3. **共享 runner 框架**：所有多任务测试脚本复用同一个 runner，统一提供 `--list`、`--only`、依赖排序、失败处理等能力。
4. **依赖关系显式声明**：scenario 之间的前后序依赖必须在注册时显式写出，runner 据此自动排序。
5. **开发期逐个运行，回归期只跑一次**：单个 scenario 调试通过后再执行全量回归。
6. **失败时快速反馈**：单个 scenario 调试失败应立即退出，方便定位；全量回归则收集所有失败后统一报告。

### Scenario 注册约定

每个 scenario 在 runner 中按统一格式注册：

```text
register_scenario(
  id: string,              // 唯一标识
  description: string,     // 人类可读描述
  dependencies: string[],  // 依赖列表
  handler: function        // 执行函数
)
```

示例：

```bash
register_scenario \
  "tc-fork-auto-external" \
  "External user opens fork PR; pull_request run is skipped" \
  "setup" \
  run_tc_fork_auto_external
```

**关于 group**：group 不是必需概念。当 scenario 数量较多、需要按主题过滤时，可作为可选的组织标签使用（如 `auto`、`manual`）。group 不影响执行顺序，执行顺序仅由 `dependencies` 决定。

### CLI 约定

| 参数 | 说明 |
|------|------|
| `--list` | 列出所有 scenario，包含 id、[group]、dependencies、description |
| `--only <scenario-id>` | 只运行指定 scenario，失败立即退出 |
| `--only <group>` | 运行指定 group 下的所有 scenario；仅当该脚本支持 group 时提供 |
| `--no-cleanup` | 失败后保留现场，便于调试；默认自动 cleanup |

### 依赖关系

`dependencies` 可包含两类内容：

1. **基础设施依赖**：如 `setup`，表示测试环境已准备就绪。
2. **scenario 依赖**：其他 scenario 的 `id`，表示该 scenario 必须先成功执行。

runner 的职责：

- 在运行前根据依赖关系进行拓扑排序。
- 遇到循环依赖时报错并退出。
- 依赖项失败时，依赖它的 scenario 不应继续执行。

### 失败行为

| 运行模式 | 失败行为 |
|----------|----------|
| `--only <scenario-id>` | 该 scenario 失败时立即退出，返回非零状态码 |
| `--only <group>` | group 内任一 scenario 失败时立即退出 |
| 全量回归（无参数） | 收集所有失败，最后统一报告；任一失败都导致最终退出码非零 |

### Cleanup 策略

- 单个 scenario 成功执行后，runner 默认自动执行其 cleanup。
- `--no-cleanup` 时，失败的 scenario 保留现场，便于人工排查。
- 全量回归时，每个 scenario 成功完成后执行 cleanup；失败的 scenario 根据 `--no-cleanup` 决定是否保留。
- cleanup 逻辑本身不应隐藏失败原因；若 cleanup 失败，应作为独立错误报告。

### 全量回归的执行时机

全量回归只在以下条件满足后执行一次：

- 所有 task 已实现。
- 所有 scenario 已通过 `--only` 方式 individually 验证通过。
- 相关代码或配置变更已稳定。

全量回归不是日常调试工具，而是最终 gate。

### 应用到具体脚本

编写新的多任务测试脚本时：

1. 复用项目已有的 runner 框架（如 `scripts/ocr-review-e2e/lib/runner.sh`）。
2. 每个 scenario 注册时填写清晰的 `id`、`description` 和 `dependencies`；`group` 仅在需要组织过滤时使用。
3. 保持 scenario 之间尽量独立；若必须共享状态，通过 `dependencies` 显式表达。
4. 提供 `--list` 输出，方便他人快速了解测试覆盖范围。
