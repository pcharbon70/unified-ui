# unified-ui

Multi-agent Claude Code orchestration system for unified UI development in Elixir.

## Overview

This repository contains configuration and workflow definitions for developing Elixir-based user interface applications across multiple platforms (terminal, desktop, web) using a unified Spark-powered DSL.

## The Vision

The goal is to create a declarative UI DSL that abstracts platform-specific rendering, allowing developers to:

- Define UIs once using a common declarative syntax
- Target terminal, desktop, and web platforms from a single codebase
- Leverage the Jido ecosystem for agent-based component communication
- Build on proven patterns from The Elm Architecture

## Architecture

### Multi-Agent Orchestration

This repository implements a specialized Claude Code agent system:

- **Expert Agents (Opus)**: elixir-expert, research-agent, architecture-agent
- **Planning Agents (Sonnet)**: feature-planner, fix-planner, task-planner
- **Implementation Agents (Sonnet)**: implementation-agent, test-developer, test-fixer
- **Review Agents (Sonnet)**: 8 specialized reviewers for comprehensive validation

### Target Frameworks

| Framework | Status | Platform |
|-----------|--------|----------|
| **TermUi** | Mature | Terminal UI with 20+ widgets, 60 FPS rendering |
| **DesktopUi** | Early Stage | Desktop applications (TBD) |
| **WebUi** | Conceptual | Phoenix + Elm SPA architecture |

## Repository Structure

```
.claude/
├── agent-definitions/    # 24 specialized agent definitions
├── commands/             # 24 workflow commands
├── hooks/                # Automatic code formatting
├── AGENTS.md             # Complete orchestration guide
├── AGENT-SYSTEM-GUIDE.md # Model specs and tool permissions
└── HOOKS-GUIDE.md        # Hook system reference

notes/
└── research/             # Research and planning documents
```

## Key Workflows

### Four-Phase Workflow (Complex Features)

For topics requiring comprehensive research:

```
/research → /plan → /breakdown → /execute
```

1. **research** - Codebase impact analysis and third-party integration detection
2. **plan** - Strategic implementation planning
3. **breakdown** - Task decomposition into numbered checklists
4. **execute** - Sequential implementation

### Traditional Planning

- `/feature` - Comprehensive feature planning
- `/fix` - Focused fix planning
- `/task` - Lightweight task planning

### Testing & Review

- `/add-tests` - Systematic test development
- `/fix-tests` - Test failure resolution
- `/review` - Runs ALL review agents in parallel

## Documentation

- **CLAUDE.md** - Repository guidance for Claude Code
- **AGENTS.md** - Complete agent orchestration patterns
- **AGENT-SYSTEM-GUIDE.md** - Model specifications and expert guidance
- **HOOKS-GUIDE.md** - Hook system reference with examples

## Related Projects

- [jido_signal](https://github.com/agentjido/jido_signal) - Agent communication envelopes
- [term_ui](https://github.com/pcharbon70/term_ui) - Terminal UI framework
- [desktop_ui](https://github.com/pcharbon70/desktop_ui) - Desktop UI framework
- [Spark](https://github.com/ash-project/spark) - DSL building framework

## License

MIT
