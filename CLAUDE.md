# Code Review Guide

Pre-generated diffs are available in `./reviews/owner-repo/pr-number/` (created by `./main.sh`).

## Review Structure

Each PR review directory contains:
- `summary.txt` - PR metadata and summary
- `raw.diff` - Complete unified diff
- `files/*.diff` - Individual file changes

When additional context is needed, refer to the actual repository code in `./repos/owner/repo/`.

## Initial Code Review

### Overview Requirements
* Include PR title, author, and list of modified files
* Summarize positive aspects concisely (2-3 sentences maximum)

### Focus Areas
1. **Security Vulnerabilities**
   - XSS, SQL injection, command injection
   - Exposed secrets or credentials
   - Authentication/authorization bypasses
   - Unsafe data handling or validation

2. **Logic and Performance Issues**
   - Race conditions or concurrency bugs
   - Business logic errors
   - Edge case handling gaps
   - Algorithm inefficiencies (O(n²) where O(n) possible)

3. **Code Quality Concerns**
   - Memory leaks or resource management
   - Missing error handling
   - Unhandled promise rejections
   - Dead or unreachable code

4. **Naming and Documentation Issues**
   - Temporal terms: `new`, `old`, `updated`, `fixed`, `temp`
   - Vague comparatives: `correct`, `proper`, `better`
   - Comments explaining "how" but not "why"
   - Version suffixes: `V2`, `New2`, `Final`

5. **Minor Quality Issues**
   - Typos in user-facing strings or comments
   - Full-width spaces (　) or non-ASCII characters in code

### Review Template

Use the following format for your initial review:

```
## Code Review Results

### PR Overview
- **Title**: [PR Title]
- **Author**: [Author]
- **Status**: [Status]
- **Changed Files**: [List of main files]

### Positive Points (Summary)
[2-3 sentence summary of what was done well]

### Issues

#### 1. **[Category]: [Concise Description]**
**Location**: [File:Line Number]

\`\`\`[language]
[Problematic code snippet]
\`\`\`

[Description of the issue]

**Suggested Fix**:
\`\`\`[language]
[Proposed fix]
\`\`\`

#### 2. **[Category]: [Concise Description]**
...
```

### Naming & Comment Review Guidelines

#### Patterns to Avoid
1. **Temporal References**
   ```javascript
   // Avoid these:
   const newFunction = () => {}      // What makes it "new"?
   const updatedData = {}            // Updated from what?
   const fixedCalculation = () => {} // What was broken?
   const tempSolution = {}           // How temporary?
   ```

2. **Context-free Contextual References**
   ```javascript
   // Avoid these:
   const correctValue = 42           // Correct for what context?
   const betterAlgorithm = () => {}  // Better than what?
   return value * 1.08               // "Updated rate" - from what?
   ```

#### Recommended Patterns
1. **Descriptive Purpose-Based Names**
   ```javascript
   // Prefer these:
   const calculateTaxInclusivePrice = () => {}
   const sessionCache = {}           // Clear purpose, not "temp"
   const userAuthenticationToken = "" // Not "newToken"
   ```

2. **Comments with Business/Technical Context**
   ```javascript
   // Prefer these:
   return value * 1.08  // 8% consumption tax rate (Japan)
   if (count > 5) {}    // Max retries per API rate limit policy
   const TIMEOUT_MS = 30000  // 30s timeout per security requirements
   ```

### Out of Scope
* Style preferences (unless they cause actual issues)
* General "best practices" without specific problems
* Features that work correctly but could be "improved"
* Formatting issues (assuming linter exists)


## Re-evaluation Phase

Critically re-examine each flagged issue against the project's actual implementation and context.

### Re-evaluation Strategy

Scale your investigation depth according to issue severity:

- **Detailed Re-evaluation Required** (Issues flagged with Focus Areas 1, 2, 3)
  - Vulnerabilities, logic issues, code quality issues
  - Perform all steps in "Re-evaluation Procedure" below
  
- **Simplified Review Acceptable** (Focus Areas 4-5)
  - Naming/comment issues, minor issues (typos, etc.)
  - Simple pattern confirmation is sufficient
  - Project convention consistency must still be verified

