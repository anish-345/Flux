# Cascade Workflow - Global Application Guide

**Status:** Active Global Steering  
**Scope:** All Kiro Agent Interactions  
**Last Updated:** April 12, 2026  
**Inclusion:** auto

---

## 🎯 Purpose

This guide explains how Cascade Workflow principles are applied globally across ALL Kiro agent interactions, not just project-level work. It ensures consistent, systematic, high-quality responses regardless of task type.

---

## 🔄 Global Application Framework

### For ANY User Request:

#### 1. Analysis Phase (Always First)
```
User Request
    ↓
Understand the Problem
    ├─ What is being asked?
    ├─ What's the context?
    ├─ What files/info needed?
    └─ What's the root cause?
    ↓
Gather Information (Parallel)
    ├─ Read relevant files
    ├─ Search for patterns
    ├─ Check dependencies
    └─ Identify constraints
    ↓
Summarize Findings
    ├─ What did I learn?
    ├─ What's the root cause?
    ├─ What are the options?
    └─ What's the best approach?
```

#### 2. Planning Phase (Always Second)
```
Create Plan
    ├─ Break into steps
    ├─ Identify dependencies
    ├─ Set priorities
    └─ Define success criteria
    ↓
Communicate Plan
    ├─ Share with user
    ├─ Get feedback
    ├─ Adjust if needed
    └─ Confirm understanding
    ↓
Create TODO List
    ├─ [ ] Step 1
    ├─ [ ] Step 2
    ├─ [x] Current step
    └─ [ ] Step N
```

#### 3. Implementation Phase (Focused & Minimal)
```
Make Changes
    ├─ Minimal, focused changes
    ├─ Follow code style
    ├─ Add necessary imports
    └─ Use tools directly
    ↓
Verify Immediately
    ├─ Run analysis
    ├─ Run tests
    ├─ Build project
    └─ Check for errors
    ↓
Fix Issues
    ├─ Identify root cause
    ├─ Fix at source
    ├─ Re-verify
    └─ Check side effects
```

#### 4. Verification Phase (Always Before Completion)
```
Automated Verification
    ├─ flutter analyze
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

#### 5. Documentation Phase (Always Last)
```
Update Code
    ├─ Add comments
    ├─ Update docstrings
    ├─ Explain complex logic
    └─ Document decisions
    ↓
Update Project Docs
    ├─ Update README
    ├─ Update guides
    ├─ Add examples
    └─ Update status
    ↓
Create Memories
    ├─ Store learnings
    ├─ Document patterns
    ├─ Save solutions
    └─ Prevent recurrence
    ↓
Mark Complete
    ├─ Update TODO list
    ├─ Summarize work
    ├─ Share results
    └─ Confirm satisfaction
```

---

## 📋 Task Type Specific Application

### For Code Changes
```
1. Analysis
   - Read affected files
   - Search for related code
   - Understand current implementation
   - Identify root cause

2. Planning
   - Design solution
   - Plan changes
   - Identify tests needed
   - Set success criteria

3. Implementation
   - Make minimal changes
   - Follow code style
   - Add necessary imports
   - Use edit tools

4. Verification
   - Run analysis
   - Run tests
   - Build project
   - Verify fix

5. Documentation
   - Add comments
   - Update docs
   - Create memory
   - Mark complete
```

### For Flutter/Dart Projects (MANDATORY)
```
1. Analysis
   - Read affected files
   - Search for related code
   - Understand current implementation
   - Identify root cause

2. Planning
   - Design solution
   - Plan changes
   - Identify tests needed
   - Set success criteria

3. Implementation
   - Make minimal changes
   - Follow code style
   - Add necessary imports
   - Use edit tools

4. Verification (FLUTTER SPECIFIC)
   - Run: flutter analyze
   - Fix ALL issues found
   - Re-run: flutter analyze
   - Verify: "No issues found!"
   - Run: flutter test
   - Run: flutter build
   - Verify fix

5. Documentation
   - Add comments
   - Update docs
   - Create memory
   - Mark complete ONLY when flutter analyze is clean
```

### For Bug Fixes
```
1. Analysis
   - Read error logs
   - Reproduce issue
   - Identify root cause
   - Map affected code

2. Planning
   - Design fix
   - Plan minimal change
   - Identify tests
   - Set success criteria

3. Implementation
   - Fix at source
   - Minimal change
   - Follow patterns
   - Use edit tools

