# cl-checkpoint-sync

Checkpoint-based fast sync for blockchain state synchronization with **zero external dependencies**.

## Features

- **Snapshot sync**: Download and verify state snapshots
- **Checkpoint validation**: Verify checkpoints against trusted roots
- **Incremental sync**: Resume interrupted downloads
- **State verification**: Merkle proof validation
- **Pure Common Lisp**: No CFFI, no external libraries

## Installation

```lisp
(asdf:load-system :cl-checkpoint-sync)
```

## Quick Start

```lisp
(use-package :cl-checkpoint-sync)

;; Initialize checkpoint sync
(let ((syncer (make-checkpoint-syncer
               :checkpoint-root *trusted-root*
               :peer-list *bootstrap-peers*)))
  ;; Start sync
  (sync-from-checkpoint syncer)
  ;; Get sync progress
  (sync-progress syncer))
```

## API Reference

- `(make-checkpoint-syncer &key checkpoint-root peer-list)` - Create syncer
- `(sync-from-checkpoint syncer)` - Start checkpoint sync
- `(sync-progress syncer)` - Get current progress
- `(verify-checkpoint checkpoint state-root)` - Verify checkpoint
- `(apply-checkpoint-state syncer state)` - Apply synced state

## Testing

```lisp
(asdf:test-system :cl-checkpoint-sync)
```

## License

BSD-3-Clause

Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
