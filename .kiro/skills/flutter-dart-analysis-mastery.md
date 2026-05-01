# Flutter & Dart Analysis Mastery - Global Agent Skill

**Status:** Active Global Skill  
**Scope:** ALL Flutter/Dart Projects (Across ALL Workspaces)  
**Last Updated:** April 12, 2026  
**Inclusion:** auto

---

## 🎯 Overview

This skill ensures that **EVERY Flutter/Dart project** I work on in Kiro (regardless of workspace or project) is analyzed with `flutter analyze` and ALL issues are fixed BEFORE any task is marked as complete. This is a **UNIVERSAL MANDATORY requirement** for all Flutter/Dart work across all projects.

---

## 🔴 CRITICAL REQUIREMENT

### NEVER Mark Flutter/Dart Task Complete Without Clean Analysis

**MANDATORY BEFORE COMPLETION:**
```bash
flutter analyze
# Output MUST be: "No issues found!"
```

**If output shows issues:**
- ❌ DO NOT mark task complete
- ❌ DO NOT report success
- ❌ DO NOT skip analysis
- ✅ DO fix all issues
- ✅ DO re-run analysis
- ✅ DO verify clean output

---

## 📋 Flutter Analysis Workflow

### Step 1: Run Initial Analysis
```bash
flutter analyze
```

**Possible outputs:**
- ✅ "No issues found!" → Task ready to complete
- ❌ Issues found → Go to Step 2

### Step 2: Identify All Issues
```
flutter analyze output:
lib/main.dart:10:5 - warning: Unused import 'package:flutter/material.dart'
lib/main.dart:25:10 - error: The argument type 'String' can't be assigned to the parameter type 'int'
lib/widgets/button.dart:5:3 - info: Avoid using 'print' for logging
lib/screens/login.dart:45:3 - warning: Missing const constructor
```

**Categorize issues:**
- **Errors:** Must fix (blocks compilation)
- **Warnings:** Must fix (code quality)
- **Info:** Should fix (best practices)

### Step 3: Fix Each Issue

**For Unused Imports:**
```dart
// Before
import 'package:flutter/material.dart';
import 'package:unused_package/unused.dart';

// After
import 'package:flutter/material.dart';
```

**For Type Mismatches:**
```dart
// Before
void processData(String value) {
  int result = value; // Type mismatch
}

// After
void processData(String value) {
  int result = int.parse(value); // Fixed
}
```

**For Missing Const:**
```dart
// Before
final button = RaisedButton(
  child: Text('Click me'),
);

// After
final button = const RaisedButton(
  child: Text('Click me'),
);
```

**For Null Safety Issues:**
```dart
// Before
String? value;
print(value.length); // Null safety violation

// After
String? value;
print(value?.length ?? 0); // Fixed
```

### Step 4: Re-run Analysis
```bash
flutter analyze
```

**If still issues:**
- Go back to Step 2
- Fix remaining issues
- Re-run analysis

**If clean:**
- ✅ "No issues found!"
- Proceed to Step 5

### Step 5: Verify with Tests & Build
```bash
flutter test
flutter build apk
```

**Verify:**
- ✅ All tests pass
- ✅ Build succeeds
- ✅ No new issues

### Step 6: Mark Complete
- ✅ Report task complete
- ✅ Document what was fixed
- ✅ Create memory
- ✅ Update TODO list

---

## 🔍 Common Flutter Analysis Issues

### Category 1: Import Issues

**Unused Imports**
```
warning: Unused import 'package:flutter/material.dart'
```
Fix: Remove the import line

**Unused Packages**
```
warning: Unused import 'package:http/http.dart'
```
Fix: Remove or use the package

### Category 2: Type Issues

**Type Mismatch**
```
error: The argument type 'String' can't be assigned to the parameter type 'int'
```
Fix: Convert type or use correct type

**Null Safety Violation**
```
error: The value of 'x' can't be null, so this condition is always false
```
Fix: Add null checks or use null-coalescing operator

**Missing Type Annotation**
```
warning: Missing type annotation for 'x'
```
Fix: Add explicit type annotation

### Category 3: Code Quality Issues

**Unused Variables**
```
warning: Unused local variable 'x'
```
Fix: Remove variable or use it

**Unused Parameters**
```
warning: Unused parameter 'x'
```
Fix: Remove parameter or use it

**Dead Code**
```
warning: Dead code
```
Fix: Remove unreachable code

### Category 4: Best Practices

**Missing Const**
```
info: Avoid using 'new' keyword
```
Fix: Use const constructor

**Deprecated API**
```
warning: 'RaisedButton' is deprecated
```
Fix: Use replacement (e.g., ElevatedButton)

**Missing Documentation**
```
info: Missing documentation for public member
```
Fix: Add documentation comment

---

## 🛠️ Fixing Strategies

### Strategy 1: Unused Imports
```dart
// Identify unused imports
import 'package:unused/unused.dart'; // Not used anywhere

// Remove the line
// Done!
```

### Strategy 2: Type Issues
```dart
// Identify type mismatch
int value = "123"; // String assigned to int

// Fix by converting
int value = int.parse("123");

// Or use correct type
String value = "123";
```

### Strategy 3: Null Safety
```dart
// Identify null safety issue
String? value;
print(value.length); // Could be null

// Fix with null check
String? value;
print(value?.length ?? 0);

// Or use null assertion (if sure)
String? value;
print(value!.length);
```