4. Verification
   - Verify fix works
   - Test edge cases
   - Check regressions
   - Build project

5. Documentation
   - Document fix
   - Add test
   - Create memory
   - Mark complete
```

### For Feature Implementation
```
1. Analysis
   - Understand requirements
   - Read related code
   - Identify integration points
   - Plan architecture

2. Planning
   - Design feature
   - Break into steps
   - Identify dependencies
   - Set success criteria

3. Implementation
   - Implement incrementally
   - Follow patterns
   - Add tests
   - Use edit tools

4. Verification
   - Test feature
   - Test integration
   - Check regressions
   - Build project

5. Documentation
   - Document feature
   - Add examples
   - Update guides
   - Create memory
```

### For Analysis/Research
```
1. Analysis
   - Understand question
   - Search for information
   - Read relevant docs
   - Gather context

2. Planning
   - Organize findings
   - Identify patterns
   - Plan presentation
   - Set success criteria

3. Implementation
   - Synthesize information
   - Create summaries
   - Add examples
   - Organize clearly

4. Verification
   - Verify accuracy
   - Check completeness
   - Validate sources
   - Confirm understanding

5. Documentation
   - Document findings
   - Create summary
   - Store learnings
   - Mark complete
```

### For Deployment/DevOps
```
1. Analysis
   - Understand requirements
   - Check current setup
   - Identify constraints
   - Plan approach

2. Planning
   - Design deployment
   - Plan steps
   - Identify risks
   - Set success criteria

3. Implementation
   - Execute deployment
   - Follow best practices
   - Use automation
   - Monitor progress

4. Verification
   - Verify deployment
   - Test functionality
   - Check monitoring
   - Confirm success

5. Documentation
   - Document process
   - Create runbook
   - Update guides
   - Create memory
```

---

## 🎯 Communication Patterns (Cascade-Aligned)

### Pattern 1: Analysis Summary
```
I've analyzed the project and found:
- 8 improvement areas identified
- Root causes: [list]
- Recommended approach: [approach]
- Next steps: [steps]
```

### Pattern 2: Plan Presentation
```
Here's my plan:
- [ ] Step 1: [description]
- [ ] Step 2: [description]
- [x] Step 3: [current]
- [ ] Step 4: [description]

Success criteria:
- [criteria 1]
- [criteria 2]
```

### Pattern 3: Progress Update
```
Progress:
- ✅ Completed: [what]
- ⏳ In progress: [what]
- 📋 Planned: [what]

Next: [next step]
```

### Pattern 4: Verification Report
```
Verification results:
- ✅ Analysis: [result]
- ✅ Tests: [result]
- ✅ Build: [result]
- ✅ Functionality: [result]

Status: Ready for deployment
```

### Pattern 5: Completion Summary
```
Completed:
- ✅ [what was done]
- ✅ [what was done]
- ✅ [what was done]

Results:
- [result 1]
- [result 2]

Next steps:
- [next step 1]
- [next step 2]
```

---

## 🚀 Parallel Execution Strategy (Global)

### Identify Parallel Opportunities
```
Task: Analyze project
Sequential: Read file 1 → Read file 2 → Read file 3 (3 min)
Parallel: Read files 1-3 simultaneously (1 min)
Gain: 3x faster
```

### Batch Tool Calls
```
# Good - Parallel
readMultipleFiles(paths=[file1, file2, file3])
grepSearch(query1)
grepSearch(query2)

# Bad - Sequential
readFile(file1)
readFile(file2)
readFile(file3)
```

### When to Use Parallel
- Reading multiple files
- Searching for different patterns
- Running multiple read-only commands
- Gathering information from different sources
- Analyzing multiple components

### When NOT to Use Parallel
- When output of one tool is needed for next
- When making destructive changes
- When operations have dependencies
- When order matters

---

## 📊 Quality Metrics (Global)

### For Every Task, Track:

**Efficiency**
- Analysis time
- Planning time
- Implementation time
- Verification time
- Total time

**Quality**
- Root cause analysis: 100%?
- Verification: All steps?
- Tests: Passing?
- Build: Successful?
- Documentation: Complete?

**Completeness**
- All steps completed?
- All criteria met?
- All tests passing?
- All docs updated?
- All memories created?

---

## 🎓 Learning & Improvement

### After Every Task:

1. **Reflect**
   - What went well?
   - What could improve?
   - What did I learn?
   - What patterns emerged?

2. **Document**
   - Create memory
   - Store learnings
   - Document patterns
   - Save solutions

3. **Improve**
   - Apply learnings
   - Refine approach
   - Update processes
   - Share knowledge

---

## 🔄 Cascade Checklist (For Every Task)

### Before Starting
- [ ] Understand the problem
- [ ] Identify root cause
- [ ] Plan approach
- [ ] Define success criteria

### During Execution
- [ ] Follow Cascade phases
- [ ] Use parallel execution
- [ ] Track progress
- [ ] Verify continuously

### After Completion
- [ ] Verify all criteria met
- [ ] Document changes
- [ ] Create memories
- [ ] Summarize results

---

## 🌟 Examples of Global Application

### Example 1: Simple Code Fix
```
User: "Fix the login button"

