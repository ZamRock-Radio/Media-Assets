# ---------- 3️⃣  Show menu ----------------------------------------------------
echo
echo "⚙️  What would you like to do?"
echo "   (c) Switch to an existing branch"
echo "   (a) Add a new branch"
echo "   (s) Stage a commit & push"
echo "   (v) View / Stash / Apply unstaged changes"
echo "   (r) Refresh current branch (pull from remote)"
read -r -p "Choose: [c/a/s/v/r] " choice
choice=${choice:-c}
case $choice in
  c|C) action=switch ;;
  a|A) action=create ;;
  s|S) action=stage ;;
  v|V) action=view_unstaged ;;
  r|R) action=refresh ;;
  *) echo "❌  Unknown choice." >&2; exit 1 ;;
esac

# ---------- 4️⃣  Action: Refresh current branch -------------------------------
if [[ $action == refresh ]]; then
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  echo
  echo "🔄  Refreshing branch: '$current_branch'"

  # Check if there's an upstream set
  if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
    echo "⚠️  No upstream branch set for '$current_branch'."
    echo "   Use 'git branch --set-upstream-to=origin/$current_branch' to link it."
    exit 1
  fi

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
  echo "   Upstream: $upstream"

  # Check for unstaged changes
  if git status -s | grep -q .; then
    echo
    echo "You have unstaged changes:"
    git status -s
    read -r -p "Stash them before refreshing? (y/N): " stash_answer
    stash_answer=${stash_answer:-N}
    if [[ $stash_answer =~ ^[Yy]$ ]]; then
      echo "git stash push -u -m \"stash before refresh\""
      git stash push -u -m "stash before refresh"
    else
      echo "❌  Aborting – please commit or stash your changes first."
      exit 1
    fi
  fi

  # Show current status
  echo
  echo "📊  Current status:"
  git status -sb

  # Fetch latest from remote
  echo
  echo "git fetch origin"
  git fetch origin

  # Pull with rebase
  echo
  echo "git pull --rebase origin \"$current_branch\""
  git pull --rebase origin "$current_branch"

  # Show final status
  echo
  echo "✅  Refresh completed."
  git status -sb

  # Optionally re-apply stash if we stashed earlier
  if git stash list | grep -q "stash before refresh"; then
    echo
    read -r -p "Apply your stashed changes back? (y/N): " apply_stash
    apply_stash=${apply_stash:-N}
    if [[ $apply_stash =~ ^[Yy]$ ]]; then
      echo "git stash pop"
      git stash pop
    fi
  fi

  exit 0
fi

# ---------- 5️⃣  Action: View / Stash / Apply unstaged changes ----------------
if [[ $action == view_unstaged ]]; then
  echo
  echo "🔍  Checking for unstaged changes..."
  if ! git status -s | grep -q .; then
    echo "✅  No unstaged changes found."
    exit 0
  fi

  echo
  echo "📝  Unstaged changes (git diff --stat):"
  git diff --stat
  echo
  echo "📝  Full diff (press 'q' to quit):"
  git diff

  echo
  echo "What would you like to do?"
  echo "   (s) Stash these changes"
  echo "   (a) Apply the most recent stash (if any)"
  echo "   (l) List all stashes"
  echo "   (c) Cancel"
  read -r -p "Choose: [s/a/l/c] " sub_choice
  sub_choice=${sub_choice:-c}

  case $sub_choice in
    s|S)
      echo "git stash push -u -m \"stash from git.sh\""
      git stash push -u -m "stash from git.sh"
      echo "✔  Changes stashed."
      ;;
    a|A)
      if git stash list | grep -q .; then
        echo "git stash pop"
        git stash pop
        echo "✔  Applied most recent stash."
      else
        echo "❌  No stashes found."
      fi
      ;;
    l|L)
      echo "📋  List of stashes:"
      git stash list
      ;;
    c|C)
      echo "✅  Cancelled."
      ;;
    *)
      echo "❌  Unknown choice."
      ;;
  esac
  exit 0
fi

