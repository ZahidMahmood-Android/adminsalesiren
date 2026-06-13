# PERMANENT CODEX PROJECT INSTRUCTIONS

You are my coding assistant for the Sale Alert product.

These instructions must be followed for every task in this project unless I explicitly override them.

My AI quota is limited, so your main goal is to complete the exact requested task with minimum token usage, minimum file reading, and minimum code changes.

---

## 1. Main Behaviour

- Complete only the task I ask for.
- Do not build extra features.
- Do not improve unrelated code.
- Do not refactor unrelated files.
- Do not rename files, folders, classes, variables, or methods unless I ask.
- Do not change architecture unless I ask.
- Do not generate future modules unless I ask.
- Do not make assumptions that increase scope.
- Ask a short clarification only when the task is impossible without it.
- Prefer the smallest safe change.

---

## 2. Cost and Token Saving Rules

- Keep every response short.
- Do not explain basic Flutter, Firebase, Riverpod, or Clean Architecture concepts.
- Do not repeat the project idea in every response.
- Do not print full files unless I ask.
- Only show changed files and a short summary.
- Do not provide long reasoning.
- Do not provide multiple alternatives unless I ask.
- Do not create documentation unless I ask.
- Do not create large implementation plans unless I ask.
- Do not scan the whole project.
- Do not read unnecessary files.
- Do not open generated files unless required.

---

## 3. Strict Build/Run/Test Rules

Never run these commands unless I explicitly ask:

```bash
flutter run
flutter build
flutter test
dart test
dart analyze
pod install
gradle build
./gradlew build
xcodebuild
npm run build
firebase deploy
```

Also:

- Do not build the app.
- Do not compile the app.
- Do not run the app.
- Do not deploy anything.
- Do not run tests.
- Do not install packages automatically unless I ask.
- If a dependency is needed, suggest it first and wait for my confirmation.

---

## 4. File Reading Rules

- Read only files required for the current task.
- Start with the smallest relevant file.
- Do not scan the entire repository.
- Do not open these folders unless directly required:

```text
build/
.dart_tool/
.gradle/
ios/Pods/
android/.gradle/
.idea/
.vscode/
coverage/
```

- Do not inspect lock files unless dependency resolution is the task.
- Do not inspect generated Firebase files unless the task requires Firebase initialization.

---

## 5. Code Change Rules

- Make the smallest working change.
- Keep existing style.
- Keep existing folder structure.
- Keep existing naming conventions.
- Do not introduce new patterns without permission.
- Do not add unnecessary comments.
- Do not format unrelated code.
- Do not modify unrelated imports.
- Do not remove existing comments unless they are wrong.
- Do not add TODOs unless I ask.

---

## 6. Flutter Rules

- Use Flutter.
- Use Riverpod.
- Use Clean Architecture.
- Use feature-first structure.
- Keep widgets small.
- Keep business logic out of widgets.
- Use providers for state and dependencies.
- Use loading, success, and error states where required.
- Do not add unnecessary packages.
- Prefer existing widgets/components if available.

---

## 7. Firebase Rules

- Do not call Firebase directly from UI widgets.
- Use repository pattern.
- Keep Firebase implementation inside the data layer.
- Keep domain layer independent from Firebase.
- Use Firestore models in data layer.
- Use domain entities in domain layer.
- Use Firebase Storage only when image/file upload is required.
- Do not modify Firestore security rules unless I ask.
- Do not deploy Firebase rules unless I ask.

---

## 8. Required Architecture

Use this structure unless I say otherwise:

```text
lib/
  core/
    constants/
    errors/
    extensions/
    routing/
    services/
    theme/
    utils/
    widgets/
  features/
    feature_name/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        screens/
        widgets/
```

Layer rules:

- Domain layer must not depend on Firebase.
- Domain layer must not depend on Flutter UI.
- Presentation layer must not contain Firebase calls.
- Data layer handles Firebase, Firestore, Storage, and external services.
- Repository interface belongs in domain layer.
- Repository implementation belongs in data layer.
- Providers belong in presentation/provider layer unless already structured differently.

---

## 9. Product Build Priority

The project build order is:

1. Admin Panel
2. Firebase data structure
3. Mobile App
4. Push Notifications
5. Website
6. AI extraction
7. Retailer dashboard
8. Monetization

Do not work on later phases unless I explicitly ask.

---

## 10. Current Focus

Current focus:

```text
Admin Panel MVP
```

Allowed current features:

- Firebase initialization
- Admin login
- Dashboard layout
- Cities management
- Categories management
- Brands CRUD
- Offers CRUD
- Firebase Storage image upload for offer image
- Publish/unpublish offer
- Verified/unverified offer
- Featured/not featured offer
- Offer reports later
- Notifications later

Do not build:

- Mobile app screens
- Website
- AI extraction
- Retailer dashboard
- Payment system
- Cashback
- Wallet
- Complex recommendation engine
- Multi-country support

unless I explicitly ask.

---

## 11. Response Format

For successful tasks, respond only like this:

```text
Done.

Changed:
- file/path/example.dart: short explanation
- file/path/another.dart: short explanation

Notes:
- Any important limitation or manual next step
```

For blocked tasks, respond only like this:

```text
Blocked.

Reason:
- Short reason

Need:
- Exact file, decision, or instruction needed
```

Do not add long explanations.

---

## 12. Dependency Rules

- Do not add dependencies unless required.
- If a dependency is required, tell me first in one line and wait.
- Do not upgrade existing dependencies unless I ask.
- Do not replace existing packages unless I ask.
- Prefer stable and widely used packages.

---

## 13. Error Fixing Rules

When fixing an error:

- Fix only the reported error.
- Do not refactor the full file.
- Do not update unrelated packages.
- Do not change architecture.
- Choose the smallest safe fix.
- Explain root cause in one short line only.

---

## 14. Git Rules

Do not do any of the following unless I ask:

```bash
git commit
git push
git pull
git merge
git rebase
git checkout
git reset
```

Also:

- Do not create commits.
- Do not change branches.
- Do not push code.
- If I ask for commit messages, provide short conventional commit messages only.

---

## 15. Testing Rules

- Do not write tests unless I ask.
- If I ask for tests, write only tests for changed logic.
- Do not run tests unless I ask.
- Do not generate large test suites automatically.

---

## 16. Documentation Rules

- Do not update README unless I ask.
- Do not create markdown files unless I ask.
- Do not update project documentation unless I ask.
- If a small note is needed, put it in the response only.

---

## 17. Task Execution Process

For every task:

1. Read only the minimum required files.
2. Identify the smallest change.
3. Modify only required files.
4. Do not run, build, compile, test, or deploy.
5. Respond using the required short format.
6. Stop.

---

## 18. Very Important Final Rule

Always remember:

```text
Do the exact task only.
Use minimum context.
Use minimum tokens.
Make minimum changes.
Do not run/build/test/deploy.
Stop after the requested task is complete.
```

---

# One-Time Confirmation Prompt for Codex

After adding this file to the project, send this message to Codex:

```text
Read and follow CODEX_PROJECT_INSTRUCTIONS.md permanently for this project. Do not run, build, compile, test, deploy, or scan the whole project unless I explicitly ask.
```

---

# Example Task Prompt

Use this style for each Codex task:

```text
Task: Create the Offer entity only.

Rules:
- Follow CODEX_PROJECT_INSTRUCTIONS.md.
- Do not create repository, UI, provider, Firebase code, tests, or documentation.
- Do not run, build, compile, test, or deploy.
- Only create the domain entity file.
- After completion, give a short summary of changed files.
```
