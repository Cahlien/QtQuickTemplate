# Navigation System Bugs

Three interacting defects in the NavigationController / NavigationStack system
cause a pop from the License page to sometimes land on the wrong page.

---

## Bug 1 — Tab clicks push instead of replacing

**Location:** `qml/Main.qml:95-96`

NavBar tab clicks call `NavigationController.push()`. Because the dedup guard
in `NavigationStack.onPushRequested` only checks the *current top* of the
StackView, switching between tabs silently grows the back-stack:

```
[Readme]                                 ← app start
[Readme, Controls]                       ← click Controls tab
[Readme, Controls, Readme]               ← click Readme tab (pushed again!)
[Readme, Controls, Readme, License]      ← click MIT License
[Readme, Controls, Readme]               ← pop  →  lands on Readme, not Controls
```

A single pop correctly returns to the last-pushed page, but that page is not
necessarily the one the user expects when tabs have been clicked more than once.

**Fix:** Tab navigation calls `NavigationController.replace()` instead of
`push()`. This swaps the top of the stack without growing it, which matches
standard flat-tab semantics: tabs replace, sub-pages push.

---

## Bug 2 — `syncNavigationState()` fires twice per StackView operation

**Location:** `qml/organisms/NavigationStack.qml:146-147`

Both `onCurrentItemChanged` and `onDepthChanged` call `syncNavigationState()`.
A single `stackView.pop()` emits both signals. When `depthChanged` fires
first — before `currentItem` has updated — the first `syncNavigationState()`
call reads the *outgoing* page from `stackView.currentItem` and sends its URL
to `NavigationController.setCurrent()` paired with the *new* depth. This emits
a spurious `currentChanged` with an inconsistent state snapshot. The second
call from `currentItemChanged` then corrects it, but the intermediate emission
is a source of unexpected binding evaluations and incorrect intermediate
values for `displayedShowChrome` and `pendingNavigationKey`.

**Fix:** Guard `syncNavigationState()` with a check on the current item's
`StackView.status`. During a pop the outgoing item has status `Deactivating`;
skip the sync in that case and let the subsequent `currentItemChanged` call
handle it with the correct item.

---

## Bug 3 — `pop()` emits `currentChanged` before the pop happens

**Location:** `src/main/common/navigation/navigation_controller.cpp:69-74`

`NavigationController::pop()` pushes the current entry onto the forward stack
and immediately emits `currentChanged` — *before* emitting `popRequested`.
At that moment every Q_PROPERTY that shares the `currentChanged` NOTIFY signal
(`currentUrl`, `canGoBack`, `canGoForward`, …) is re-read by QML, but
`currentUrl` and friends still describe the *about-to-be-popped* page.
The only visible change is `canGoForward` flipping to `true` while the URL
has not yet advanced.

`forward()` has the same pattern in reverse: it emits `currentChanged` after
`pushRequested`, which is redundant because `syncNavigationState()` →
`setCurrent()` already emits it with the fully-consistent state.

**Fix:** Remove the premature `emit currentChanged()` from `pop()` and the
redundant trailing `emit currentChanged()` from `forward()`. In both cases
the `setCurrent()` call triggered by `syncNavigationState()` emits
`currentChanged` with all properties in a consistent state.
