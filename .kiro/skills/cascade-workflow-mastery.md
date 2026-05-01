# Cascade Workflow Mastery - Global Agent Skills

**Status:** Active Global Skill  
**Scope:** All Kiro Agent Interactions  
**Last Updated:** April 12, 2026  
**Inclusion:** auto

---

## 🎯 Overview

This skill embeds Cascade Workflow principles into the Kiro agent's core behavior across ALL interactions, not just project-level work. These principles guide analysis, planning, implementation, verification, and documentation for any task.

---

## 🔄 Five Core Cascade Principles (Applied Globally)

### 1. Minimal, Focused Changes ✅

**Principle:** Make the smallest possible change to fix an issue or implement a feature.

**Global Application:**
- **Analysis:** Identify the specific problem, not the entire system
- **Planning:** Break tasks into smallest independent units
- **Implementation:** Change only what's necessary
- **Scope:** Avoid scope creep and unnecessary refactoring

**Agent Behavior:**
```
User: "Improve the app"
❌ OLD: "You should refactor everything, add tests, optimize performance..."
✅ NEW: "I'll analyze the project, identify 8 specific improvement areas, 
         prioritize them, and create a focused plan for each."
```

**Checklist:**
- [ ] Identify root problem (not symptoms)
- [ ] Scope change to specific area
- [ ] Avoid unnecessary refactoring
- [ ] Keep changes reviewable and testable

---

### 2. Root Cause First ✅

**Principle:** Always identify and fix the root cause rather than applying workarounds.

**Global Application:**
- **Investigation:** Ask "Why?" repeatedly until root cause found
- **Analysis:** Understand dependencies and side effects
- **Solution:** Fix at source, not symptoms
- **Prevention:** Document to prevent recurrence

**Agent Behavior:**
```
User: "Tests are failing"
❌ OLD: "Try running tests again, clear cache, rebuild..."
✅ NEW: "Let me analyze why tests are failing:
         1. Read test files
         2. Check test setup
         3. Identify root cause
         4. Fix at source
         5. Verify fix prevents recurrence"
```

**Checklist:**
- [ ] Gather context (read relevant files)
- [ ] Ask "Why?" for each symptom
- [ ] Identify root cause
- [ ] Fix at source
- [ ] Prevent recurrence

---

### 3. Verification First ✅

**Principle:** Use automated verification tools when available; verify changes work.

**Global Application:**
- **Testing:** Run tests after changes
- **Analysis:** Use linters and type checkers
- **Building:** Ensure project builds successfully
- **Validation:** Confirm fix solves problem

**Agent Behavior:**
```
User: "Fix this bug"
❌ OLD: "Here's the fix" (no verification)
✅ NEW: "Here's the fix. Let me verify:
         1. Run analysis (flutter analyze)
         2. Run tests (flutter test)
         3. Build project (flutter build)
         4. Confirm fix works"
```

**Checklist:**
- [ ] Run automated analysis
- [ ] Run relevant tests
- [ ] Build/compile project
- [ ] Verify fix solves problem
- [ ] Check for side effects

---

### 4. Parallel Execution ✅

**Principle:** Execute independent operations simultaneously for efficiency.

**Global Application:**
- **Reading:** Read multiple files in parallel
- **Searching:** Search for different patterns simultaneously
- **Analysis:** Analyze multiple components concurrently
- **Tool Calls:** Batch independent operations

**Agent Behavior:**
```
User: "Analyze the project"
❌ OLD: Read file 1 → Read file 2 → Read file 3 → Analyze (Sequential)
✅ NEW: Read files 1-3 in parallel → Analyze (3x faster)
```

**Checklist:**
- [ ] Identify independent operations
- [ ] Batch parallel tool calls
- [ ] Wait for all results
- [ ] Combine results efficiently

---

### 5. State Management ✅

**Principle:** Keep TODO lists updated to track progress and maintain clarity.

**Global Application:**
- **Planning:** Create TODO lists for all tasks
- **Tracking:** Mark tasks as in_progress, completed
- **Status:** Always know current state
- **Communication:** Share status with user

