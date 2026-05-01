---
description: Cascade-style iterative development workflow for code changes and refactoring
---

# Cascade Iteration Workflow

This workflow describes the iterative development methodology used by Cascade agents for making code changes, refactoring, and verification.

## Core Principles

1. **Minimal, Focused Changes**: Make the smallest possible change to fix an issue or implement a feature
2. **Root Cause First**: Always identify and fix the root cause rather than applying workarounds
3. **Verification**: Use automated verification tools when available
4. **Parallel Execution**: Batch independent operations together for efficiency
5. **State Management**: Keep TODO lists updated to track progress

## Iteration Process

### 1. Analysis Phase

**Gather Context:**
- Read relevant files to understand current implementation
- Search for related code patterns across the codebase
- Identify dependencies and potential side effects
- Use parallel tool calls when gathering information from multiple sources

**Example:**
```
# Read multiple files in parallel
- Read file A
- Read file B
- Search for pattern X
- Search for pattern Y
```

### 2. Planning Phase

**Create/Update TODO List:**
- Break down complex tasks into smaller steps
- Mark current task as `in_progress`
- Mark completed tasks as `completed`
- Use appropriate priority levels (high, medium, low)

**Example:**
```
- Task 1: Analyze current implementation (completed)
- Task 2: Design solution (in_progress)
- Task 3: Implement changes (pending)
- Task 4: Verify with tests (pending)
```

### 3. Implementation Phase

**Make Changes:**
- Use `edit` or `multi_edit` tools for code changes
- Prefer `multi_edit` when making multiple changes to the same file
- Keep changes scoped and follow existing code style
- Add necessary imports at the top of files (separate edit if needed)

**Best Practices:**
- Never output code to the user - use edit tools directly
- Ensure generated code is immediately runnable
- Add all necessary dependencies
- Follow the project's existing patterns and conventions

### 4. Verification Phase

**Run Analysis:**
- Execute `flutter analyze` (or equivalent for your stack)
- Fix any errors or warnings found
- Run tests if available
- Build the project to ensure no compilation errors

**Example:**
```bash
flutter analyze
flutter test
flutter build apk
```

### 5. Documentation Phase

**Update Documentation:**
- Update relevant comments in code
- Update README if needed
- Create or update memories for important context
- Mark TODO items as completed

## Common Patterns

### Refactoring Large Files

1. **Analyze the file structure** - Identify distinct responsibilities
2. **Extract components** - Create new files for separated concerns
3. **Update imports** - Add necessary imports in both old and new files
4. **Update references** - Change references to use new components
5. **Verify** - Run analysis to ensure no broken references
6. **Clean up** - Remove unused code and imports

### Bug Fixing

1. **Reproduce the issue** - Understand the exact conditions
2. **Find root cause** - Use logs, debugging, or code analysis
3. **Fix at source** - Make minimal change to fix root cause
4. **Add regression prevention** - Add tests or logging if appropriate
5. **Verify** - Ensure fix works and doesn't break other things

### Adding New Features

1. **Understand requirements** - Clarify what needs to be built
2. **Design the solution** - Plan the implementation approach
3. **Implement incrementally** - Build in small, testable chunks
4. **Add dependencies** - Update package files if needed
5. **Test thoroughly** - Verify the feature works as expected
6. **Document** - Add comments and update relevant docs

## Tool Usage Guidelines

### When to Use Parallel Calls

- Reading multiple files
- Searching for different patterns
- Running multiple read-only commands
- Gathering information from different sources

### When to Use Sequential Calls

- When output of one tool is needed for the next
- When making destructive changes
- When operations have dependencies

### Edit vs Multi-Edit

- Use `edit` for single changes
- Use `multi_edit` for multiple changes to the same file
- Always read the file first before editing
- Ensure old_string matches exactly (including whitespace)

## Communication Style

- Be terse and direct
- Deliver fact-based progress updates
- Briefly summarize after clusters of tool calls
- Ask for clarification only when genuinely uncertain
- Never use acknowledgment phrases like "Great idea!" or "I agree"
- Jump straight into addressing the request

## Error Handling

1. **Analyze the error** - Understand what went wrong
2. **Fix the root cause** - Don't just suppress symptoms
3. **Verify the fix** - Ensure the error is resolved
4. **Check for side effects** - Ensure nothing else broke
5. **Document if needed** - Add comments or update docs

## Example Workflow: Refactoring a God Object

