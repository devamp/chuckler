# TODO

Planned features. Each item notes what exists today so the work can start from it.

## 1. Swipe between prompts on the Create tab

- Swiping left or right on the Create tab cycles through the available prompts.
- The app remembers which prompts the user has already answered, both on the phone and on the account, so answered prompts show as answered after a reinstall or on another device.
- The icon in the top right of the prompt shows which segment the prompt belongs to:
  - **Friends**: friends-only prompts
  - **Local**: prompts within x miles
  - **Global**: prompts for everyone

**Today:**
- `lib/pages/createpage/CreatePageContent.dart` already cycles prompts with chevron buttons (`promptVal`), so swiping can reuse that index.
- Answered state lives in `PromptService.userPostsForPrompts`, filled at login by `getUserPostForPrompt` in `lib/data/posts.dart` (one Firestore query per prompt). It is not cached in Isar.
- `DbPrompt` has a `type` field, read from the Firestore prompt doc and not used by the UI yet. It may fit the segment.
- `lib/pages/createpage/prompt_identifier.dart` is the top-right badge. Its popup text is a placeholder ("HERE IS WHAT A DAILY IS!").
- Nothing stores a user's location yet, so Local needs that first.

## 2. Swipe-based voting on the Home tab

- The Home tab becomes a card-swiping mechanic:
  - **Swipe left**: like one answer.
  - **Swipe right**: like the other answer.
  - **Swipe up**: comment.
  - **Swipe down**: skip.
  - A **back** button returns to the previous matchup.
- The current Home page does not have to be scrapped, but it needs a new way to fit this in.
- Each answer still shows whether it is from a friend, local or global. The feed is not filtered by default, but the user can filter to specific types, as the current page intends.

**Today:**
- `lib/pages/feedpage/feed_page.dart` builds the feed from `Posts` via `getPosts`. The app does not read `MatchUps` yet, even though the Cloud Function `createMatchup` writes them (and functions do not run on the free Spark plan).
- The feed's Global/Local/Friends dropdown (`DropdownButtonExample` in `feed_page.dart`) only changes its own label. It does not filter anything yet.
- `likeAPost` and `postWin` exist in `lib/data/posts.dart`, and `addCommentToPost` / `getComments` in `lib/data/comments.dart`, but nothing calls `likeAPost` or `postWin`, and `comment_form.dart` does not call the comment functions.
- Posts have no field saying whether they are friend, local or global.