Analysis (2 min):
- Read login screen code
- Search for button implementation
- Identify issue
- Find root cause

Planning (1 min):
- [ ] Analyze code
- [x] Design fix
- [ ] Implement
- [ ] Verify
- [ ] Document

Implementation (2 min):
- Make minimal change
- Follow code style
- Use edit tools

Verification (2 min):
- Run analysis
- Run tests
- Build project
- Test button

Documentation (1 min):
- Add comment
- Update docs
- Mark complete

Total: 8 minutes (vs 15 without Cascade)
```

### Example 2: Complex Feature
```
User: "Add user authentication"

Analysis (10 min):
- Read auth code
- Search for patterns
- Identify integration points
- Plan architecture

Planning (5 min):
- [ ] Analyze requirements
- [ ] Design architecture
- [x] Plan implementation
- [ ] Implement
- [ ] Test
- [ ] Document

Implementation (30 min):
- Implement incrementally
- Follow patterns
- Add tests
- Use edit tools

Verification (10 min):
- Run analysis
- Run tests
- Build project
- Test functionality

Documentation (5 min):
- Document feature
- Add examples
- Update guides
- Create memory

Total: 60 minutes (vs 120 without Cascade)
```

### Example 3: Analysis Task
```
User: "Analyze the codebase"

Analysis (15 min):
- Read architecture
- Search for patterns
- Identify components
- Map dependencies

Planning (5 min):
- [ ] Analyze structure
- [x] Identify patterns
- [ ] Create summary
- [ ] Document findings

Implementation (10 min):
- Synthesize information
- Create diagrams
- Add examples
- Organize clearly

Verification (5 min):
- Verify accuracy
- Check completeness
- Validate findings

Documentation (5 min):
- Document analysis
- Create summary
- Store learnings

Total: 40 minutes (vs 60 without Cascade)
```

---

## 🎯 Decision Framework (Global)

### When Faced with Multiple Approaches:

1. **Which fixes root cause?**
   - Identify root cause
   - Evaluate each approach
   - Choose one that fixes root

2. **Which is most minimal?**
   - Evaluate change size
   - Choose smallest change
   - Avoid unnecessary work

3. **Which is most verifiable?**
   - Evaluate testability
   - Choose most testable
   - Ensure verification possible

4. **Which is most maintainable?**
   - Evaluate code quality
   - Choose most maintainable
   - Follow project patterns

---

## 🎯 Flutter & Dart Project Requirements (MANDATORY)

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

### Flutter Verification Checklist

**For ALL Flutter/Dart tasks:**
- [ ] `flutter analyze` - No issues
- [ ] `flutter test` - All tests pass
- [ ] `flutter build apk` - Builds successfully
- [ ] Manual testing - Functionality works
- [ ] No regressions - Related features work

**ONLY mark complete when ALL pass**

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

---

### Cascade + Kiro Powers

**Cascade Provides:**
- Systematic approach
- Root cause analysis
- Verification strategy
- Clear planning

**Kiro Powers Provide:**
- Automation
- Extended functionality
- AI integration
- Deployment tools

**Combined:**
1. Use Cascade for analysis & planning
2. Use Kiro Powers for implementation
3. Use Cascade for verification
4. Use Kiro Powers for deployment

---

## ✅ Activation

This steering file is automatically included in all Kiro agent interactions.

**Cascade Workflow Mastery Skill:** `.kiro/skills/cascade-workflow-mastery.md`

---

**Status:** ✅ Active Global Steering  
**Scope:** All Kiro Agent Interactions  
**Last Updated:** April 12, 2026  
**Inclusion:** auto (automatically loaded)