### Re-evaluation Procedure

1. **Extensive Information Gathering**
   - Read the entire function/class containing the flagged code
   - Understand the structure and context of all related files
   - Review commit history (`git log`) to understand modification rationale
   - Identify authorship and timeline (`git blame`)
   - Investigate 2-3 representative usage locations of the same pattern

2. **Critical Analysis Perspectives**
   - Will this issue actually cause problems in practice?
   - Is the implementation justified by project constraints?
   - Does the fix benefit outweigh the risk?

3. **Required Investigation Items**
   - Overall structure of the relevant file
   - Similar pattern usage across codebase (comprehensive grep search)
   - Related documentation (README, design docs, coding standards)
   - Dependencies with surrounding code

### Managing Investigation Constraints

When comprehensive investigation isn't feasible:

1. **Sample-Based Analysis**:
   - Check 3-5 representative files for patterns
   - If 80% or more follow a pattern, consider it the project standard
   - Be transparent: "After reviewing 5 similar implementations..."

2. **Conservative Approach**:
   - When uncertain, lean towards "Fix Required" or "Consider"
   - Never use "Acceptable" unless you have strong evidence
   - Prefer false positives over missed issues

3. **Acknowledge Limitations Explicitly**:
   - ❌ Bad: "Needs assessment based on project patterns"
   - ✅ Good: "Checked auth.js, user.js, and session.js - none use this pattern, recommend fixing"

### Re-evaluation Template

```
## Re-evaluation Results

### Issue 1 Re-evaluation

**Investigation Details**:
- File purpose: [What this file/module does]
- Component scope: [Responsibilities and boundaries]
- Git history insights: [Relevant commits or patterns]
- Similar code patterns: [3+ specific locations, e.g., `auth.js:45`, `user.js:120`]
- Documentation references: [README, ADRs, or design docs]

**Analysis Summary**:
1. Risk level: [High/Medium/Low with brief justification]
2. Pattern consistency: [Matches/conflicts with codebase norms]
3. Technical merit: [Sound/questionable given constraints]

**Final Verdict**: ✅Acceptable / ⚠️Consider / ❌Fix Required

**Rationale**:
[2-3 sentences explaining specific reasons based on gathered information]

### Issue 2 Re-evaluation
...
```

### Verdict Criteria

- **Acceptable**: Justified by project context or fix carries high risk
- **Consider**: Worth future improvement but not immediately critical
- **Fix Required**: Causes demonstrable harm without justifiable reason


## Project-Specific Standards

When you identify recurring patterns that warrant standardization, suggest adding them to CLAUDE.md for consistent application.

## Output

### Language
Please provide output in Japanese.

### Consolidated Output Format

Combine your initial review and re-evaluation findings using this structure:

```
## Final Review Results

### PR Overview
[PR information summary]

### Positive Points
[Summary of positive aspects]

### Issues and Final Verdict

#### 1. {Category}: {Concise Description} (Final Verdict: {❌Fix Required/⚠️Consider/✅Acceptable})
**Location**: {File:Line Number}

**Issue**:
\`\`\`{language}
[Code snippet showing the problem]
\`\`\`
[Clear explanation of why this is problematic]

**Suggested Fix**:
\`\`\`{language}
[Proposed fix]
\`\`\`

**Re-evaluation Results**:
- Findings: [Key discoveries from investigation]
- Risk: [High/Medium/Low]
- Justification: [Why this verdict was chosen]

---

#### 2. {Category}: {Concise Description} (Final Verdict: {❌Fix Required/⚠️Consider/✅Acceptable})
...
```

This unified format integrates initial findings with re-evaluation results for comprehensive clarity.


# Key Constraints
- Perform only the requested task without additions or omissions
- File creation/editing is prohibited unless essential
- This is a review task only—do not implement fixes

Prioritize thoroughness over brevity. Comprehensive analysis is valued above conciseness.

Remember: Invest time in deep analysis. Challenge assumptions, uncover subtle issues, and consider long-term implications. Thoroughness supersedes speed.