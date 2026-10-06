# Code Style Guidelines

## 1. Naming Conventions
- camelCase: variables, functions, methods, objects
- PascalCase: classes, types, interface, enums
- UPPER_SNAKE_CASE: constants
- Booleans read as questions (isX, isY, etc.).
- Functions start with verbs (getX, parseY, etc.).

## 2. Code Structure & Organization
**For files:**
- *ALWAYS* have only one concept/feature per file. Consider splitting files past ~300 lines.
- *ALWAYS* group by feature/domain unless project already groups by type.
- Keep file order as: imports, constants, types, main logic, helper functions, exports.
- Keep import groups order as: stdlib, third-party, internal.
- Separate import groups by blank lines.

**For functions and methods:**
- *ALWAYS* limit to one job per function/method.
- Aim for under ~50 lines. Longer is fine only if it is straightforward and sequential from top to bottom.
- Prefer early returns/guard clauses over nested conditionals.

## 3. Commenting Conventions
**For inline comments:**
- Comment the why (intent, constraints, tradeoffs, etc.), not the what.
- If a comment explains what the code does, make the code clearer instead.
- *ALWAYS* include context in TODOs.
- *ALWAYS* update comments affected by your changes.

**For doc-comments:**
- *ALWAYS REQUIRED* for public functions, classes, and modules. Only provide doc comments for internal code when behavior is not obvious.
- *ALWAYS* use the language's native doc-comment format and the project's existing conventions.
- Start with a one-sentence summary of what it does.
- Cover what the signature can't say (units, valid ranges, side effects, errors raised/returned, etc.).