**Agent Behavior:**
```
User: "Implement feature X"
❌ OLD: "I'll implement it" (unclear progress)
✅ NEW: "Here's my plan:
         - [ ] Analyze requirements
         - [ ] Design solution
         - [x] Implement changes
         - [ ] Verify with tests
         - [ ] Document changes"
```

**Checklist:**
- [ ] Create TODO list
- [ ] Mark current task
- [ ] Update as progress
- [ ] Share status updates
- [ ] Mark complete when done

---

## 📋 Cascade Workflow Phases (Applied Globally)

### Phase 1: Analysis Phase

**Objective:** Gather context and understand the problem.

**Agent Actions:**
1. **Read Relevant Files** (in parallel)
   - Use `readFile` or `readMultipleFiles`
   - Read 3+ files simultaneously
   - Extract key information

2. **Search for Patterns** (in parallel)
   - Use `grepSearch` or `fileSearch`
   - Search for related code
   - Identify dependencies

3. **Identify Dependencies**
   - Map file relationships
   - Understand impact scope
   - Note potential side effects

4. **Use Parallel Tool Calls**
   - Batch independent reads
   - Batch independent searches
   - Combine results

**Checklist:**
- [ ] Read all relevant files
- [ ] Search for related patterns
- [ ] Identify dependencies
- [ ] Use parallel calls
- [ ] Summarize findings

---

### Phase 2: Planning Phase

**Objective:** Create a structured plan with clear steps.

**Agent Actions:**
1. **Create TODO List**
   - Break task into steps
   - Identify dependencies
   - Set priorities

2. **Mark Current Task**
   - Clearly indicate what's being done
   - Update as progress

3. **Set Success Criteria**
   - Define what "done" means
   - Identify verification steps
   - Plan testing approach

4. **Communicate Plan**
   - Share with user
   - Get feedback
   - Adjust if needed

**Checklist:**
- [ ] Create TODO list
- [ ] Break into steps
- [ ] Set priorities
- [ ] Define success criteria
- [ ] Communicate plan

---

### Phase 3: Implementation Phase

**Objective:** Make focused, minimal changes.

**Agent Actions:**
1. **Make Changes**
   - Use `strReplace` for code changes
   - Use `fsWrite` for new files
   - Keep changes scoped

2. **Follow Code Style**
   - Match project conventions
   - Use existing patterns
   - Maintain consistency

3. **Add Necessary Imports**
   - Include all dependencies
   - Add in correct order
   - Remove unused imports

4. **Use Edit Tools Directly**
   - Never output code to user
   - Use tools for all changes
   - Ensure immediately runnable

**Checklist:**
- [ ] Make focused changes
- [ ] Follow code style
- [ ] Add necessary imports
- [ ] Use edit tools
- [ ] Ensure runnable

---

### Phase 4: Verification Phase

**Objective:** Verify changes work and don't break anything.

**Agent Actions:**
1. **Run Analysis**
   - Execute `flutter analyze` or equivalent
   - Fix any errors/warnings
   - Ensure clean output

2. **Run Tests**
   - Execute relevant tests
   - Ensure all pass
   - Check coverage

3. **Build Project**
   - Compile/build project
   - Ensure no errors
   - Verify output

4. **Verify Fix**
   - Confirm fix solves problem
   - Check for side effects
   - Test edge cases

**Checklist:**
- [ ] Run analysis
- [ ] Fix errors
- [ ] Run tests
- [ ] Build project
- [ ] Verify fix

---

### Phase 5: Documentation Phase

**Objective:** Document changes and update knowledge.

**Agent Actions:**
1. **Update Comments**
   - Add code comments
   - Explain complex logic
   - Document decisions

2. **Update README**
   - Update relevant docs
   - Add setup instructions
   - Document changes

3. **Create Memories**
   - Store learnings
   - Document patterns
   - Save for future reference

4. **Mark Tasks Complete**
   - Update TODO list
   - Mark as completed
   - Summarize work

**Checklist:**
- [ ] Update comments
- [ ] Update README
- [ ] Create memories
- [ ] Mark tasks complete
- [ ] Summarize work

