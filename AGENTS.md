## 项目介绍
依托github平台，提供多个 Composite actions 来自动化项目管理，包括（但不限于）
- 代码审查（code review）
- 代码修复（code fix）
- 问题解答（Q&A）

## 项目规则
项目规则有关的 *.md 文件，存放在目录 agent-rules 中

## 参考资料
### 代码资源
- [anomalyco/opencodeopencode](https://github.com/anomalyco/opencode)
- [Barmore-Genc/opencode-pr-reviewer](https://github.com/Barmore-Genc/opencode-pr-reviewer)
- [alibaba/open-code-review](https://github.com/alibaba/open-code-review)

### 文档资源
[how to create github composite action](https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action)

## Action Development Standard

所有 GitHub Composite Action 必须遵循统一的技术栈与目录约定，以降低维护成本并保证一致性。

### 技术栈

- **包管理器**：pnpm >= 9
- **运行时**：Node.js >= 24
- **语言**：TypeScript 5.x
- **打包工具**：esbuild（通过 `packages/shared` 暴露的 `build-action` 调用）
- **工作区**：pnpm workspace（`packages/*`、`actions/*`）

### 目录结构

每个 Action 位于 `actions/<action-name>/`，必须包含：

```
actions/<action-name>/
├── action.yml          # Composite Action 定义（using: composite）
├── package.json        # 依赖、scripts、engines、action-steps
├── tsconfig.json       # 继承 packages/shared/tsconfig.action.json
├── README.md           # 说明、输入输出表格、使用示例
├── src/                # TypeScript 源码，每个 step 一个文件
│   ├── step-a.ts
│   └── step-b.ts
└── dist/               # 构建产物，必须提交到仓库
    ├── step-a.js
    └── step-b.js
```

### package.json 约定

- `engines.node` 必须为 `>=24`
- `scripts.build` 必须调用共享 build helper
- `scripts.lint` 必须执行 `tsc --noEmit`
- 通过 `action-steps` 字段声明需要打包的 step 名称列表，例如：

```json
{
  "action-steps": ["install", "configure", "run"],
  "scripts": {
    "build": "node build.js",
    "lint": "tsc --noEmit"
  },
  "dependencies": {
    "@gh-action-bundles/shared": "workspace:*"
  }
}
```

`build.js` invokes the shared helper:

```js
const { buildAction } = require('@gh-action-bundles/shared/build-action');
buildAction();
```

### tsconfig.json 约定

必须继承共享 preset，仅覆盖路径相关选项：

```json
{
  "extends": "../../packages/shared/tsconfig.action.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"]
}
```

### 构建与产物

- 使用 `pnpm build` 在 Action 目录或根目录构建
- `dist/` 必须随源码一起提交，因为消费者通过 `uses: owner/repo/actions/<name>@<ref>` 引用 Action 时不会执行安装/构建
- 禁止在 `dist/` 中提交 sourcemap 或 minified 代码（默认配置）

### Node 版本

- 所有 Action 的 esbuild target 为 `node24`
- `@types/node` 使用与 Node 24 对齐的版本
- GitHub Actions runner 使用 `ubuntu-latest` 或自带 Node 24 的环境