# ---------- 6️⃣  Action: Switch branch ----------------------------------------
if [[ $action == switch ]]; then
  echo
  echo "📁  Local branches (git branch --list):"
  echo "git branch --list"
  git branch --list

  read -r -p "Enter branch name (or number) to checkout: " sel

  # Convert numeric selection to a branch name
  if [[ $sel =~ ^[0-9]+$ ]]; then
    branches=($(git branch --format="%(refname:short)"))
    if (( sel < 0 || sel >= ${#branches[@]} )); then
      echo "❌  Invalid index." >&2; exit 1
    fi
    sel=${branches[$sel]}
  fi

  # --- Check for unstaged changes before switching --------------------------
  if git status -s | grep -q .; then
    echo "You have uncommitted changes:"
    git status -s
    read -r -p "Stash them before switching branches? (y/N): " stash_answer
    stash_answer=${stash_answer:-N}
    if [[ $stash_answer =~ ^[Yy]$ ]]; then
      echo "git stash -u -m \"stash before checkout\""
      git stash -u -m "stash before checkout"
    else
      echo "❌  Aborting – please commit or stash your changes first."
      exit 1
    fi
  fi

  echo "git checkout \"$sel\""
  git checkout "$sel"

  echo
  echo "✔  Switched to branch '$sel'."

  # --- Ask whether to pull the latest changes ("populate" the branch) ------
  echo
  echo "Current status (git status -sb):"
  echo "git status -sb"
  git status -sb
  read -r -p "Pull latest changes to populate branch? (y/N): " pull_answer
  pull_answer=${pull_answer:-N}
  if [[ $pull_answer =~ ^[Yy]$ ]]; then
    echo "git pull"
    git pull
  fi

  exit 0
fi

# ---------- 7️⃣  Action: Add new branch ---------------------------------------
if [[ $action == create ]]; then
  # --- Check for unstaged changes BEFORE creating branch --------------------
  if git status -s | grep -q .; then
    echo "You have uncommitted changes:"
    git status -s
    echo "⚠️  Creating a new branch with uncommitted changes can be risky."
    read -r -p "Stash them before creating branch? (y/N): " stash_answer
    stash_answer=${stash_answer:-N}
    if [[ $stash_answer =~ ^[Yy]$ ]]; then
      echo "git stash -u -m \"stash before new branch\""
      git stash -u -m "stash before new branch"
    else
      read -r -p "Proceed anyway? (y/N): " proceed
      proceed=${proceed:-N}
      if [[ ! $proceed =~ ^[Yy]$ ]]; then
        echo "❌  Aborted."
        exit 1
      fi
    fi
  fi

  read -r -p "Enter name for new branch (default: upgrades): " nb
  nb=${nb:-upgrades}

  # Reject invalid branch names
  if [[ $nb =~ [[:space:]] || $nb =~ [^a-zA-Z0-9._-] ]]; then
    echo "❌  Branch names may only contain letters, numbers, '.', '_' or '-'."
    exit 1
  fi

  # Abort if the branch already exists
  if git rev-parse --verify "$nb" &>/dev/null; then
    echo "⚠️  Branch '$nb' already exists."
    exit 1
  fi

  echo
  echo "⚠️  About to create branch '$nb' from 'main' and push it."
  read -r -p "Proceed? (y/N): " pr
  pr=${pr:-N}
  if [[ ! $pr =~ ^[Yy]$ ]]; then
    echo "❌  Aborted."
    exit 0
  fi

  echo "git fetch origin"
  git fetch origin

  echo "git checkout main"
  git checkout main

  echo "git pull --ff-only origin main"
  git pull --ff-only origin main

  echo "git checkout -b \"$nb\""
  git checkout -b "$nb"

  echo "git push -u origin \"$nb\""
  git push -u origin "$nb"

  echo "✔  Branch '$nb' created, checked out, and pushed."
  exit 0
fi

# ---------- 8️⃣  Action: Stage commit ---------------------------------------
if [[ $action == stage ]]; then
  echo "git add ."
  git add .

  echo
  echo "✅  Staged changes."
  read -r -p "Enter commit message: " msg
  msg=${msg:-"No message"}

  current_branch=$(git rev-parse --abbrev-ref HEAD)

  echo
  echo "📝  Commit details:"
  echo "   Branch : $current_branch"
  echo "   Message: $msg"
  read -r -p "Commit and push to '$current_branch'? (y/N): " push_choice
  push_choice=${push_choice:-N}

  if [[ $push_choice =~ ^[Yy]$ ]]; then
    echo "git commit -m \"$msg\""
    git commit -m "$msg"

    # Behind-ahead handling — ONLY if upstream exists
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
      upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
      echo "git status -sb"
      git status -sb

      ahead=$(git rev-list --count "$upstream..HEAD")     # Commits on HEAD not on remote → YOU ARE AHEAD
      behind=$(git rev-list --count "HEAD..$upstream")   # Commits on remote not on HEAD → YOU ARE BEHIND

      # If you’re BEHIND → pull & rebase
      if (( behind > 0 )); then
        echo "🎉  Branch $current_branch is behind $upstream by $behind commit(s)."
        if git status -s | grep -q .; then
          echo "git stash push -m \"pre-pull stash\""
          git stash push -m "pre-pull stash"
        fi
        echo "git pull --rebase"
        git pull --rebase
        if git stash list | grep -q "pre-pull stash"; then
          echo "git stash pop"
          git stash pop
        fi
      fi

      # If you’re AHEAD → just push (do NOT pull)
      if (( ahead > 0 )); then
        echo "📦  Branch $current_branch is ahead of $upstream by $ahead commit(s)."
      fi

    else
      echo "⚠️  No upstream set for branch '$current_branch'."
    fi

    echo "git push"
    git push
    echo "✔  Commit pushed to '$current_branch'."
  else
    echo "❌  Commit not pushed."
  fi
  exit 0
fi