```
1. Read the large file to understand structure
2. Identify distinct responsibilities (UI, state, logic, etc.)
3. Create new files for each responsibility
4. Extract code to new files
5. Update imports in original file
6. Update references throughout codebase
7. Run flutter analyze
8. Fix any errors found
9. Run tests
10. Build the project
11. Update TODO list to mark task complete
```

## Memory Management

- Create memories for important context that should persist
- Update memories when information changes
- Delete outdated or incorrect memories
- Use relevant tags for easy retrieval

## MCP Server Integration

### Context7 (Documentation)
- Use for fetching current documentation on libraries, frameworks, SDKs, APIs
- Always call `resolve-library-id` first to get the correct library ID
- Use `query-docs` for API syntax, configuration, version migration, debugging
- Prefer over web search for library documentation

### Dart MCP Server
- Use for Dart/Flutter development tasks
- Prefer MCP tools over shell commands for:
  - `dart pub get` → `mcp2_pub`
  - `flutter test` → `mcp2_run_tests`
  - `dart analyze` → `mcp2_analyze_files`
  - `dart format` → `mcp2_dart_format`
- Use `mcp2_launch_app` to run Flutter apps
- Use `mcp2_hot_reload` for applying code changes without restarting

### Memory MCP Server
- Create memories for important context that should persist across sessions
- Use tags for easy retrieval (e.g., `architecture`, `bug_fix`, `feature`)
- Update memories when information changes
- Delete outdated or incorrect memories

### Exa MCP Server
- Use for web search when you need current information
- Use `web_search_exa` for finding current info, news, facts
- Use `web_fetch_exa` to read full content from known URLs
- Prefer Context7 for library docs, Exa for general web content

## Project-Specific Guidelines

### Flutter Projects
- Run `flutter analyze` after changes
- Run `flutter pub get` after modifying pubspec.yaml
- Use `mcp2_run_tests` for running tests instead of shell commands
- Use `mcp2_launch_app` to test the app in a real environment
- Hot reload with `mcp2_hot_reload` for faster iteration

### Rust Projects
- Use `cargo check` for quick validation
- Use `cargo test` for running tests
- Use `cargo build` for compilation verification
- Run `cargo clippy` for linting

### Web Projects
- Use appropriate package managers (npm, yarn, pnpm)
- Run type checking (tsc, eslint, etc.)
- Test in browser when possible

## Advanced Patterns

### Working with Large Codebases

1. **Use grep strategically** - Search for patterns to understand code flow
2. **Follow dependency chains** - Trace imports and references
3. **Identify entry points** - Find main() or equivalent
4. **Map the architecture** - Understand the overall structure before making changes

### Debugging Complex Issues

1. **Add logging** - Insert debug statements to track state
2. **Isolate the problem** - Create minimal reproduction cases
3. **Use available tools** - Leverage MCP servers for debugging
4. **Test incrementally** - Verify each step of the fix

### Performance Optimization

1. **Profile first** - Use profiling tools to identify bottlenecks
2. **Measure before and after** - Quantify improvements
3. **Optimize hot paths** - Focus on frequently executed code
4. **Consider trade-offs** - Balance performance vs maintainability

## Troubleshooting

### Common Issues

**Analysis Errors:**
- Check for missing imports
- Verify dependency versions in pubspec.yaml
- Run `flutter pub get` to update dependencies
- Check for circular dependencies

**Build Failures:**
- Check for syntax errors
- Verify all dependencies are installed
- Check platform-specific requirements
- Review error messages carefully

**Test Failures:**
- Understand what the test expects
- Check if test data is valid
- Verify test environment setup
- Consider if the test needs updating

**Runtime Errors:**
- Add logging to track state
- Check for null safety issues
- Verify async/await usage
- Check for race conditions

## Best Practices Summary

1. **Always read before editing** - Understand the context
2. **Make minimal changes** - Fix the root cause only
3. **Verify after changes** - Run analysis and tests
4. **Document important decisions** - Add comments and memories
5. **Use parallel execution** - Batch independent operations
6. **Keep TODO lists updated** - Track progress visibly
7. **Communicate directly** - Be terse and factual
8. **Leverage MCP tools** - Use specialized tools when available

## Final Checklist

Before considering a task complete:
- [ ] All code changes implemented
- [ ] All imports added/updated
- [ ] Analysis passes with no errors
- [ ] Tests pass (if available)
- [ ] Build succeeds
- [ ] TODO list updated
- [ ] Documentation updated (if needed)
- [ ] Memories created/updated (if needed)
- [ ] No console errors or warnings
- [ ] Feature works as expected in testing