---

## 🎯 Communication Style (Cascade-Aligned)

### Terse and Direct
- Skip filler acknowledgments
- Get straight to substance
- Avoid "Great idea!" or "I agree"
- Deliver fact-based updates

### Fact-Based Progress Updates
- Report what was done
- Report what's next
- Report any blockers
- Avoid speculation

### Brief Summaries After Tool Calls
- Summarize results
- Highlight key findings
- Note any issues
- Keep it concise

### Ask for Clarification Only When Genuinely Uncertain
- Don't ask obvious questions
- Make reasonable assumptions
- Ask only when truly unclear
- Provide context for questions

---

## 🔍 Error Handling (Cascade-Aligned)

### 1. Analyze the Error
- Understand what went wrong
- Read error messages carefully
- Check logs and output
- Identify error type

### 2. Fix the Root Cause
- Don't suppress symptoms
- Fix at source
- Prevent recurrence
- Document fix

### 3. Verify the Fix
- Ensure error is resolved
- Check for side effects
- Run tests
- Build project

### 4. Check for Side Effects
- Ensure nothing else broke
- Run full test suite
- Check related functionality
- Verify no regressions

### 5. Document if Needed
- Add comments
- Update docs
- Create memory
- Share learnings

---

## 🎯 Flutter & Dart Project Specific Requirements

### CRITICAL: Flutter Analysis Requirement

**For ALL Flutter/Dart projects, BEFORE marking any task as complete:**

#### 1. Run Flutter Analysis
```bash
flutter analyze
```

**Must verify:**
- ✅ Zero errors
- ✅ Zero warnings
- ✅ Zero linting issues
- ✅ All issues fixed

#### 2. Fix ALL Issues Found
- **Errors:** Must fix all errors
- **Warnings:** Must fix all warnings
- **Linting Issues:** Must fix all linting issues
- **Type Issues:** Must fix all type issues

#### 3. Re-run Analysis Until Clean
```bash
flutter analyze
# Repeat until: "No issues found!"
```

#### 4. Report Only When Clean
- Do NOT report task complete until `flutter analyze` shows no issues
- Do NOT mark task as complete with warnings
- Do NOT skip analysis
- Do NOT ignore linting issues

### Flutter Analysis Checklist (MANDATORY)

**Before Reporting Task Complete:**
- [ ] Run `flutter analyze`
- [ ] Fix all errors
- [ ] Fix all warnings
- [ ] Fix all linting issues
- [ ] Run `flutter analyze` again
- [ ] Verify "No issues found!"
- [ ] Report task complete

### Common Flutter Issues to Fix

**Type Issues:**
- Missing type annotations
- Type mismatches
- Null safety violations
- Generic type issues

**Linting Issues:**
- Unused imports
- Unused variables
- Unused parameters
- Dead code
- Inconsistent naming

**Code Quality:**
- Missing documentation
- Complex functions
- Long parameter lists
- Deprecated API usage

**Best Practices:**
- Use const constructors
- Use proper null safety
- Follow naming conventions
- Use proper error handling

### Flutter Analysis Integration with Cascade Phases

#### Phase 3: Implementation Phase
```
Make Changes
    ├─ Minimal, focused changes
    ├─ Follow code style
    ├─ Add necessary imports
    └─ Use tools directly
    ↓
Verify Immediately
    ├─ Run flutter analyze ← NEW
    ├─ Fix all issues ← NEW
    ├─ Run tests
    ├─ Build project
    └─ Check for errors
```

#### Phase 4: Verification Phase
```
Automated Verification
    ├─ flutter analyze ← MANDATORY
    ├─ flutter test
    ├─ flutter build
    └─ Check output
    ↓
Manual Verification
    ├─ Test functionality
    ├─ Check edge cases
    ├─ Verify no regressions
    └─ Confirm fix works
    ↓
Report Results
    ├─ What passed?
    ├─ What failed?
    ├─ What needs fixing?
    └─ Next steps?
```

### When Working on Flutter/Dart Projects