### Strategy 4: Missing Const
```dart
// Identify missing const
final widget = Container(
  child: Text('Hello'),
);

// Fix by adding const
final widget = const Container(
  child: Text('Hello'),
);
```

### Strategy 5: Unused Variables
```dart
// Identify unused variable
void myFunction() {
  int unused = 5; // Never used
  print('Hello');
}

// Fix by removing
void myFunction() {
  print('Hello');
}

// Or use the variable
void myFunction() {
  int value = 5;
  print('Value: $value');
}
```

---

## 📊 Analysis Output Interpretation

### Clean Output
```
$ flutter analyze
No issues found!
```
✅ **Status:** Ready to complete task

### With Warnings
```
$ flutter analyze
lib/main.dart:10:5 - warning: Unused import 'package:flutter/material.dart'
lib/main.dart:25:10 - warning: Missing const constructor

2 issues found.
```
❌ **Status:** Must fix warnings before completing

### With Errors
```
$ flutter analyze
lib/main.dart:10:5 - error: The argument type 'String' can't be assigned to the parameter type 'int'
lib/main.dart:25:10 - error: Null safety violation

2 issues found.
```
❌ **Status:** Must fix errors before completing

### With Info Messages
```
$ flutter analyze
lib/main.dart:10:5 - info: Avoid using 'print' for logging
lib/main.dart:25:10 - info: Missing documentation

2 issues found.
```
⚠️ **Status:** Should fix info messages for best practices

---

## 🔄 Integration with Cascade Phases

### Phase 3: Implementation Phase
```
Make Changes
    ├─ Minimal, focused changes
    ├─ Follow code style
    ├─ Add necessary imports
    └─ Use tools directly
    ↓
Verify Immediately
    ├─ Run flutter analyze ← MANDATORY
    ├─ Fix all issues ← MANDATORY
    ├─ Run tests
    ├─ Build project
    └─ Check for errors
```

### Phase 4: Verification Phase
```
Automated Verification
    ├─ flutter analyze ← MANDATORY (must be clean)
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

---

## ✅ Flutter Task Completion Checklist

**MANDATORY before marking task complete:**

- [ ] Code changes implemented
- [ ] `flutter analyze` run
- [ ] All errors fixed
- [ ] All warnings fixed
- [ ] All linting issues fixed
- [ ] `flutter analyze` re-run
- [ ] Output: "No issues found!"
- [ ] `flutter test` run
- [ ] All tests passing
- [ ] `flutter build apk` successful
- [ ] Manual testing done
- [ ] No regressions
- [ ] Comments added
- [ ] Docs updated
- [ ] Memory created
- [ ] Task marked complete

**If ANY step fails:**
- ❌ DO NOT mark complete
- ✅ DO fix the issue
- ✅ DO re-run verification
- ✅ DO repeat until all pass

---

## 🎯 Decision Framework for Flutter Issues

### When Finding Issues:

1. **Is it an error?**
   - YES → Must fix before completing
   - NO → Go to step 2

2. **Is it a warning?**
   - YES → Must fix before completing
   - NO → Go to step 3

3. **Is it an info message?**
   - YES → Should fix for best practices
   - NO → Go to step 4

4. **Is it a style issue?**
   - YES → Fix to maintain consistency
   - NO → Document and move on

---

## 📝 Documentation of Fixes

### When Fixing Issues, Document:

1. **What was the issue?**
   - Type of issue (error, warning, info)
   - Location (file, line)
   - Description

2. **Why was it an issue?**
   - Impact on code quality
   - Impact on functionality
   - Best practice violation

3. **How was it fixed?**
   - Change made
   - Reason for fix
   - Alternative approaches

4. **How to prevent recurrence?**
   - Pattern to avoid
   - Best practice to follow
   - Code review checklist

---

## 🧠 Memory Creation for Flutter Issues

### Create Memory When:
- Fixing common Flutter issues
- Discovering new patterns
- Finding best practices
- Preventing recurrence

### Memory Template:
```
Entity: Flutter Issue - [Issue Type]
Type: Flutter Best Practice
Observations:
- Issue: [Description]
- Root cause: [Why it happens]
- Fix: [How to fix]
- Prevention: [How to prevent]
- Example: [Code example]
```

---

## 🚀 Efficiency Tips

### Batch Fix Similar Issues
```
Instead of:
1. Fix unused import in file A
2. Run flutter analyze
3. Fix unused import in file B
4. Run flutter analyze

Do:
1. Fix all unused imports in all files
2. Run flutter analyze once
3. Fix any remaining issues
4. Run flutter analyze once more
```

### Use IDE Features
- Use IDE to show all issues
- Use IDE quick fixes
- Use IDE refactoring tools
- Use IDE code generation

### Automate Where Possible
```bash
# Format code
flutter format .

# Fix some issues automatically
dart fix --apply

# Then run analysis
flutter analyze
```

---

## 🔗 Related Skills

- **Cascade Workflow Mastery** - `.kiro/skills/cascade-workflow-mastery.md`
- **Flutter/Dart Best Practices** - Global steering file
- **Code Quality Tools** - Linting and formatting

---

## ✅ Activation

This skill is automatically included for all Flutter/Dart project interactions.

**Mandatory for:**
- All Flutter code changes
- All Dart code changes
- All Flutter/Dart projects
- Before marking ANY task complete

---

**Status:** ✅ Active Global Skill  
**Scope:** All Flutter/Dart Project Interactions  
**Last Updated:** April 12, 2026  
**Inclusion:** auto (automatically loaded)