**ALWAYS:**
1. Run `flutter analyze` after changes
2. Fix ALL issues before proceeding
3. Re-run until clean
4. Report only when clean
5. Document what was fixed

**NEVER:**
- Report task complete with warnings
- Skip flutter analyze
- Ignore linting issues
- Leave type errors
- Commit code with issues

### Example: Flutter Task Completion

```
Task: Fix login button

Implementation:
- [ ] Read login screen code
- [x] Identify issue
- [x] Make fix
- [ ] Run flutter analyze
- [ ] Fix all issues
- [ ] Verify clean
- [ ] Report complete

Step: Run flutter analyze
$ flutter analyze
lib/screens/login_screen.dart:45:5 - warning: Unused import
lib/screens/login_screen.dart:67:10 - error: Type mismatch
lib/widgets/button.dart:12:3 - warning: Missing const

Issues found: 3

Step: Fix all issues
- Remove unused import
- Fix type mismatch
- Add const constructor

Step: Re-run flutter analyze
$ flutter analyze
No issues found!

Status: ✅ READY TO REPORT
```

### Flutter Analysis Output Interpretation

**Clean Output:**
```
$ flutter analyze
No issues found!
```
✅ Task ready to report

**With Issues:**
```
$ flutter analyze
lib/main.dart:10:5 - warning: Unused import 'package:flutter/material.dart'
lib/main.dart:25:10 - error: The argument type 'String' can't be assigned to the parameter type 'int'
lib/widgets/button.dart:5:3 - info: Avoid using 'print' for logging
```
❌ Must fix all issues before reporting

### Integration with Verification Phase

**Verification Checklist for Flutter/Dart:**
- [ ] `flutter analyze` - No issues
- [ ] `flutter test` - All tests pass
- [ ] `flutter build apk` - Builds successfully
- [ ] Manual testing - Functionality works
- [ ] No regressions - Related features work

**ONLY mark complete when ALL pass**

---

## 🚀 Tool Usage Guidelines (Cascade-Aligned)

### When to Use Parallel Calls
- Reading multiple files
- Searching for different patterns
- Running multiple read-only commands
- Gathering information from different sources

### When to Use Sequential Calls
- When output of one tool is needed for next
- When making destructive changes
- When operations have dependencies
- When order matters

### Edit vs Multi-Edit
- Use `edit` for single changes
- Use `multi_edit` for multiple changes to same file
- Always read file first before editing
- Ensure old_string matches exactly

### Parallel Tool Call Pattern
```
# Good - Independent operations
readMultipleFiles(paths=[file1, file2, file3])
grepSearch(query1)
grepSearch(query2)

# Bad - Sequential when could be parallel
readFile(file1)
readFile(file2)
readFile(file3)
```

---

## 📊 Metrics & Tracking

### Efficiency Metrics
- **Analysis Speed:** Measure parallel vs sequential
- **Change Size:** Keep changes minimal
- **Verification Time:** Track test/build time
- **Documentation:** Ensure all changes documented

### Quality Metrics
- **Root Cause Analysis:** 100% of issues analyzed
- **Verification:** All changes verified
- **Test Coverage:** Maintain/improve coverage
- **Code Quality:** Zero linting warnings

### Progress Metrics
- **TODO Completion:** Track task completion
- **Phase Progress:** Track phase completion
- **Blocker Resolution:** Track and resolve blockers
- **User Satisfaction:** Ensure user happy with results

---

## 🎓 Learning & Memory

### Create Memories For:
- Important patterns discovered
- Root causes identified
- Solutions that worked
- Lessons learned
- Common mistakes

### Update Memories When:
- Information changes
- New patterns discovered
- Better solutions found
- Mistakes repeated

### Delete Memories When:
- Information becomes outdated
- Incorrect or misleading
- No longer relevant
- Superseded by better info

---

## 🔄 Cascade Workflow Checklist (Global)

### For Every Task:

**Analysis Phase**
- [ ] Read relevant files (parallel)
- [ ] Search for patterns (parallel)
- [ ] Identify dependencies
- [ ] Use parallel tool calls
- [ ] Summarize findings

**Planning Phase**
- [ ] Create TODO list
- [ ] Mark current task
- [ ] Break into steps
- [ ] Set priorities
- [ ] Define success criteria

**Implementation Phase**
- [ ] Make focused changes
- [ ] Follow code style
- [ ] Add necessary imports
- [ ] Use edit tools directly
- [ ] Ensure immediately runnable

**Verification Phase**
- [ ] Run analysis
- [ ] Fix errors
- [ ] Run tests
- [ ] Build project
- [ ] Verify fix

**Documentation Phase**
- [ ] Update comments
- [ ] Update README
- [ ] Create memories
- [ ] Mark tasks complete
- [ ] Summarize work

---

## 🎯 Decision Framework

### When Faced with Multiple Approaches:

1. **Identify Root Cause**
   - Why is this needed?
   - What's the real problem?
   - What's the minimal fix?

2. **Evaluate Options**
   - Which fixes root cause?
   - Which is most minimal?
   - Which is most verifiable?

3. **Choose Cascade Approach**
   - Minimal change
   - Root cause fix
   - Verifiable solution
   - Well-documented

4. **Implement & Verify**
   - Make change
   - Verify it works
   - Check side effects
   - Document

---

## 🌟 Cascade Principles in Action

### Example 1: Bug Fix
```
User: "The app crashes when uploading files"

Analysis:
- Read crash logs
- Search for upload code
- Identify crash location
- Find root cause

Planning:
- [ ] Analyze crash logs
- [ ] Find root cause
- [x] Implement fix
- [ ] Verify fix
- [ ] Test edge cases

Implementation:
- Fix at source (not workaround)
- Minimal change
- Follow code style

Verification:
- Run tests
- Build project
- Test upload scenario
- Check for side effects

Documentation:
- Add comment explaining fix
- Update crash handling
- Create memory
```

### Example 2: Feature Implementation
```
User: "Add dark mode support"

Analysis:
- Read theme code
- Search for color usage
- Identify theme system
- Map dependencies

Planning:
- [ ] Analyze theme system
- [ ] Design dark mode
- [x] Implement changes
- [ ] Test all screens
- [ ] Document changes

Implementation:
- Extend theme system
- Add dark colors
- Update all screens
- Follow existing patterns

Verification:
- Test all screens
- Check contrast
- Verify no regressions
- Build project

Documentation:
- Document theme system
- Add setup guide
- Create memory
```

---

## 🚀 Integration with Kiro Powers

### Cascade + Kiro Powers Synergy

**Cascade Provides:**
- Systematic approach
- Root cause analysis
- Verification strategy
- Clear planning

**Kiro Powers Provide:**
- Automation capabilities
- Extended functionality
- AI integration
- Deployment tools

**Combined Approach:**
1. Use Cascade for analysis & planning
2. Use Kiro Powers for implementation
3. Use Cascade for verification
4. Use Kiro Powers for deployment

---

## 📚 References

### Cascade Workflow
- File: `.windsurf/workflows/cascade-iteration-workflow.md`
- Principles: Minimal changes, root cause, verification, parallel execution

### Kiro Powers
- netlify-deployment: Web deployment automation
- nova-act: Automated testing workflows
- strands: AI agents for code analysis
- power-builder: Custom power development

### Project Documentation
- KIRO_CASCADE_IMPROVEMENT_PLAN.md
- KIRO_IMPROVEMENT_REPORT.md
- IMPROVEMENTS_ACHIEVED.md

---

## ✅ Activation Checklist

When starting any task, verify:

- [ ] Cascade principles understood
- [ ] Analysis phase planned
- [ ] Parallel execution identified
- [ ] TODO list created
- [ ] Success criteria defined
- [ ] Verification strategy ready
- [ ] Documentation plan ready
- [ ] Kiro Powers considered

---

**Status:** ✅ Active Global Skill  
**Scope:** All Kiro Agent Interactions  
**Last Updated:** April 12, 2026  
**Inclusion:** auto (automatically loaded for all interactions)

